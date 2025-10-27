import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aigc_video_demo/shared/models/extracted_audio_item_model.dart';
import 'package:aigc_video_demo/shared/utils/audio_logger.dart';

/// 视频音频提取记录管理器
/// 负责管理从视频中提取的音频文件的本地存储、查询、统计等功能
class ExtractedAudioManager {
  static final ExtractedAudioManager _instance = ExtractedAudioManager._internal();
  factory ExtractedAudioManager() => _instance;
  ExtractedAudioManager._internal();

  // ==================== 配置常量 ====================
  /// SharedPreferences 存储键
  static const String _storageKey = 'extracted_audio_items';

  /// 最大记录数量
  static const int maxRecordCount = 1000;

  // ==================== 内存缓存 ====================
  /// 内存中的提取记录列表
  List<ExtractedAudioItemModel> _audioItems = [];

  /// 是否已初始化
  bool _initialized = false;

  /// 日志工具
  final _logger = AudioLogger.instance;

  // ==================== 初始化 ====================

  /// 初始化管理器
  Future<void> initialize() async {
    if (_initialized) {
      _logger.w('ExtractedAudioManager 已初始化，跳过');
      return;
    }

    try {
      await _loadFromStorage();
      _initialized = true;
      _logger.s('ExtractedAudioManager 初始化完成，加载了 ${_audioItems.length} 条记录');
    } catch (e) {
      _logger.e('ExtractedAudioManager 初始化失败', e);
      _audioItems = [];
      _initialized = true;
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  // ==================== CRUD 操作 ====================

  /// 添加音频提取记录
  ///
  /// [item] 提取记录项
  /// [autoSave] 是否自动保存（默认 true）
  ///
  /// 返回：是否添加成功
  Future<bool> addAudioRecord(ExtractedAudioItemModel item, {bool autoSave = true}) async {
    try {
      await _ensureInitialized();

      // 设置时间戳
      final now = DateTime.now().millisecondsSinceEpoch;
      item.createdAt ??= now;
      item.updatedAt = now;

      // 如果没有 ID，生成一个
      if (item.id == null || item.id!.isEmpty) {
        item.id = _generateId();
      }

      // 检查是否已存在相同 ID 的记录
      final existingIndex = _audioItems.indexWhere((a) => a.id == item.id);
      if (existingIndex != -1) {
        // 更新现有记录
        _audioItems[existingIndex] = item;
        _logger.d('🔄 更新音频记录: ${item.id}');
      } else {
        // 添加新记录到列表开头
        _audioItems.insert(0, item);
        _logger.d('➕ 添加音频记录: ${item.id} (${item.audioFileName})');
      }

      // 限制记录数量
      if (_audioItems.length > maxRecordCount) {
        final removed = _audioItems.removeLast();
        _logger.d('🗑️ 移除最旧的音频记录: ${removed.id}');
      }

      // 自动保存
      if (autoSave) {
        await _saveToStorage();
      }

      return true;
    } catch (e) {
      _logger.d('❌ 添加音频记录失败: $e');
      return false;
    }
  }

  /// 批量添加音频记录
  Future<bool> addAudioRecords(List<ExtractedAudioItemModel> items) async {
    try {
      await _ensureInitialized();

      for (var item in items) {
        await addAudioRecord(item, autoSave: false);
      }

      await _saveToStorage();
      _logger.d('✅ 批量添加 ${items.length} 条音频记录');
      return true;
    } catch (e) {
      _logger.d('❌ 批量添加音频记录失败: $e');
      return false;
    }
  }

  /// 更新音频记录
  Future<bool> updateAudioRecord(ExtractedAudioItemModel item) async {
    try {
      await _ensureInitialized();

      if (item.id == null) {
        _logger.d('❌ 更新失败：音频记录 ID 为空');
        return false;
      }

      final index = _audioItems.indexWhere((a) => a.id == item.id);
      if (index == -1) {
        _logger.d('❌ 更新失败：未找到 ID 为 ${item.id} 的音频记录');
        return false;
      }

      item.updatedAt = DateTime.now().millisecondsSinceEpoch;
      _audioItems[index] = item;
      await _saveToStorage();

      _logger.d('✅ 更新音频记录: ${item.id}');
      return true;
    } catch (e) {
      _logger.d('❌ 更新音频记录失败: $e');
      return false;
    }
  }

  /// 更新提取状态
  Future<bool> updateExtractStatus(String id, ExtractStatus status, {String? errorMessage}) async {
    try {
      await _ensureInitialized();

      final index = _audioItems.indexWhere((a) => a.id == id);
      if (index == -1) {
        _logger.d('❌ 更新状态失败：未找到 ID 为 $id 的音频记录');
        return false;
      }

      _audioItems[index].status = status;
      _audioItems[index].updatedAt = DateTime.now().millisecondsSinceEpoch;

      if (status == ExtractStatus.success) {
        _audioItems[index].completedAt = DateTime.now().millisecondsSinceEpoch;
      }

      if (errorMessage != null) {
        _audioItems[index].errorMessage = errorMessage;
      }

      await _saveToStorage();
      _logger.d('✅ 更新提取状态: $id -> ${status.name}');
      return true;
    } catch (e) {
      _logger.d('❌ 更新提取状态失败: $e');
      return false;
    }
  }

  /// 删除音频记录
  Future<bool> deleteAudioRecord(String id) async {
    try {
      await _ensureInitialized();

      final index = _audioItems.indexWhere((a) => a.id == id);
      if (index == -1) {
        _logger.d('⚠️ 删除失败：未找到 ID 为 $id 的音频记录');
        return false;
      }

      _audioItems.removeAt(index);
      await _saveToStorage();

      _logger.d('✅ 删除音频记录: $id');
      return true;
    } catch (e) {
      _logger.d('❌ 删除音频记录失败: $e');
      return false;
    }
  }

  /// 批量删除音频记录
  Future<bool> deleteAudioRecords(List<String> ids) async {
    try {
      await _ensureInitialized();

      _audioItems.removeWhere((item) => ids.contains(item.id));
      await _saveToStorage();

      _logger.d('✅ 批量删除 ${ids.length} 条音频记录');
      return true;
    } catch (e) {
      _logger.d('❌ 批量删除音频记录失败: $e');
      return false;
    }
  }

  /// 清空所有音频记录
  Future<bool> clearAllRecords() async {
    try {
      await _ensureInitialized();

      final count = _audioItems.length;
      _audioItems.clear();
      await _saveToStorage();

      _logger.d('✅ 清空所有音频记录，共 $count 条');
      return true;
    } catch (e) {
      _logger.d('❌ 清空音频记录失败: $e');
      return false;
    }
  }

  // ==================== 查询操作 ====================

  /// 获取所有音频记录
  Future<List<ExtractedAudioItemModel>> getAllRecords() async {
    await _ensureInitialized();
    return List.unmodifiable(_audioItems);
  }

  /// 根据 ID 获取音频记录
  Future<ExtractedAudioItemModel?> getRecordById(String id) async {
    await _ensureInitialized();
    try {
      return _audioItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取音频记录数量
  Future<int> getRecordCount() async {
    await _ensureInitialized();
    return _audioItems.length;
  }

  /// 根据视频路径查找记录
  Future<List<ExtractedAudioItemModel>> getRecordsByVideoPath(String videoPath) async {
    await _ensureInitialized();
    return _audioItems.where((item) => item.videoPath == videoPath).toList();
  }

  // ==================== 搜索和过滤 ====================

  /// 根据音频格式过滤
  Future<List<ExtractedAudioItemModel>> filterByFormat(AudioFormat format) async {
    await _ensureInitialized();
    return _audioItems.where((item) => item.audioFormat == format).toList();
  }

  /// 根据提取状态过滤
  Future<List<ExtractedAudioItemModel>> filterByStatus(ExtractStatus status) async {
    await _ensureInitialized();
    return _audioItems.where((item) => item.status == status).toList();
  }

  /// 根据时间范围过滤
  Future<List<ExtractedAudioItemModel>> filterByTimeRange(DateTime start, DateTime end) async {
    await _ensureInitialized();

    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return _audioItems.where((item) {
      final createdAt = item.createdAt;
      return createdAt != null && createdAt >= startMs && createdAt <= endMs;
    }).toList();
  }

  /// 获取收藏的记录
  Future<List<ExtractedAudioItemModel>> getFavoriteRecords() async {
    await _ensureInitialized();
    return _audioItems.where((item) => item.isFavorite == true).toList();
  }

  /// 搜索音频记录（根据文件名）
  Future<List<ExtractedAudioItemModel>> searchByFileName(String keyword) async {
    await _ensureInitialized();

    if (keyword.isEmpty) {
      return _audioItems;
    }

    final lowerKeyword = keyword.toLowerCase();
    return _audioItems.where((item) {
      final audioName = item.audioFileName?.toLowerCase() ?? '';
      final videoName = item.videoFileName?.toLowerCase() ?? '';
      return audioName.contains(lowerKeyword) || videoName.contains(lowerKeyword);
    }).toList();
  }

  /// 根据标签搜索
  Future<List<ExtractedAudioItemModel>> searchByTag(String tag) async {
    await _ensureInitialized();
    return _audioItems.where((item) => item.tags?.contains(tag) ?? false).toList();
  }

  /// 高级搜索
  Future<List<ExtractedAudioItemModel>> advancedSearch({
    String? keyword,
    AudioFormat? audioFormat,
    ExtractStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    bool? isFavorite,
    List<String>? tags,
  }) async {
    await _ensureInitialized();

    var results = _audioItems;

    // 按关键词搜索
    if (keyword != null && keyword.isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      results = results.where((item) {
        final audioName = item.audioFileName?.toLowerCase() ?? '';
        final videoName = item.videoFileName?.toLowerCase() ?? '';
        return audioName.contains(lowerKeyword) || videoName.contains(lowerKeyword);
      }).toList();
    }

    // 按音频格式过滤
    if (audioFormat != null) {
      results = results.where((item) => item.audioFormat == audioFormat).toList();
    }

    // 按状态过滤
    if (status != null) {
      results = results.where((item) => item.status == status).toList();
    }

    // 按收藏状态过滤
    if (isFavorite != null) {
      results = results.where((item) => item.isFavorite == isFavorite).toList();
    }

    // 按标签过滤
    if (tags != null && tags.isNotEmpty) {
      results = results.where((item) {
        return tags.any((tag) => item.tags?.contains(tag) ?? false);
      }).toList();
    }

    // 按时间范围过滤
    if (startTime != null || endTime != null) {
      final startMs = startTime?.millisecondsSinceEpoch ?? 0;
      final endMs = endTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

      results = results.where((item) {
        final createdAt = item.createdAt;
        return createdAt != null && createdAt >= startMs && createdAt <= endMs;
      }).toList();
    }

    return results;
  }

  // ==================== 排序 ====================

  /// 按创建时间排序
  Future<List<ExtractedAudioItemModel>> sortByCreatedTime({bool ascending = false}) async {
    await _ensureInitialized();

    final sorted = List<ExtractedAudioItemModel>.from(_audioItems);
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? 0;
      final bTime = b.createdAt ?? 0;
      return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
    });

    return sorted;
  }

  /// 按完成时间排序
  Future<List<ExtractedAudioItemModel>> sortByCompletedTime({bool ascending = false}) async {
    await _ensureInitialized();

    final sorted = List<ExtractedAudioItemModel>.from(_audioItems);
    sorted.sort((a, b) {
      final aTime = a.completedAt ?? 0;
      final bTime = b.completedAt ?? 0;
      return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
    });

    return sorted;
  }

  /// 按文件名排序
  Future<List<ExtractedAudioItemModel>> sortByFileName({bool ascending = true}) async {
    await _ensureInitialized();

    final sorted = List<ExtractedAudioItemModel>.from(_audioItems);
    sorted.sort((a, b) {
      final aName = a.audioFileName ?? '';
      final bName = b.audioFileName ?? '';
      return ascending ? aName.compareTo(bName) : bName.compareTo(aName);
    });

    return sorted;
  }

  /// 按文件大小排序
  Future<List<ExtractedAudioItemModel>> sortByFileSize({bool ascending = true}) async {
    await _ensureInitialized();

    final sorted = List<ExtractedAudioItemModel>.from(_audioItems);
    sorted.sort((a, b) {
      final aSize = a.audioFileSize ?? 0;
      final bSize = b.audioFileSize ?? 0;
      return ascending ? aSize.compareTo(bSize) : bSize.compareTo(aSize);
    });

    return sorted;
  }

  // ==================== 统计信息 ====================

  /// 获取统计信息
  Future<AudioExtractStats> getStats() async {
    await _ensureInitialized();

    int mp3Count = 0;
    int aacCount = 0;
    int wavCount = 0;
    int m4aCount = 0;
    int flacCount = 0;
    int oggCount = 0;
    int otherCount = 0;

    int pendingCount = 0;
    int extractingCount = 0;
    int successCount = 0;
    int failedCount = 0;

    int totalAudioSize = 0;
    int totalVideoSize = 0;

    for (var item in _audioItems) {
      // 统计格式
      switch (item.audioFormat) {
        case AudioFormat.mp3:
          mp3Count++;
          break;
        case AudioFormat.aac:
          aacCount++;
          break;
        case AudioFormat.wav:
          wavCount++;
          break;
        case AudioFormat.m4a:
          m4aCount++;
          break;
        case AudioFormat.flac:
          flacCount++;
          break;
        case AudioFormat.ogg:
          oggCount++;
          break;
        case null:
          otherCount++;
          break;
      }

      // 统计状态
      switch (item.status) {
        case ExtractStatus.pending:
          pendingCount++;
          break;
        case ExtractStatus.extracting:
          extractingCount++;
          break;
        case ExtractStatus.success:
          successCount++;
          break;
        case ExtractStatus.failed:
          failedCount++;
          break;
        case null:
          break;
      }

      // 统计文件大小
      totalAudioSize += item.audioFileSize ?? 0;
      totalVideoSize += item.videoFileSize ?? 0;
    }

    return AudioExtractStats(
      totalCount: _audioItems.length,
      mp3Count: mp3Count,
      aacCount: aacCount,
      wavCount: wavCount,
      m4aCount: m4aCount,
      flacCount: flacCount,
      oggCount: oggCount,
      otherCount: otherCount,
      pendingCount: pendingCount,
      extractingCount: extractingCount,
      successCount: successCount,
      failedCount: failedCount,
      totalAudioSize: totalAudioSize,
      totalVideoSize: totalVideoSize,
      favoriteCount: _audioItems.where((item) => item.isFavorite == true).length,
    );
  }

  // ==================== 收藏管理 ====================

  /// 切换收藏状态
  Future<bool> toggleFavorite(String id) async {
    try {
      await _ensureInitialized();

      final index = _audioItems.indexWhere((a) => a.id == id);
      if (index == -1) {
        _logger.d('❌ 切换收藏失败：未找到 ID 为 $id 的音频记录');
        return false;
      }

      _audioItems[index].isFavorite = !(_audioItems[index].isFavorite ?? false);
      _audioItems[index].updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveToStorage();

      _logger.d('✅ 切换收藏状态: $id -> ${_audioItems[index].isFavorite}');
      return true;
    } catch (e) {
      _logger.d('❌ 切换收藏失败: $e');
      return false;
    }
  }

  // ==================== 标签管理 ====================

  /// 添加标签
  Future<bool> addTag(String id, String tag) async {
    try {
      await _ensureInitialized();

      final index = _audioItems.indexWhere((a) => a.id == id);
      if (index == -1) {
        _logger.d('❌ 添加标签失败：未找到 ID 为 $id 的音频记录');
        return false;
      }

      _audioItems[index].tags ??= [];
      if (!_audioItems[index].tags!.contains(tag)) {
        _audioItems[index].tags!.add(tag);
        _audioItems[index].updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveToStorage();
        _logger.d('✅ 添加标签: $id -> $tag');
      }

      return true;
    } catch (e) {
      _logger.d('❌ 添加标签失败: $e');
      return false;
    }
  }

  /// 移除标签
  Future<bool> removeTag(String id, String tag) async {
    try {
      await _ensureInitialized();

      final index = _audioItems.indexWhere((a) => a.id == id);
      if (index == -1) {
        _logger.d('❌ 移除标签失败：未找到 ID 为 $id 的音频记录');
        return false;
      }

      if (_audioItems[index].tags?.remove(tag) ?? false) {
        _audioItems[index].updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveToStorage();
        _logger.d('✅ 移除标签: $id -> $tag');
      }

      return true;
    } catch (e) {
      _logger.d('❌ 移除标签失败: $e');
      return false;
    }
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    await _ensureInitialized();
    final tags = <String>{};
    for (var item in _audioItems) {
      if (item.tags != null) {
        tags.addAll(item.tags!);
      }
    }
    return tags.toList()..sort();
  }

  // ==================== 持久化存储 ====================

  /// 从 SharedPreferences 加载
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        _logger.d('📦 无音频提取记录数据');
        _audioItems = [];
        return;
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      _audioItems = jsonList
          .map((item) => ExtractedAudioItemModel.fromJson(item))
          .toList();

      _logger.d('✅ 从存储加载 ${_audioItems.length} 条音频提取记录');
    } catch (e) {
      _logger.d('❌ 加载音频提取记录失败: $e');
      _audioItems = [];
    }
  }

