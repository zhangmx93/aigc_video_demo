# 🎵 视频音频提取功能使用说明

## 功能概述

本功能实现了从视频文件中提取音频的完整流程，包括：
- 📱 从相册选择视频文件
- 🎬 使用 FFmpeg 提取音频
- 💾 自动保存提取记录
- 📊 统计和管理音频文件

## 技术栈

- **文件选择**: `file_picker` - 选择视频文件
- **音频提取**: `ffmpeg_kit_flutter_new` - FFmpeg 音频提取
- **本地存储**: `shared_preferences` - 持久化记录
- **路径管理**: `path_provider` - 获取应用目录

## 使用步骤

### 1. 启动应用
```bash
flutter run
```

### 2. 进入音频提取页面
- 在首页点击 **"Audio-Extraction"** 选项
- 图标：🎵 音频轨道图标

### 3. 提取音频

#### 步骤：
1. **点击"选择视频提取音频"按钮**
2. **从相册选择视频文件**
3. **等待提取完成**（显示加载对话框）
4. **查看提取结果**

#### 提取过程：
```
选择视频 → 创建记录 → FFmpeg 提取 → 保存音频 → 更新记录 → 显示成功
```

### 4. 管理音频记录

#### 可用操作：
- 📋 **查看列表** - 显示所有提取的音频记录
- 🔍 **查看详情** - 点击卡片查看完整信息
- ⭐ **收藏** - 标记重要的音频
- 🗑️ **删除** - 删除单条记录或清空所有
- 📈 **统计** - 查看提取统计信息
- 🔄 **刷新** - 重新加载记录列表

## FFmpeg 提取参数说明

使用的 FFmpeg 命令：
```bash
-i "$videoPath" -vn -ar 44100 -ac 2 -b:a 192k "$audioPath"
```

### 参数解释：

| 参数 | 说明 | 值 |
|------|------|-----|
| `-i` | 输入文件 | 视频文件路径 |
| `-vn` | 禁用视频 | 只提取音频流 |
| `-ar` | 采样率 | 44100 Hz |
| `-ac` | 声道数 | 2 (立体声) |
| `-b:a` | 音频比特率 | 192 kbps |
| 输出 | 音频文件 | MP3 格式 |

### 音频质量设置：

- **采样率**: 44100 Hz (CD 音质)
- **比特率**: 192 kbps (高质量)
- **声道**: 立体声 (2 通道)
- **格式**: MP3

## 文件存储位置

### iOS:
```
/var/mobile/Containers/Data/Application/[APP_ID]/Documents/extracted_audio/
```

### Android:
```
/data/user/0/com.example.aigc_video_demo/app_flutter/extracted_audio/
```

### 文件命名规则:
```
原视频名_时间戳.mp3
例如: my_video_1698765432000.mp3
```

## 权限配置

### iOS (Info.plist)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问您的相册以选择视频进行音频提取</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存提取的音频文件到相册</string>
```

### Android (AndroidManifest.xml)
```xml
<!-- 文件访问权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<!-- Android 13+ 需要的权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

## 功能特性

### ✅ 已实现功能

1. **视频选择**
   - ✅ 支持从相册选择视频
   - ✅ 支持多种视频格式
   - ✅ 自动获取视频信息

2. **音频提取**
   - ✅ 使用 FFmpeg 高质量提取
   - ✅ 实时显示提取进度
   - ✅ 自动保存到应用目录

3. **记录管理**
   - ✅ 自动创建提取记录
   - ✅ 记录视频和音频信息
   - ✅ 支持收藏和标签
   - ✅ 本地持久化存储

4. **统计信息**
   - ✅ 总记录数
   - ✅ 成功/失败统计
   - ✅ 格式分布统计
   - ✅ 文件大小统计

## 界面说明

### 统计卡片
显示四个关键指标：
- 📁 **总数** - 所有记录数量
- ✅ **成功** - 成功提取的数量
- ❌ **失败** - 失败的数量
- ⭐ **收藏** - 收藏的数量

