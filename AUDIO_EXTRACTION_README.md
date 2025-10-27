# 视频音频提取本地存储管理器

本模块提供了一个完整的音频提取记录管理解决方案，用于管理从视频中提取的音频文件的本地存储、查询、统计等功能。

## 📁 文件结构

```
lib/shared/
├── models/
│   └── extracted_audio_item_model.dart      # 音频提取记录模型
├── managers/
│   └── extracted_audio_manager.dart         # 音频提取记录管理器
├── utils/
│   └── audio_logger.dart                    # 日志工具
└── examples/
    └── extracted_audio_example.dart         # 使用示例
```

## 🚀 快速开始

### 1. 添加依赖

在 `pubspec.yaml` 中已包含以下依赖：

```yaml
dependencies:
  shared_preferences: ^2.3.3  # 本地存储
  ffmpeg_kit_flutter_new: ^4.0.0  # FFmpeg 音频提取（需要单独添加）
```

### 2. 初始化管理器

```dart
import 'package:aigc_video_demo/shared/managers/extracted_audio_manager.dart';

// 在应用启动时初始化
final audioManager = ExtractedAudioManager();
await audioManager.initialize();
```

### 3. 基本使用

```dart
// 创建音频提取记录
final record = ExtractedAudioItemModel(
  videoPath: '/path/to/video.mp4',
  videoFileName: 'my_video.mp4',
  audioPath: '/path/to/audio.mp3',
  audioFileName: 'my_video_audio.mp3',
  audioFormat: AudioFormat.mp3,
  status: ExtractStatus.success,
  duration: 180000, // 3分钟
  bitrate: '192',
  sampleRate: '44100',
  channels: 2,
);

// 添加记录
await audioManager.addAudioRecord(record);

// 查询所有记录
final records = await audioManager.getAllRecords();

// 搜索记录
final results = await audioManager.searchByFileName('音乐');
```

## 📦 核心功能

### 1. ExtractedAudioItemModel（音频提取记录模型）

#### 主要字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String? | 唯一标识符 |
| `videoPath` | String? | 原视频文件路径 |
| `videoFileName` | String? | 原视频文件名 |
| `audioPath` | String? | 提取后的音频文件路径 |
| `audioFileName` | String? | 音频文件名 |
| `audioFormat` | AudioFormat? | 音频格式（MP3/AAC/WAV等） |
| `status` | ExtractStatus? | 提取状态（待提取/提取中/成功/失败） |
| `duration` | int? | 视频时长（毫秒） |
| `bitrate` | String? | 音频比特率 |
| `sampleRate` | String? | 音频采样率 |
| `channels` | int? | 音频声道数 |
| `tags` | List<String>? | 标签列表 |
| `isFavorite` | bool? | 是否收藏 |

#### 枚举类型

**AudioFormat（音频格式）**
- `mp3` - MP3 格式
- `aac` - AAC 格式
- `wav` - WAV 格式
- `m4a` - M4A 格式
- `flac` - FLAC 格式
- `ogg` - OGG 格式

**ExtractStatus（提取状态）**
- `pending` - 待提取
- `extracting` - 提取中
- `success` - 提取成功
- `failed` - 提取失败

#### 便捷方法

```dart
// 检查文件是否存在
final audioExists = await record.audioFileExists();
final videoExists = await record.videoFileExists();

// 获取格式化的信息
final audioSize = record.getFormattedAudioSize();  // "5.00 MB"
final duration = record.getFormattedDuration();    // "3:00"
final status = record.getStatusDescription();      // "提取成功"
```

### 2. ExtractedAudioManager（管理器）

#### 初始化

```dart
final manager = ExtractedAudioManager();
await manager.initialize();
```

#### CRUD 操作

**添加记录**
```dart
// 单条添加
await manager.addAudioRecord(record);

// 批量添加
await manager.addAudioRecords([record1, record2, record3]);
```

