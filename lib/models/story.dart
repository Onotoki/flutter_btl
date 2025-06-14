class Story {
  // Thuộc tính của kiểu Story
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final List<String> categories;
  final String status;
  final int views;
  final int chapters;
  final String updatedAt;
  final String slug;
  final List<String> authors;
  final List<dynamic> chaptersData;
  final String itemType; // 'comic', 'ebook', hoặc 'text_story'

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

  // Kiểm tra xem truyện này có phải truyện chữ không
  bool get isNovel => itemType == 'ebook' || itemType == 'text_story';

  // Kiểm tra xem truyện này có phải truyện tranh không
  bool get isComic => itemType == 'comic';

  factory Story.fromJson(Map<String, dynamic> json) {
    try {
      // In ra cấu trúc JSON để debug
      print('Parsing Story from JSON: ${json.keys.toList()}');

      // Xử lý trường hợp dữ liệu nằm trong 'items'
      if (json.containsKey('items') &&
          json['items'] is List &&
          (json['items'] as List).isNotEmpty) {
        try {
          return Story.fromJson(json['items'][0]);
        } catch (e) {
          print('Error parsing nested item from items: $e');
        }
      }

      // Xử lý trường hợp dữ liệu nằm trong 'item'
      if (json.containsKey('item') && json['item'] is Map) {
        try {
          return Story.fromJson(json['item']);
        } catch (e) {
          print('Error parsing nested item from item: $e');
        }
      }

      // Xác định loại truyện
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
          print('Error determining item type: $e');
        }

        // Mặc định là comic nếu không xác định được
        return 'comic';
      }

      // Xử lý categories có thể là List<dynamic> hoặc List<Map>
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
          print('Error parsing categories: $e');
        }
        return [];
      }

      // Xử lý authors - có thể là List<dynamic> hoặc String
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
          print('Error parsing authors: $e');
        }
        return [];
      }

      // Trích xuất thumbnail với nhiều tên trường có thể có
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

          // fallback nếu có trường thumbnail khác
          for (var field in ['thumbnail', 'cover', 'image']) {
            if (json.containsKey(field) && json[field] != null) {
              var thumbUrl = json[field].toString();
              print('Found thumbnail in field $field: $thumbUrl');

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
          print('Error extracting thumbnail: $e');
        }

        print('No thumbnail found in JSON');
        return 'https://via.placeholder.com/150x200'; // Default placeholder
      }

      // Xử lý trường chapters để đếm số chương
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
          print('Error counting chapters: $e');
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
      print('Error in Story.fromJson: $e');
      // Return a default story object in case of error
      return Story(
        id: '',
        title: 'Error Loading Story',
        description: '',
        thumbnail: 'https://via.placeholder.com/150x200',
        categories: [],
        status: 'Unknown',
        views: 0,
        chapters: 0,
        updatedAt: '',
        slug: '',
        itemType: 'comic',
      );
    }
  }

  // Convert Story object to JSON for caching
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
