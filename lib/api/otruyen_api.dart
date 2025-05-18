import 'dart:convert';
import 'package:http/http.dart' as http;

class OTruyenApi {
  // Url gốc
  static const String baseUrl = 'https://otruyenapi.com/v1/api';

  // In ra console phản hồi từ API để debug dễ hơn
  static void _logResponse(String endpoint, http.Response response) {
    // In ra đường dẫn mà mình call
    print('==== API Call: $endpoint ====');

    //In ra mã code: 200, 201, ...
    print('Status Code: ${response.statusCode}');

    // In ra nội dung phản hồi
    print('Response Body: ${response.body}');
  }

  // Xử lý phản hồi API chung
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Nếu mã phản hồi 200 và status là success thì trả về dữ liệu nhận đc, ngược lại thì ném ra ngoại lệ lỗi
      if (jsonResponse['status'] == 'success') {
        //print("Trả về ${jsonResponse['data']}");
        return jsonResponse['data']; // Trả về phần data của phản hồi
      } else {
        throw Exception('API phản hồi lỗi: ${jsonResponse['message']}');
      }
    } else {
      throw Exception('Lỗi kết nối API: ${response.statusCode}');
    }
  }

  // Lấy thông tin trang chủ
  // https://otruyenapi.com/v1/api/home
  static Future<Map<String, dynamic>> getHomeData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/home'),
    );

    _logResponse('/home', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện theo trạng thái
  // https://otruyenapi.com/v1/api/danh-sach/$type?page=1
  //type (bắt buộc): "truyen-moi", "sap-ra-mat", "dang-phat-hanh", "hoan-thanh"
  //page (bắt buộc): Số trang, mặc định 1
  static Future<Map<String, dynamic>> getComicsByStatus(String type,
      {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/$type?page=$page'),
    );

    _logResponse('/danh-sach/$type', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện mới cập nhật
  static Future<Map<String, dynamic>> getNewlyUpdatedComics(
      {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/truyen-moi?page=$page'),
    );

    _logResponse('/danh-sach/truyen-moi', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện đang phát hành
  static Future<Map<String, dynamic>> getOngoingComics({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/dang-phat-hanh?page=$page'),
    );

    _logResponse('/danh-sach/dang-phat-hanh', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện hoàn thành
  static Future<Map<String, dynamic>> getCompletedComics({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/hoan-thanh?page=$page'),
    );

    _logResponse('/danh-sach/hoan-thanh', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện sắp ra mắt
  static Future<Map<String, dynamic>> getUpcomingComics({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/sap-ra-mat?page=$page'),
    );

    _logResponse('/danh-sach/sap-ra-mat', response);

    return _processResponse(response);
  }

  // Lấy danh sách thể loại
  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai'),
    );

    _logResponse('/the-loai', response);

    return _processResponse(response);
  }

  // Lấy danh sách truyện theo thể loại
  //https://otruyenapi.com/v1/api/the-loai
  static Future<Map<String, dynamic>> getComicsByCategory(String slug,
      {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai/$slug?page=$page'),
    );

    _logResponse('/the-loai/$slug', response);

    return _processResponse(response);
  }

  // Lấy thông tin chi tiết truyện
  // https://otruyenapi.com/v1/api/truyen-tranh/$slug
  // slug (bắt buộc): Định danh truyện
  static Future<Map<String, dynamic>> getComicDetail(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/truyen-tranh/$slug'),
    );

    _logResponse('/truyen-tranh/$slug', response);

    return _processResponse(response);
  }

  // Tìm kiếm truyện
  // https://otruyenapi.com/v1/api/tim-kiem?keyword=one%20piece
  // keyword (bắt buộc): Từ khóa tìm kiếm
  static Future<Map<String, dynamic>> searchComics(String keyword) async {
    // chuyển đổi ký tự đặc biệt thành dạng mã hóa URL.
    // Ví dụ: "hành động" -> "h%C3%A0nh%20%C4%91%E1%BB%99ng"
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

        // API tìm kiếm có cấu trúc đặc biệt, với items nằm trong data
        //Nếu data chứa key 'items', thì trả về {'items': ...} để UI dễ xử lý.
        // if (data.containsKey('items')) {
        //   return {'items': data['items']};
        // }
        return data;
      } else {
        throw Exception('API phản hồi lỗi: ${jsonResponse['message']}');
      }
    } else {
      // Nếu status code không bằng 200
      throw Exception('Lỗi kết nối API: ${response.statusCode}');
    }
  }

  // Lấy nội dung của một chương
  // https://otruyenapi.com/v1/api/the-loai/slug?page=1
  // slug (bắt buộc): Định danh thể loại
  // page (bắt buộc): Số trang, mặc định 1
  static Future<Map<String, dynamic>> getChapterContent(
      String chapterUrl) async {
    try {
      // Gọi API với URL gốc
      final response = await http.get(Uri.parse(chapterUrl));

      _logResponse('Chapter: $chapterUrl', response);

      // Nếu code phản hồi là 200, xử lý kết quả
      if (response.statusCode == 200) {
        return _processChapterResponse(response.body);
      }
      // Nếu lỗi 403 ( bị chặn Forbidden), thử URL thay thế
      // else if (response.statusCode == 403) {
      //   // Trích xuất ID chương từ URL gốc
      //   final originalUrl = Uri.parse(chapterUrl);
      //   final pathSegments = originalUrl.pathSegments;
      //   String chapterId = '';

      //   if (pathSegments.isNotEmpty) {
      //     chapterId = pathSegments.last;

      //     // Tạo URL thay thế
      //     final alternativeUrl = '$baseUrl/chapter/$chapterId';

      //     // Gọi API thay thế
      //     final altResponse = await http.get(Uri.parse(alternativeUrl));

      //     _logResponse('Alternative Chapter: $alternativeUrl', altResponse);

      //     if (altResponse.statusCode == 200) {
      //       return _processChapterResponse(altResponse.body);
      //     }
      //   }
      // }

      throw Exception('Không thể tải nội dung chương');
    } catch (e) {
      throw Exception('Lỗi khi tải nội dung chương: $e');
    }
  }

  // Xử lý phản hồi từ API chương
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

        // Xử lý chapter_image để tạo URLs đầy đủ
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

        // Tìm nội dung văn bản
        if (item.containsKey('content') && item['content'] != null) {
          result['content'] = item['content'].toString();
        }
      }

      return result;
    }

    throw Exception('Cấu trúc API chương không hợp lệ');
  }
}
