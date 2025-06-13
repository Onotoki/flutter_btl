import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ quản lý cache cho ứng dụng
/// Sử dụng SharedPreferences để lưu trữ dữ liệu cache với thời gian hết hạn
class CacheService {
  // Tiền tố cho các key cache để tránh xung đột
  static const String _keyPrefix = 'otruyen_cache_';

  // Thời gian cache cho các loại dữ liệu khác nhau (đơn vị: phút)
  static const Map<String, int> _cacheDurations = {
    'home': 10, // 10 phút cho dữ liệu trang chủ
    'categories': 60, // 1 giờ cho danh mục
    'story_detail': 30, // 30 phút cho chi tiết truyện
    'search': 5, // 5 phút cho kết quả tìm kiếm
    'chapters': 120, // 2 giờ cho danh sách chương
    'user_prefs': -1, // Không bao giờ hết hạn cho cài đặt người dùng
  };

  /// Lưu dữ liệu vào cache
  /// [key] - khóa để lưu trữ
  /// [data] - dữ liệu cần lưu
  /// [dataType] - loại dữ liệu (để xác định thời gian cache)
  /// [customDuration] - thời gian cache tuỳ chỉnh (phút)
  static Future<void> saveData(
    String key,
    dynamic data, {
    String? dataType,
    int? customDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Xác định thời gian cache
      int duration;
      if (customDuration != null) {
        duration = customDuration;
      } else if (dataType != null && _cacheDurations.containsKey(dataType)) {
        duration = _cacheDurations[dataType]!;
      } else {
        duration = 5; // Mặc định 5 phút
      }

      // Tạo đối tượng cache với thông tin metadata
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration': duration,
        'dataType': dataType ?? 'unknown',
      };

      await prefs.setString('$_keyPrefix$key', json.encode(cacheData));
      print(
          'Đã lưu cache cho key: $key (loại: $dataType, thời gian: ${duration}phút)');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu cache: $e');
    }
  }

  /// Lấy dữ liệu từ cache
  /// [key] - khóa để lấy dữ liệu
  /// Trả về null nếu không tìm thấy hoặc cache đã hết hạn
  static Future<T?> getData<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_keyPrefix$key');

      if (cacheString == null) return null;

      final cacheData = json.decode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      final duration = cacheData['duration'] as int;
      final dataType = cacheData['dataType'] as String? ?? 'unknown';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Kiểm tra cache đã hết hạn chưa (duration -1 nghĩa là không bao giờ hết hạn)
      if (duration != -1 && now - timestamp > (duration * 60 * 1000)) {
        await clearData(key);
        print('Cache đã hết hạn cho key: $key (loại: $dataType)');
        return null;
      }

      print('Truy xuất cache thành công cho key: $key (loại: $dataType)');
      return cacheData['data'] as T;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu cache: $e');
      return null;
    }
  }

  /// Xóa dữ liệu cache theo key
  /// [key] - khóa của cache cần xóa
  static Future<void> clearData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$key');
      print('Đã xóa cache cho key: $key');
    } catch (e) {
      print('Lỗi khi xóa dữ liệu cache: $e');
    }
  }

  /// Xóa tất cả cache theo loại dữ liệu
  /// [dataType] - loại dữ liệu cần xóa
  static Future<void> clearDataByType(String dataType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        final cacheString = prefs.getString(key);
        if (cacheString != null) {
          try {
            final cacheData = json.decode(cacheString);
            if (cacheData['dataType'] == dataType) {
              await prefs.remove(key);
              print('Đã xóa cache cho key: $key (loại: $dataType)');
            }
          } catch (e) {
            // Dữ liệu cache không hợp lệ, xóa nó đi
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      print('Lỗi khi xóa cache theo loại: $e');
    }
  }

  /// Xóa tất cả dữ liệu cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      print('Đã xóa tất cả dữ liệu cache');
    } catch (e) {
      print('Lỗi khi xóa tất cả cache: $e');
    }
  }

  /// Kiểm tra cache có còn hợp lệ không
  /// [key] - khóa cache cần kiểm tra
  /// Trả về true nếu cache còn hợp lệ, false nếu đã hết hạn
  static Future<bool> isCacheValid(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_keyPrefix$key');

      if (cacheString == null) return false;

      final cacheData = json.decode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      final duration = cacheData['duration'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Duration -1 nghĩa là không bao giờ hết hạn
      return duration == -1 || now - timestamp <= (duration * 60 * 1000);
    } catch (e) {
      print('Lỗi khi kiểm tra tính hợp lệ của cache: $e');
      return false;
    }
  }

  /// Lấy thông tin cache để debug
  /// [key] - khóa cache cần lấy thông tin
  /// Trả về Map chứa các thông tin chi tiết về cache
  static Future<Map<String, dynamic>?> getCacheInfo(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString('$_keyPrefix$key');

      if (cacheString == null) return null;

      final cacheData = json.decode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      final duration = cacheData['duration'] as int;
      final dataType = cacheData['dataType'] as String? ?? 'unknown';
      final now = DateTime.now().millisecondsSinceEpoch;

      final ageMinutes = (now - timestamp) / (1000 * 60);
      final isExpired = duration != -1 && ageMinutes > duration;

      return {
        'key': key,
        'dataType': dataType,
        'duration': duration,
        'ageMinutes': ageMinutes.round(),
        'isExpired': isExpired,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp).toString(),
      };
    } catch (e) {
      print('Lỗi khi lấy thông tin cache: $e');
      return null;
    }
  }
}
