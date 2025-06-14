/// Lớp mô hình dữ liệu đại diện cho một câu chuyện/truyện
/// Hỗ trợ nhiều loại truyện: truyện tranh (comic), sách điện tử (ebook), truyện chữ (text_story)
class Story {
  // Thuộc tính của kiểu Story
  final String id; // Mã định danh duy nhất của truyện
  final String title; // Tiêu đề truyện
  final String description; // Mô tả nội dung truyện
  final String thumbnail; // Đường dẫn hình thu nhỏ
  final List<String> categories; // Danh sách thể loại truyện
  final String status; // Trạng thái truyện (đang cập nhật, hoàn thành, etc.)
  final int views; // Số lượt xem
  final int chapters; // Số chương
  final String updatedAt; // Thời gian cập nhật cuối cùng
  final String slug; // Đường dẫn thân thiện URL
  final List<String> authors; // Danh sách tác giả
  final List<dynamic> chaptersData; // Dữ liệu chi tiết các chương
  final String itemType; // Loại truyện: 'comic', 'ebook', hoặc 'text_story'

  /// Constructor khởi tạo đối tượng Story với các thuộc tính bắt buộc và tùy chọn
  Story({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.categories,
    required this.status,
    required this.views,
    required this.chapters,
    required this.updatedAt,
    required this.slug,
    this.authors = const [],
    this.chaptersData = const [],
    this.itemType = 'comic', // Mặc định là truyện tranh
  });

  /// Kiểm tra xem truyện này có phải truyện chữ không
  bool get isNovel => itemType == 'ebook' || itemType == 'text_story';

  /// Kiểm tra xem truyện này có phải truyện tranh không
  bool get isComic => itemType == 'comic';