  /// 保存到 SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _audioItems.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_storageKey, jsonString);
      _logger.d('💾 保存 ${_audioItems.length} 条音频提取记录到存储');
    } catch (e) {
      _logger.d('❌ 保存音频提取记录失败: $e');
      rethrow;
    }
  }

  /// 手动保存（用于批量操作后）
  Future<void> save() async {
    await _saveToStorage();
  }

  // ==================== 导入导出 ====================

  /// 导出为 JSON 字符串
  Future<String> exportToJson() async {
    await _ensureInitialized();
    final jsonList = _audioItems.map((item) => item.toJson()).toList();
    return json.encode(jsonList);
  }

  /// 从 JSON 字符串导入（会覆盖现有数据）
  Future<bool> importFromJson(String jsonString, {bool merge = false}) async {
    try {
      await _ensureInitialized();

      final List<dynamic> jsonList = json.decode(jsonString);
      final importedItems = jsonList
          .map((item) => ExtractedAudioItemModel.fromJson(item))
          .toList();

      if (merge) {
        // 合并模式：添加不存在的记录
        for (var item in importedItems) {
          final exists = _audioItems.any((a) => a.id == item.id);
          if (!exists) {
            _audioItems.add(item);
          }
        }
      } else {
        // 覆盖模式：直接替换
        _audioItems = importedItems;
      }

      await _saveToStorage();
      _logger.d('✅ 导入 ${importedItems.length} 条音频提取记录');
      return true;
    } catch (e) {
      _logger.d('❌ 导入音频提取记录失败: $e');
      return false;
    }
  }

  // ==================== 工具方法 ====================

  /// 生成唯一 ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_audioItems.length}';
  }

  /// 获取格式化的统计信息
  Future<String> getFormattedStats() async {
    final stats = await getStats();
    return '''
音频提取记录统计:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 总计: ${stats.totalCount} 条

📁 格式分布:
  🎵 MP3: ${stats.mp3Count} 条
  🎵 AAC: ${stats.aacCount} 条
  🎵 WAV: ${stats.wavCount} 条
  🎵 M4A: ${stats.m4aCount} 条
  🎵 FLAC: ${stats.flacCount} 条
  🎵 OGG: ${stats.oggCount} 条
  📁 其他: ${stats.otherCount} 条

📈 状态分布:
  ⏳ 待提取: ${stats.pendingCount} 条
  ⚙️ 提取中: ${stats.extractingCount} 条
  ✅ 成功: ${stats.successCount} 条
  ❌ 失败: ${stats.failedCount} 条

💾 存储信息:
  音频总大小: ${_formatFileSize(stats.totalAudioSize)}
  视频总大小: ${_formatFileSize(stats.totalVideoSize)}

⭐ 收藏: ${stats.favoriteCount} 条
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
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
}

/// 音频提取统计信息
class AudioExtractStats {
  final int totalCount;
  final int mp3Count;
  final int aacCount;
  final int wavCount;
  final int m4aCount;
  final int flacCount;
  final int oggCount;
  final int otherCount;
  final int pendingCount;
  final int extractingCount;
  final int successCount;
  final int failedCount;
  final int totalAudioSize;
  final int totalVideoSize;
  final int favoriteCount;

  AudioExtractStats({
    required this.totalCount,
    required this.mp3Count,
    required this.aacCount,
    required this.wavCount,
    required this.m4aCount,
    required this.flacCount,
    required this.oggCount,
    required this.otherCount,
    required this.pendingCount,
    required this.extractingCount,
    required this.successCount,
    required this.failedCount,
    required this.totalAudioSize,
    required this.totalVideoSize,
    required this.favoriteCount,
  });

  @override
  String toString() {
    return 'AudioExtractStats(total: $totalCount, success: $successCount, failed: $failedCount)';
  }
}
