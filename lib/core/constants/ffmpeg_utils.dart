import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

int defaultFfmpegKitExecuteTimeoutCancelMilliseconds = 30000;

class AudioClipFixedDurationClipConfig {
  final double boxLRMargin; // 盒子左右边距
  final double clipMaxDuration;  // 裁剪保留时长
  final double clipAreaRTPadding; // 裁剪两边边距
  final double waveItemWidth; // 每个竖线宽度
  final double waveItemHeight; // 每个竖线最大高度
  final double waveItemSpacing; // 每个竖线间距
  final Color waveItemColor; // 竖线颜色
  final Color waveItemHighColor; // 竖线高亮颜色

  final double clipAreaRenderHeight; // 裁剪区域渲染高度
  final double playOpBtnSize; // 播放按钮大小
  final double playOpBtnBorderRadius; // 播放按钮圆角
  final double playOpBtnMargin; // 播放按钮边距
  final double playOpIconSize; // 播放按钮图标大小

  final double clipAreaLeftMargin; // 裁剪区域左边距


  AudioClipFixedDurationClipConfig({
    this.boxLRMargin = 16,
    this.clipMaxDuration = 30,
    this.clipAreaRTPadding = 12,
    this.waveItemWidth = 2,
    this.waveItemHeight = 36,
    this.waveItemSpacing = 1,
    this.waveItemColor = const Color.fromRGBO(151, 159, 171, 1),
    this.waveItemHighColor = const Color.fromRGBO(0, 87, 255, 1),
    this.clipAreaRenderHeight = 56,
    this.playOpBtnSize = 44,
    this.playOpIconSize = 24,
    this.playOpBtnBorderRadius = 44,
    this.playOpBtnMargin = 2,
    this.clipAreaLeftMargin = 8,
  });

  AudioClipFixedDurationClipConfig copyWith({
    double? boxLRMargin,
    double? clipMaxDuration,
    double? clipAreaRTPadding,
    double? waveItemWidth,
    double? waveItemHeight,
    double? waveItemSpacing,
    Color? waveItemColor,
    Color? waveItemHighColor,
    double? clipAreaRenderHeight,
    double? playOpBtnSize,
    double? playOpIconSize,
    double? playOpBtnBorderRadius,
    double? playOpBtnMargin,
    double? clipAreaLeftMargin,
  }) {
    return AudioClipFixedDurationClipConfig(
      boxLRMargin: boxLRMargin ?? this.boxLRMargin,
      clipMaxDuration: clipMaxDuration ?? this.clipMaxDuration,
      clipAreaRTPadding: clipAreaRTPadding ?? this.clipAreaRTPadding,
      waveItemWidth: waveItemWidth ?? this.waveItemWidth,
      waveItemHeight: waveItemHeight ?? this.waveItemHeight,
      waveItemSpacing: waveItemSpacing ?? this.waveItemSpacing,
      waveItemColor: waveItemColor ?? this.waveItemColor,
      waveItemHighColor: waveItemHighColor ?? this.waveItemHighColor,
      clipAreaRenderHeight: clipAreaRenderHeight ?? this.clipAreaRenderHeight,
      playOpBtnSize: playOpBtnSize ?? this.playOpBtnSize,
      playOpIconSize: playOpIconSize ?? this.playOpIconSize,
      playOpBtnBorderRadius: playOpBtnBorderRadius ?? this.playOpBtnBorderRadius,
      playOpBtnMargin: playOpBtnMargin ?? this.playOpBtnMargin,
      clipAreaLeftMargin: clipAreaLeftMargin ?? this.clipAreaLeftMargin,
    );
  }
}

AudioClipFixedDurationClipConfig audioClipFixedDurationClipConfig = AudioClipFixedDurationClipConfig();

