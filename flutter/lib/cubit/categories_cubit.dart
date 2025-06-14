import 'package:btl/cubit/cacheable_cubit.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/category.dart';
import 'package:btl/utils/content_filter.dart';

/// Cubit quản lý danh sách thể loại truyện
/// Kế thừa từ CacheableCubit để có khả năng cache dữ liệu
class CategoriesCubit extends CacheableCubit<List<Category>> {
  /// Khóa cache để lưu trữ danh sách thể loại
  @override
  String get cacheKey => 'categories_list';

  /// Loại dữ liệu được cache
  @override
  String get dataType => 'categories';

  /// Phương thức tải dữ liệu thể loại từ API
  @override
  Future<List<Category>> fetchFromApi() async {
    print('Đang tải danh sách thể loại từ API...');
    final result = await OTruyenApi.getCategories();

    List<Category> categories = [];

    // Kiểm tra cấu trúc dữ liệu trả về từ API
    if (result.containsKey('data') &&
        result['data'] is Map &&
        result['data']['items'] is List) {
      final items = result['data']['items'] as List;
      print('Tìm thấy ${items.length} thể loại từ API');

      // Duyệt qua từng item và tạo đối tượng Category
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          try {
            final category = Category.fromJson(item);

            // Lọc bỏ các thể loại dành cho người lớn
            if (!ContentFilter.isAdultCategory(category.name)) {
              categories.add(category);
            } else {
              print('Đã lọc bỏ thể loại người lớn: ${category.name}');
            }
          } catch (e) {
            print('Lỗi khi phân tích thể loại: $e');
          }
        }
      }
    } else if (result.containsKey('items') && result['items'] is List) {
      // Cấu trúc dữ liệu thay thế
      final items = result['items'] as List;
      print('Tìm thấy ${items.length} thể loại từ API (cấu trúc thay thế)');

      for (var item in items) {
        if (item is Map<String, dynamic>) {
          try {
            final category = Category.fromJson(item);

            // Lọc bỏ các thể loại dành cho người lớn
            if (!ContentFilter.isAdultCategory(category.name)) {
              categories.add(category);
            } else {
              print('Đã lọc bỏ thể loại người lớn: ${category.name}');
            }
          } catch (e) {
            print('Lỗi khi phân tích thể loại: $e');
          }
        }
      }
    }

    print('Đã phân tích thành công ${categories.length} thể loại sau khi lọc');
    return categories;
  }

  /// Phân loại categories dựa trên tên thể loại
  /// Trả về Map với 2 key: 'comic' và 'novel'
  Map<String, List<Category>> categorizeByType(List<Category> categories) {
    final Map<String, List<Category>> result = {
      'comic': [],
      'novel': [],
    };

    // Danh sách các thể loại thường thuộc về truyện chữ/novel
    final novelKeywords = [
      'tiểu thuyết',
      'văn học',
      'light novel',
      'ebook',
      'truyện chữ',
      'ngôn tình',
      'cung đấu',
      'xuyên không',
      'trọng sinh',
      'đam mỹ',
      'tu tiên',
      'huyền huyễn',
      'kiếm hiệp',
      'võ hiệp',
      'cổ đại',
      'hiện đại',
      'tương lai',
      'khoa học',
      'viễn tưởng',
      'fantasy',
      'romance',
      'drama',
      'mystery',
      'thriller'
    ];

    // Danh sách các thể loại thường thuộc về truyện tranh/comic
    final comicKeywords = [
      'action',
      'adventure',
      'comedy',
      'shounen',
      'shoujo',
      'seinen',
      'josei',
      'mecha',
      'martial arts',
      'supernatural',
      'horror',
      'psychological',
      'slice of life',
      'school life',
      'sports',
      'historical',
      'military',
      'music',
      'one shot',
      'webtoon',
      'manga',
      'manhwa',
      'manhua',
      'doujinshi'
    ];

    for (final category in categories) {
      final lowerName = category.name.toLowerCase();

      bool isNovel = novelKeywords
          .any((keyword) => lowerName.contains(keyword.toLowerCase()));

      bool isComic = comicKeywords
          .any((keyword) => lowerName.contains(keyword.toLowerCase()));

      if (isNovel && !isComic) {
        result['novel']!.add(category);
      } else if (isComic && !isNovel) {
        result['comic']!.add(category);
      } else {
        // Nếu không xác định được hoặc có thể áp dụng cho cả hai,
        // thêm vào cả hai danh sách
        result['comic']!.add(category);
        result['novel']!.add(category);
      }
    }

    print(
        'Đã phân loại: ${result['comic']!.length} thể loại truyện tranh, ${result['novel']!.length} thể loại truyện chữ');
    return result;
  }

  /// Phương thức khôi phục dữ liệu thể loại từ cache
  @override
  List<Category>? parseFromCache(dynamic cachedData) {
    try {
      if (cachedData is List) {
        final categories = <Category>[];

        // Duyệt qua dữ liệu cache và tạo lại đối tượng Category
        for (var item in cachedData) {
          if (item is Map<String, dynamic>) {
            try {
              final category = Category(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                description: item['description'] ?? '',
                stories: item['stories'] ?? 0,
                slug: item['slug'] ?? '',
              );

              // Áp dụng filter cho dữ liệu cache giống như dữ liệu từ API
              if (!ContentFilter.isAdultCategory(category.name)) {
                categories.add(category);
              } else {
                print(
                    'Đã lọc bỏ thể loại người lớn từ cache: ${category.name}');
              }
            } catch (e) {
              print('Lỗi khi phân tích thể loại từ cache: $e');
            }
          }
        }

        print(
            'Đã khôi phục thành công ${categories.length} thể loại từ cache sau khi lọc');
        return categories;
      }
    } catch (e) {
      print('Lỗi khi phân tích cache thể loại: $e');
    }
    return null;
  }
}
