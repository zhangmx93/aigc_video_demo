import 'package:flutter/foundation.dart';

/// 简单的日志工具类
class AudioLogger {
  static final AudioLogger _instance = AudioLogger._internal();
  factory AudioLogger() => _instance;
  AudioLogger._internal();

  static AudioLogger get instance => _instance;

  /// 是否启用调试日志
  bool debugEnabled = kDebugMode;

  /// 调试日志
  void d(String message) {
    if (debugEnabled) {
      debugPrint('[AudioExtract] $message');
    }
  }

  /// 信息日志
  void i(String message) {
    debugPrint('[AudioExtract] ℹ️ $message');
  }

  /// 警告日志
  void w(String message) {
    debugPrint('[AudioExtract] ⚠️ $message');
  }

  /// 错误日志
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[AudioExtract] ❌ $message');
    if (error != null) {
      debugPrint('[AudioExtract] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[AudioExtract] StackTrace: $stackTrace');
    }
  }

  /// 成功日志
  void s(String message) {
    if (debugEnabled) {
      debugPrint('[AudioExtract] ✅ $message');
    }
  }
}
