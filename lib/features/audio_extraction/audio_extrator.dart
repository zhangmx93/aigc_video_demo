import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:ffmpeg_kit_flutter_new/log.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MP3Extractor {
  /// 从视频中提取MP3音频 - 修复版本
  static Future<String?> extractMP3FromVideo({
    required String videoPath,
    String? outputPath,
    int bitrate = 192,
  }) async {
    await FFmpegKit.execute('-i "$videoPath" -hide_banner');

    // 验证输入文件
    if (!await File(videoPath).exists()) {
      print('❌ 输入文件不存在: $videoPath');
      return null;
    }

    final finalOutputPath = outputPath ?? await _generateOutputPath();

    // 策略1：首先尝试直接复制音频流（最快、最可靠）
    print('🔄 策略1: 尝试直接复制音频流...');
    var result = await _extractWithCopy(videoPath, finalOutputPath);
    if (result != null) return result;

    // 策略2：尝试简化的MP3编码（避免过滤器问题）
    print('🔄 策略2: 尝试简化MP3编码...');
    result = await _extractWithSimpleMP3(videoPath, finalOutputPath, bitrate);
    if (result != null) return result;

    // 策略3：尝试AAC编码
    print('🔄 策略3: 尝试AAC编码...');
    result = await _extractWithAAC(videoPath, finalOutputPath, bitrate);
    if (result != null) return result;

    // 策略4：尝试使用 PCM 解码 + MP3 编码（最兼容的方式）
    print('🔄 策略4: 尝试PCM解码+MP3编码（最兼容模式）...');
    result = await _extractWithPCM(videoPath, finalOutputPath, bitrate);
    if (result != null) return result;

    print('❌ 所有提取策略都失败了');
    return null;
  }

  /// 策略1：直接复制音频流（避免编码器问题）
  static Future<String?> _extractWithCopy(
      String videoPath, String outputPath) async {
    // 先尝试复制为原始格式，让FFmpeg自动选择音频流
    final tempOutput = outputPath.replaceAll('.mp3', '_temp.aac');
    final command = '-y -i "$videoPath" -vn -c:a copy "$tempOutput"';

    print('🎬 复制命令: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // 如果复制成功，检查文件并重命名
        final file = File(tempOutput);
        if (await file.exists()) {
          final stats = await file.stat();
          if (stats.size > 0) {
            // 如果已经是MP3格式，直接使用；否则转换为MP3
            if (tempOutput.endsWith('.mp3')) {
              await file.rename(outputPath);
              print('✅ 直接复制MP3成功: $outputPath');
              return outputPath;
            } else {
              // 将复制的音频转换为MP3
              return await _convertToMP3(tempOutput, outputPath);
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ 直接复制失败: $e');
    }

    // 清理临时文件
    try {
      await File(tempOutput).delete();
    } catch (e) {
      // 忽略删除错误
    }

    return null;
  }

  /// 策略2：简化MP3编码（避免复杂的过滤器）
  static Future<String?> _extractWithSimpleMP3(
      String videoPath, String outputPath, int bitrate) async {
    // 不强制采样率和声道，避免触发过滤器重初始化错误
    final command =
        '-i "$videoPath" -c:a libmp3lame -q:a 2 "$outputPath"';

    print('🎬 简化MP3命令: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final file = File(outputPath);
        if (await file.exists() && (await file.stat()).size > 0) {
          print('✅ 简化MP3提取成功: $outputPath');
          return outputPath;
        }
      } else {
        await _logFailureDetails(session, '简化MP3');
      }
    } catch (e) {
      print('❌ 简化MP3异常: $e');
    }

    return null;
  }

  /// 策略3：AAC编码作为备选
  static Future<String?> _extractWithAAC(
      String videoPath, String outputPath, int bitrate) async {
    final aacOutput = outputPath.replaceAll('.mp3', '.m4a');
    // 不强制采样率和声道，避免触发过滤器重初始化错误
    final command =
        '-y -i "$videoPath" -vn -c:a aac -b:a ${bitrate}k "$aacOutput"';

    print('🎬 AAC命令: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final file = File(aacOutput);
        if (await file.exists() && (await file.stat()).size > 0) {
          print('✅ AAC提取成功: $aacOutput');
          return aacOutput;
        }
      } else {
        await _logFailureDetails(session, 'AAC编码');
      }
    } catch (e) {
      print('❌ AAC编码异常: $e');
    }

    return null;
  }

  /// 策略4：使用PCM解码再编码为MP3（最兼容的方式）
  static Future<String?> _extractWithPCM(
      String videoPath, String outputPath, int bitrate) async {
    // 两步法：先提取为WAV，再转为MP3
    // 这是最兼容的方式，可以处理各种音频流问题
    final tempWavPath = outputPath.replaceAll('.mp3', '_temp.wav');

    // 步骤1：提取为WAV格式（PCM编码）- 不强制采样率和声道
    final extractCommand =
        '-y -i "$videoPath" -vn -acodec pcm_s16le "$tempWavPath"';

    print('🎬 步骤1 - 提取WAV: $extractCommand');

    try {
      final extractSession = await FFmpegKit.execute(extractCommand);
      final extractCode = await extractSession.getReturnCode();

      if (!ReturnCode.isSuccess(extractCode)) {
        print('❌ WAV提取失败');
        await _logFailureDetails(extractSession, 'WAV提取');
        return null;
      }

      // 检查WAV文件
      final wavFile = File(tempWavPath);
      if (!await wavFile.exists() || (await wavFile.stat()).size == 0) {
        print('❌ WAV文件无效');
        return null;
      }

      // 步骤2：转换为MP3
      final convertCommand =
          '-y -i "$tempWavPath" -c:a libmp3lame -b:a ${bitrate}k "$outputPath"';

      print('🎬 步骤2 - 转换MP3: $convertCommand');

      final convertSession = await FFmpegKit.execute(convertCommand);
      final convertCode = await convertSession.getReturnCode();

      // 删除临时WAV文件
      try {
        await wavFile.delete();
      } catch (e) {
        print('⚠️ 删除临时WAV文件失败: $e');
      }

      if (ReturnCode.isSuccess(convertCode)) {
        final file = File(outputPath);
        if (await file.exists() && (await file.stat()).size > 0) {
          print('✅ PCM解码+MP3编码成功: $outputPath');
          return outputPath;
        }
      } else {
        await _logFailureDetails(convertSession, 'WAV转MP3');
      }
    } catch (e) {
      print('❌ PCM解码+MP3编码异常: $e');

      // 清理临时文件
      try {
        await File(tempWavPath).delete();
      } catch (_) {
        // 忽略删除错误
      }
    }

    return null;
  }

  /// 将音频文件转换为MP3
  static Future<String?> _convertToMP3(
      String inputPath, String outputPath) async {
    // 不强制采样率和声道，避免触发过滤器错误
    final command =
        '-y -i "$inputPath" -c:a libmp3lame -b:a 192k "$outputPath"';

    print('🎬 转换命令: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // 删除临时文件
        await File(inputPath).delete();
        print('✅ 音频转换成功: $outputPath');
        return outputPath;
      }
    } catch (e) {
      print('❌ 音频转换失败: $e');
    }

    return null;
  }

  /// 记录详细的失败信息
  static Future<void> _logFailureDetails(Session session, String method) async {
    final returnCode = await session.getReturnCode();
    final failStackTrace = await session.getFailStackTrace();
    final duration = await session.getDuration();
    final logs = await session.getAllLogs();

    print('❌ $method 失败 - ReturnCode: ${returnCode?.getValue()}');
    print('⏱️ 执行时长: $duration ms');

    if (failStackTrace != null && failStackTrace.isNotEmpty) {
      print('🔍 失败堆栈: $failStackTrace');
    }

    // 查找错误日志
    if (logs.isNotEmpty) {
      final errorLogs = logs.where((log) {
        final message = log.getMessage().toLowerCase();
        return message.contains('error') ||
            message.contains('failed') ||
            message.contains('invalid');
      }).toList();

      if (errorLogs.isNotEmpty) {
        print('📋 相关错误日志:');
        for (final log in errorLogs.take(5)) {
          // 只显示前5条错误日志
          print('  ${log.getMessage()}');
        }
      }
    }

    // 分析具体错误
    await _analyzeSpecificError(failStackTrace, logs);
  }

  /// 分析具体的错误类型
  static Future<void> _analyzeSpecificError(
      String? failStackTrace, List<Log> logs) async {
    final allMessages = [
      if (failStackTrace != null) failStackTrace,
      ...logs.map((log) => log.getMessage())
    ].join('\n').toLowerCase();

    if (allMessages.contains('all_channel_counts') ||
        allMessages.contains('not connected to any destination')) {
      print('💡 错误原因: 🔧 FFmpeg过滤器配置问题');
      print('💡 解决方案: 使用简化的提取命令，避免复杂的过滤器链');
    } else if (allMessages.contains('no audio stream')) {
      print('💡 错误原因: 🎵 视频文件中没有音频流');
      print('💡 建议: 请选择包含音频的视频文件');
    } else if (allMessages.contains('invalid argument')) {
      print('💡 错误原因: 📝 参数配置错误');
      print('💡 解决方案: 尝试不同的编码参数或格式');
    } else if (allMessages.contains('permission denied')) {
      print('💡 错误原因: 🔒 文件权限不足');
      print('💡 解决方案: 检查文件读写权限');
    } else {
      print('💡 错误原因: 未知错误，建议尝试不同的视频文件');
    }
  }

  /// 生成输出路径
  static Future<String> _generateOutputPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/extracted_audio_$timestamp.mp3';
  }

  /// 检查视频文件是否包含音频流
  static Future<bool> hasAudioStream(String videoPath) async {
    final command = '-i "$videoPath" -hide_banner';

    try {
      final session = await FFmpegKit.execute(command);
      final logs = await session.getAllLogs();

      for (final log in logs) {
        final message = log.getMessage();
        if (message.contains('Audio:') && !message.contains('0 streams')) {
          return true;
        }
      }
    } catch (e) {
      print('❌ 检查音频流失败: $e');
    }

    return false;
  }
}
