import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/utils/content_filter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  List<Story> _searchResults = [];
  bool _hasSearched = false;
  String _debugInfo = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _debugInfo = '';
    });

    try {
      final result = await OTruyenApi.searchComics(keyword);
      String log = 'Kết quả tìm kiếm: ${result.keys.toList()}\n';
      List<Story> unfilteredResults = [];

      // Kiểm tra cấu trúc chuẩn của API tìm kiếm (items nằm trong response)
      if (result.containsKey('items') && result['items'] is List) {
        log += 'Tìm thấy items trong response\n';
        unfilteredResults = _parseStories(result['items']);
      }
      // Hoặc có thể dữ liệu được đóng gói trong cấu trúc phức tạp hơn
      else {
        log += 'Không tìm thấy items trực tiếp, tìm kiếm thêm...\n';
        // Debug các key có trong result
        result.keys.forEach((key) {
          log += '- Key: $key, Type: ${result[key].runtimeType}\n';
        });

        // Nếu có trường item (số ít)
        if (result.containsKey('item') &&
            result['item'] is Map<String, dynamic>) {
          log += 'Tìm thấy item object\n';
          unfilteredResults = [Story.fromJson(result['item'])];
        }
        // Nếu có trường sectionComic (như trong home.json)
        else if (result.containsKey('sectionComic') &&
            result['sectionComic'] is List) {
          log += 'Tìm thấy sectionComic\n';
          List<Story> stories = [];
          for (var section in result['sectionComic']) {
            if (section is Map &&
                section.containsKey('comics') &&
                section['comics'] is List) {
              stories.addAll(_parseStories(section['comics']));
            }
          }
          unfilteredResults = stories;
        }
      }

      log += 'Số truyện tìm thấy trước khi lọc: ${unfilteredResults.length}\n';

      // Lọc bỏ truyện người lớn
      int beforeFilter = unfilteredResults.length;
      List<Story> filteredResults =
          ContentFilter.filterStories(unfilteredResults);
      log +=
          'Đã lọc bỏ ${beforeFilter - filteredResults.length} truyện người lớn\n';
      log += 'Số truyện còn lại sau khi lọc: ${filteredResults.length}\n';

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
        _debugInfo = log;
        print(log);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tìm kiếm truyện: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method để chuyển đổi dữ liệu JSON thành danh sách Story
  List<Story> _parseStories(dynamic data) {
    List<Story> stories = [];

    try {
      if (data is List) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            stories.add(Story.fromJson(item));
          }
        }
      }
    } catch (e) {
      print('Lỗi khi phân tích dữ liệu truyện: $e');
    }

    return stories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: "Tìm kiếm truyện...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
            onSubmitted: (value) {
              _performSearch(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _performSearch(_searchController.text);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : !_hasSearched
                  ? const Center(
                      child: Text('Nhập từ khóa để tìm kiếm truyện'),
                    )
                  : Column(
                      children: [
                        // Debug info - chỉ hiển thị trong chế độ debug
                        if (_debugInfo.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Debug Info'),
                                  content: SingleChildScrollView(
                                    child: Text(_debugInfo),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              color: Colors.amber.withOpacity(0.3),
                              child: const Text('Tap for Debug Info'),
                            ),
                          ),

                        // Kết quả tìm kiếm
                        Expanded(
                          child: _searchResults.isEmpty
                              ? const Center(
                                  child: Text('Không tìm thấy truyện nào'),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.55,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final story = _searchResults[index];
                                      return StoryTile(
                                        story: story,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  StoryDetailPage(
                                                story: story,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
    );
  }

  // @override
  // void dispose() {
  //   searchController.dispose();
  //   super.dispose();
  // }
}
