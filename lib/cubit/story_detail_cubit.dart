import 'package:btl/cubit/cacheable_cubit.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';

/// Lớp chứa thông tin chi tiết của truyện
class StoryDetail {
  final Story story; // Đối tượng truyện
  final List<Map<String, dynamic>> chapters; // Danh sách chương
  final Map<String, dynamic> metadata; // Thông tin bổ sung

  StoryDetail({
    required this.story,
    required this.chapters,
    required this.metadata,
  });

  /// Chuyển đổi dữ liệu thành JSON để lưu cache
  Map<String, dynamic> toJson() {
    return {
      'story': story.toJson(),
      'chapters': chapters,
      'metadata': metadata,
    };
  }

  /// Tạo đối tượng StoryDetail từ JSON cache
  factory StoryDetail.fromJson(Map<String, dynamic> json) {
    return StoryDetail(
      story: Story(
        id: json['story']['id'] ?? '',
        title: json['story']['title'] ?? '',
        description: json['story']['description'] ?? '',
        thumbnail: json['story']['thumbnail'] ?? '',
        categories:
            (json['story']['categories'] as List?)?.cast<String>() ?? [],
        status: json['story']['status'] ?? '',
        views: json['story']['views'] ?? 0,
        chapters: json['story']['chapters'] ?? 0,
        updatedAt: json['story']['updatedAt'] ?? '',
        slug: json['story']['slug'] ?? '',
        authors: (json['story']['authors'] as List?)?.cast<String>() ?? [],
        chaptersData: json['story']['chaptersData'] ?? [],
        itemType: json['story']['itemType'] ?? 'comic',
      ),
      chapters: (json['chapters'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Cubit quản lý thông tin chi tiết của truyện
/// Kế thừa từ CacheableCubit để có khả năng cache thông tin chi tiết
class StoryDetailCubit extends CacheableCubit<StoryDetail> {
  String _storySlug = ''; // Slug của truyện hiện tại

  /// Khóa cache dựa trên slug của truyện
  @override
  String get cacheKey => 'story_detail_$_storySlug';

  /// Loại dữ liệu được cache
  @override
  String get dataType => 'story_detail';

  /// Phương thức tải thông tin chi tiết truyện từ API
  @override
  Future<StoryDetail> fetchFromApi() async {
    final result = await OTruyenApi.getComicDetail(_storySlug);

    // Phân tích kết quả API thành đối tượng StoryDetail
    final story = Story.fromJson(result);
    final chapters = result['chapters'] as List<Map<String, dynamic>>? ?? [];
    final metadata = {
      'views': result['views'],
      'rating': result['rating'],
      'updated_at': result['updated_at'],
    };

    return StoryDetail(
      story: story,
      chapters: chapters,
      metadata: metadata,
    );
  }

  /// Phương thức khôi phục thông tin chi tiết truyện từ cache
  @override
  StoryDetail? parseFromCache(dynamic cachedData) {
    try {
      if (cachedData is Map<String, dynamic>) {
        return StoryDetail.fromJson(cachedData);
      }
    } catch (e) {
      print('Lỗi khi phân tích cache chi tiết truyện: $e');
    }
    return null;
  }

  /// Tải thông tin chi tiết truyện theo slug
  Future<void> loadStoryDetail(String slug) async {
    _storySlug = slug;
    await loadData();
  }

  /// Làm mới thông tin chi tiết truyện (không dùng cache)
  void refreshStoryDetail(String slug) {
    _storySlug = slug;
    refresh();
  }
}
