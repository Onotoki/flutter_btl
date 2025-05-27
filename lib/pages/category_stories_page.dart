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
  String errorMessage = '';
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final result = await OTruyenApi.getComicsByCategory(widget.category.slug);

      setState(() {
        List<Story> loadedStories = [];
        if (result.containsKey('items') && result['items'] is List) {
          // Tải và phân tích truyện từ API
          loadedStories = _parseStories(result['items']);

          // Lọc bỏ truyện người lớn
          int beforeFilter = loadedStories.length;
          loadedStories = ContentFilter.filterStories(loadedStories);
          debugInfo =
              'Filtered out ${beforeFilter - loadedStories.length} adult stories';
          print(debugInfo);
        }

        stories = loadedStories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải danh sách truyện: $e';
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : stories.isEmpty
                  ? const Center(
                      child: Text('Không có truyện nào trong thể loại này'))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8, // giảm khoảng cách dọc
                          crossAxisSpacing: 8, // giữ nguyên khoảng cách ngang
                          childAspectRatio: 0.55, // tăng tỉ lệ => ô thấp hơn,
                        ),
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
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
                      ),
                    ),
    );
  }
}
