# FFmpeg Kit Flutter 插件错误修复指南

## 错误信息
```
MissingPluginException(No implementation found for method listen on channel flutter.arthenica.com/ffmpeg_kit_event)
```

## 错误原因
这个错误表明 `ffmpeg_kit_flutter_new` 插件的原生代码没有正确注册到 Flutter 引擎中。

## 解决方案

### 方案 1: 完全重新构建（推荐）

#### iOS 平台
```bash
# 1. 清理项目
flutter clean

# 2. 删除 iOS 构建缓存
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
cd ..

# 3. 重新获取依赖
flutter pub get

# 4. 安装 iOS Pods
cd ios
pod install --repo-update
cd ..

# 5. 重新运行
flutter run
```

#### Android 平台
```bash
# 1. 清理项目
flutter clean

# 2. 删除 Android 构建缓存
cd android
./gradlew clean
cd ..

# 3. 重新获取依赖
flutter pub get

# 4. 重新运行
flutter run
```

### 方案 2: 检查插件是否正确安装

#### 检查 pubspec.yaml
确保依赖正确添加：
```yaml
dependencies:
  ffmpeg_kit_flutter_new: ^4.0.0
```

#### 检查插件文件
运行以下命令查看插件是否安装：
```bash
flutter pub deps | grep ffmpeg
```

应该看到：
```
ffmpeg_kit_flutter_new 4.0.0
```

### 方案 3: 针对不同平台的特殊处理

#### macOS 平台
如果在 macOS 上运行，需要额外配置：

1. 打开 `macos/Podfile`
2. 取消注释或添加：
```ruby
platform :osx, '10.14'
```

3. 重新安装 pods：
```bash
cd macos
pod install --repo-update
cd ..
```

#### iOS 模拟器问题
如果在 iOS 模拟器上运行出错，尝试：

1. 停止应用
2. 卸载应用（从模拟器中删除）
3. 清理构建
4. 重新运行

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### 方案 4: 检查最低 SDK 版本

#### iOS 最低版本
打开 `ios/Podfile`，确保：
```ruby
platform :ios, '12.0'  # ffmpeg_kit 需要 iOS 12.0+
```

#### Android 最低版本
打开 `android/app/build.gradle`，确保：
```gradle
android {
    defaultConfig {
        minSdkVersion 24  // ffmpeg_kit 需要 API 24+
        targetSdkVersion 34
    }
}
```

### 方案 5: 热重启 vs 完全重启

**重要**: 添加新插件后，必须完全重启应用（Stop + Run），而不是热重载（Hot Reload）或热重启（Hot Restart）。

```bash
# 停止当前运行的应用
# 然后重新运行
flutter run
```

### 方案 6: 检查 Flutter 和 Dart 版本

确保使用的 Flutter 和 Dart 版本符合要求：

```bash
flutter --version
```

`ffmpeg_kit_flutter_new` 需要：
- Flutter: >= 3.0.0
- Dart: >= 3.0.0

## 推荐的完整修复流程

按照以下步骤操作（最全面的解决方案）：

### 对于 iOS:
```bash
# 1. 完全清理
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..

# 2. 重新获取依赖
flutter pub get

# 3. 重新安装 pods（可能需要几分钟）
cd ios
pod install --repo-update
cd ..

# 4. 停止所有运行的应用实例
# 在 Xcode 或终端中停止应用

# 5. 完全重新构建和运行
flutter run
```

### 对于 Android:
```bash
# 1. 完全清理
flutter clean
cd android
./gradlew clean
cd ..

# 2. 删除 Gradle 缓存（可选）
rm -rf android/.gradle

# 3. 重新获取依赖
flutter pub get

# 4. 停止所有运行的应用实例
# 在 Android Studio 或模拟器中卸载应用

# 5. 完全重新构建和运行
flutter run
```

## 验证插件是否正常工作

创建一个简单的测试：

```dart
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

Future<void> testFFmpegKit() async {
  try {
    await FFmpegKit.execute('-version').then((session) async {
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      print('FFmpeg 版本信息:');
      print(output);
    });
    print('✅ FFmpeg Kit 工作正常');
  } catch (e) {
    print('❌ FFmpeg Kit 错误: $e');
  }
}
```

## 常见问题

### Q1: 执行 `pod install` 时卡住
**A**:
```bash
# 更新 CocoaPods 仓库
pod repo update
# 或者跳过更新直接安装
pod install --verbose
```

### Q2: Android Gradle 构建失败
**A**: 检查 `android/app/build.gradle` 中的 `minSdkVersion` 是否 >= 24

### Q3: 在真机上不工作，但模拟器正常
**A**: 确保真机系统版本满足最低要求（iOS 12.0+ 或 Android 7.0+）

### Q4: 依然报错 "MissingPluginException"
**A**:
1. 完全卸载应用
2. 重启模拟器/真机
3. `flutter clean && flutter pub get`
4. 重新运行

## 替代方案

如果 `ffmpeg_kit_flutter_new` 继续出现问题，可以考虑使用其他包：

### ffmpeg_kit_flutter (官方包)
```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.0
```

### flutter_ffmpeg (旧版本，但更稳定)
```yaml
dependencies:
  flutter_ffmpeg: ^0.4.2
```

## 我的项目已执行的修复步骤

我已经为您执行了：
1. ✅ `flutter clean` - 清理项目
2. ✅ `flutter pub get` - 重新获取依赖

## 下一步操作

### iOS 用户请执行:
```bash
cd ios
pod install --repo-update
cd ..
flutter run
```

### Android 用户请执行:
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### 通用步骤（推荐）:
```bash
# 完全停止应用
# 然后重新运行
flutter run

# 注意：不要使用 Hot Reload (r) 或 Hot Restart (R)
# 必须完全重启应用
```

## 联系支持

如果问题依然存在，请提供：
1. 完整的错误日志
2. `flutter doctor -v` 输出
3. 运行平台（iOS/Android/macOS）
4. 模拟器还是真机

---

**重要提醒**: 添加或更新原生插件后，**必须完全重启应用**，热重载不会生效！
