import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lớp API chính để xử lý tất cả các yêu cầu API
/// Cung cấp các phương thức để lấy dữ liệu truyện tranh và truyện chữ
class OTruyenApi {
  // Url API - Đảm bảo rằng đúng IP địa chỉ máy chủ
  static const String baseUrl = 'https://flutter.bug.io.vn/v1/api';
  // static const String baseUrl = 'http://192.168.48.186:5000/v1/api';
  // Backup URL nếu cần thiết
  // static const String baseUrl = 'http://localhost:5000/v1/api';

  /// Ghi log phản hồi từ API để debug dễ hơn
  /// [endpoint] - điểm cuối API được gọi
  /// [response] - phản hồi HTTP từ server
  static void _logResponse(String endpoint, http.Response response) {
    // In ra đường dẫn mà mình call
    print('Gọi API: $endpoint');

    //In ra mã code: 200, 201, ...
    print('Mã trạng thái: ${response.statusCode}');

    // In ra nội dung phản hồi
    try {
      final jsonResponse = json.decode(response.body);
      print('Các khóa JSON phản hồi: ${jsonResponse.keys.toList()}');
      if (jsonResponse.containsKey('status')) {
        print('Trạng thái: ${jsonResponse['status']}');
      }
      if (jsonResponse.containsKey('message')) {
        print('Thông báo: ${jsonResponse['message']}');
      }
      if (jsonResponse.containsKey('data')) {
        final data = jsonResponse['data'];
        print('Loại dữ liệu: ${data.runtimeType}');
        if (data is List) {
          print('Độ dài danh sách dữ liệu: ${data.length}');
          if (data.isNotEmpty) {
            print(
                'Các khóa phần tử đầu tiên: ${data[0] is Map ? data[0].keys.toList() : "Không phải Map"}');
          }
        } else if (data is Map) {
          print('Các khóa Map dữ liệu: ${data.keys.toList()}');
        }
      }
    } catch (e) {
      print(
          'Không thể phân tích JSON: ${response.body.substring(0, min(100, response.body.length))}...');
    }
  }

  /// Hàm min tự định nghĩa vì có thể dart:math min chưa được import
  static int min(int a, int b) => a < b ? a : b;

