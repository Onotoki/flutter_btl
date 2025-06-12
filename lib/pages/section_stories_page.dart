import 'package:flutter/material.dart';
import 'package:btl/models/story.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/utils/content_filter.dart';

class SectionStoriesPage extends StatefulWidget {
  final String sectionTitle;
  final List<Story> stories; // Truyện ban đầu từ trang chủ
  final String? sectionType; // Loại section để load từ API

  const SectionStoriesPage({
    super.key,
    required this.sectionTitle,
    required this.stories,
    this.sectionType,
  });

  @override
  State<SectionStoriesPage> createState() => _SectionStoriesPageState();
}

class _SectionStoriesPageState extends State<SectionStoriesPage> {
  late ScrollController _scrollController;
  List<Story> allStories = []; // Tất cả truyện (bao gồm từ API)
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage =
      2; // Bắt đầu từ trang 2 vì trang 1 đã có trong widget.stories
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Khởi tạo với truyện có sẵn từ trang chủ
    allStories = List.from(widget.stories);

    // Load thêm truyện nếu có thể
    if (widget.sectionType != null) {
      _loadMoreStoriesFromApi();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData && widget.sectionType != null) {
        _loadMoreStoriesFromApi();
      }
    }
  }

  Future<void> _loadMoreStoriesFromApi() async {
    if (isLoadingMore || !hasMoreData || widget.sectionType == null) return;

    setState(() {
      isLoadingMore = true;
      errorMessage = '';
    });

    try {
      Map<String, dynamic> result;

      // Gọi API tương ứng với từng section type
      switch (widget.sectionType) {
        case 'truyen-moi':
          result = await OTruyenApi.getNewlyUpdatedComics(page: currentPage);
          break;
        case 'dang-phat-hanh':
          result = await OTruyenApi.getOngoingComics(page: currentPage);
          break;
        case 'hoan-thanh':
          result = await OTruyenApi.getCompletedComics(page: currentPage);
          break;
        case 'sap-ra-mat':
          result = await OTruyenApi.getUpcomingComics(page: currentPage);
          break;
        case 'ebook-moi':
          result = await OTruyenApi.getNewlyUpdatedEbooks(page: currentPage);
          break;
        default:
          setState(() {
            isLoadingMore = false;
            hasMoreData = false;
          });
          return;
      }

      List<Story> newStories = [];
      if (result.containsKey('items') && result['items'] is List) {
        newStories = _parseStories(result['items']);

        // Lọc bỏ truyện người lớn
        newStories = ContentFilter.filterStories(newStories);

        // Lọc theo loại truyện (comic/novel) tùy theo section
        if (widget.sectionType != 'ebook-moi') {
          newStories = newStories.where((story) => story.isComic).toList();
        }
      }

      setState(() {
        // Tránh trùng lặp với truyện đã có
        for (var story in newStories) {
          if (!allStories.any((existing) => existing.id == story.id)) {
            allStories.add(story);
          }
        }

        isLoadingMore = false;
        currentPage++;

        // Kiểm tra xem có còn dữ liệu không
        if (newStories.length < 15) {
          hasMoreData = false;
        }
      });

      print(
          'Loaded ${newStories.length} new stories for ${widget.sectionTitle}');
    } catch (e) {
      setState(() {
        isLoadingMore = false;
        errorMessage = 'Không thể tải thêm truyện: $e';
      });
      print('Error loading more stories: $e');
    }
  }

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
            const Text('Đã hiển thị tất cả truyện'),
          ],
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMoreStoriesFromApi,
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                '${allStories.length} truyện',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: allStories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có truyện nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Reset và tải lại từ đầu
                setState(() {
                  allStories = List.from(widget.stories);
                  currentPage = 2;
                  hasMoreData = true;
                  errorMessage = '';
                });
                if (widget.sectionType != null) {
                  await _loadMoreStoriesFromApi();
                }
              },
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
                          final story = allStories[index];
                          return StoryTile(
                            story: story,
                            onTap: () {
                              try {
                                if (story.id.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoryDetailPage(
                                        story: story,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error navigating to story detail: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Không thể mở chi tiết truyện: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                        childCount: allStories.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildLoadingIndicator(),
                  ),
                ],
              ),
            ),
    );
  }
}