  /// Factory method để tạo đối tượng Story từ dữ liệu JSON
  /// Xử lý nhiều định dạng JSON khác nhau từ các API khác nhau
  factory Story.fromJson(Map<String, dynamic> json) {
    try {
      // In ra cấu trúc JSON để gỡ lỗi
      print('Đang phân tích Story từ JSON: ${json.keys.toList()}');

      // Xử lý trường hợp dữ liệu nằm trong 'items'
      if (json.containsKey('items') &&
          json['items'] is List &&
          (json['items'] as List).isNotEmpty) {
        try {
          return Story.fromJson(json['items'][0]);
        } catch (e) {
          print('Lỗi khi phân tích mục lồng từ items: $e');
        }
      }

      // Xử lý trường hợp dữ liệu nằm trong 'item'
      if (json.containsKey('item') && json['item'] is Map) {
        try {
          return Story.fromJson(json['item']);
        } catch (e) {
          print('Lỗi khi phân tích mục lồng từ item: $e');
        }
      }

      /// Hàm helper xác định loại truyện dựa trên dữ liệu JSON
      String determineItemType(Map<String, dynamic> json) {
        try {
          // Kiểm tra trường itemType từ API
          if (json.containsKey('itemType') && json['itemType'] != null) {
            return json['itemType'].toString();
          }

          // Kiểm tra trường localEpubFilename để phát hiện ebook
          if ((json.containsKey('localEpubFilename') &&
                  json['localEpubFilename'] != null) ||
              (json.containsKey('localCoverFilename') &&
                  json['localCoverFilename'] != null)) {
            return 'ebook';
          }
        } catch (e) {
          print('Lỗi khi xác định loại mục: $e');
        }

        // Mặc định là comic nếu không xác định được
        return 'comic';
      }

      /// Hàm helper phân tích danh sách thể loại từ dữ liệu JSON đa dạng
      List<String> parseCategories(dynamic categoriesData) {
        try {
          if (categoriesData is List) {
            return categoriesData
                .where((item) => item != null)
                .map((item) {
                  if (item is Map) {
                    return item['name']?.toString() ?? '';
                  } else {
                    return item.toString();
                  }
                })
                .where((name) => name.isNotEmpty)
                .toList();
          } else if (categoriesData is String && categoriesData.isNotEmpty) {
            return [categoriesData];
          }
        } catch (e) {
          print('Lỗi khi phân tích thể loại: $e');
        }
        return [];
      }

      /// Hàm helper phân tích danh sách tác giả từ dữ liệu JSON
      List<String> parseAuthors(dynamic authorsData) {
        try {
          if (authorsData is List) {
            return authorsData
                .where((item) => item != null)
                .map((item) => item.toString())
                .where((name) => name.isNotEmpty && name != "Đang cập nhật")
                .toList();
          } else if (authorsData is String &&
              authorsData.isNotEmpty &&
              authorsData != "Đang cập nhật") {
            return [authorsData];
          }
        } catch (e) {
          print('Lỗi khi phân tích tác giả: $e');
        }
        return [];
      }

      /// Hàm helper trích xuất URL hình thu nhỏ từ nhiều trường khác nhau
      String extractThumbnail(Map<String, dynamic> json) {
        try {
          final cdn = 'https://img.otruyenapi.com';
          final serverBasePath = 'http://192.168.1.190:5000';

          // Kiểm tra trường thumb_url_full (URL đầy đủ)
          if (json.containsKey('thumb_url_full') &&
              json['thumb_url_full'] is String &&
              (json['thumb_url_full'] as String).isNotEmpty) {
            return json['thumb_url_full'];
          }

          // Kiểm tra trường thumb_url (cấu trúc chuẩn của API)
          if (json.containsKey('thumb_url') &&
              json['thumb_url'] is String &&
              (json['thumb_url'] as String).isNotEmpty) {
            final thumb = json['thumb_url'];
            print('Đã tìm thấy hình thu nhỏ trong thumb_url: $thumb');

            // Nếu là ebook, cần xử lý khác
            final itemType = determineItemType(json);
            if (itemType == 'ebook' || itemType == 'text_story') {
              // Đường dẫn đầy đủ sẽ là /ebooks/{slug}/{filename}
              if (json.containsKey('slug') && json['slug'] != null) {
                return '$serverBasePath/ebooks/${json['slug']}/$thumb';
              }
            }

            if (thumb.startsWith('http')) {
              return thumb;
            }
            return '$cdn/uploads/comics/$thumb';
          }

          // Kiểm tra trường og_image trong seoOnPage
          if (json.containsKey('seoOnPage') &&
              json['seoOnPage'] is Map<String, dynamic>) {
            var seo = json['seoOnPage'];
            if (seo.containsKey('og_image') &&
                seo['og_image'] is List &&
                (seo['og_image'] as List).isNotEmpty) {
              var ogImage = seo['og_image'][0].toString();
              print('Tìm thấy hình thu nhỏ trong seoOnPage.og_image: $ogImage');
              if (ogImage.startsWith('http')) {
                return ogImage;
              }
              if (ogImage.startsWith('comics/')) {
                return '$cdn/uploads/$ogImage';
              }
              return '$cdn/uploads/comics/$ogImage';
            }
          }

          // Phương án dự phòng nếu có trường thumbnail khác
          for (var field in ['thumbnail', 'cover', 'image']) {
            if (json.containsKey(field) && json[field] != null) {
              var thumbUrl = json[field].toString();
              print('Tìm thấy hình thu nhỏ trong trường $field: $thumbUrl');

              // Kiểm tra để tạo URL đầy đủ
              if (thumbUrl.startsWith('http')) {
                return thumbUrl;
              } else if (thumbUrl.startsWith('/')) {
                return '$cdn$thumbUrl';
              } else {
                return '$cdn/uploads/comics/$thumbUrl';
              }
            }
          }
        } catch (e) {
          print('Lỗi khi trích xuất hình thu nhỏ: $e');
        }

        print('Không tìm thấy hình thu nhỏ trong JSON');
        return 'https://via.placeholder.com/150x200'; // Hình mặc định
      }

      /// Hàm helper đếm số chương từ dữ liệu chapters
      int countChapters(dynamic chaptersData) {
        try {
          if (chaptersData is List && chaptersData.isNotEmpty) {
            int count = 0;
            for (var server in chaptersData) {
              if (server is Map &&
                  server.containsKey('server_data') &&
                  server['server_data'] is List) {
                count += (server['server_data'] as List).length;
              }
            }
            return count > 0 ? count : 1;
          }
        } catch (e) {
          print('Lỗi khi đếm chương: $e');
        }
        return 1;
      }

      final itemType = determineItemType(json);

      return Story(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        title: (json['name'] ?? json['title'] ?? 'Truyện không tên').toString(),
        description:
            (json['description'] ?? json['desc'] ?? json['content'] ?? '')
                .toString(),
        thumbnail: extractThumbnail(json),
        categories:
            parseCategories(json['category'] ?? json['categories'] ?? []),
        status: (json['status'] ?? json['state'] ?? 'Đang cập nhật').toString(),
        views: json['views'] != null
            ? int.tryParse(json['views'].toString()) ?? 0
            : 0,
        chapters:
            json.containsKey('chapters') ? countChapters(json['chapters']) : 0,
        updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        authors: parseAuthors(json['author'] ?? []),
        chaptersData: json['chapters'] ?? [],
        itemType: itemType,
      );
    } catch (e) {
      print('Lỗi trong Story.fromJson: $e');
      // Trả về đối tượng story mặc định trong trường hợp lỗi
      return Story(
        id: '',
        title: 'Lỗi Tải Truyện',
        description: '',
        thumbnail: 'https://via.placeholder.com/150x200',
        categories: [],
        status: 'Không xác định',
        views: 0,
        chapters: 0,
        updatedAt: '',
        slug: '',
        itemType: 'comic',
      );
    }
  }

  /// Chuyển đổi đối tượng Story thành JSON để lưu cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'categories': categories,
      'status': status,
      'views': views,
      'chapters': chapters,
      'updatedAt': updatedAt,
      'slug': slug,
      'authors': authors,
      'chaptersData': chaptersData,
      'itemType': itemType,
    };
  }
}