### 记录卡片
每条记录显示：
- 🎵 格式图标和文件名
- ⏱️ 音频时长
- 💾 文件大小
- 🎼 音频格式
- 📊 提取状态
- 🏷️ 标签（如果有）
- ⭐ 收藏按钮
- 🗑️ 删除按钮

### 详情信息
点击记录查看：
- 视频文件名和路径
- 音频文件名和路径
- 音频格式和大小
- 采样率、比特率、声道
- 提取状态和时间
- 标签和收藏状态

## 错误处理

### 常见错误及解决方案

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 无法获取视频路径 | 权限不足或选择取消 | 检查权限配置 |
| 提取失败 | 视频格式不支持或损坏 | 选择其他视频 |
| 文件保存失败 | 存储空间不足 | 清理存储空间 |
| 权限被拒绝 | 用户拒绝权限 | 引导用户开启权限 |

### 日志查看

提取过程中的详细日志会记录在：
- iOS: Xcode Console
- Android: Android Studio Logcat

查找关键字：`[AudioExtract]`

## 性能优化建议

1. **视频大小限制**
   - 建议单个视频不超过 500MB
   - 大文件提取时间较长

2. **存储空间**
   - 定期清理不需要的音频文件
   - 监控应用存储使用情况

3. **内存管理**
   - 避免同时提取多个大文件
   - 提取完成后及时释放资源

## 开发调试

### 测试提取功能

1. **准备测试视频**
   - 短视频（< 10MB）用于快速测试
   - 中等视频（10-50MB）用于常规测试
   - 大视频（> 50MB）用于压力测试

2. **检查提取结果**
```dart
// 查看提取的音频文件
final records = await ExtractedAudioManager().getAllRecords();
for (var record in records) {
  print('音频: ${record.audioPath}');
  print('大小: ${record.getFormattedAudioSize()}');
  print('状态: ${record.getStatusDescription()}');
}
```

3. **查看 FFmpeg 日志**
```dart
await FFmpegKit.execute(command).then((session) async {
  final logs = await session.getOutput();
  print('FFmpeg 输出: $logs');
});
```

## 常见问题 FAQ

### Q1: 支持哪些视频格式？
**A**: 支持大部分常见格式：MP4, MOV, AVI, MKV, FLV, WMV 等。

### Q2: 提取的音频质量如何？
**A**: 使用 192kbps MP3 格式，44100Hz 采样率，接近 CD 音质。

### Q3: 可以修改音频格式吗？
**A**: 可以。修改 FFmpeg 命令参数即可支持 AAC, WAV, FLAC 等格式。

### Q4: 提取需要多长时间？
**A**: 取决于视频大小，一般 1 分钟视频约需 5-10 秒。

### Q5: 音频文件保存在哪里？
**A**: 保存在应用私有目录，可通过代码访问路径。

### Q6: 如何导出音频文件？
**A**: 可以添加分享功能，使用 `share_plus` 插件导出到其他应用。

## 后续扩展

### 计划功能

- [ ] 支持批量提取
- [ ] 支持更多音频格式
- [ ] 音频播放预览
- [ ] 分享到其他应用
- [ ] 云端备份
- [ ] 音频编辑功能

### 如何贡献

欢迎提交 Issue 和 Pull Request！

## 相关文档

- [FFmpeg Kit Flutter 文档](https://pub.dev/packages/ffmpeg_kit_flutter_new)
- [File Picker 文档](https://pub.dev/packages/file_picker)
- [音频提取管理器 API](AUDIO_EXTRACTION_README.md)

## 技术支持

遇到问题？
1. 查看本文档的常见问题部分
2. 检查应用日志
3. 提交 Issue 到项目仓库

---

**版本**: 1.0.0
**更新时间**: 2024-10-24
**作者**: AIGC Video Demo Team