// AudioClipFixedDurationClipConfig().copyWith(
//   boxLRMargin: 16,
//   clipMaxDuration: 30,
//   clipAreaRTPadding: 12,
//   waveItemWidth: 2,
//   waveItemHeight: 36,
//   waveItemSpacing: 1,
//   waveItemColor: const Color.fromRGBO(151, 159, 171, 1),
//   waveItemHighColor: const Color.fromRGBO(0, 87, 255, 1),
//   playOpIconSize: 24,

//   clipAreaRenderHeight: 56,
//   playOpBtnSize: 44,
//   playOpBtnBorderRadius: 44,
//   playOpBtnMargin: 2,
//   clipAreaLeftMargin: 8,
// );
class FfmpegKitExecuteResData {
  final String command;
  final FFmpegSession? session;
  final dynamic error;
  final int code;

  FfmpegKitExecuteResData({
    required this.command,
    this.session,
    this.error,
    required this.code,
  });
}

class FfmpegKitInitClipAudioData {
  String souceFilePath;
  String mp3FilePath;
  double duration;
  List<double> waveBarData;
  FfmpegKitInitClipAudioData({
    required this.souceFilePath,
    required this.mp3FilePath,
    required this.duration,
    required this.waveBarData
  });
}

class AudioClipFixedDurationClipedData {
  final String mp3FilePath;
  double clipStartTime = 0;
  double clipEndTime = 0;
  double clipDuaration = 0;
  double totalDuration = 0;


  AudioClipFixedDurationClipedData({
    required this.mp3FilePath,
    required this.clipStartTime,
    required this.clipEndTime,
    required this.clipDuaration,
    required this.totalDuration,
  });
}


class FfmpegUtilsKit {
  static getUuid() {
    return const Uuid().v4().replaceAll(RegExp("-"), '');
  }

  static String formatSeconds(double seconds) {
    int totalSeconds = seconds.ceil();
    int minutes = (totalSeconds ~/ 60) % 60;
    int remainingSeconds = totalSeconds % 60;

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr';
  }
  
  static String formatDoubleSecondsToTime(double seconds) {
    int totalSeconds = seconds.floor();
    int hours = (totalSeconds ~/ 3600) % 24;
    int minutes = (totalSeconds ~/ 60) % 60;
    int secondsRemainder = totalSeconds % 60;
    int milliseconds = ((seconds - totalSeconds) * 1000).round();

    String hoursString = hours.toString().padLeft(2, '0');
    String minutesString = minutes.toString().padLeft(2, '0');
    String secondsString = secondsRemainder.toString().padLeft(2, '0');
    String millisecondsString = milliseconds.toString().padLeft(3, '0');

    return '$hoursString:$minutesString:$secondsString.$millisecondsString';
  }

