# 🔍 音频提取失败 - 快速诊断

## 当前状态
- ✅ FFmpeg 插件已安装
- ✅ 代码已添加详细日志
- ❌ FFmpeg 返回码: 1（失败）
- ❓ 缺少完整的错误日志

## 立即执行的操作

### 步骤 1: 重新运行应用
```bash
# 热重启（按 R）或完全重启
flutter run
```

### 步骤 2: 查看启动时的 FFmpeg 测试
应该看到：
```
🧪 测试 FFmpeg...
✅ FFmpeg 测试完成
返回码: 0
版本信息: ffmpeg version n8.0
```

如果这里返回码不是 0，说明 FFmpeg 本身有问题。

### 步骤 3: 选择视频并查看完整日志
现在日志会分段打印，查找：

```
📝 FFmpeg 完整输出日志:
================================================================================
[这里是完整的 FFmpeg 输出]
================================================================================
📌 最后 20 行:
[这里是最后 20 行，通常包含错误]
```

### 步骤 4: 把完整日志发给我

特别是最后 20 行，通常包含关键错误信息，比如：
- `No such file or directory`
- `Permission denied`
- `Invalid data found`
- `Codec not found`
- `Unknown encoder`

## 常见错误分析

### 错误 1: Encoder 'libmp3lame' not found
**表现：**
```
Encoder libmp3lame not found
Unknown encoder 'libmp3lame'
```

**解决：** FFmpeg 编译时未包含 mp3 编码器

**临时方案：** 使用音频流复制（已在代码中）
```dart
final command = '-i "$actualVideoPath" -vn -acodec copy -y "$audioPath"';
```

### 错误 2: No such file or directory
**表现：**
```
$actualVideoPath: No such file or directory
```

**原因：** 文件路径不正确

**检查：**
- 查看日志中的"原始视频路径"
- 查看"视频文件是否存在"
- 查看"视频已复制到"

### 错误 3: Invalid data found when processing input
**表现：**
```
Invalid data found when processing input
```

**原因：** 视频文件损坏或格式不支持

**解决：** 尝试其他视频文件

### 错误 4: Permission denied
**表现：**
```
Permission denied
Cannot write to output file
```

**原因：** 输出目录没有写权限

**检查：**
- 查看"输出目录是否存在: true"
- 确认应用有存储权限

## 我修改的关键代码

### 1. 使用最简单的 FFmpeg 命令
```dart
// 直接复制音频流，不重新编码（最快，最兼容）
final command = '-i "$actualVideoPath" -vn -acodec copy -y "$audioPath"';
```

这个命令的优点：
- ✅ 不需要编码器
- ✅ 速度最快
- ✅ 不损失质量
- ⚠️ 输出格式取决于原视频的音频编码

### 2. 详细的日志输出
- 分段打印，避免截断
- 显示最后 20 行（关键错误通常在这里）
- 显示完整的命令和路径

### 3. Android content:// URI 处理
- 自动检测并复制到临时目录
- FFmpeg 可以访问

## 如果日志还是不完整

### 使用 adb logcat 查看（Android）
```bash
# 连接设备后，在终端运行
adb logcat | grep -i "ffmpeg\|flutter"

# 或者只看错误
adb logcat | grep -E "error|ERROR|failed|FAILED"
```

### 使用 Xcode Console 查看（iOS）
1. 打开 Xcode
2. Window → Devices and Simulators
3. 选择设备，点击 "Open Console"
4. 搜索 "FFmpeg" 或 "flutter"

## 测试用的简单视频

建议使用：
- **格式：** MP4
- **大小：** < 10 MB
- **时长：** < 30 秒
- **音频编码：** AAC 或 MP3
- **来源：** 手机录制的视频（最兼容）

## 下一步

1. **重新运行应用**
2. **选择一个小视频**（< 10MB）
3. **复制完整的日志**，特别是：
   - 🧪 FFmpeg 测试结果
   - 📝 完整输出日志
   - 📌 最后 20 行
4. **把日志发给我**

## 备用方案

如果 FFmpeg 一直失败，可以：

### 方案 A: 使用服务器端处理
- 上传视频到服务器
- 服务器提取音频
- 下载结果

### 方案 B: 使用原生平台代码
- Android: MediaExtractor
- iOS: AVAssetExportSession

### 方案 C: 换个 FFmpeg 包
```yaml
# 尝试官方包
dependencies:
  ffmpeg_kit_flutter: ^6.0.3
```

---

**现在重新运行，把日志复制给我！特别是"最后 20 行"部分！** 🔍
