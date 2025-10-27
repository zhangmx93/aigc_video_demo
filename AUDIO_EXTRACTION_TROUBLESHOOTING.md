# 🔧 音频提取失败故障排查指南

## 查看调试日志

我已经在代码中添加了详细的日志输出。请按以下步骤查看：

### 1. 在终端查看日志

运行应用时，在终端中会看到这些日志：

```
🎬 开始提取音频...
📹 视频路径: /path/to/video.mp4
🎵 音频路径: /path/to/audio.mp3
⚙️ FFmpeg命令: -i "/path/to/video.mp4" -vn -ar 44100 -ac 2 -b:a 192k -y "/path/to/audio.mp3"
🔍 FFmpeg 返回码: xxx
📝 FFmpeg 输出日志:
...
```

### 2. 查看应用内错误提示

提取失败时，应用会显示详细的错误信息，包括：
- FFmpeg 错误码
- 关键错误日志
- 文件路径信息

## 常见问题及解决方案

### 问题 1: MissingPluginException

**错误信息：**
```
MissingPluginException(No implementation found for method...)
```

**原因：** FFmpeg 插件未正确注册

**解决方案：**
```bash
# 1. 完全停止应用
# 2. 清理项目
flutter clean

# 3. 重新获取依赖
flutter pub get

# 4. 完全重启应用（不要用热重载）
flutter run
```

### 问题 2: 视频文件路径包含特殊字符

**错误信息：**
```
No such file or directory
```

**原因：** 文件路径包含空格或特殊字符

**解决方案：**
已在代码中用双引号包裹路径：
```dart
final command = '-i "$videoPath" -vn -ar 44100 -ac 2 -b:a 192k -y "$audioPath"';
```

如果仍然失败，检查视频文件名是否包含特殊字符。

### 问题 3: 视频编码格式不支持

**错误信息：**
```
Invalid data found when processing input
Unsupported codec
```

**原因：** 视频编码格式 FFmpeg 不支持

**解决方案：**
尝试使用更通用的提取命令：
```dart
// 简化版命令，自动检测音频流
final command = '-i "$videoPath" -vn -acodec libmp3lame -y "$audioPath"';

// 或者直接复制音频流（最快，但可能不兼容）
final command = '-i "$videoPath" -vn -acodec copy -y "$audioPath"';
```

### 问题 4: 输出目录权限问题

**错误信息：**
```
Permission denied
Cannot write to output file
```

**原因：** 应用对输出目录没有写权限

**解决方案：**

#### Android:
检查 `AndroidManifest.xml` 权限：
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

在运行时请求权限：
```dart
import 'package:permission_handler/permission_handler.dart';

// 请求存储权限
await Permission.storage.request();
```

#### iOS:
检查 `Info.plist` 权限：
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册</string>
```

### 问题 5: 文件选择器返回空路径

**错误信息：**
```
❌ 无法获取视频路径
```

**原因：**
- 用户取消选择
- FilePicker 无法访问文件

**解决方案：**
确保权限已授予，并且从支持的位置选择文件。

### 问题 6: 音频流不存在

**错误信息：**
```
Stream specifier ':a' in filtergraph description
Output file does not contain any stream
```

**原因：** 视频文件中没有音频流

**解决方案：**

修改代码检查音频流：
```dart
// 先检查视频是否有音频流
final checkCommand = '-i "$videoPath" 2>&1';
// 然后根据检查结果决定是否提取
```

### 问题 7: FFmpeg 超时

**错误信息：**
处理一直在进行，但从不完成

**原因：**
- 视频文件太大
- 设备性能不足

**解决方案：**

1. 限制视频大小：
```dart
// 检查文件大小
if (videoFileSize > 500 * 1024 * 1024) { // 500 MB
  // 提示用户文件太大
  return;
}
```

2. 添加超时处理：
```dart
await FFmpegKit.execute(command).timeout(
  const Duration(minutes: 5),
  onTimeout: () {
    print('❌ 提取超时');
    return null;
  },
);
```

## 调试步骤

### 步骤 1: 检查 FFmpeg 是否正常工作

在 `initState` 中添加测试：
```dart
Future<void> _testFFmpeg() async {
  try {
    await FFmpegKit.execute('-version').then((session) async {
      final logs = await session.getOutput();
      print('FFmpeg 版本信息:');
      print(logs);
    });
  } catch (e) {
    print('❌ FFmpeg 测试失败: $e');
  }
}
```

### 步骤 2: 测试简单的音频提取

使用最简单的命令：
```dart
final command = '-i "$videoPath" "$audioPath"';
```

如果成功，逐步添加参数：
```dart
// 第一步：只指定输出格式
final command = '-i "$videoPath" -f mp3 "$audioPath"';