**更新记录**
```dart
// 更新整条记录
await manager.updateAudioRecord(record);

// 仅更新状态
await manager.updateExtractStatus(
  recordId,
  ExtractStatus.success,
  errorMessage: '提取失败原因', // 可选
);
```

**删除记录**
```dart
// 删除单条
await manager.deleteAudioRecord(recordId);

// 批量删除
await manager.deleteAudioRecords(['id1', 'id2', 'id3']);

// 清空所有
await manager.clearAllRecords();
```

**查询记录**
```dart
// 获取所有记录
final all = await manager.getAllRecords();

// 根据ID查询
final record = await manager.getRecordById(recordId);

// 获取记录数量
final count = await manager.getRecordCount();

// 根据视频路径查找
final records = await manager.getRecordsByVideoPath('/path/to/video.mp4');
```

#### 搜索和过滤

**按格式过滤**
```dart
final mp3Records = await manager.filterByFormat(AudioFormat.mp3);
```

**按状态过滤**
```dart
final successRecords = await manager.filterByStatus(ExtractStatus.success);
```

**按时间范围过滤**
```dart
final start = DateTime(2024, 1, 1);
final end = DateTime.now();
final records = await manager.filterByTimeRange(start, end);
```

**文件名搜索**
```dart
final results = await manager.searchByFileName('音乐');
```

**标签搜索**
```dart
final records = await manager.searchByTag('背景音乐');
```

**高级搜索**
```dart
final results = await manager.advancedSearch(
  keyword: 'video',
  audioFormat: AudioFormat.mp3,
  status: ExtractStatus.success,
  isFavorite: true,
  tags: ['音乐', '背景音'],
  startTime: DateTime(2024, 1, 1),
  endTime: DateTime.now(),
);
```

#### 排序功能

```dart
// 按创建时间排序
final sorted = await manager.sortByCreatedTime(ascending: false);

// 按完成时间排序
final sorted = await manager.sortByCompletedTime(ascending: false);

// 按文件名排序
final sorted = await manager.sortByFileName(ascending: true);

// 按文件大小排序
final sorted = await manager.sortByFileSize(ascending: false);
```

#### 收藏管理

```dart
// 切换收藏状态
await manager.toggleFavorite(recordId);

// 获取所有收藏
final favorites = await manager.getFavoriteRecords();
```

#### 标签管理

```dart
// 添加标签
await manager.addTag(recordId, '背景音乐');

// 移除标签
await manager.removeTag(recordId, '背景音乐');

// 获取所有标签
final tags = await manager.getAllTags();
```

#### 统计信息

```dart
// 获取统计对象
final stats = await manager.getStats();
print('总记录数: ${stats.totalCount}');
print('MP3: ${stats.mp3Count}');
print('成功: ${stats.successCount}');
print('失败: ${stats.failedCount}');

// 获取格式化的统计信息
final formatted = await manager.getFormattedStats();
print(formatted);
```

#### 导入导出

```dart
// 导出为 JSON
final jsonString = await manager.exportToJson();

// 从 JSON 导入（覆盖模式）
await manager.importFromJson(jsonString, merge: false);

// 从 JSON 导入（合并模式）
await manager.importFromJson(jsonString, merge: true);
```

## 💡 使用场景示例

### 场景 1: 完整的音频提取流程

