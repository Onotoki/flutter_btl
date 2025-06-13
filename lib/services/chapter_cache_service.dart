import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý cache cho nội dung các chương truyện
/// Sử dụng SharedPreferences để lưu trữ dài hạn và memory cache để truy cập nhanh
class ChapterCacheService {
  // Tiền tố cho khóa cache trong SharedPreferences
  static const String _cacheKeyPrefix = 'chapter_cache_';
  // Thời gian cache tối đa là 30 phút
  static const int _maxCacheAgeMinutes = 30;
  // Giới hạn số chương được cache để tránh tràn bộ nhớ
  static const int _maxCachedChapters = 10;

  // Singleton pattern để đảm bảo chỉ có một instance duy nhất
  static final ChapterCacheService _instance = ChapterCacheService._internal();
  factory ChapterCacheService() => _instance;
  ChapterCacheService._internal();

  // Cache trong bộ nhớ RAM để truy cập nhanh hơn
  final Map<String, CachedChapter> _memoryCache = {};

  /// Lưu cache nội dung chương truyện
  /// [storySlug] - Định danh duy nhất của truyện
  /// [chapterNumber] - Số thứ tự chương
  /// [chapterData] - Dữ liệu nội dung chương
  Future<void> cacheChapter(String storySlug, int chapterNumber,
      Map<String, dynamic> chapterData) async {
    try {
      final cacheKey = _getCacheKey(storySlug, chapterNumber);
      final cachedChapter = CachedChapter(
        storySlug: storySlug,
        chapterNumber: chapterNumber,
        data: chapterData,
        cachedAt: DateTime.now(),
      );

      // Lưu vào cache bộ nhớ
      _memoryCache[cacheKey] = cachedChapter;

      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, json.encode(cachedChapter.toJson()));

      print('Đã cache chương $chapterNumber cho truyện $storySlug');

      // Dọn dẹp các cache cũ
      await _cleanupOldCache();
    } catch (e) {
      print('Lỗi khi cache chương: $e');
    }
  }

  /// Lấy nội dung chương đã được cache
  /// Trả về null nếu không có cache hoặc cache đã hết hạn
  Future<Map<String, dynamic>?> getCachedChapter(
      String storySlug, int chapterNumber) async {
    try {
      final cacheKey = _getCacheKey(storySlug, chapterNumber);

      // Kiểm tra cache bộ nhớ trước
      if (_memoryCache.containsKey(cacheKey)) {
        final cached = _memoryCache[cacheKey]!;
        if (_isCacheValid(cached.cachedAt)) {
          print('Tìm thấy cache trong bộ nhớ cho chương $chapterNumber');
          return cached.data;
        } else {
          // Xóa cache đã hết hạn khỏi bộ nhớ
          _memoryCache.remove(cacheKey);
        }
      }

      // Kiểm tra cache trong SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null) {
        final cachedChapter = CachedChapter.fromJson(json.decode(cachedJson));

        if (_isCacheValid(cachedChapter.cachedAt)) {
          // Cập nhật lại cache bộ nhớ
          _memoryCache[cacheKey] = cachedChapter;
          print('Tìm thấy cache trên ổ cứng cho chương $chapterNumber');
          return cachedChapter.data;
        } else {
          // Xóa cache đã hết hạn
          await prefs.remove(cacheKey);
          print('Đã xóa cache hết hạn cho chương $chapterNumber');
        }
      }

      return null;
    } catch (e) {
      print('Lỗi khi lấy cache chương: $e');
      return null;
    }
  }

  /// Kiểm tra cache có còn hiệu lực hay không
  /// So sánh thời gian cache với thời gian hiện tại
  bool _isCacheValid(DateTime cachedAt) {
    final now = DateTime.now();
    final difference = now.difference(cachedAt).inMinutes;
    return difference < _maxCacheAgeMinutes;
  }

  /// Tạo khóa cache duy nhất cho mỗi chương
  String _getCacheKey(String storySlug, int chapterNumber) {
    return '${_cacheKeyPrefix}${storySlug}_$chapterNumber';
  }

  /// Dọn dẹp các cache cũ để tránh tràn bộ nhớ
  /// Giữ lại những cache gần đây nhất theo giới hạn _maxCachedChapters
  Future<void> _cleanupOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_cacheKeyPrefix))
          .toList();

      // Sắp xếp theo thời gian sửa đổi gần nhất và chỉ giữ lại những cái gần đây
      final List<CacheEntry> cacheEntries = [];

      for (final key in keys) {
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          try {
            final cachedChapter =
                CachedChapter.fromJson(json.decode(cachedJson));
            cacheEntries
                .add(CacheEntry(key: key, cachedAt: cachedChapter.cachedAt));
          } catch (e) {
            // Xóa cache không hợp lệ
            await prefs.remove(key);
          }
        }
      }

      // Sắp xếp theo thời gian cache (mới nhất trước)
      cacheEntries.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));

      // Xóa các cache cũ nếu vượt quá giới hạn
      if (cacheEntries.length > _maxCachedChapters) {
        for (int i = _maxCachedChapters; i < cacheEntries.length; i++) {
          await prefs.remove(cacheEntries[i].key);
          _memoryCache.remove(cacheEntries[i].key);
          print('Đã xóa cache cũ: ${cacheEntries[i].key}');
        }
      }
    } catch (e) {
      print('Lỗi khi dọn dẹp cache: $e');
    }
  }

  /// Xóa tất cả cache cho một truyện cụ thể
  Future<void> clearStoryCache(String storySlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('${_cacheKeyPrefix}${storySlug}_'))
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
        _memoryCache.remove(key);
      }

      print('Đã xóa cache cho truyện: $storySlug');
    } catch (e) {
      print('Lỗi khi xóa cache truyện: $e');
    }
  }

  /// Xóa toàn bộ cache chương
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_cacheKeyPrefix))
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      _memoryCache.clear();
      print('Đã xóa toàn bộ cache chương');
    } catch (e) {
      print('Lỗi khi xóa toàn bộ cache: $e');
    }
  }

  /// Tải trước các chương lân cận để cải thiện trải nghiệm người dùng
  /// Tải trước chương trước và chương sau để người dùng đọc mượt mà hơn
  Future<void> preloadAdjacentChapters(
      String storySlug,
      int currentChapter,
      Future<Map<String, dynamic>> Function(String, int)
          loadChapterFunction) async {
    // Tải trước chương tiếp theo
    final nextChapter = currentChapter + 1;
    final cachedNext = await getCachedChapter(storySlug, nextChapter);
    if (cachedNext == null) {
      try {
        final nextData = await loadChapterFunction(storySlug, nextChapter);
        await cacheChapter(storySlug, nextChapter, nextData);
        print('Đã tải trước chương tiếp theo: $nextChapter');
      } catch (e) {
        print('Không thể tải trước chương tiếp theo: $e');
      }
    }

    // Tải trước chương trước đó
    if (currentChapter > 1) {
      final prevChapter = currentChapter - 1;
      final cachedPrev = await getCachedChapter(storySlug, prevChapter);
      if (cachedPrev == null) {
        try {
          final prevData = await loadChapterFunction(storySlug, prevChapter);
          await cacheChapter(storySlug, prevChapter, prevData);
          print('Đã tải trước chương trước đó: $prevChapter');
        } catch (e) {
          print('Không thể tải trước chương trước đó: $e');
        }
      }
    }
  }
}

