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
              categories.add(Category(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                description: item['description'] ?? '',
                stories: item['stories'] ?? 0,
                slug: item['slug'] ?? '',
              ));
            } catch (e) {
              print('Lỗi khi phân tích thể loại từ cache: $e');
            }
          }
        }

        print('Đã khôi phục thành công ${categories.length} thể loại từ cache');
        return categories;
      }
    } catch (e) {
      print('Lỗi khi phân tích cache thể loại: $e');
    }
    return null;
  }
}
