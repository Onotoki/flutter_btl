import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';

/// Service quản lý các chức năng đọc truyện
/// Bao gồm quản lý highlight (đánh dấu văn bản), bookmark (dấu trang)
/// và các tiện ích như tìm kiếm Google, dịch văn bản
class ReadingService {
  // Khóa lưu trữ danh sách highlight trong SharedPreferences
  static const String _highlightsKey = 'reading_highlights';
  // Khóa lưu trữ danh sách bookmark trong SharedPreferences
  static const String _bookmarksKey = 'reading_bookmarks';

  // Singleton pattern - đảm bảo chỉ có một instance duy nhất
  static final ReadingService _instance = ReadingService._internal();
  factory ReadingService() => _instance;
  ReadingService._internal();

  // Generator tạo ID duy nhất cho highlight và bookmark
  final Uuid _uuid = const Uuid();

  // CÁC PHƯƠNG THỨC QUẢN LÝ HIGHLIGHT (ĐÁNH DẤU VĂN BẢN)

  /// Lấy danh sách highlight của một truyện cụ thể
  /// [storySlug] slug của truyện cần lấy highlight
  /// Trả về danh sách các highlight thuộc truyện đó
  Future<List<Highlight>> getHighlights(String storySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    return highlightsList
        .map((json) => Highlight.fromJson(json))
        .where((highlight) => highlight.storySlug == storySlug)
        .toList();
  }

  /// Thêm một highlight mới vào danh sách
  /// [highlight] đối tượng highlight cần thêm
  Future<void> addHighlight(Highlight highlight) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    highlightsList.add(highlight.toJson());
    await prefs.setString(_highlightsKey, json.encode(highlightsList));
  }

  /// Xóa một highlight theo ID
  /// [id] ID của highlight cần xóa
  Future<void> removeHighlight(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    highlightsList.removeWhere((json) => json['id'] == id);
    await prefs.setString(_highlightsKey, json.encode(highlightsList));
  }

  /// Lấy tất cả highlight của tất cả truyện
  /// Trả về danh sách đầy đủ các highlight
  Future<List<Highlight>> getAllHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    return highlightsList.map((json) => Highlight.fromJson(json)).toList();
  }

  // CÁC PHƯƠNG THỨC QUẢN LÝ BOOKMARK (DẤU TRANG)

  /// Lấy danh sách bookmark của một truyện cụ thể
  /// [storySlug] slug của truyện cần lấy bookmark
  /// Trả về danh sách các bookmark thuộc truyện đó
  Future<List<Bookmark>> getBookmarks(String storySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    return bookmarksList
        .map((json) => Bookmark.fromJson(json))
        .where((bookmark) => bookmark.storySlug == storySlug)
        .toList();
  }

  /// Thêm một bookmark mới vào danh sách
  /// [bookmark] đối tượng bookmark cần thêm
  Future<void> addBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    bookmarksList.add(bookmark.toJson());
    await prefs.setString(_bookmarksKey, json.encode(bookmarksList));
  }

  /// Xóa một bookmark theo ID
  /// [id] ID của bookmark cần xóa
  Future<void> removeBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    bookmarksList.removeWhere((json) => json['id'] == id);
    await prefs.setString(_bookmarksKey, json.encode(bookmarksList));
  }

  /// Lấy tất cả bookmark của tất cả truyện
  /// Trả về danh sách đầy đủ các bookmark
  Future<List<Bookmark>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    return bookmarksList.map((json) => Bookmark.fromJson(json)).toList();
  }

  // CÁC PHƯƠNG THỨC TIỆN ÍCH

  /// Tạo một ID duy nhất mới
  /// Trả về chuỗi ID ngẫu nhiên dạng UUID v4
  String generateId() => _uuid.v4();

  /// Mở Google Search với văn bản được chọn
  /// [text] văn bản cần tìm kiếm
  Future<void> searchOnGoogle(String text) async {
    try {
      final query = Uri.encodeComponent(text);
      final url = Uri.parse('https://www.google.com/search?q=$query');

      // Thử kiểm tra khả năng mở URL trước với xử lý lỗi
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(url);
      } catch (e) {
        print('Cảnh báo: canLaunchUrl thất bại, thử mở trực tiếp: $e');
        canLaunch = true; // Giả định có thể mở và để launchUrl xử lý
      }

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        throw 'Không thể mở Google Search';
      }
    } catch (e) {
      print('Lỗi khi mở Google Search: $e');
      rethrow;
    }
  }

  /// Mở Google Translate để dịch văn bản được chọn
  /// [text] văn bản cần dịch
  /// Trả về thông báo kết quả hoặc ném lỗi nếu thất bại
  Future<String> translateText(String text) async {
    try {
      final query = Uri.encodeComponent(text);
      final url =
          Uri.parse('https://translate.google.com/?sl=en&tl=vi&text=$query');

      // Thử kiểm tra khả năng mở URL trước với xử lý lỗi
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(url);
      } catch (e) {
        print('Cảnh báo: canLaunchUrl thất bại, thử mở trực tiếp: $e');
        canLaunch = true; // Giả định có thể mở và để launchUrl xử lý
      }

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        return 'Đã mở Google Translate';
      } else {
        throw 'Không thể mở Google Translate';
      }
    } catch (e) {
      print('Lỗi khi mở Google Translate: $e');
      throw 'Lỗi dịch: $e';
    }
  }

  // DANH SÁCH MÀU SẮC CHO HIGHLIGHT

  /// Danh sách các màu có sẵn để đánh dấu văn bản
  /// Mỗi màu bao gồm tên, màu nền và màu chữ
  static const List<Map<String, dynamic>> highlightColors = [
    {'name': 'Vàng', 'color': 0xFFFFEB3B, 'textColor': 0xFF000000},
    {'name': 'Xanh lá', 'color': 0xFF4CAF50, 'textColor': 0xFFFFFFFF},
    {'name': 'Xanh dương', 'color': 0xFF2196F3, 'textColor': 0xFFFFFFFF},
    {'name': 'Đỏ', 'color': 0xFFF44336, 'textColor': 0xFFFFFFFF},
    {'name': 'Tím', 'color': 0xFF9C27B0, 'textColor': 0xFFFFFFFF},
    {'name': 'Cam', 'color': 0xFFFF9800, 'textColor': 0xFF000000},
    {'name': 'Hồng', 'color': 0xFFE91E63, 'textColor': 0xFFFFFFFF},
  ];
}