  /// Xử lý phản hồi API chung - kiểm tra trạng thái và trả về dữ liệu
  /// [response] - phản hồi HTTP từ server
  /// Trả về dữ liệu nếu thành công, ném exception nếu có lỗi
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final jsonResponse = json.decode(response.body);
        // Nếu mã phản hồi 200 và status là success thì trả về dữ liệu nhận đc, ngược lại thì ném ra ngoại lệ lỗi
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'] ??
              {}; // Trả về phần data của phản hồi, mặc định là object rỗng
        } else {
          throw Exception(
              'API phản hồi lỗi: ${jsonResponse['message'] ?? "Lỗi không xác định"}');
        }
      } catch (e) {
        throw Exception('Lỗi phân tích phản hồi JSON: $e');
      }
    } else {
      throw Exception('Lỗi kết nối API: ${response.statusCode}');
    }
  }

  /// Thực hiện gọi API với xử lý lỗi và timeout
  /// [url] - URL đầy đủ cần gọi
  /// Trả về HTTP Response hoặc ném exception nếu có lỗi
  static Future<http.Response> _safeApiCall(String url) async {
    try {
      return await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout khi kết nối tới API');
        },
      );
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy thông tin trang chủ - hỗ trợ cả truyện tranh và truyện chữ
  /// Trả về Map chứa dữ liệu trang chủ bao gồm truyện mới, hot, v.v.
  static Future<Map<String, dynamic>> getHomeData() async {
    final response = await _safeApiCall('$baseUrl/home');
    _logResponse('/home', response);
    return _processResponse(response);
  }

  /// Lấy danh sách truyện theo trạng thái cụ thể
  /// [type] - loại trạng thái (truyen-moi, dang-phat-hanh, hoan-thanh, ...)
  /// [page] - số trang (mặc định là 1)
  /// Trả về Map chứa danh sách truyện và thông tin phân trang
  static Future<Map<String, dynamic>> getComicsByStatus(String type,
      {int page = 1}) async {
    final response = await _safeApiCall('$baseUrl/danh-sach/$type?page=$page');
    _logResponse('/danh-sach/$type', response);
    return _processResponse(response);
  }

  /// Lấy danh sách truyện mới cập nhật
  /// [page] - số trang (mặc định là 1)
  static Future<Map<String, dynamic>> getNewlyUpdatedComics(
      {int page = 1}) async {
    return getComicsByStatus('truyen-moi', page: page);
  }

  /// Lấy danh sách ebook mới cập nhật
  /// [page] - số trang (mặc định là 1)
  static Future<Map<String, dynamic>> getNewlyUpdatedEbooks(
      {int page = 1}) async {
    return getComicsByStatus('ebook-moi', page: page);
  }

  /// Lấy danh sách truyện đang phát hành
  /// [page] - số trang (mặc định là 1)
  static Future<Map<String, dynamic>> getOngoingComics({int page = 1}) async {
    return getComicsByStatus('dang-phat-hanh', page: page);
  }

  /// Lấy danh sách truyện hoàn thành
  /// [page] - số trang (mặc định là 1)
  static Future<Map<String, dynamic>> getCompletedComics({int page = 1}) async {
    return getComicsByStatus('hoan-thanh', page: page);
  }

  /// Lấy danh sách truyện sắp ra mắt
  /// [page] - số trang (mặc định là 1)
  static Future<Map<String, dynamic>> getUpcomingComics({int page = 1}) async {
    return getComicsByStatus('sap-ra-mat', page: page);
  }

  /// Lấy danh sách tất cả thể loại truyện
  /// Trả về Map chứa danh sách các thể loại với slug và tên
  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai'),
    );

    _logResponse('/the-loai', response);

    return _processResponse(response);
  }

  /// Lấy danh sách truyện theo thể loại cụ thể
  /// [slug] - slug của thể loại (ví dụ: action, romance, ...)
  /// [page] - số trang (mặc định là 1)
  /// Trả về Map chứa danh sách truyện thuộc thể loại và thông tin phân trang
  static Future<Map<String, dynamic>> getComicsByCategory(String slug,
      {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai/$slug?page=$page'),
    );

    _logResponse('/the-loai/$slug', response);

    return _processResponse(response);
  }

  /// Lấy thông tin chi tiết truyện (có thể là truyện tranh hoặc ebook)
  /// [slug] - slug của truyện (định danh duy nhất)
  /// Trả về Map chứa thông tin chi tiết bao gồm: tên, mô tả, chương, v.v.
  static Future<Map<String, dynamic>> getComicDetail(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/truyen-tranh/$slug'),
    );

    _logResponse('/truyen-tranh/$slug', response);

    return _processResponse(response);
  }

  /// Lấy nội dung chi tiết truyện chữ với xử lý lỗi toàn diện
  /// [slug] - slug của truyện chữ
  /// Trả về Map chứa thông tin truyện và nội dung (chapters hoặc content)
  static Future<Map<String, dynamic>> getNovelContent(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/truyen-chu/$slug'),
      );

      _logResponse('/truyen-chu/$slug', response);

      // Kiểm tra kỹ hơn cấu trúc phản hồi
      if (response.statusCode != 200) {
        throw Exception('Lỗi API: ${response.statusCode}');
      }

      Map<String, dynamic> result;
      try {
        // Kiểm tra phản hồi JSON hợp lệ
        result = json.decode(response.body);

        // In thêm thông tin chi tiết để debug
        print('Phản hồi API truyện chữ cho $slug:');
        print('Mã trạng thái: ${response.statusCode}');
        print('Trạng thái: ${result['status']}');

        if (result.containsKey('data')) {
          final data = result['data'];
          print('Loại dữ liệu: ${data.runtimeType}');

          if (data is Map) {
            print('Các khóa dữ liệu: ${data.keys.toList()}');

            // Kiểm tra cụ thể các trường cần thiết
            if (data.containsKey('content')) {
              print('Nội dung có sẵn: có');
              final content = data['content'];
              if (content is Map) {
                print('Cấu trúc nội dung: ${content.keys.toList()}');
                if (content.containsKey('chapters')) {
                  print(
                      'Chương có sẵn: ${content['chapters'] is List ? (content['chapters'] as List).length : "Không"}');
                }
                if (content.containsKey('isEpub')) {
                  print('Là EPUB: ${content['isEpub']}');
                }
              }
            } else {
              print('Nội dung có sẵn: không');
            }
          }
        }
      } catch (e) {
        print('Lỗi phân tích JSON truyện chữ: $e');
        throw Exception('Lỗi phân tích dữ liệu truyện chữ: $e');
      }

      return _processResponse(response);
    } catch (e) {
      print('Lỗi trong getNovelContent: $e');
      // Trả về một object với content trống để UI có thể xử lý
      return {
        'item': {
          'description': 'Không thể tải nội dung: $e',
        },
        'content': {
          'chapters': [],
          'content': '',
        }
      };
    }
  }

  /// Lấy mục lục EPUB - danh sách tất cả các chương trong ebook
  /// [slug] - slug của ebook EPUB
  /// Trả về Map chứa danh sách chapters với title và thông tin chương
  static Future<Map<String, dynamic>> getEpubTableOfContents(
      String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/truyen-chu/$slug/muc-luc'),
      );

      _logResponse('/truyen-chu/$slug/muc-luc', response);

      if (response.statusCode != 200) {
        throw Exception('Lỗi API: ${response.statusCode}');
      }

      final result = json.decode(response.body);
      print('Phản hồi mục lục EPUB cho $slug:');
      print('Trạng thái: ${result['status']}');
      print(
          'Số lượng chương: ${result.containsKey('data') && result['data'].containsKey('chapters') ? result['data']['chapters'].length : 0}');

      return _processResponse(response);
    } catch (e) {
      print('Lỗi trong getEpubTableOfContents: $e');
      throw Exception('Lỗi khi lấy mục lục EPUB: $e');
    }
  }

  /// Đọc nội dung chương EPUB cụ thể
  /// [slug] - slug của ebook EPUB
  /// [chapterNumber] - số thứ tự chương cần đọc
  /// Trả về Map chứa title và content HTML của chương
  static Future<Map<String, dynamic>> getEpubChapterContent(
      String slug, int chapterNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/truyen-chu/$slug/chuong/$chapterNumber'),
      );

      _logResponse('/truyen-chu/$slug/chuong/$chapterNumber', response);

      if (response.statusCode != 200) {
        throw Exception('Lỗi API: ${response.statusCode}');
      }

      final result = json.decode(response.body);
      print('Phản hồi chương $chapterNumber EPUB cho $slug:');
      print('Trạng thái: ${result['status']}');
      print(
          'Tiêu đề chương: ${result.containsKey('data') && result['data'].containsKey('chapter') ? result['data']['chapter']['title'] : 'Không xác định'}');
      print(
          'Độ dài nội dung: ${result.containsKey('data') && result['data'].containsKey('chapter') ? result['data']['chapter']['content'].length : 0}');

      return _processResponse(response);
    } catch (e) {
      print('Lỗi trong getEpubChapterContent: $e');
      throw Exception('Lỗi khi đọc nội dung chương: $e');
    }
  }

  /// Tìm kiếm truyện theo từ khóa
  /// [keyword] - từ khóa tìm kiếm
  /// Trả về Map chứa danh sách truyện khớp với từ khóa
  static Future<Map<String, dynamic>> searchComics(String keyword) async {
    // chuyển đổi ký tự đặc biệt thành dạng mã hóa URL.
    final encodedKeyword = Uri.encodeComponent(keyword);
    final response = await http.get(
      Uri.parse('$baseUrl/tim-kiem?keyword=$encodedKeyword'),
    );

    _logResponse('/tim-kiem', response);

    // Xử lý phản hồi API tìm kiếm
    if (response.statusCode == 200) {
      // Giải mã JSON trả về thành biến Dart (dạng Map<String, dynamic>)
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success') {
        final data = jsonResponse['data'];
        return data;
      } else {
        throw Exception('API phản hồi lỗi: ${jsonResponse['message']}');
      }
    } else {
      // Nếu status code không bằng 200
      throw Exception('Lỗi kết nối API: ${response.statusCode}');
    }
  }

  /// Lấy nội dung của một chương truyện tranh
  /// [chapterUrl] - URL đầy đủ của chương cần tải
  /// Trả về Map chứa danh sách hình ảnh hoặc nội dung text
  static Future<Map<String, dynamic>> getChapterContent(
      String chapterUrl) async {
    try {
      // Gọi API với URL gốc
      final response = await http.get(Uri.parse(chapterUrl));

      _logResponse('Chương: $chapterUrl', response);

      // Nếu code phản hồi là 200, xử lý kết quả
      if (response.statusCode == 200) {
        return _processChapterResponse(response.body);
      }

      throw Exception('Không thể tải nội dung chương');
    } catch (e) {
      throw Exception('Lỗi khi tải nội dung chương: $e');
    }
  }

  /// Xử lý phản hồi từ API chương - chuẩn hóa dữ liệu cho cả truyện tranh và truyện chữ
  /// [responseBody] - nội dung phản hồi JSON từ API
  /// Trả về Map chuẩn hóa với images, content, chapters
  static Map<String, dynamic> _processChapterResponse(String responseBody) {
    final data = json.decode(responseBody);

    //containsKey: kiểm tra 1 khoá có tồn tại trong map hay không (json)
    if (data['status'] == 'success' && data.containsKey('data')) {
      final apiData = data['data'];
      final String domainCdn = apiData['domain_cdn'] ?? '';

      // Biến lưu kết quả sau khi chuẩn hóa
      Map<String, dynamic> result = {
        'images': <String>[],
        'content': '',
      };

      if (apiData.containsKey('item')) {
        final item = apiData['item'];

        // Xử lý chapter_image để tạo URLs đầy đủ cho truyện tranh
        if (item.containsKey('chapter_image') &&
            item['chapter_image'] is List) {
          final chapterPath = item['chapter_path'] ?? '';
          final List<dynamic> imageList = item['chapter_image'];
          List<String> images = [];

          for (var img in imageList) {
            if (img is Map<String, dynamic> && img.containsKey('image_file')) {
              final imageFile = img['image_file'];
              final fullUrl = '$domainCdn/$chapterPath/$imageFile';
              images.add(fullUrl);
            }
          }

          result['images'] = images;
        }
        // Fallback - kiểm tra trường images nếu có
        else if (item.containsKey('images') && item['images'] is List) {
          List<dynamic> rawImages = item['images'];
          List<String> images = [];

          for (var img in rawImages) {
            if (img is String) {
              images.add(img);
            } else if (img is Map<String, dynamic> && img.containsKey('url')) {
              images.add(img['url'].toString());
            }
          }

          result['images'] = images;
        }

        // Tìm nội dung văn bản cho truyện chữ
        if (item.containsKey('content') && item['content'] != null) {
          result['content'] = item['content'].toString();
        }
      }

      // Kiểm tra nếu có dữ liệu nội dung truyện chữ
      if (apiData.containsKey('content')) {
        final content = apiData['content'];

        // Kiểm tra nếu có các chương (EPUB format)
        if (content.containsKey('chapters') &&
            content['chapters'] is List &&
            (content['chapters'] as List).isNotEmpty) {
          // Nếu có chapters, lưu vào result
          result['chapters'] = content['chapters'];
          result['hasChapters'] = true;
          result['totalChapters'] =
              content['totalChapters'] ?? content['chapters'].length;
        }

        // Kiểm tra nếu có nội dung văn bản trực tiếp
        if (content.containsKey('content') &&
            content['content'].toString().isNotEmpty) {
          result['content'] = content['content'].toString();
        }
      }

      return result;
    }

    throw Exception('Cấu trúc API chương không hợp lệ');
  }
}