// Các lớp hỗ trợ

/// Lớp đại diện cho một chương đã được cache
/// Chứa thông tin về truyện, số chương, dữ liệu và thời gian cache
class CachedChapter {
  final String storySlug; // Định danh truyện
  final int chapterNumber; // Số thứ tự chương
  final Map<String, dynamic> data; // Dữ liệu nội dung chương
  final DateTime cachedAt; // Thời gian cache

  CachedChapter({
    required this.storySlug,
    required this.chapterNumber,
    required this.data,
    required this.cachedAt,
  });

  /// Chuyển đổi object thành JSON để lưu trữ
  Map<String, dynamic> toJson() => {
        'storySlug': storySlug,
        'chapterNumber': chapterNumber,
        'data': data,
        'cachedAt': cachedAt.millisecondsSinceEpoch,
      };

  /// Tạo object từ JSON đã lưu trữ
  factory CachedChapter.fromJson(Map<String, dynamic> json) => CachedChapter(
        storySlug: json['storySlug'],
        chapterNumber: json['chapterNumber'],
        data: json['data'],
        cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt']),
      );
}

/// Lớp chứa thông tin cache entry để sắp xếp và quản lý
class CacheEntry {
  final String key; // Khóa cache
  final DateTime cachedAt; // Thời gian cache

  CacheEntry({required this.key, required this.cachedAt});
}