```dart
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

Future<void> extractAudioFromVideo(String videoPath, String audioPath) async {
  final manager = ExtractedAudioManager();

  // 1. 创建待提取记录
  final record = ExtractedAudioItemModel(
    videoPath: videoPath,
    videoFileName: videoPath.split('/').last,
    audioPath: audioPath,
    audioFileName: audioPath.split('/').last,
    audioFormat: AudioFormat.mp3,
    status: ExtractStatus.pending,
  );

  // 2. 添加记录
  await manager.addAudioRecord(record);
  final recordId = record.id!;

  // 3. 更新为提取中
  await manager.updateExtractStatus(recordId, ExtractStatus.extracting);

  try {
    // 4. 使用 FFmpeg 提取音频
    final command = '-i "$videoPath" -q:a 0 -map a "$audioPath"';
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // 5. 提取成功，更新记录
        final file = File(audioPath);
        final fileSize = await file.length();

        final updatedRecord = record.copyWith(
          status: ExtractStatus.success,
          audioFileSize: fileSize,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await manager.updateAudioRecord(updatedRecord);
      } else {
        // 提取失败
        await manager.updateExtractStatus(
          recordId,
          ExtractStatus.failed,
          errorMessage: '提取失败',
        );
      }
    });
  } catch (e) {
    // 异常处理
    await manager.updateExtractStatus(
      recordId,
      ExtractStatus.failed,
      errorMessage: e.toString(),
    );
  }
}
```

### 场景 2: 展示音频列表

```dart
Future<void> showAudioList() async {
  final manager = ExtractedAudioManager();

  // 获取所有成功提取的记录，按时间排序
  final successRecords = await manager.filterByStatus(ExtractStatus.success);
  final sorted = await manager.sortByCreatedTime(ascending: false);

  for (var record in sorted) {
    print('━━━━━━━━━━━━━━━━━━━━━━');
    print('📁 ${record.audioFileName}');
    print('🎵 格式: ${record.audioFormat?.displayName}');
    print('⏱️  时长: ${record.getFormattedDuration()}');
    print('💾 大小: ${record.getFormattedAudioSize()}');
    print('🏷️  标签: ${record.tags?.join(', ') ?? '无'}');
    print('⭐ 收藏: ${record.isFavorite == true ? '是' : '否'}');
  }
}
```

### 场景 3: 清理失效记录

```dart
Future<void> cleanupInvalidRecords() async {
  final manager = ExtractedAudioManager();
  final records = await manager.getAllRecords();

  final idsToDelete = <String>[];

  for (var record in records) {
    // 检查音频文件是否存在
    final exists = await record.audioFileExists();
    if (!exists && record.id != null) {
      idsToDelete.add(record.id!);
    }
  }

  if (idsToDelete.isNotEmpty) {
    await manager.deleteAudioRecords(idsToDelete);
    print('已清理 ${idsToDelete.length} 条失效记录');
  }
}
```

## 🔧 配置说明

### 最大记录数量

默认最大记录数为 1000 条。可以修改 `ExtractedAudioManager` 中的常量：

```dart
static const int maxRecordCount = 1000;
```

### 日志开关

可以通过 `AudioLogger` 控制日志输出：

```dart
import 'package:aigc_video_demo/shared/utils/audio_logger.dart';

// 禁用调试日志
AudioLogger.instance.debugEnabled = false;
```

## 📝 注意事项

1. **初始化时机**：建议在应用启动时调用 `initialize()` 方法
2. **文件路径**：使用绝对路径，确保路径有效
3. **存储容量**：记录达到最大数量时，会自动删除最旧的记录
4. **并发操作**：管理器内部会自动处理并发保存
5. **错误处理**：所有异步方法都返回布尔值或可能为 null 的结果，请做好错误处理

## 🎯 常见问题

### Q: 如何在应用重启后保持数据？
A: 数据通过 SharedPreferences 自动持久化，无需额外操作。

### Q: 如何备份数据？
A: 使用 `exportToJson()` 导出为 JSON 字符串，保存到文件或云端。

### Q: 如何判断提取是否成功？
A: 检查记录的 `status` 字段是否为 `ExtractStatus.success`。

### Q: 如何获取某个视频的所有提取记录？
A: 使用 `getRecordsByVideoPath(videoPath)` 方法。

## 📚 相关资源

- [FFmpeg Kit Flutter 文档](https://pub.dev/packages/ffmpeg_kit_flutter_new)
- [SharedPreferences 文档](https://pub.dev/packages/shared_preferences)
- [使用示例代码](lib/shared/examples/extracted_audio_example.dart)

## 📄 许可证

本模块遵循项目整体许可证。
