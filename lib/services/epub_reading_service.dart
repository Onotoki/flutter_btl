import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/epub_highlight.dart';
import '../models/epub_bookmark.dart';

/// Dịch vụ quản lý việc đọc EPUB, bao gồm highlights và bookmarks
/// Sử dụng SharedPreferences để lưu trữ dữ liệu cục bộ
class EpubReadingService {
  // Các khóa lưu trữ trong SharedPreferences
  static const String _highlightsKey =
      'epub_highlights'; // Khóa lưu trữ highlights
  static const String _bookmarksKey =
      'epub_bookmarks'; // Khóa lưu trữ bookmarks

  // Singleton pattern để đảm bảo chỉ có một instance duy nhất
  static final EpubReadingService _instance = EpubReadingService._internal();
  factory EpubReadingService() => _instance;
  EpubReadingService._internal();

  // Generator để tạo ID duy nhất
  final Uuid _uuid = const Uuid();

  // Các phương thức quản lý Highlight
  /// Lấy danh sách highlights của một cuốn sách cụ thể
  /// [bookId] - ID của cuốn sách cần lấy highlights
  /// Trả về danh sách các EpubHighlight
  Future<List<EpubHighlight>> getHighlights(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    // Lọc và chuyển đổi JSON thành EpubHighlight objects
    return highlightsList
        .map((json) => EpubHighlight.fromJson(json))
        .where((highlight) => highlight.bookId == bookId)
        .toList();
  }

  /// Thêm một highlight mới vào storage
  /// [highlight] - Đối tượng EpubHighlight cần thêm
  Future<void> addHighlight(EpubHighlight highlight) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    // Thêm highlight mới vào danh sách và lưu
    highlightsList.add(highlight.toJson());
    await prefs.setString(_highlightsKey, json.encode(highlightsList));
  }

  /// Xóa một highlight theo ID
  /// [id] - ID của highlight cần xóa
  Future<void> removeHighlight(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    // Loại bỏ highlight có ID tương ứng
    highlightsList.removeWhere((json) => json['id'] == id);
    await prefs.setString(_highlightsKey, json.encode(highlightsList));
  }

  /// Lấy tất cả highlights từ tất cả các sách
  /// Trả về danh sách đầy đủ các EpubHighlight
  Future<List<EpubHighlight>> getAllHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString(_highlightsKey) ?? '[]';
    final List<dynamic> highlightsList = json.decode(highlightsJson);

    return highlightsList.map((json) => EpubHighlight.fromJson(json)).toList();
  }

  // Các phương thức quản lý Bookmark
  /// Lấy danh sách bookmarks của một cuốn sách cụ thể
  /// [bookId] - ID của cuốn sách cần lấy bookmarks
  /// Trả về danh sách các EpubBookmark
  Future<List<EpubBookmark>> getBookmarks(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    // Lọc và chuyển đổi JSON thành EpubBookmark objects
    return bookmarksList
        .map((json) => EpubBookmark.fromJson(json))
        .where((bookmark) => bookmark.bookId == bookId)
        .toList();
  }

  /// Thêm một bookmark mới vào storage
  /// [bookmark] - Đối tượng EpubBookmark cần thêm
  Future<void> addBookmark(EpubBookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    // Thêm bookmark mới vào danh sách và lưu
    bookmarksList.add(bookmark.toJson());
    await prefs.setString(_bookmarksKey, json.encode(bookmarksList));
  }

  /// Xóa một bookmark theo ID
  /// [id] - ID của bookmark cần xóa
  Future<void> removeBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    // Loại bỏ bookmark có ID tương ứng
    bookmarksList.removeWhere((json) => json['id'] == id);
    await prefs.setString(_bookmarksKey, json.encode(bookmarksList));
  }

  /// Lấy tất cả bookmarks từ tất cả các sách
  /// Trả về danh sách đầy đủ các EpubBookmark
  Future<List<EpubBookmark>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
    final List<dynamic> bookmarksList = json.decode(bookmarksJson);

    return bookmarksList.map((json) => EpubBookmark.fromJson(json)).toList();
  }

  // Các phương thức tiện ích
  /// Tạo một ID duy nhất sử dụng UUID v4
  /// Trả về chuỗi ID ngẫu nhiên
  String generateId() => _uuid.v4();

  /// Tìm kiếm văn bản trên Google
  /// [text] - Văn bản cần tìm kiếm
  /// Mở trình duyệt với kết quả tìm kiếm Google
  Future<void> searchOnGoogle(String text) async {
    final query = Uri.encodeComponent(text);
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Dịch văn bản sử dụng Google Translate
  /// [text] - Văn bản cần dịch (từ tiếng Anh sang tiếng Việt)
  /// Trả về thông báo về trạng thái dịch thuật
  Future<String> translateText(String text) async {
    try {
      final query = Uri.encodeComponent(text);
      final url =
          Uri.parse('https://translate.google.com/?sl=en&tl=vi&text=$query');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return 'Đã mở Google Translate';
    } catch (e) {
      return 'Lỗi dịch: $e';
    }
  }

  // Màu sắc highlight cho EPUB
  /// Danh sách các màu sắc có thể sử dụng để highlight văn bản
  /// Mỗi màu bao gồm tên, mã màu nền và mã màu chữ
  static const List<Map<String, dynamic>> highlightColors = [
    {'name': 'Vàng', 'color': 0xFFFFEB3B, 'textColor': 0xFF000000},
    {'name': 'Xanh lá', 'color': 0xFF4CAF50, 'textColor': 0xFFFFFFFF},
    {'name': 'Xanh dương', 'color': 0xFF2196F3, 'textColor': 0xFFFFFFFF},
    {'name': 'Đỏ', 'color': 0xFFF44336, 'textColor': 0xFFFFFFFF},
    {'name': 'Tím', 'color': 0xFF9C27B0, 'textColor': 0xFFFFFFFF},
    {'name': 'Cam', 'color': 0xFFFF9800, 'textColor': 0xFF000000},
    {'name': 'Hồng', 'color': 0xFFE91E63, 'textColor': 0xFFFFFFFF},
  ];

  // Chuyển đổi sang định dạng FolioReader
  /// Chuyển đổi EpubHighlight sang định dạng FolioReader
  /// [highlight] - Đối tượng EpubHighlight cần chuyển đổi
  /// Trả về Map với cấu trúc dữ liệu tương thích FolioReader
  Map<String, dynamic> highlightToFolioFormat(EpubHighlight highlight) {
    return {
      'bookId': highlight.bookId,
      'content': highlight.content,
      'date': highlight.createdAt.millisecondsSinceEpoch,
      'type': 'highlight',
      'pageNumber': highlight.pageNumber,
      'pageId': highlight.pageId,
      'rangy': highlight.rangy,
      'uuid': highlight.id,
      'note': highlight.note,
    };
  }

  /// Chuyển đổi từ định dạng FolioReader sang EpubHighlight
  /// [data] - Map chứa dữ liệu từ FolioReader
  /// Trả về đối tượng EpubHighlight tương ứng
  EpubHighlight highlightFromFolioFormat(Map<String, dynamic> data) {
    return EpubHighlight(
      id: data['uuid'] ?? generateId(),
      bookId: data['bookId'] ?? '',
      content: data['content'] ?? '',
      pageNumber: data['pageNumber'] ?? 0,
      pageId: data['pageId'] ?? '',
      rangy: data['rangy'] ?? '',
      note: data['note'] ?? '',
      color: '0xFFFFEB3B', // Màu vàng mặc định
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data['date'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}