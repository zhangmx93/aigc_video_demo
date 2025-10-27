import 'package:aigc_video_demo/shared/managers/extracted_audio_manager.dart';
import 'package:aigc_video_demo/shared/models/extracted_audio_item_model.dart';

/// 视频音频提取管理器使用示例
///
/// 本示例演示如何使用 ExtractedAudioManager 和 ExtractedAudioItemModel
/// 来管理从视频中提取的音频文件
class ExtractedAudioExample {
  final _audioManager = ExtractedAudioManager();

  /// 示例 1: 初始化管理器
  Future<void> initializeExample() async {
    // 在应用启动时初始化管理器
    await _audioManager.initialize();
    print('管理器初始化完成');
  }

  /// 示例 2: 添加新的音频提取记录
  Future<void> addRecordExample() async {
    // 创建一个新的音频提取记录
    final newRecord = ExtractedAudioItemModel(
      videoPath: '/path/to/video.mp4',
      videoFileName: 'my_video.mp4',
      audioPath: '/path/to/extracted/audio.mp3',
      audioFileName: 'my_video_audio.mp3',
      audioFormat: AudioFormat.mp3,
      status: ExtractStatus.success,
      videoFileSize: 104857600, // 100 MB
      audioFileSize: 5242880,   // 5 MB
      duration: 180000,         // 3分钟（毫秒）
      bitrate: '192',
      sampleRate: '44100',
      channels: 2,
      tags: ['音乐', '背景音'],
      isFavorite: false,
    );

    // 添加记录
    final success = await _audioManager.addAudioRecord(newRecord);
    if (success) {
      print('音频记录添加成功！');
      print('记录ID: ${newRecord.id}');
      print('音频大小: ${newRecord.getFormattedAudioSize()}');
      print('时长: ${newRecord.getFormattedDuration()}');
    }
  }

  /// 示例 3: 更新提取状态（用于提取过程中）
  Future<void> updateStatusExample() async {
    // 假设我们有一个记录ID
    const recordId = 'some_record_id';

    // 开始提取时
    await _audioManager.updateExtractStatus(
      recordId,
      ExtractStatus.extracting,
    );

    // 模拟提取过程...
    await Future.delayed(const Duration(seconds: 3));

    // 提取成功
    await _audioManager.updateExtractStatus(
      recordId,
      ExtractStatus.success,
    );

    // 如果提取失败
    // await _audioManager.updateExtractStatus(
    //   recordId,
    //   ExtractStatus.failed,
    //   errorMessage: '提取失败：文件损坏',
    // );
  }

  /// 示例 4: 查询所有音频记录
  Future<void> getAllRecordsExample() async {
    final records = await _audioManager.getAllRecords();
    print('共有 ${records.length} 条音频记录');

    for (var record in records) {
      print('---');
      print('ID: ${record.id}');
      print('视频: ${record.videoFileName}');
      print('音频: ${record.audioFileName}');
      print('格式: ${record.audioFormat?.displayName}');
      print('状态: ${record.getStatusDescription()}');
      print('大小: ${record.getFormattedAudioSize()}');
      print('时长: ${record.getFormattedDuration()}');
    }
  }

  /// 示例 5: 按格式筛选
  Future<void> filterByFormatExample() async {
    // 获取所有 MP3 格式的记录
    final mp3Records = await _audioManager.filterByFormat(AudioFormat.mp3);
    print('MP3 格式记录数: ${mp3Records.length}');

    // 获取所有 AAC 格式的记录
    final aacRecords = await _audioManager.filterByFormat(AudioFormat.aac);
    print('AAC 格式记录数: ${aacRecords.length}');
  }

  /// 示例 6: 按状态筛选
  Future<void> filterByStatusExample() async {
    // 获取所有成功提取的记录
    final successRecords = await _audioManager.filterByStatus(ExtractStatus.success);
    print('成功提取的记录数: ${successRecords.length}');

    // 获取所有失败的记录
    final failedRecords = await _audioManager.filterByStatus(ExtractStatus.failed);
    print('提取失败的记录数: ${failedRecords.length}');
  }

  /// 示例 7: 搜索功能
  Future<void> searchExample() async {
    // 根据文件名搜索
    final results = await _audioManager.searchByFileName('音乐');
    print('搜索到 ${results.length} 条包含"音乐"的记录');

    // 高级搜索
    final advancedResults = await _audioManager.advancedSearch(
      keyword: 'video',
      audioFormat: AudioFormat.mp3,
      status: ExtractStatus.success,
      isFavorite: true,
      tags: ['音乐'],
    );
    print('高级搜索结果: ${advancedResults.length} 条');
  }

  /// 示例 8: 收藏管理
  Future<void> favoriteExample() async {
    const recordId = 'some_record_id';

    // 切换收藏状态
    await _audioManager.toggleFavorite(recordId);

    // 获取所有收藏的记录
    final favorites = await _audioManager.getFavoriteRecords();
    print('收藏的记录数: ${favorites.length}');
  }

