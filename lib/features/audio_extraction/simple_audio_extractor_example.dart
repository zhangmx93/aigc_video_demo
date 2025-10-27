import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'simple_audio_extractor.dart';

/// SimpleAudioExtractor 使用示例页面
class SimpleAudioExtractorExamplePage extends StatefulWidget {
  const SimpleAudioExtractorExamplePage({super.key});

  @override
  State<SimpleAudioExtractorExamplePage> createState() =>
      _SimpleAudioExtractorExamplePageState();
}

class _SimpleAudioExtractorExamplePageState
    extends State<SimpleAudioExtractorExamplePage> {
  String? _selectedVideoPath;
  String? _extractedAudioPath;
  bool _isExtracting = false;
  bool _isConverting = false;
  String _statusMessage = '请选择一个视频文件';

  // 音频播放器
  Player? _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速音频提取器'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 视频文件选择
            _buildVideoSection(),
            const SizedBox(height: 24),

            // 提取按钮
            _buildExtractButton(),
            const SizedBox(height: 24),

            // 状态信息
            _buildStatusSection(),
            const SizedBox(height: 24),

            // 结果显示
            if (_extractedAudioPath != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '视频文件',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickVideoFile,
              icon: const Icon(Icons.video_library),
              label: const Text('选择视频文件'),
            ),
            if (_selectedVideoPath != null) ...[
              const SizedBox(height: 12),
              Text(
                '已选择: ${_getFileName(_selectedVideoPath!)}',
                style: const TextStyle(color: Colors.green),
              ),
              Text(
                '路径: $_selectedVideoPath',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtractButton() {
    return ElevatedButton.icon(
      onPressed: _selectedVideoPath != null && !_isExtracting
          ? _extractAudioFast
          : null,
      icon: _isExtracting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.flash_on),
      label: Text(_isExtracting ? '提取中...' : '快速提取音频'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.orange,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      color: _extractedAudioPath != null ? Colors.green[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _extractedAudioPath != null
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: _extractedAudioPath != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '提取结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.audio_file, color: Colors.blue),
              title: Text(_getFileName(_extractedAudioPath!)),
              subtitle: Text(_extractedAudioPath!),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteExtractedAudio,
              ),
            ),
            const SizedBox(height: 12),

            // 音频播放控制器
            if (_audioPlayer != null) _buildAudioPlayerControls(),

            const SizedBox(height: 12),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _audioPlayer == null ? _initAudioPlayer : _togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_audioPlayer == null ? '播放音频' : (_isPlaying ? '暂停' : '播放')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAudioInfo,
                    icon: const Icon(Icons.info),
                    label: const Text('音频信息'),
                  ),
                ),
              ],
            ),

            // 转换按钮 (仅当文件是 m4a 格式时显示)
            if (_extractedAudioPath != null && _extractedAudioPath!.endsWith('.m4a')) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isConverting ? null : _convertToMP3,
                icon: _isConverting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.transform),
                label: Text(_isConverting ? '转换中...' : '转换为 MP3 格式'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerControls() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 进度条
            Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble().clamp(
                      0.0,
                      _totalDuration.inMilliseconds.toDouble() > 0
                          ? _totalDuration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    min: 0,
                    max: _totalDuration.inMilliseconds.toDouble() > 0
                        ? _totalDuration.inMilliseconds.toDouble()
                        : 1,
                    onChanged: (value) {
                      _audioPlayer?.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),

            // 播放控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final newPosition = _currentPosition - const Duration(seconds: 10);
                    _audioPlayer?.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                  iconSize: 48,
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final newPosition = _currentPosition + const Duration(seconds: 10);
                    _audioPlayer?.seek(newPosition > _totalDuration ? _totalDuration : newPosition);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () {
                    _audioPlayer?.stop();
                    setState(() {
                      _isPlaying = false;
                      _currentPosition = Duration.zero;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoPath = result.files.single.path;
          _extractedAudioPath = null;
          _statusMessage = '视频文件已选择,请选择格式和质量后提取';
        });

        // 检查是否包含音频流
        final hasAudio =
            await SimpleAudioExtractor.hasAudioStream(_selectedVideoPath!);
        if (!hasAudio) {
          setState(() {
            _statusMessage = '警告: 该视频可能不包含音频流';
          });
        }
      }
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  Future<void> _extractAudioFast() async {
    if (_selectedVideoPath == null) return;

    setState(() {
      _isExtracting = true;
      _statusMessage = '正在快速提取音频(流复制模式)...';
      _extractedAudioPath = null;
    });

    try {
      final audioPath = await SimpleAudioExtractor.extractAudioFast(
        videoPath: _selectedVideoPath!,
      );

      setState(() {
        _isExtracting = false;
        if (audioPath != null) {
          _extractedAudioPath = audioPath;
          _statusMessage = '音频快速提取成功!';
        } else {
          _statusMessage = '快速提取失败,请尝试普通提取';
        }
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _statusMessage = '快速提取异常: $e';
      });
    }
  }

  /// 初始化音频播放器
  Future<void> _initAudioPlayer() async {
    if (_extractedAudioPath == null) return;

    try {
      // 先释放旧的播放器
      await _audioPlayer?.dispose();

      // 创建新的播放器
      _audioPlayer = Player();

      // 监听播放状态
      _audioPlayer!.stream.playing.listen((isPlaying) {
        if (mounted) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });

      // 监听播放位置
      _audioPlayer!.stream.position.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });

      // 监听总时长
      _audioPlayer!.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });

      // 加载音频文件
      await _audioPlayer!.open(Media(_extractedAudioPath!));

      if (!mounted) return;

      setState(() {
        _statusMessage = '音频播放器已就绪';
      });
    } catch (e) {
      _showError('初始化播放器失败: $e');
    }
  }

  /// 切换播放/暂停状态
  void _togglePlayPause() {
    if (_audioPlayer == null) return;

    if (_isPlaying) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.play();
    }
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _showAudioInfo() async {
    if (_selectedVideoPath == null) return;

    final audioInfo =
        await SimpleAudioExtractor.getAudioInfo(_selectedVideoPath!);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音频信息'),
        content: audioInfo != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('编码器: ${audioInfo['codec'] ?? '未知'}'),
                  Text('采样率: ${audioInfo['sampleRate'] ?? '未知'} Hz'),
                  Text('声道: ${audioInfo['channels'] ?? '未知'}'),
                  Text('比特率: ${audioInfo['bitrate'] ?? '未知'} kb/s'),
                ],
              )
            : const Text('无法获取音频信息'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 将 M4A 格式转换为 MP3 格式
  Future<void> _convertToMP3() async {
    if (_extractedAudioPath == null || !_extractedAudioPath!.endsWith('.m4a')) {
      _showError('只能转换 M4A 格式的音频文件');
      return;
    }

    setState(() {
      _isConverting = true;
      _statusMessage = '正在转换为 MP3 格式...';
    });

    try {
      // 先停止播放
      await _audioPlayer?.pause();

      // 生成输出路径
      final mp3OutputPath = _extractedAudioPath!.replaceAll('.m4a', '.mp3');
      final tempWavPath = _extractedAudioPath!.replaceAll('.m4a', '_temp.wav');

      String? resultPath;

      // 策略1: 直接转换
      print('🔄 策略1: 尝试直接转换...');
      resultPath = await _convertDirectly(_extractedAudioPath!, mp3OutputPath);

      if (resultPath == null) {
        // 策略2: 两步法 (通过WAV中转)
        print('🔄 策略2: 尝试两步法(WAV中转)...');
        resultPath = await _convertViaWav(_extractedAudioPath!, mp3OutputPath, tempWavPath);
      }

      if (resultPath != null) {
        // 删除原来的 M4A 文件
        try {
          await File(_extractedAudioPath!).delete();
        } catch (e) {
          print('⚠️ 删除原文件失败: $e');
        }

        // 释放当前播放器
        await _audioPlayer?.dispose();
        _audioPlayer = null;

        setState(() {
          _isConverting = false;
          _extractedAudioPath = resultPath;
          _isPlaying = false;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
          _statusMessage = 'MP3 转换成功! 文件已保存';
        });

        _showSuccess('音频已成功转换为 MP3 格式');
      } else {
        setState(() {
          _isConverting = false;
          _statusMessage = 'MP3 转换失败';
        });
        _showError('所有转换策略都失败了');
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
        _statusMessage = '转换异常: $e';
      });
      _showError('转换异常: $e');
    }
  }

  /// 策略1: 直接转换
  Future<String?> _convertDirectly(String inputPath, String outputPath) async {
    try {
      final command = '-i "$inputPath" -c:a libmp3lame -q:a 2 -y "$outputPath"';
      print('🎬 直接转换命令: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          print('✅ 直接转换成功');
          return outputPath;
        }
      }

      print('❌ 直接转换失败');
      await _logConversionError(session);
      return null;
    } catch (e) {
      print('⚠️ 直接转换异常: $e');
      return null;
    }
  }

  /// 策略2: 两步法 - 先转WAV再转MP3
  Future<String?> _convertViaWav(
    String inputPath,
    String mp3OutputPath,
    String tempWavPath,
  ) async {
    try {
      // 步骤1: M4A → WAV
      final extractCommand = '-i "$inputPath" -acodec pcm_s16le -y "$tempWavPath"';
      print('🎬 步骤1 - 转换为WAV: $extractCommand');

      final extractSession = await FFmpegKit.execute(extractCommand);
      final extractCode = await extractSession.getReturnCode();

      if (!ReturnCode.isSuccess(extractCode)) {
        print('❌ WAV转换失败');
        await _logConversionError(extractSession);
        return null;
      }

      final wavFile = File(tempWavPath);
      if (!await wavFile.exists() || await wavFile.length() == 0) {
        print('❌ WAV文件无效');
        return null;
      }

      // 步骤2: WAV → MP3
      final convertCommand = '-i "$tempWavPath" -c:a libmp3lame -q:a 2 -y "$mp3OutputPath"';
      print('🎬 步骤2 - 转换为MP3: $convertCommand');

      final convertSession = await FFmpegKit.execute(convertCommand);
      final convertCode = await convertSession.getReturnCode();

      // 删除临时WAV文件
      try {
        await wavFile.delete();
      } catch (e) {
        print('⚠️ 删除临时WAV文件失败: $e');
      }

      if (ReturnCode.isSuccess(convertCode)) {
        final mp3File = File(mp3OutputPath);
        if (await mp3File.exists() && await mp3File.length() > 0) {
          print('✅ 两步法转换成功');
          return mp3OutputPath;
        }
      }

      print('❌ MP3转换失败');
      await _logConversionError(convertSession);
      return null;
    } catch (e) {
      print('⚠️ 两步法转换异常: $e');

      // 清理临时文件
      try {
        await File(tempWavPath).delete();
      } catch (_) {}

      return null;
    }
  }

  /// 记录转换错误日志
  Future<void> _logConversionError(dynamic session) async {
    try {
      final logs = await session.getAllLogs();
      final errorLogs = logs.where((log) {
        final message = log.getMessage().toLowerCase();
        return message.contains('error') || message.contains('failed');
      }).take(3);

      if (errorLogs.isNotEmpty) {
        print('📋 错误信息:');
        for (final log in errorLogs) {
          print('  ${log.getMessage()}');
        }
      }
    } catch (e) {
      print('⚠️ 获取错误日志失败: $e');
    }
  }

  Future<void> _deleteExtractedAudio() async {
    if (_extractedAudioPath == null) return;

    try {
      // 先停止并释放播放器
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      final file = File(_extractedAudioPath!);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _extractedAudioPath = null;
          _isPlaying = false;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
          _statusMessage = '已删除提取的音频文件';
        });
      }
    } catch (e) {
      _showError('删除文件失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }
}
