import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/pages/categories_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Map<String, List<Story>> _categories = {
    'Đang đọc': [],
    'Yêu thích': [],
  };

  bool _isLoading = true;
  String _errorMessage = '';
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final debugLogs = StringBuffer('Đang lấy tất cả dữ liệu danh mục...\n');

      debugLogs.write('Đang tải truyện từ mục mới cập nhật...\n');
      final newUpdateResult =
          await OTruyenApi.getComicDetail('luong-tu-ao-tuong');

      if (newUpdateResult == null || newUpdateResult is! Map<String, dynamic>) {
        debugLogs.write('API trả về dữ liệu không hợp lệ hoặc null\n');
        setState(() {
          _errorMessage = 'Dữ liệu từ API không hợp lệ';
          _isLoading = false;
          _debugInfo = debugLogs.toString();
          print(debugLogs);
        });
        return;
      }

      List<Story> favoriteCommics =
          _parseStoriesData(newUpdateResult, debugLogs);
      _categories['Yêu thích'] = favoriteCommics;

      setState(() {
        _isLoading = false;
        _debugInfo = debugLogs.toString();
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

  List<Story> _parseStoriesData(
      Map<String, dynamic>? result, StringBuffer debugLogs) {
    List<Story> stories = [];

    if (result == null) {
      debugLogs.write('Dữ liệu API là null\n');
      return stories;
    }

    try {
      if (result.containsKey('data') && result['data'] is List) {
        stories = _parseStories(result['data']);
      } else if (result.containsKey('items') && result['items'] is List) {
        stories = _parseStories(result['items']);
      } else {
        result.forEach((key, value) {
          if (value is List && stories.isEmpty) {
            stories = _parseStories(value);
          }
        });
      }
    } catch (e) {
      debugLogs.write('Lỗi khi phân tích dữ liệu truyện: $e\n');
    }

    return stories;
  }

  List<Story> _parseStories(dynamic data) {
    List<Story> stories = [];

    try {
      if (data is List) {
        print('Parsing ${data.length} stories from data');
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
            print('Error parsing story item: $e, item: $item');
          }
        }
        print('Successfully parsed ${stories.length} stories');
      }
    } catch (e) {
      print('Error parsing stories data: $e');
    }

    return stories;
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, List<Story> stories) {
    return GestureDetector(
      onTap: () {
        if (title == "Thể loại") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoriesPage()),
          );
        }
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalStoryList(List<Story> stories) {
    return SizedBox(
      height: 220,
      child: stories.isEmpty
          ? const Center(child: Text('Chưa có chuyện nào'))
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
                        builder: (context) =>
                            StoryDetailPage(story: stories[index]),
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
            : Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var category in _categories.entries) ...[
                          _buildSectionTitle(
                              context, category.key, category.value),
                          _buildHorizontalStoryList(category.value),
                        ],
                      ],
                    ),
                  ),
                ),
              );
  }
}