  /// 示例 9: 标签管理
  Future<void> tagManagementExample() async {
    const recordId = 'some_record_id';

    // 添加标签
    await _audioManager.addTag(recordId, '背景音乐');
    await _audioManager.addTag(recordId, '无损');

    // 根据标签搜索
    final bgmRecords = await _audioManager.searchByTag('背景音乐');
    print('背景音乐标签的记录数: ${bgmRecords.length}');

    // 移除标签
    await _audioManager.removeTag(recordId, '无损');

    // 获取所有使用过的标签
    final allTags = await _audioManager.getAllTags();
    print('所有标签: ${allTags.join(', ')}');
  }

  /// 示例 10: 排序功能
  Future<void> sortExample() async {
    // 按创建时间排序（最新的在前）
    final sortedByTime = await _audioManager.sortByCreatedTime(ascending: false);
    print('最新的记录: ${sortedByTime.first.audioFileName}');

    // 按文件名排序
    final sortedByName = await _audioManager.sortByFileName(ascending: true);
    print('按文件名排序后的第一条: ${sortedByName.first.audioFileName}');

    // 按文件大小排序
    final sortedBySize = await _audioManager.sortByFileSize(ascending: false);
    print('最大的音频文件: ${sortedBySize.first.audioFileName} - ${sortedBySize.first.getFormattedAudioSize()}');
  }

  /// 示例 11: 统计信息
  Future<void> statsExample() async {
    // 获取统计信息
    final stats = await _audioManager.getStats();
    print('总记录数: ${stats.totalCount}');
    print('MP3: ${stats.mp3Count}');
    print('AAC: ${stats.aacCount}');
    print('成功: ${stats.successCount}');
    print('失败: ${stats.failedCount}');
    print('收藏: ${stats.favoriteCount}');

    // 获取格式化的统计信息
    final formattedStats = await _audioManager.getFormattedStats();
    print(formattedStats);
  }

  /// 示例 12: 删除记录
  Future<void> deleteExample() async {
    const recordId = 'some_record_id';

    // 删除单条记录
    await _audioManager.deleteAudioRecord(recordId);

    // 批量删除
    await _audioManager.deleteAudioRecords(['id1', 'id2', 'id3']);

    // 清空所有记录
    // await _audioManager.clearAllRecords();
  }

  /// 示例 13: 导入导出
  Future<void> importExportExample() async {
    // 导出为 JSON
    final jsonString = await _audioManager.exportToJson();
    print('导出的JSON长度: ${jsonString.length}');

    // 保存到文件或上传到服务器...
    // await File('backup.json').writeAsString(jsonString);

    // 从 JSON 导入（覆盖模式）
    // await _audioManager.importFromJson(jsonString, merge: false);

    // 从 JSON 导入（合并模式）
    // await _audioManager.importFromJson(jsonString, merge: true);
  }

  /// 示例 14: 完整的音频提取流程
  Future<void> completeExtractFlowExample() async {
    // 1. 创建待提取记录
    final record = ExtractedAudioItemModel(
      videoPath: '/path/to/video.mp4',
      videoFileName: 'video.mp4',
      audioPath: '/path/to/output.mp3',
      audioFileName: 'output.mp3',
      audioFormat: AudioFormat.mp3,
      status: ExtractStatus.pending,
    );

    // 2. 添加记录
    await _audioManager.addAudioRecord(record);
    final recordId = record.id!;

    // 3. 更新状态为提取中
    await _audioManager.updateExtractStatus(recordId, ExtractStatus.extracting);

    try {
      // 4. 执行实际的音频提取（使用 ffmpeg_kit_flutter_new）
      // final command = '-i "${record.videoPath}" -q:a 0 -map a "${record.audioPath}"';
      // await FFmpegKit.execute(command).then((session) async {
      //   final returnCode = await session.getReturnCode();
      //   if (ReturnCode.isSuccess(returnCode)) {
      //     // 提取成功，更新记录
      //     ...
      //   }
      // });

      // 5. 提取成功后更新记录信息
      final updatedRecord = record.copyWith(
        status: ExtractStatus.success,
        audioFileSize: 5242880, // 实际文件大小
        duration: 180000,       // 实际时长
        bitrate: '192',
        sampleRate: '44100',
        channels: 2,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _audioManager.updateAudioRecord(updatedRecord);
      print('✅ 音频提取完成！');
    } catch (e) {
      // 6. 提取失败，更新状态
      await _audioManager.updateExtractStatus(
        recordId,
        ExtractStatus.failed,
        errorMessage: e.toString(),
      );
      print('❌ 音频提取失败: $e');
    }
  }

  /// 示例 15: 检查音频文件是否存在
  Future<void> checkFileExistsExample() async {
    final records = await _audioManager.getAllRecords();

    for (var record in records) {
      final audioExists = await record.audioFileExists();
      final videoExists = await record.videoFileExists();

      print('记录: ${record.audioFileName}');
      print('  音频文件存在: $audioExists');
      print('  视频文件存在: $videoExists');
    }
  }
}

/// 在应用中使用的完整示例
void main() async {
  final example = ExtractedAudioExample();

  // 1. 初始化
  await example.initializeExample();

  // 2. 添加记录
  await example.addRecordExample();

  // 3. 查询记录
  await example.getAllRecordsExample();

  // 4. 搜索和筛选
  await example.searchExample();

  // 5. 统计信息
  await example.statsExample();
}
