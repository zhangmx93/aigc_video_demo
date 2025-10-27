import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';

/// 音频格式枚举
enum AudioFormat {
  mp3('mp3', 'libmp3lame'),
  aac('m4a', 'aac'),
  wav('wav', 'pcm_s16le'),
  ogg('ogg', 'libvorbis'),
  flac('flac', 'flac');

  const AudioFormat(this.extension, this.codec);
  final String extension;
  final String codec;
}

/// 音频质量枚举
enum AudioQuality {
  low(96),
  medium(128),
  high(192),
  veryHigh(256),
  lossless(320);

  const AudioQuality(this.bitrate);
  final int bitrate;
}

/// 简单音频提取器 - 提供更灵活的API
class SimpleAudioExtractor {
  /// 从视频中提取音频的主方法(使用多策略方案)
  ///
  /// [videoPath] 视频文件路径
  /// [format] 输出音频格式,默认为MP3
  /// [quality] 音频质量,默认为高质量
  /// [outputPath] 自定义输出路径(可选)
  /// [startTime] 开始时间(秒),用于截取音频片段
  /// [duration] 持续时间(秒),用于截取音频片段
  /// [onProgress] 进度回调(0.0-1.0)
  ///
  /// 返回提取的音频文件路径,失败返回null
  static Future<String?> extractAudio({
    required String videoPath,
    AudioFormat format = AudioFormat.mp3,
    AudioQuality quality = AudioQuality.high,
    String? outputPath,
    double? startTime,
    double? duration,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. 验证输入文件
      if (!await _validateInputFile(videoPath)) {
        print('❌ 输入视频文件无效: $videoPath');
        return null;
      }

      // 2. 生成输出路径
      final String finalOutputPath = outputPath ??
          await _generateOutputPath(format.extension);

      // 使用多策略方案进行提取
      String? result;

      // 策略1: 尝试标准提取
      print('🔄 策略1: 尝试标准提取...');
      result = await _extractWithStandardMethod(
        videoPath: videoPath,
        outputPath: finalOutputPath,
        format: format,
        quality: quality,
        startTime: startTime,
        duration: duration,
        onProgress: onProgress,
      );
      if (result != null) return result;

      // 策略2: 尝试简化参数提取(去除可能导致过滤器问题的参数)
      print('🔄 策略2: 尝试简化参数提取...');
      result = await _extractWithSimplifiedParams(
        videoPath: videoPath,
        outputPath: finalOutputPath,
        format: format,
        quality: quality,
        startTime: startTime,
        duration: duration,
      );
      if (result != null) return result;

      // 策略3: 两步法 - 先提取为WAV,再转换
      if (format != AudioFormat.wav) {
        print('🔄 策略3: 尝试两步法(WAV中转)...');
        result = await _extractWithTwoStepMethod(
          videoPath: videoPath,
          outputPath: finalOutputPath,
          format: format,
          quality: quality,
          startTime: startTime,
          duration: duration,
        );
        if (result != null) return result;
      }

      print('❌ 所有提取策略都失败了');
      return null;

    } catch (e, stackTrace) {
      print('❌ 提取音频时发生异常: $e');
      print('堆栈信息: $stackTrace');
      return null;
    } finally {
      // 清理进度回调
      FFmpegKitConfig.enableStatisticsCallback(null);
    }
  }

  /// 策略1: 标准提取方法
  static Future<String?> _extractWithStandardMethod({
    required String videoPath,
    required String outputPath,
    required AudioFormat format,
    required AudioQuality quality,
    double? startTime,
    double? duration,
    Function(double progress)? onProgress,
  }) async {
    try {
      final String command = _buildCommand(
        videoPath: videoPath,
        outputPath: outputPath,
        format: format,
        quality: quality,
        startTime: startTime,
        duration: duration,
      );

      print('🎬 标准命令: $command');

      if (onProgress != null) {
        await _setupProgressCallback(videoPath, onProgress);
      }

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          final fileSize = await outputFile.length();
          print('✅ 标准提取成功: $outputPath');
          print('📊 文件大小: ${await _formatFileSize(fileSize)}');
          return outputPath;
        }
      }