  static Future<Directory> createSubdirectoryInTemporaryDirectory() async {
    DateTime now = DateTime.now();
    String formattedDate = '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
    Directory tempDir = await getTemporaryDirectory();
    String subDirName = 'audio_edit_temp/$formattedDate';
    String subDirPath = '${tempDir.path}/$subDirName';
    Directory subDir = Directory(subDirPath);
    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
      debugPrint('Subdirectory created: $subDirPath');
    } else {
      debugPrint('Subdirectory already exists: $subDirPath');
    }
    return subDir;
  }

  static Future<bool> deleteDirectory(String path) async {
    Directory directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      debugPrint('Directory deleted: $path');
      return true;
    } else {
      debugPrint('Directory does not exist: $path');
      return false;
    }
  }

  static Future<void> deleteAllTempFiles() async {
    Directory tempDir = await getTemporaryDirectory();
    await deleteDirectory(tempDir.path);
  }

  static Future<void> deleteAudioDirectoriesStartingWith(String prefix) async {
    Directory tempDir = await getTemporaryDirectory();
    String subDirName = 'audio_edit_temp';
    String subDirPath = '${tempDir.path}/$subDirName';
    Directory directory = Directory(subDirPath);
    if (await directory.exists()) {
      List<FileSystemEntity> contents = directory.listSync();
      for (FileSystemEntity entity in contents) {
        if (entity is Directory) {
          String directoryName = entity.path.split('/').last;
          if (directoryName.startsWith(prefix)) {
            await entity.delete(recursive: true);
            debugPrint('Directory deleted: ${entity.path}');
          }
        }
      }
    } else {
      debugPrint('Directory does not exist: $subDirPath');
    }
  }

  static Future<bool> deleteAudioTempDirectory() async {
    Directory tempDir = await getTemporaryDirectory();
    String subDirName = 'audio_edit_temp';
    String subDirPath = '${tempDir.path}/$subDirName';
    Directory directory = Directory(subDirPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      debugPrint('Directory deleted: $subDirPath');
      return true;
    } else {
      debugPrint('Directory does not exist: $subDirPath');
      return true;
    }
  }

  static Future<void> deleteAudioTempFilesByDate(String formattedDate) async {
    Directory tempDir = await getTemporaryDirectory();
    String subDirName = 'audio_edit_temp/$formattedDate';
    String subDirPath = '${tempDir.path}/$subDirName';
    Directory directory = Directory(subDirPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
      debugPrint('Directory deleted: $subDirPath');
    } else {
      debugPrint('Directory does not exist or is not a directory: $subDirPath');
    }
  }

  static Future<void> copyFileFromCacheToDirectory(String cacheFilePath) async {
    try {
      String filename = cacheFilePath.split('/').last;
      String? filePath = await FilePicker.platform.getDirectoryPath();
      if (filePath == null) {
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_copyFileFromCacheToDirectory:用户取消了选择目标文件夹');
        return;
      }
      String destinationDirectoryPath = filePath;
      // debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_copyFileFromCacheToDirectory:用户选择的目标文件夹路径：$destinationDirectoryPath');
      // 构建目标文件路径
      String destinationFilePath = '$destinationDirectoryPath/$filename';
      await File(cacheFilePath).copy(destinationFilePath);
      // debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_copyFileFromCacheToDirectory:文件已成功复制到目标路径：$destinationFilePath');
    } catch (e) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_copyFileFromCacheToDirectory:复制文件时出现错误：$e');
    }
  }

  static List<List<T>> splitList<T>(List<T> list, int totalChunks) {
    if (list.isEmpty || totalChunks <= 0) {
      return [];
    }else if(totalChunks<=0){
      return [list];
    }else{
      final chunkSize = (list.length / totalChunks).ceil();
      final result = List<List<T>>.generate(totalChunks, (index) {
        final start = index * chunkSize;
        final end = (index + 1) * chunkSize;
        return list.sublist(start, end.clamp(0, list.length));
      });
      return result;
    }
  }

  static List<double> getWavebarDataByDecodeData<T extends num>(
    List<T> decodedata, {
    int points = 200,
    int averageCount = 100,
  }) {
    try{
      List<List<T>> channelDatasChunk = splitList<T>(decodedata, points).toList();
      // debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_getWavebarDataByDecodeData with channelDatasChunk: 🍉🍉🍉<----->>>${channelDatasChunk.length}<<<----->🍉🍉🍉");
      List<double> res = [];
      for(int index=0; index < channelDatasChunk.length; index++){
        final int step = (channelDatasChunk[index].length / averageCount).floor();
        double sum = 0;
        for (int i = 0; i < channelDatasChunk[index].length; i += step) {
          sum += (channelDatasChunk[index][i.clamp(0, channelDatasChunk[index].length-1)]).toDouble();
        }
        final double average = sum / (channelDatasChunk[index].length / step);
        res.add(average);
      }
      return res;
    } catch (e){
      debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_getWavebarDataByDecodeData with catchError: 🐛🐛🐛$e🐛🐛🐛");
      return [];
    }
  }

  static List<double> fixedPaintGainMaxHeightWaveBarData(List<double> data, double halfHeight) {
    double max = data.reduce((value, element) => value > element ? value : element);
    if (max == 0) {
      return List.generate(data.length, (index) => 1);
    }
    double gainRatio = halfHeight / max;
    return List.generate(data.length, (index) {
      double gainHeight = data[index] * gainRatio;
      return gainHeight <= 0 ? 1 : gainHeight;
    });
  }

  static Future<List<double>> getRenderWaveData(String filePath, {
    int points = 200,
    double gainMaxHeight = 100,
    int averageCount = 10,
    int? timeoutCancelMilliseconds,
  }) {
    Completer<List<double>> completer = Completer<List<double>>();
    getDecodedAudioData(filePath, timeoutCancelMilliseconds: timeoutCancelMilliseconds).then((decodedata) {
      if(decodedata.isNotEmpty){
        // debugPrint("FfmpegUtilsKit_getRenderWaveData data: 🍉🍉🍉<----->>>decodedata.length:${decodedata.length} points:$points<<<----->🍉🍉🍉");
        List<double> waveData = getWavebarDataByDecodeData<int>(decodedata, points: points, averageCount: averageCount);
        // debugPrint("FfmpegUtilsKit_getRenderWaveData data: 🍉🍉🍉🍉🍉<----->>>decodedata.length:${decodedata.length} points:$points ${waveData.length}<<<----->🍉🍉🍉");
        completer.complete(fixedPaintGainMaxHeightWaveBarData(waveData, gainMaxHeight));
      }else{
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute with null: 🐛🐛🐛${null}🐛🐛🐛');
        completer.complete([]);
      }
    }).catchError((onError){
       debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute with catchError: 🐛🐛🐛$onError🐛🐛🐛');
       completer.complete([]);
    });
    return completer.future;
  }

  /// 获取视频时长
  static Future<double> getMediaDuration(String filepath) async {
    Completer<double> completer = Completer<double>();

    try {
      String command = '-i $filepath -show_entries format=duration -v quiet -of json';
      final session = await FFprobeKit.getMediaInformationFromCommand(command);
      final information = session.getMediaInformation();

      if (information != null) {
        final output = await session.getOutput();
        if (output != null) {
          var outputData = jsonDecode(output);
          double duration = double.parse(outputData["format"]["duration"]);
          completer.complete(duration);
        } else {
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getMediaDuration with null output: 🐛🐛🐛null output🐛🐛🐛');
          completer.complete(0);
        }
      } else {
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getMediaDuration with null information: 🐛🐛🐛null information🐛🐛🐛');
        completer.complete(0);
      }

      session.cancel();

    } catch (error, stackTrace) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getMediaDuration with error: 🐛🐛🐛$error🐛🐛🐛');
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getMediaDuration with stackTrace: 🐛🐛🐛$stackTrace');
      completer.complete(0);
    }

    return completer.future;
    // FFprobeKit.getMediaInformation(filepath).then((session) async {
    //   final information = await session.getMediaInformation();
    //   if (information != null) {
    //     // CHECK THE FOLLOWING ATTRIBUTES ON ERROR
    //     final output = await session.getOutput();
    //     if(output != null){
    //       // debugPrint("getMediaInformation: $output");
    //       var outputData = jsonDecode(output!);
    //       debugPrint("getMediaInformation: $outputData");
    //       debugPrint("getMediaInformation: ${outputData["streams"][0]["duration"]}");
    //     }
    //   }
    // }).onError((error, stackTrace){
    //   debugPrint('getMediaInformation failed with error: $error');
    // });
  }

  static Future<FfmpegKitExecuteResData?> ffmpegExecute(String command, {int? timeoutCancelMilliseconds}) {
    debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegKitExecute with command: 🍉🍉🍉<----->>>$command<<<----->🍉🍉🍉");
    Completer<FfmpegKitExecuteResData?> completer = Completer<FfmpegKitExecuteResData?>();
    try {
      FFmpegKit.execute(command).then((session) {
        Timer? timer;
        void handleTimeout() {
          timer?.cancel();
          session.cancel();
          timer = null;
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute 执行超时');
        }
        timer = Timer(Duration(milliseconds: timeoutCancelMilliseconds ?? defaultFfmpegKitExecuteTimeoutCancelMilliseconds), handleTimeout);
        session.getState().then((sessionState) {
          timer?.cancel();
          timer = null;
          if (sessionState == SessionState.completed) {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute 执行成功 ${session.getAllLogsAsString()}');
          } else if (sessionState == SessionState.failed) {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute 执行失败 ${session.getAllLogsAsString()}');
          } else if (sessionState == SessionState.created) {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute 创建');
          }
        });
        // debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute session:  🍑🍑🍑$session🍑🍑🍑");
        completer.complete(FfmpegKitExecuteResData(command: command, session: session, error: null, code: 1));
      }).catchError((error, stackTrace) {
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute with catchError: 🐛🐛🐛$error🐛🐛🐛');
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute with catchError: 🐛🐛🐛$stackTrace');
        completer.complete(FfmpegKitExecuteResData(command: command, session: null, error: error, code: 0));
      });
    } catch (error) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_ffmpegExecute with Exceptionerror: 🐛🐛🐛$error🐛🐛🐛');
      completer.complete(FfmpegKitExecuteResData(command: command, session: null, error: error, code: 0));
    }

    return completer.future;
  }

  static Future<String?> transToMp3(String filePath,{ int? timeoutCancelMilliseconds }) async {
    Completer<String?> completer = Completer<String?>();
    Directory tempDir = await createSubdirectoryInTemporaryDirectory();
    final outputPath = '${tempDir.path}/trans_out_audio__${getUuid()}.mp3';

    try {
      // 执行转换命令，并设置超时处理
      ffmpegExecute('-i "$filePath" -c:a libmp3lame -q:a 2 "$outputPath"', timeoutCancelMilliseconds: timeoutCancelMilliseconds)
        .then((FfmpegKitExecuteResData? data) async {
          if (data != null && data.code == 1) {
            FFmpegSession session = data.session!;
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_transToMp3 Successfully with path: 🍉🍉🍉<----->>>$outputPath<<<----->🍉🍉🍉");
              completer.complete(outputPath);
            } else {
              debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToMp3 with failure: 🐛🐛🐛null🐛🐛🐛');
              completer.complete(null);
            }
            // 取消会话
            session.cancel();
          } else {
            completer.complete(null);
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToMp3 with failure: 🐛🐛🐛null🐛🐛🐛');
          }
        }).catchError((error) {
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToMp3 with failure: 🐛🐛🐛$error🐛🐛🐛');
          completer.complete(null);
        });

    } catch (error) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToMp3 with failure: 🐛🐛🐛$error🐛🐛🐛');
      completer.complete(null);
    }

    return completer.future;
  }


  static Future<String?> transToWav(String filePath, { int? timeoutCancelMilliseconds }) async {
    Completer<String?> completer = Completer<String?>();
    Directory tempDir = await createSubdirectoryInTemporaryDirectory();
    final outputPath = '${tempDir.path}/trans_out_audio__${getUuid()}.wav';

    try {
      // 执行转换命令，并设置超时处理
      ffmpegExecute('-i "$filePath" "$outputPath"', timeoutCancelMilliseconds: timeoutCancelMilliseconds)
        .then((FfmpegKitExecuteResData? data) async {
          if (data != null && data.code == 1) {
            FFmpegSession session = data.session!;
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              // debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_transToWav Successfully with path: 🍉🍉🍉<----->>>$outputPath<<<----->🍉🍉🍉");
              completer.complete(outputPath);
            } else {
              debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToWav with failure: 🐛🐛🐛null🐛🐛🐛');
              completer.complete(null);
            }
            // 取消会话
            session.cancel();
          } else {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToWav with failure: 🐛🐛🐛null🐛🐛🐛');
            completer.complete(null);
          }
        }).catchError((error) {
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToWav with failure: 🐛🐛🐛$error🐛🐛🐛');
          completer.complete(null);
        });

    } catch (error) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_transToWav with failure: 🐛🐛🐛$error🐛🐛🐛');
      completer.complete(null);
    }

    return completer.future;
  }

  // 裁剪区间输入和输出皆是 mp3
  static Future<String?> cropMedia({
    required String filePath,
    required double clipStartTime,
    required double clipEndTime,
    int? timeoutCancelMilliseconds
  }) async {
    Completer<String?> completer = Completer<String?>();
    Directory tempDir = await createSubdirectoryInTemporaryDirectory();
    final outputPath = '${tempDir.path}/trans_out_audio__${getUuid()}.mp3';

    try {
      // 执行裁剪命令，并设置超时处理
      ffmpegExecute('-i "$filePath" -ss ${formatDoubleSecondsToTime(clipStartTime)} -to ${formatDoubleSecondsToTime(clipEndTime)} -c:v copy -c:a copy "$outputPath"', timeoutCancelMilliseconds: timeoutCancelMilliseconds)
        .then((FfmpegKitExecuteResData? data) async {
          if (data != null && data.code == 1) {
            FFmpegSession session = data.session!;
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_cropMedia Successfully with path: 🍉🍉🍉<----->>>$outputPath<<<----->🍉🍉🍉");
              completer.complete(outputPath);
            } else {
              debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_cropMedia with failure: 🐛🐛🐛null🐛🐛🐛');
              completer.complete(null);
            }
            // 取消会话
            session.cancel();
          } else {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_cropMedia with failure: 🐛🐛🐛null🐛🐛🐛');
            completer.complete(null);
          }
        }).catchError((error) {
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_cropMedia with failure: 🐛🐛🐛$error🐛🐛🐛');
          completer.complete(null);
        });

    } catch (error) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_cropMedia with failure: 🐛🐛🐛$error🐛🐛🐛');
      completer.complete(null);
    }

    return completer.future;
  }


  static Future<List<int>> getDecodedAudioData(String filePath, {int? timeoutCancelMilliseconds}) async {
    Completer<List<int>> completer = Completer<List<int>>();
    Directory tempDir = await createSubdirectoryInTemporaryDirectory();
    final outputPath = '${tempDir.path}/trans_out_audio__${getUuid()}.pcm';

    try {
      // 执行解码命令，并设置超时处理
      ffmpegExecute('-i "$filePath" -f s16le -acodec pcm_s16le -ar 4800 "$outputPath"', timeoutCancelMilliseconds: timeoutCancelMilliseconds)
        .then((FfmpegKitExecuteResData? data) async {
          if (data != null && data.code == 1) {
            FFmpegSession session = data.session!;
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              File file = File(outputPath);
              if (await file.exists()) {
                // debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData PCM file is exist: 🍉🍉🍉<----->>>$outputPath<<<----->🍉🍉🍉");
                List<int> decodedData = await file.readAsBytes();
                // debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData output: 🍉🍉🍉<----->>>${decodedData.length}<<<----->🍉🍉🍉");
                completer.complete(decodedData);
              } else {
                debugPrint("🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData PCM file does not exist.: 🍉🍉🍉<----->>>null<<<----->🍉🍉🍉");
                completer.complete([]);
              }
            } else {
              debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData with failure: 🐛🐛🐛null🐛🐛🐛');
              completer.complete([]);
            }
            // 取消会话
            session.cancel();
          } else {
            debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData with failure: 🐛🐛🐛null🐛🐛🐛');
            completer.complete([]);
          }
        }).catchError((error) {
          debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData with failure: 🐛🐛🐛$error🐛🐛🐛');
          completer.complete([]);
        });

    } catch (e) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getDecodedAudioData with Exceptionerror: 🐛🐛🐛$e🐛🐛🐛');
      completer.complete([]);
    }

    return completer.future;
  }

  // testWaveBarData
  // static Future<List<double>> getWaveBarData({
  //   required double waveRenderWidth,
  //   required double waveBarMaxheight,
  //   required double waveItemWidth,
  //   required double waveItemSpacing,  
  // }) async {
  //   List<double> waveBarData = [];
  //   Random random = Random();
  //   int count = ((waveRenderWidth + waveItemSpacing) / (waveItemWidth + waveItemSpacing)).truncate();
  //   for(int i = 0; i < count; i++) {
  //     double randomNumber = random.nextDouble() * (waveBarMaxheight - 1) + 1;
  //     waveBarData.add(randomNumber.toDouble());
  //   }
  //   return waveBarData;
  //   // waveBarData = await FfmpegUtilsKit.getWaveBarData(
  //   //    waveRenderWidth: waveRenderMaxWidth.toDouble(),
  //   //    waveBarMaxheight: clipConfig['waveItemHeight'].toDouble(),
  //   //    waveItemWidth: clipConfig['waveItemWidth'].toDouble(),
  //   //    waveItemSpacing: clipConfig['waveItemSpacing'].toDouble(),
  //   // );
  // }
  
  // 计算波形渲染的最大宽度
  static double calculateWaveRenderMaxWidth(double duration, double windowWidth, AudioClipFixedDurationClipConfig clipConfig) {
    double left = clipConfig.playOpBtnSize + clipConfig.boxLRMargin + clipConfig.clipAreaLeftMargin + clipConfig.playOpBtnMargin * 2;
    double waveBarRenderViewMaxBoxWidth = windowWidth - left - clipConfig.clipAreaRTPadding * 2;
    double waveRenderWidthRatio =  duration / clipConfig.clipMaxDuration;
    return waveBarRenderViewMaxBoxWidth * waveRenderWidthRatio;
  }

  // 计算波形渲染点的数量
  static int calculateWaveRenderPoints(double waveRenderMaxWidth, AudioClipFixedDurationClipConfig clipConfig) {
    return ((waveRenderMaxWidth + clipConfig.waveItemSpacing) ~/ (clipConfig.waveItemWidth + clipConfig.waveItemSpacing));
  }
  
  // 获取裁剪组件初始化渲染数据
  static Future<FfmpegKitInitClipAudioData?> getAudioDataByFile({
   required String filepath,
   required double windowWidth,
   AudioClipFixedDurationClipConfig? clipConfig,
   int? timeoutCancelMilliseconds,
  }) async {
    try {
      clipConfig ??= audioClipFixedDurationClipConfig;
      
      // 转换为 MP3 格式
      String? mp3FilePath = await transToMp3(filepath, timeoutCancelMilliseconds: timeoutCancelMilliseconds);
      if (mp3FilePath == null) {
        debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getAudioDataByFile: 转换mp3失败 filePath: $filepath');
        return null;
      }
      
      // 获取音频持续时间
      double duration = await getMediaDuration(mp3FilePath);
      
      // 计算波形数据
      double waveRenderMaxWidth = calculateWaveRenderMaxWidth(duration, windowWidth, clipConfig);
      List<double> waveBarData = await getRenderWaveData(
        mp3FilePath,
        points: calculateWaveRenderPoints(waveRenderMaxWidth, clipConfig),
        gainMaxHeight: clipConfig.waveItemHeight,
        timeoutCancelMilliseconds: timeoutCancelMilliseconds,
      );

      return FfmpegKitInitClipAudioData(
        souceFilePath: filepath,
        mp3FilePath: mp3FilePath,
        duration: duration,
        waveBarData: waveBarData,
      );
    } catch (e) {
      debugPrint('🍎🍎🍎🍎🍎FfmpegUtilsKit_getAudioDataByFile:获取裁剪初始化数据失败：$e');
      return null;
    } 
  }
}