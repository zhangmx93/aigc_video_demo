import 'dart:io';

/// 提取音频记录状态
enum ExtractStatus {
  pending,    // 待提取
  extracting, // 提取中
  success,    // 提取成功
  failed,     // 提取失败
}

/// 音频格式类型
enum AudioFormat {
  mp3,   // MP3 格式
  aac,   // AAC 格式
  wav,   // WAV 格式
  m4a,   // M4A 格式
  flac,  // FLAC 格式
  ogg,   // OGG 格式
}

/// 从视频中提取的音频记录模型
class ExtractedAudioItemModel {
  /// 唯一标识符
  String? id;

  /// 原视频文件路径
  String? videoPath;

  /// 原视频文件名
  String? videoFileName;

  /// 提取后的音频文件路径
  String? audioPath;

  /// 音频文件名
  String? audioFileName;

  /// 音频格式
  AudioFormat? audioFormat;

  /// 提取状态
  ExtractStatus? status;

  /// 视频文件大小（字节）
  int? videoFileSize;

  /// 音频文件大小（字节）
  int? audioFileSize;

  /// 视频时长（毫秒）
  int? duration;

  /// 音频比特率（kbps）
  String? bitrate;

  /// 音频采样率（Hz）
  String? sampleRate;

  /// 音频声道数
  int? channels;

  /// 创建时间戳（毫秒）
  int? createdAt;

  /// 更新时间戳（毫秒）
  int? updatedAt;

  /// 提取完成时间戳（毫秒）
  int? completedAt;

  /// 错误信息（如果提取失败）
  String? errorMessage;

  /// 视频缩略图路径（可选）
  String? thumbnailPath;

  /// 备注信息
  String? notes;

  /// 标签列表
  List<String>? tags;

  /// 是否收藏
  bool? isFavorite;

  ExtractedAudioItemModel({
    this.id,
    this.videoPath,
    this.videoFileName,
    this.audioPath,
    this.audioFileName,
    this.audioFormat,
    this.status,
    this.videoFileSize,
    this.audioFileSize,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.errorMessage,
    this.thumbnailPath,
    this.notes,
    this.tags,
    this.isFavorite,
  });

  // ==================== JSON 序列化 ====================

  /// 从 JSON 创建
  factory ExtractedAudioItemModel.fromJson(Map<String, dynamic> json) {
    return ExtractedAudioItemModel(
      id: json['id'] as String?,
      videoPath: json['videoPath'] as String?,
      videoFileName: json['videoFileName'] as String?,
      audioPath: json['audioPath'] as String?,
      audioFileName: json['audioFileName'] as String?,
      audioFormat: json['audioFormat'] != null
          ? AudioFormat.values.firstWhere(
              (e) => e.name == json['audioFormat'],
              orElse: () => AudioFormat.mp3,
            )
          : null,
      status: json['status'] != null
          ? ExtractStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => ExtractStatus.pending,
            )
          : null,
      videoFileSize: json['videoFileSize'] as int?,
      audioFileSize: json['audioFileSize'] as int?,
      duration: json['duration'] as int?,
      bitrate: json['bitrate'] as String?,
      sampleRate: json['sampleRate'] as String?,
      channels: json['channels'] as int?,
      createdAt: json['createdAt'] as int?,
      updatedAt: json['updatedAt'] as int?,
      completedAt: json['completedAt'] as int?,
      errorMessage: json['errorMessage'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoPath': videoPath,
      'videoFileName': videoFileName,
      'audioPath': audioPath,
      'audioFileName': audioFileName,
      'audioFormat': audioFormat?.name,
      'status': status?.name,
      'videoFileSize': videoFileSize,
      'audioFileSize': audioFileSize,
      'duration': duration,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'channels': channels,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'errorMessage': errorMessage,
      'thumbnailPath': thumbnailPath,
      'notes': notes,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  // ==================== 便捷方法 ====================

  /// 复制并更新部分字段
  ExtractedAudioItemModel copyWith({
    String? id,
    String? videoPath,
    String? videoFileName,
    String? audioPath,
    String? audioFileName,
    AudioFormat? audioFormat,
    ExtractStatus? status,
    int? videoFileSize,
    int? audioFileSize,
    int? duration,
    String? bitrate,
    String? sampleRate,
    int? channels,
    int? createdAt,
    int? updatedAt,
    int? completedAt,
    String? errorMessage,
    String? thumbnailPath,
    String? notes,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return ExtractedAudioItemModel(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      videoFileName: videoFileName ?? this.videoFileName,
      audioPath: audioPath ?? this.audioPath,
      audioFileName: audioFileName ?? this.audioFileName,
      audioFormat: audioFormat ?? this.audioFormat,
      status: status ?? this.status,
      videoFileSize: videoFileSize ?? this.videoFileSize,
      audioFileSize: audioFileSize ?? this.audioFileSize,
      duration: duration ?? this.duration,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 检查音频文件是否存在
  Future<bool> audioFileExists() async {
    if (audioPath == null) return false;
    return await File(audioPath!).exists();
  }

  /// 检查视频文件是否存在
  Future<bool> videoFileExists() async {
    if (videoPath == null) return false;
    return await File(videoPath!).exists();
  }

  /// 获取音频文件扩展名
  String? getAudioExtension() {
    return audioFormat?.name;
  }

  /// 获取格式化的文件大小
  String getFormattedAudioSize() {
    if (audioFileSize == null) return '未知';
    return _formatFileSize(audioFileSize!);
  }

  String getFormattedVideoSize() {
    if (videoFileSize == null) return '未知';
    return _formatFileSize(videoFileSize!);
  }

  /// 获取格式化的时长
  String getFormattedDuration() {
    if (duration == null) return '未知';
    final seconds = duration! ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 获取状态描述
  String getStatusDescription() {
    switch (status) {
      case ExtractStatus.pending:
        return '待提取';
      case ExtractStatus.extracting:
        return '提取中';
      case ExtractStatus.success:
        return '提取成功';
      case ExtractStatus.failed:
        return '提取失败';
      case null:
        return '未知';
    }
  }

  @override
  String toString() {
    return 'ExtractedAudioItemModel(id: $id, videoFileName: $videoFileName, audioFileName: $audioFileName, status: ${status?.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtractedAudioItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 音频格式扩展方法
extension AudioFormatExtension on AudioFormat {
  /// 获取文件扩展名
  String get extension {
    switch (this) {
      case AudioFormat.mp3:
        return 'mp3';
      case AudioFormat.aac:
        return 'aac';
      case AudioFormat.wav:
        return 'wav';
      case AudioFormat.m4a:
        return 'm4a';
      case AudioFormat.flac:
        return 'flac';
      case AudioFormat.ogg:
        return 'ogg';
    }
  }

  /// 获取显示名称
  String get displayName {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.aac:
        return 'AAC';
      case AudioFormat.wav:
        return 'WAV';
      case AudioFormat.m4a:
        return 'M4A';
      case AudioFormat.flac:
        return 'FLAC';
      case AudioFormat.ogg:
        return 'OGG';
    }
  }

  /// 获取 MIME 类型
  String get mimeType {
    switch (this) {
      case AudioFormat.mp3:
        return 'audio/mpeg';
      case AudioFormat.aac:
        return 'audio/aac';
      case AudioFormat.wav:
        return 'audio/wav';
      case AudioFormat.m4a:
        return 'audio/mp4';
      case AudioFormat.flac:
        return 'audio/flac';
      case AudioFormat.ogg:
        return 'audio/ogg';
    }
  }
}
