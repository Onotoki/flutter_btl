import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/utils/back_to_intro_page.dart';
import 'package:btl/utils/phan_duoi_back_to_intro_page.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/pages/categories_page.dart';
import 'package:btl/pages/search_page.dart';
import 'package:btl/utils/content_filter.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final Map<String, List<Story>> _categories = {
    'Truyện mới cập nhật': [],
    'Đang phát hành': [],
    'Hoàn thành': [],
    'Sắp ra mắt': []
  };

  // Biến kiểm tra xem dữ liệu đã loaad xong chưa
  bool _isLoading = true;
  String _errorMessage = '';
  // Biến để in log ra cho việc debug
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      String debugLogs = '';

      // Sử dụng các hàm API cụ thể cho từng danh mục
      debugLogs += 'Đang lấy tất cả dữ liệu danh mục...\n';

      // 1. Tải truyện mới cập nhật
      debugLogs += 'Đang tải truyện từ mục mới cập nhật...\n';
      final newUpdateResult = await OTruyenApi.getNewlyUpdatedComics();
      List<Story> newlyUpdatedComics =
          _parseStoriesData(newUpdateResult, debugLogs);
      // Lọc bỏ truyện người lớn
      int beforeFilter = newlyUpdatedComics.length;
      newlyUpdatedComics = ContentFilter.filterStories(newlyUpdatedComics);
      debugLogs +=
          'Đã lọc ra ${beforeFilter - newlyUpdatedComics.length} truyện người lớn từ mục mới cập nhật\n';
      _categories['Truyện mới cập nhật'] = newlyUpdatedComics;
      debugLogs +=
          'Đã tải ${newlyUpdatedComics.length} truyện từ mục mới cập nhật sau khi lọc\n';

      // 2. Tải truyện đang phát hành
      debugLogs += 'Đang lấy tất cả dữ liệu đang phát hành...\n';
      final ongoingResult = await OTruyenApi.getOngoingComics();
      List<Story> ongoingComics = _parseStoriesData(ongoingResult, debugLogs);
      // Lọc bỏ truyện người lớn
      beforeFilter = ongoingComics.length;
      ongoingComics = ContentFilter.filterStories(ongoingComics);
      debugLogs +=
          'Đã lọc ra ${beforeFilter - ongoingComics.length} truyện người lớn từ mục đang phát hành\n';
      _categories['Đang phát hành'] = ongoingComics;
      debugLogs +=
          'Đã tải ${ongoingComics.length} truyện từ mục đang phát hành sau khi lọc\n';

      // 3. Tải truyện hoàn thành
      debugLogs += 'Fetching completed comics...\n';
      final completedResult = await OTruyenApi.getCompletedComics();
      List<Story> completedComics =
          _parseStoriesData(completedResult, debugLogs);
      // Lọc bỏ truyện người lớn
      beforeFilter = completedComics.length;
      completedComics = ContentFilter.filterStories(completedComics);
      debugLogs +=
          'Filtered out ${beforeFilter - completedComics.length} adult stories from completed\n';
      _categories['Hoàn thành'] = completedComics;
      debugLogs +=
          'Loaded ${completedComics.length} completed comics after filtering\n';

      // 4. Tải truyện sắp ra mắt
      debugLogs += 'Fetching upcoming comics...\n';
      final upcomingResult = await OTruyenApi.getUpcomingComics();
      List<Story> upcomingComics = _parseStoriesData(upcomingResult, debugLogs);
      // Lọc bỏ truyện người lớn
      beforeFilter = upcomingComics.length;
      upcomingComics = ContentFilter.filterStories(upcomingComics);
      debugLogs +=
          'Filtered out ${beforeFilter - upcomingComics.length} adult stories from upcoming\n';
      _categories['Sắp ra mắt'] = upcomingComics;
      debugLogs +=
          'Loaded ${upcomingComics.length} upcoming comics after filtering\n';

      // Xử lý nếu bất kỳ danh mục nào trống
      for (var category in _categories.keys) {
        if (_categories[category]!.isEmpty) {
          debugLogs += 'Không có dữ liệu  cho mục $category\n';
          _categories[category] = _createSampleDataForCategory();
        }
      }

      setState(() {
        _isLoading = false;
        _debugInfo = debugLogs;
        print(debugLogs);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu trang chủ: $e';
        _isLoading = false;
        print('Lỗi khi tải dữ liệu trang chủ: $e');
      });
    }
  }

  // Phân tích dữ liệu API và chuyển thành danh sách Story
  List<Story> _parseStoriesData(Map<String, dynamic> result, String debugLogs) {
    List<Story> stories = [];

    try {
      // Kiểm tra cấu trúc data
      if (result.containsKey('data') && result['data'] is List) {
        stories = _parseStories(result['data']);
      } else if (result.containsKey('items') && result['items'] is List) {
        stories = _parseStories(result['items']);
      } else {
        // Tìm trường có thể chứa danh sách truyện
        result.forEach((key, value) {
          if (value is List && stories.isEmpty) {
            stories = _parseStories(value);
          }
        });
      }
    } catch (e) {
      debugLogs += 'Error parsing stories data: $e\n';
    }

    return stories;
  }

  // Tạo dữ liệu mẫu cho một danh mục
  List<Story> _createSampleDataForCategory() {
    List<Story> sampleStories = [];

    for (int i = 0; i < 5; i++) {
      sampleStories.add(
        Story(
          id: 'sample$i',
          title: 'Truyện mẫu ${i + 1}',
          description: 'Đây là truyện mẫu khi không thể kết nối API',
          thumbnail: 'lib/images/book.jpg',
          categories: ['Mẫu'],
          status: 'Đang cập nhật',
          views: 100,
          chapters: 10,
          updatedAt: DateTime.now().toString(),
          slug: 'truyen-mau-${i + 1}',
        ),
      );
    }

    return sampleStories;
  }

  // Helper method để chuyển đổi dữ liệu JSON thành danh sách Story
  List<Story> _parseStories(dynamic data) {
    List<Story> stories = [];

    try {
      if (data is List) {
        print('Parsing ${data.length} stories from data');

        // In ra 1-2 mục dữ liệu đầu tiên để hiểu cấu trúc
        if (data.isNotEmpty && data[0] is Map) {
          print('Sample item 0: ${data[0].keys.toList()}');
          if (data.length > 1) {
            print('Sample item 1: ${data[1].keys.toList()}');
          }
        }

        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              stories.add(Story.fromJson(item));
            }
          } catch (e) {
            print('Error parsing story item: $e');
          }
        }

        print('Successfully parsed ${stories.length} stories');
      }
    } catch (e) {
      print('Error parsing stories data: $e');
    }

    return stories;
  }

  // Hàm tạo tiêu đề với điều hướng
  Widget _buildSectionTitle(
      BuildContext context, String title, List<Story> stories) {
    return GestureDetector(
      onTap: () {
        // Nếu bấm vào thể loại truyện
        if (title == "Thể loại") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoriesPage(),
            ),
          );
        }
        // Còn lại là các danh mục khác - có thể mở trang danh sách đầy đủ
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Hàm tạo danh sách ngang cho truyện
  Widget _buildHorizontalStoryList(List<Story> stories) {
    return SizedBox(
      height: 220,
      child: stories.isEmpty
          ? const Center(child: Text('Không có dữ liệu'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                return StoryTile(
                  story: stories[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailPage(
                          story: stories[index],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 50, right: 20, left: 20),
                      child: BackToIntroPage(),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 20),
                      child: PhanDuoiBackToIntroPage(),
                    ),

                    // // Debug Info - chỉ hiển thị trong chế độ development
                    // if (_debugInfo.isNotEmpty)
                    //   GestureDetector(
                    //     onTap: () {
                    //       showDialog(
                    //         context: context,
                    //         builder: (context) => AlertDialog(
                    //           title: const Text('Debug Info'),
                    //           content: SingleChildScrollView(
                    //             child: Text(_debugInfo),
                    //           ),
                    //           actions: [
                    //             TextButton(
                    //               onPressed: () => Navigator.pop(context),
                    //               child: const Text('Đóng'),
                    //             ),
                    //           ],
                    //         ),
                    //       );
                    //     },
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(8.0),
                    //       child: Container(
                    //         padding: const EdgeInsets.all(8),
                    //         color: Colors.amber.withOpacity(0.3),
                    //         child: const Text('Tap for Debug Info'),
                    //       ),
                    //     ),
                    //   ),

                    // // Thêm nút tìm kiếm và thể loại
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20),
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //         child: GestureDetector(
                    //           onTap: () {
                    //             Navigator.push(
                    //               context,
                    //               MaterialPageRoute(
                    //                 builder: (context) => const SearchPage(),
                    //               ),
                    //             );
                    //           },
                    //           child: Container(
                    //             padding: const EdgeInsets.all(12),
                    //             decoration: BoxDecoration(
                    //               color: Colors.grey[200],
                    //               borderRadius: BorderRadius.circular(10),
                    //             ),
                    //             child: const Row(
                    //               children: [
                    //                 Icon(Icons.search),
                    //                 SizedBox(width: 8),
                    //                 Text('Tìm kiếm truyện'),
                    //               ],
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // // Danh mục thể loại
                    // _buildSectionTitle(context, "Thể loại", []),

                    // Các danh mục truyện
                    for (var category in _categories.entries) ...[
                      _buildSectionTitle(context, category.key, category.value),
                      _buildHorizontalStoryList(category.value),
                    ],
                  ],
                ),
              );
  }
}

// Utility class
class Math {
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