// 第二步：添加音频编码
final command = '-i "$videoPath" -f mp3 -acodec libmp3lame "$audioPath"';

// 第三步：添加完整参数
final command = '-i "$videoPath" -vn -ar 44100 -ac 2 -b:a 192k "$audioPath"';
```

### 步骤 3: 检查文件路径

添加路径验证：
```dart
print('视频文件是否存在: ${await File(videoPath).exists()}');
print('输出目录是否存在: ${await Directory(audioDir.path).exists()}');
print('输出目录权限: ${await _checkDirectoryPermission(audioDir.path)}');
```

### 步骤 4: 查看完整的 FFmpeg 日志

查看所有日志内容（不要只看错误）：
```dart
final allLogs = await session.getAllLogsAsString();
print('完整日志：');
print(allLogs);
```

## 使用简化版命令（推荐用于调试）

如果所有方法都失败，尝试这个最简单的版本：

```dart
// 最简单的音频提取命令
final command = '-i "$videoPath" -vn -c:a copy "$audioPath"';

// 如果上面失败，尝试强制编码
final command = '-i "$videoPath" -vn -c:a libmp3lame -q:a 2 "$audioPath"';
```

## 平台特定问题

### Android 特有问题

1. **API 30+ 存储限制**
   - 使用 Scoped Storage
   - 选择文件时，FilePicker 返回的可能是内容 URI

2. **解决方案：** 复制文件到应用私有目录
```dart
// 复制视频到临时目录
final tempDir = await getTemporaryDirectory();
final tempVideoPath = '${tempDir.path}/temp_video.mp4';
await File(videoPath).copy(tempVideoPath);

// 使用临时文件提取
final command = '-i "$tempVideoPath" -vn "$audioPath"';
```

### iOS 特有问题

1. **Photo Library 权限**
   - 确保 Info.plist 有正确的权限描述
   - 用户首次使用时必须授予权限

2. **文件访问限制**
   - iOS 沙盒限制文件访问
   - 确保使用应用沙盒内的路径

## 现在运行并查看日志

### 运行应用：
```bash
flutter run
```

### 操作步骤：
1. 点击 "选择视频提取音频"
2. 选择一个视频文件
3. **查看终端输出的详细日志**
4. **查看应用内的错误提示**

### 提供给我的信息：

请将以下内容复制给我：

1. **终端日志**（从 `🎬 开始提取音频...` 开始的所有内容）
2. **应用内显示的错误信息**
3. **运行平台**（Android/iOS）
4. **视频文件信息**（格式、大小）

## 快速测试清单

- [ ] FFmpeg 插件是否正确安装？运行 `flutter pub get`
- [ ] 应用是否完全重启？（不是热重载）
- [ ] 是否授予了文件访问权限？
- [ ] 视频文件是否存在且可访问？
- [ ] 输出目录是否有写权限？
- [ ] 查看了终端的完整日志？
- [ ] 视频文件是否太大？（建议 < 100MB 测试）
- [ ] 视频文件是否包含音频流？

## 替代方案

如果 FFmpeg 一直有问题，可以考虑：

1. **使用 ffmpeg_kit_flutter (官方包)**
```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.3
```

2. **使用 flutter_ffmpeg (旧版但稳定)**
```yaml
dependencies:
  flutter_ffmpeg: ^0.4.2
```

---

**下一步：** 运行应用，选择视频提取，然后把终端日志发给我！
