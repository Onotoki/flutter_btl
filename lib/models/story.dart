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
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    // In ra cấu trúc JSON để debug
    print('Parsing Story from JSON: ${json.keys.toList()}');

    // Xử lý trường hợp dữ liệu nằm trong 'items'
    if (json.containsKey('items') &&
        json['items'] is List &&
        json['items'].isNotEmpty) {
      return Story.fromJson(json['items'][0]);
    }

    // Xử lý trường hợp dữ liệu nằm trong 'item'
    if (json.containsKey('item') && json['item'] is Map) {
      return Story.fromJson(json['item']);
    }

    // Xử lý categories có thể là List<dynamic> hoặc List<Map>
    List<String> parseCategories(dynamic categoriesData) {
      if (categoriesData is List) {
        return categoriesData
            .map((item) {
              if (item is Map) {
                return item['name']?.toString() ?? '';
              } else {
                return item.toString();
              }
            })
            .where((name) => name.isNotEmpty)
            .toList();
      } else if (categoriesData is String) {
        return [categoriesData];
      }
      return [];
    }

    // Xử lý authors - có thể là List<dynamic> hoặc String
    List<String> parseAuthors(dynamic authorsData) {
      if (authorsData is List) {
        return authorsData
            .map((item) => item.toString())
            .where((name) => name != "Đang cập nhật")
            .toList();
      } else if (authorsData is String) {
        return [authorsData];
      }
      return [];
    }

    // Trích xuất thumbnail với nhiều tên trường có thể có
    String extractThumbnail(Map<String, dynamic> json) {
      final cdn = 'https://img.otruyenapi.com';

      // Kiểm tra trường thumb_url (cấu trúc chuẩn của API)
      if (json.containsKey('thumb_url') && json['thumb_url'] is String) {
        final thumb = json['thumb_url'];
        print('Đã tìm thấy hình thu nhỏ trong thumb_url: $thumb');
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
            seo['og_image'].isNotEmpty) {
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

      print('No thumbnail found in JSON');
      return '';
    }

    // Xử lý trường chapters để đếm số chương
    int countChapters(dynamic chaptersData) {
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
      return 1;
    }

    return Story(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? json['desc'] ?? json['content'] ?? '',
      thumbnail: extractThumbnail(json),
      categories: parseCategories(json['category'] ?? json['categories'] ?? []),
      status: json['status'] ?? json['state'] ?? '',
      views: json['views'] != null
          ? int.tryParse(json['views'].toString()) ?? 0
          : 0,
      chapters:
          json.containsKey('chapters') ? countChapters(json['chapters']) : 0,
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? '',
      slug: json['slug'] ?? '',
      authors: parseAuthors(json['author'] ?? []),
      chaptersData: json['chapters'] ?? [],
    );
  }
}
