import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aigc_video_demo/shared/managers/extracted_audio_manager.dart';
import 'package:aigc_video_demo/shared/models/extracted_audio_item_model.dart';
import 'package:aigc_video_demo/core/constants/ffmpeg_utils.dart';
import 'package:path_provider/path_provider.dart';

/// 音频提取示例页面
///
/// 演示如何使用 ExtractedAudioManager 管理从视频中提取的音频记录
class AudioExtractionExamplePage extends StatefulWidget {
  const AudioExtractionExamplePage({super.key});

  @override
  State<AudioExtractionExamplePage> createState() =>
      _AudioExtractionExamplePageState();
}

class _AudioExtractionExamplePageState
    extends State<AudioExtractionExamplePage> {
  final _audioManager = ExtractedAudioManager();
  List<ExtractedAudioItemModel> _audioRecords = [];
  AudioExtractStats? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// 初始化管理器
  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _audioManager.initialize();
    await _loadRecords();
    setState(() => _isLoading = false);
  }

  /// 加载所有记录
  Future<void> _loadRecords() async {
    final records = await _audioManager.getAllRecords();
    final stats = await _audioManager.getStats();
    setState(() {
      _audioRecords = records;
      _stats = stats;
    });
  }

  /// 从本地assets加载demo.mp4并提取音频
  Future<void> _addSampleRecord() async {
    try {
      // 1. 从assets加载视频文件到临时目录
      print('📂 开始从assets加载demo.mp4...');

      final ByteData data = await rootBundle.load('assets/demo.mp4');
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempVideoPath = '${tempDir.path}/demo_video_$timestamp.mp4';

      // 将asset写入临时文件
      final buffer = data.buffer;
      await File(tempVideoPath).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      print('✅ 视频已加载到: $tempVideoPath');

      final actualVideoPath = tempVideoPath;
      final videoFileName = 'demo.mp4';

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('正在提取音频...'),
              ],
            ),
          ),
        );
      }

      // 2. 获取视频信息
      final videoFile = File(actualVideoPath);

      int videoFileSize = 0;
      try {
        videoFileSize = await videoFile.length();
        print('📊 视频文件大小: ${(videoFileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      } catch (e) {
        print('❌ 无法读取视频文件: $e');
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 无法读取视频文件: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 3. 准备输出路径
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/extracted_audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final audioFileName = '${videoFileName.split('.').first}_$timestamp.mp3';
      final audioPath = '${audioDir.path}/$audioFileName';

      // 4. 创建待提取记录
      final record = ExtractedAudioItemModel(
        videoPath: actualVideoPath,
        videoFileName: videoFileName,
        audioPath: audioPath,
        audioFileName: audioFileName,
        audioFormat: AudioFormat.mp3,
        status: ExtractStatus.extracting,
        videoFileSize: videoFileSize,
      );

      await _audioManager.addAudioRecord(record);
      final recordId = record.id!;
      await _loadRecords();

      // 5. 使用 FfmpegUtilsKit 提取音频
      print('🎬 开始使用 FfmpegUtilsKit 提取音频...');
      print('📹 视频路径: $actualVideoPath');
      print('🎵 音频路径: $audioPath');

      final extractedPath = await FfmpegUtilsKit.transToMp3(
        actualVideoPath,
        timeoutCancelMilliseconds: 60000, // 60秒超时
      );

      // 6. 处理提取结果
      if (extractedPath != null) {
        // 提取成功 - FfmpegUtilsKit 将文件保存在临时目录，需要复制到我们的目标路径
        final tempAudioFile = File(extractedPath);
        final exists = await tempAudioFile.exists();

        if (!exists) {
          print('❌ 音频文件未生成');
          await _audioManager.updateExtractStatus(
            recordId,
            ExtractStatus.failed,
            errorMessage: '音频文件未生成',
          );
          await _loadRecords();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ 音频文件未生成'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        final tempAudioFileSize = await tempAudioFile.length();
        print('📊 临时音频文件大小: ${(tempAudioFileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        if (tempAudioFileSize == 0) {
          print('❌ 音频文件为空');
          await _audioManager.updateExtractStatus(
            recordId,
            ExtractStatus.failed,
            errorMessage: '音频文件为空 (0 bytes)',
          );
          await _loadRecords();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ 音频文件为空'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // 复制临时文件到目标路径
        print('📋 复制音频文件到: $audioPath');
        try {
          await tempAudioFile.copy(audioPath);
          print('✅ 音频文件复制成功');
        } catch (e) {
          print('❌ 复制音频文件失败: $e');
          await _audioManager.updateExtractStatus(
            recordId,
            ExtractStatus.failed,
            errorMessage: '复制音频文件失败: $e',
          );
          await _loadRecords();

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ 复制音频文件失败: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // 获取最终文件大小
        final audioFile = File(audioPath);
        final audioFileSize = await audioFile.length();
        print('📊 最终音频文件大小: ${(audioFileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        // 检测实际的音频格式
        AudioFormat actualFormat = AudioFormat.mp3;
        String actualFileName = audioFileName;

        if (extractedPath.endsWith('.m4a')) {
          actualFormat = AudioFormat.m4a;
          actualFileName = audioFileName.replaceAll('.mp3', '.m4a');
          print('ℹ️ 实际提取格式为 M4A');
        }

        // 更新记录为成功状态（使用目标路径而非临时路径）
        final updatedRecord = record.copyWith(
          audioPath: audioPath,
          audioFileName: actualFileName,
          audioFormat: actualFormat,
          status: ExtractStatus.success,
          audioFileSize: audioFileSize,
          bitrate: '192',
          sampleRate: '44100',
          channels: 2,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _audioManager.updateAudioRecord(updatedRecord);
        await _loadRecords();

        print('🎉 音频提取完全成功！');

        // 关闭加载对话框并显示成功消息
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ 音频提取成功！\n'
                '格式：${actualFormat.displayName.toUpperCase()}\n'
                '文件：$actualFileName\n'
                '大小：${(audioFileSize / 1024 / 1024).toStringAsFixed(2)} MB'
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 提取失败
        print('❌ FfmpegUtilsKit.transToMp3 返回 null');

        // 提取失败的原因可能是：视频无音频、格式不支持、FFmpeg执行超时等
        String errorMsg = 'FfmpegUtilsKit 音频提取失败';

        await _audioManager.updateExtractStatus(
          recordId,
          ExtractStatus.failed,
          errorMessage: errorMsg,
        );
        await _loadRecords();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ 音频提取失败\n\n'
                '可能的原因：\n'
                '• 视频文件不包含音频（只有画面）\n'
                '• 视频格式不支持\n'
                '• 文件已损坏\n'
                '• FFmpeg执行超时\n\n'
                '建议：选择包含声音的视频文件'
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // 异常处理
      print('❌ 提取过程发生异常: $e');
      print('堆栈追踪: $stackTrace');

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // 确保关闭对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 提取过程出错:\n$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(String id) async {
    await _audioManager.toggleFavorite(id);
    await _loadRecords();
  }

  /// 删除记录
  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audioManager.deleteAudioRecord(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ 记录已删除')),
        );
      }
      await _loadRecords();
    }
  }

  /// 清空所有记录
  Future<void> _clearAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audioManager.clearAllRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ 所有记录已清空')),
        );
      }
      await _loadRecords();
    }
  }

  /// 显示统计信息
  Future<void> _showStats() async {
    final formattedStats = await _audioManager.getFormattedStats();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('统计信息'),
        content: SingleChildScrollView(
          child: Text(formattedStats),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音频提取管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStats,
            tooltip: '统计信息',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _audioRecords.isEmpty ? null : _clearAllRecords,
            tooltip: '清空所有',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 统计卡片
                if (_stats != null) _buildStatsCard(),

                // 操作按钮
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addSampleRecord,
                          icon: const Icon(Icons.audiotrack),
                          label: const Text('提取Demo视频音频'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadRecords,
                          icon: const Icon(Icons.refresh),
                          label: const Text('刷新'),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // 记录列表
                Expanded(
                  child: _audioRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无音频提取记录',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击上方按钮提取Demo视频的音频',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _audioRecords.length,
                          itemBuilder: (context, index) {
                            final record = _audioRecords[index];
                            return _buildRecordCard(record);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.folder,
              '总数',
              '${_stats!.totalCount}',
              Colors.blue,
            ),
            _buildStatItem(
              Icons.check_circle,
              '成功',
              '${_stats!.successCount}',
              Colors.green,
            ),
            _buildStatItem(
              Icons.error,
              '失败',
              '${_stats!.failedCount}',
              Colors.red,
            ),
            _buildStatItem(
              Icons.favorite,
              '收藏',
              '${_stats!.favoriteCount}',
              Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(ExtractedAudioItemModel record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Icon(
                    _getFormatIcon(record.audioFormat),
                    color: _getStatusColor(record.status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.audioFileName ?? '未命名',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      record.isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: record.isFavorite == true
                          ? Colors.pink
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(record.id!),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 信息行
              Row(
                children: [
                  _buildInfoChip(
                    Icons.schedule,
                    record.getFormattedDuration(),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.storage,
                    record.getFormattedAudioSize(),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.audiotrack,
                    record.audioFormat?.displayName ?? '未知',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 状态和标签
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.getStatusDescription(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(record.status),
                      ),
                    ),
                  ),
                  if (record.tags != null && record.tags!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: record.tags!
                            .take(3)
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  labelStyle: const TextStyle(fontSize: 10),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRecord(record.id!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// 显示记录详情
  void _showRecordDetails(ExtractedAudioItemModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.audioFileName ?? '音频详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('视频文件', record.videoFileName ?? '-'),
              _buildDetailRow('音频文件', record.audioFileName ?? '-'),
              _buildDetailRow('格式', record.audioFormat?.displayName ?? '-'),
              _buildDetailRow('状态', record.getStatusDescription()),
              _buildDetailRow('时长', record.getFormattedDuration()),
              _buildDetailRow('音频大小', record.getFormattedAudioSize()),
              _buildDetailRow('视频大小', record.getFormattedVideoSize()),
              _buildDetailRow('比特率', '${record.bitrate ?? '-'} kbps'),
              _buildDetailRow('采样率', '${record.sampleRate ?? '-'} Hz'),
              _buildDetailRow('声道', '${record.channels ?? '-'}'),
              _buildDetailRow(
                  '标签', record.tags?.join(', ') ?? '-'),
              _buildDetailRow('收藏', record.isFavorite == true ? '是' : '否'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 获取格式图标
  IconData _getFormatIcon(AudioFormat? format) {
    switch (format) {
      case AudioFormat.mp3:
        return Icons.audiotrack;
      case AudioFormat.aac:
        return Icons.audio_file;
      case AudioFormat.wav:
        return Icons.graphic_eq;
      case AudioFormat.m4a:
        return Icons.music_note;
      case AudioFormat.flac:
        return Icons.high_quality;
      case AudioFormat.ogg:
        return Icons.album;
      case null:
        return Icons.help_outline;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(ExtractStatus? status) {
    switch (status) {
      case ExtractStatus.pending:
        return Colors.orange;
      case ExtractStatus.extracting:
        return Colors.blue;
      case ExtractStatus.success:
        return Colors.green;
      case ExtractStatus.failed:
        return Colors.red;
      case null:
        return Colors.grey;
    }
  }
}
