import 'package:btl/cubit/cacheable_cubit.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';

/// Lớp chứa kết quả tìm kiếm truyện
class SearchResult {
  final String query; // Từ khóa tìm kiếm
  final List<Story> stories; // Danh sách truyện tìm được
  final int totalPages; // Tổng số trang
  final int currentPage; // Trang hiện tại

  SearchResult({
    required this.query,
    required this.stories,
    required this.totalPages,
    required this.currentPage,
  });

  /// Chuyển đổi dữ liệu thành JSON để lưu cache
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'stories': stories.map((story) => story.toJson()).toList(),
      'totalPages': totalPages,
      'currentPage': currentPage,
    };
  }

  /// Tạo đối tượng SearchResult từ JSON cache
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      query: json['query'] ?? '',
      stories: (json['stories'] as List?)
              ?.map((item) => Story(
                    id: item['id'] ?? '',
                    title: item['title'] ?? '',
                    description: item['description'] ?? '',
                    thumbnail: item['thumbnail'] ?? '',
                    categories:
                        (item['categories'] as List?)?.cast<String>() ?? [],
                    status: item['status'] ?? '',
                    views: item['views'] ?? 0,
                    chapters: item['chapters'] ?? 0,
                    updatedAt: item['updatedAt'] ?? '',
                    slug: item['slug'] ?? '',
                    authors: (item['authors'] as List?)?.cast<String>() ?? [],
                    chaptersData: item['chaptersData'] ?? [],
                    itemType: item['itemType'] ?? 'comic',
                  ))
              .toList() ??
          [],
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
    );
  }
}

/// Cubit quản lý chức năng tìm kiếm truyện
/// Kế thừa từ CacheableCubit để có khả năng cache kết quả tìm kiếm
class SearchCubit extends CacheableCubit<SearchResult> {
  String _currentQuery = ''; // Từ khóa tìm kiếm hiện tại
  int _currentPage = 1; // Trang hiện tại

  /// Khóa cache dựa trên từ khóa tìm kiếm và trang hiện tại
  @override
  String get cacheKey => 'search_${_currentQuery}_$_currentPage';

  /// Loại dữ liệu được cache
  @override
  String get dataType => 'search';

  /// Phương thức tải kết quả tìm kiếm từ API
  @override
  Future<SearchResult> fetchFromApi() async {
    // Ở đây bạn sẽ triển khai cuộc gọi API tìm kiếm
    // Hiện tại trả về kết quả rỗng
    return SearchResult(
      query: _currentQuery,
      stories: [],
      totalPages: 1,
      currentPage: _currentPage,
    );
  }

  /// Phương thức khôi phục kết quả tìm kiếm từ cache
  @override
  SearchResult? parseFromCache(dynamic cachedData) {
    try {
      if (cachedData is Map<String, dynamic>) {
        return SearchResult.fromJson(cachedData);
      }
    } catch (e) {
      print('Lỗi khi phân tích cache tìm kiếm: $e');
    }
    return null;
  }

  /// Thực hiện tìm kiếm truyện với từ khóa và trang chỉ định
  Future<void> searchStories(String query, {int page = 1}) async {
    _currentQuery = query;
    _currentPage = page;
    await loadData();
  }

  /// Tìm kiếm với làm mới dữ liệu (không dùng cache)
  void searchWithRefresh(String query, {int page = 1}) {
    _currentQuery = query;
    _currentPage = page;
    refresh();
  }
}