      await _logError(session);
    } catch (e) {
      print('⚠️ 标准提取失败: $e');
    }
    return null;
  }

  /// 策略2: 简化参数提取(去除可能导致过滤器问题的参数)
  static Future<String?> _extractWithSimplifiedParams({
    required String videoPath,
    required String outputPath,
    required AudioFormat format,
    required AudioQuality quality,
    double? startTime,
    double? duration,
  }) async {
    try {
      // 构建最简化的命令,避免复杂的过滤器
      final List<String> parts = [];

      if (startTime != null) {
        parts.add('-ss $startTime');
      }
      parts.add('-i "$videoPath"');

      if (duration != null) {
        parts.add('-t $duration');
      }

      parts.add('-vn'); // 不包含视频流

      // 使用更简化的编码参数
      if (format == AudioFormat.mp3) {
        parts.add('-c:a libmp3lame');
        parts.add('-q:a 2'); // 使用质量模式而不是比特率
      } else {
        parts.add('-c:a ${format.codec}');
        if (format != AudioFormat.flac && format != AudioFormat.wav) {
          parts.add('-b:a ${quality.bitrate}k');
        }
      }

      parts.add('-y "$outputPath"');

      final command = parts.join(' ');
      print('🎬 简化命令: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          final fileSize = await outputFile.length();
          print('✅ 简化参数提取成功: $outputPath');
          print('📊 文件大小: ${await _formatFileSize(fileSize)}');
          return outputPath;
        }
      }

      await _logError(session);
    } catch (e) {
      print('⚠️ 简化参数提取失败: $e');
    }
    return null;
  }

  /// 策略3: 两步法 - 先提取为WAV,再转换为目标格式
  static Future<String?> _extractWithTwoStepMethod({
    required String videoPath,
    required String outputPath,
    required AudioFormat format,
    required AudioQuality quality,
    double? startTime,
    double? duration,
  }) async {
    final tempWavPath = outputPath.replaceAll('.${format.extension}', '_temp.wav');

    try {
      // 步骤1: 提取为WAV
      final List<String> extractParts = [];
      if (startTime != null) {
        extractParts.add('-ss $startTime');
      }
      extractParts.add('-i "$videoPath"');
      if (duration != null) {
        extractParts.add('-t $duration');
      }
      extractParts.add('-vn');
      extractParts.add('-acodec pcm_s16le');
      extractParts.add('-y "$tempWavPath"');

      final extractCommand = extractParts.join(' ');
      print('🎬 步骤1 - 提取WAV: $extractCommand');

      final extractSession = await FFmpegKit.execute(extractCommand);
      final extractCode = await extractSession.getReturnCode();

      if (!ReturnCode.isSuccess(extractCode)) {
        print('❌ WAV提取失败');
        await _logError(extractSession);
        return null;
      }

      final wavFile = File(tempWavPath);
      if (!await wavFile.exists() || await wavFile.length() == 0) {
        print('❌ WAV文件无效');
        return null;
      }

      // 步骤2: 转换为目标格式
      final List<String> convertParts = [
        '-i "$tempWavPath"',
        '-c:a ${format.codec}',
      ];

      if (format != AudioFormat.flac && format != AudioFormat.wav) {
        convertParts.add('-b:a ${quality.bitrate}k');
      }

      convertParts.add('-y "$outputPath"');

      final convertCommand = convertParts.join(' ');
      print('🎬 步骤2 - 转换格式: $convertCommand');

      final convertSession = await FFmpegKit.execute(convertCommand);
      final convertCode = await convertSession.getReturnCode();

      // 删除临时WAV文件
      try {
        await wavFile.delete();
      } catch (e) {
        print('⚠️ 删除临时文件失败: $e');
      }

      if (ReturnCode.isSuccess(convertCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          final fileSize = await outputFile.length();
          print('✅ 两步法提取成功: $outputPath');
          print('📊 文件大小: ${await _formatFileSize(fileSize)}');
          return outputPath;
        }
      }

      await _logError(convertSession);
    } catch (e) {
      print('⚠️ 两步法提取失败: $e');

      // 清理临时文件
      try {
        await File(tempWavPath).delete();
      } catch (_) {}
    }
    return null;
  }

  /// 快速提取音频(使用流复制,速度最快但保留原始格式)
  ///
  /// [videoPath] 视频文件路径
  /// [outputPath] 自定义输出路径(可选)
  ///
  /// 返回提取的音频文件路径,失败返回null
  static Future<String?> extractAudioFast({
    required String videoPath,
    String? outputPath,
  }) async {
    try {
      if (!await _validateInputFile(videoPath)) {
        print('❌ 输入视频文件无效: $videoPath');
        return null;
      }

      // 自动检测音频格式并生成输出路径
      final String finalOutputPath = outputPath ??
          await _generateOutputPath('m4a'); // 默认使用m4a作为容器

      // 使用流复制,不重新编码
      final String command = '-i "$videoPath" -vn -acodec copy "$finalOutputPath"';

      print('🎬 快速提取命令: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(finalOutputPath);
        if (await outputFile.exists() && await outputFile.length() > 0) {
          print('✅ 快速提取成功: $finalOutputPath');
          return finalOutputPath;
        }
      }

      print('❌ 快速提取失败');
      await _logError(session);
      return null;

    } catch (e) {
      print('❌ 快速提取异常: $e');
      return null;
    }
  }

  /// 提取音频片段
  ///
  /// [videoPath] 视频文件路径
  /// [startTime] 开始时间(秒)
  /// [endTime] 结束时间(秒)
  /// [format] 输出音频格式
  /// [quality] 音频质量
  ///
  /// 返回提取的音频文件路径,失败返回null
  static Future<String?> extractAudioSegment({
    required String videoPath,
    required double startTime,
    required double endTime,
    AudioFormat format = AudioFormat.mp3,
    AudioQuality quality = AudioQuality.high,
  }) async {
    if (endTime <= startTime) {
      print('❌ 结束时间必须大于开始时间');
      return null;
    }

    final duration = endTime - startTime;

    return extractAudio(
      videoPath: videoPath,
      format: format,
      quality: quality,
      startTime: startTime,
      duration: duration,
    );
  }

  /// 批量提取多个视频的音频
  ///
  /// [videoPaths] 视频文件路径列表
  /// [format] 输出音频格式
  /// [quality] 音频质量
  /// [onProgress] 总体进度回调(0.0-1.0)
  ///
  /// 返回成功提取的音频文件路径列表
  static Future<List<String>> extractAudioBatch({
    required List<String> videoPaths,
    AudioFormat format = AudioFormat.mp3,
    AudioQuality quality = AudioQuality.high,
    Function(double progress)? onProgress,
  }) async {
    final List<String> successPaths = [];
    final int total = videoPaths.length;

    for (int i = 0; i < videoPaths.length; i++) {
      print('📹 处理第 ${i + 1}/$total 个视频...');

      final audioPath = await extractAudio(
        videoPath: videoPaths[i],
        format: format,
        quality: quality,
      );

      if (audioPath != null) {
        successPaths.add(audioPath);
      }

      // 更新总体进度
      if (onProgress != null) {
        onProgress((i + 1) / total);
      }
    }

    print('✅ 批量提取完成: ${successPaths.length}/$total 成功');
    return successPaths;
  }

  /// 构建FFmpeg命令
  static String _buildCommand({
    required String videoPath,
    required String outputPath,
    required AudioFormat format,
    required AudioQuality quality,
    double? startTime,
    double? duration,
  }) {
    final List<String> parts = [];

    // 输入文件
    if (startTime != null) {
      parts.add('-ss $startTime');
    }
    parts.add('-i "$videoPath"');

    // 持续时间
    if (duration != null) {
      parts.add('-t $duration');
    }

    // 音频设置
    parts.add('-vn'); // 不包含视频流
    parts.add('-acodec ${format.codec}');

    // 质量设置(FLAC无损格式不需要比特率)
    if (format != AudioFormat.flac && format != AudioFormat.wav) {
      parts.add('-b:a ${quality.bitrate}k');
    }

    // 采样率和声道(可选,去掉以避免重采样问题)
    // parts.add('-ar 44100'); // 采样率44.1kHz
    // parts.add('-ac 2'); // 双声道

    // 输出文件(覆盖已存在的文件)
    parts.add('-y "$outputPath"');

    return parts.join(' ');
  }

  /// 验证输入文件
  static Future<bool> _validateInputFile(String videoPath) async {
    final file = File(videoPath);
    if (!await file.exists()) {
      return false;
    }

    final size = await file.length();
    if (size == 0) {
      print('❌ 文件大小为0');
      return false;
    }

    return true;
  }

  /// 生成输出路径
  static Future<String> _generateOutputPath(String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/audio_$timestamp.$extension';
  }

  /// 设置进度回调
  static Future<void> _setupProgressCallback(
    String videoPath,
    Function(double progress) onProgress,
  ) async {
    // 获取视频总时长
    final duration = await _getVideoDuration(videoPath);
    if (duration == null || duration == 0) {
      return;
    }

    FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
      final time = statistics.getTime();
      if (time > 0) {
        final progress = (time / duration).clamp(0.0, 1.0);
        onProgress(progress);
      }
    });
  }

  /// 获取视频时长(毫秒)
  static Future<int?> _getVideoDuration(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -hide_banner'
      );

      final logs = await session.getAllLogs();
      for (final log in logs) {
        final message = log.getMessage();
        // 查找Duration行
        if (message.contains('Duration:')) {
          final match = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})')
              .firstMatch(message);
          if (match != null) {
            final hours = int.parse(match.group(1)!);
            final minutes = int.parse(match.group(2)!);
            final seconds = int.parse(match.group(3)!);
            final centiseconds = int.parse(match.group(4)!);

            return (hours * 3600 + minutes * 60 + seconds) * 1000 +
                   centiseconds * 10;
          }
        }
      }
    } catch (e) {
      print('⚠️ 获取视频时长失败: $e');
    }
    return null;
  }

  /// 记录错误信息
  static Future<void> _logError(dynamic session) async {
    try {
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogs();

      print('❌ 返回码: ${returnCode?.getValue()}');

      // 查找并打印错误日志
      final errorLogs = logs.where((log) {
        final message = log.getMessage().toLowerCase();
        return message.contains('error') ||
               message.contains('failed') ||
               message.contains('invalid');
      }).take(3);

      if (errorLogs.isNotEmpty) {
        print('📋 错误信息:');
        for (final log in errorLogs) {
          print('  ${log.getMessage()}');
        }
      }
    } catch (e) {
      print('⚠️ 获取错误信息失败: $e');
    }
  }

  /// 格式化文件大小
  static Future<String> _formatFileSize(int bytes) async {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 检查视频是否包含音频流
  static Future<bool> hasAudioStream(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -hide_banner'
      );

      final logs = await session.getAllLogs();
      for (final log in logs) {
        final message = log.getMessage();
        if (message.contains('Audio:')) {
          return true;
        }
      }
    } catch (e) {
      print('❌ 检查音频流失败: $e');
    }
    return false;
  }

  /// 获取音频信息
  static Future<Map<String, dynamic>?> getAudioInfo(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -hide_banner'
      );

      final logs = await session.getAllLogs();
      for (final log in logs) {
        final message = log.getMessage();
        if (message.contains('Audio:')) {
          // 解析音频信息: Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 128 kb/s
          final codecMatch = RegExp(r'Audio: (\w+)').firstMatch(message);
          final sampleRateMatch = RegExp(r'(\d+) Hz').firstMatch(message);
          final channelMatch = RegExp(r'(mono|stereo|\d+ channels)').firstMatch(message);
          final bitrateMatch = RegExp(r'(\d+) kb/s').firstMatch(message);

          return {
            'codec': codecMatch?.group(1),
            'sampleRate': sampleRateMatch != null
                ? int.parse(sampleRateMatch.group(1)!)
                : null,
            'channels': channelMatch?.group(1),
            'bitrate': bitrateMatch != null
                ? int.parse(bitrateMatch.group(1)!)
                : null,
          };
        }
      }
    } catch (e) {
      print('❌ 获取音频信息失败: $e');
    }
    return null;
  }
}
