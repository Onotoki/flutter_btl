import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/category.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/utils/content_filter.dart';

class CategoryStoriesPage extends StatefulWidget {
  final Category category;

  const CategoryStoriesPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryStoriesPage> createState() => _CategoryStoriesPageState();
}

class _CategoryStoriesPageState extends State<CategoryStoriesPage> {
  List<Story> stories = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  String errorMessage = '';
  String debugInfo = '';
  int currentPage = 1;

  // ScrollController để theo dõi việc scroll
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadStories();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm theo dõi việc scroll và load more khi cần
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Khi scroll gần đến cuối (còn 200 pixels), load thêm dữ liệu
      if (!isLoadingMore && hasMoreData) {
        _loadMoreStories();
      }
    }
  }

  Future<void> _loadStories() async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      stories.clear();
      hasMoreData = true;
    });

    try {
      final result = await OTruyenApi.getComicsByCategory(widget.category.slug,
          page: currentPage);

      setState(() {
        List<Story> loadedStories = [];
        if (result.containsKey('items') && result['items'] is List) {
          // Tải và phân tích truyện từ API
          loadedStories = _parseStories(result['items']);

          // Lọc bỏ truyện người lớn
          int beforeFilter = loadedStories.length;
          loadedStories = ContentFilter.filterStories(loadedStories);
          debugInfo =
              'Page $currentPage: Loaded ${loadedStories.length} stories, filtered out ${beforeFilter - loadedStories.length} adult stories';
          print(debugInfo);
        }

        stories = loadedStories;
        isLoading = false;

        // Kiểm tra xem có dữ liệu để load thêm không
        // Nếu số stories trả về ít hơn expected (thường là 20), thì hết dữ liệu
        if (loadedStories.length < 15) {
          hasMoreData = false;
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải danh sách truyện: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentPage++;
      final result = await OTruyenApi.getComicsByCategory(widget.category.slug,
          page: currentPage);

      setState(() {
        List<Story> newStories = [];
        if (result.containsKey('items') && result['items'] is List) {
          // Tải và phân tích truyện từ API
          newStories = _parseStories(result['items']);

          // Lọc bỏ truyện người lớn
          int beforeFilter = newStories.length;
          newStories = ContentFilter.filterStories(newStories);

          String loadMoreDebug =
              'Page $currentPage: Loaded ${newStories.length} new stories, filtered out ${beforeFilter - newStories.length} adult stories';
          debugInfo += '\n$loadMoreDebug';
          print(loadMoreDebug);
        }

        // Thêm stories mới vào danh sách hiện tại
        stories.addAll(newStories);
        isLoadingMore = false;

        // Kiểm tra xem có dữ liệu để load thêm không
        if (newStories.length < 15) {
          hasMoreData = false;
          print('No more data available');
        }
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
        currentPage--; // Rollback page number if failed
      });
      print('Error loading more stories: $e');

      // Hiển thị snackbar thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thêm truyện: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method để chuyển đổi dữ liệu JSON thành danh sách Story
  List<Story> _parseStories(List<dynamic> data) {
    List<Story> result = [];

    try {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          result.add(Story.fromJson(item));
        }
      }
    } catch (e) {
      print('Lỗi khi phân tích dữ liệu truyện: $e');
    }

    return result;
  }

  // Widget hiển thị loading indicator ở cuối danh sách
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          if (isLoadingMore) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Đang tải thêm truyện...'),
          ] else if (!hasMoreData) ...[
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(height: 8),
            const Text('Đã tải hết tất cả truyện'),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          // Hiển thị số lượng truyện đã tải
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                '${stories.length} truyện',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStories,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : stories.isEmpty
                  ? const Center(
                      child: Text('Không có truyện nào trong thể loại này'))
                  : RefreshIndicator(
                      onRefresh: _loadStories,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(8.0),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.5,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final story = stories[index];
                                  return StoryTile(
                                    story: story,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryDetailPage(
                                            story: story,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: stories.length,
                              ),
                            ),
                          ),
                          // Loading indicator ở cuối
                          SliverToBoxAdapter(
                            child: _buildLoadingIndicator(),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
