import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/category.dart';
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

  List<Category> _allGenres = [];
  List<String> _selectedSlugs = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final data = await OTruyenApi.getCategories();
      setState(() {
        _allGenres =
            ContentFilter.filterCategories(Category.parseCategories(data));
      });
      print('Tải ${_allGenres.length} thể loại từ API');
    } catch (e) {
      print('Lỗi khi tải thể loại: $e');
    }
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _isFiltering = false;
      _debugInfo = '';
    });

    try {
      final result = await OTruyenApi.searchComics(keyword);
      List<Story> stories = [];

      if (result.containsKey('items') && result['items'] is List) {
        stories = _parseStories(result['items']);
        print('Tìm thấy ${stories.length} truyện từ API search');
      }

      stories = ContentFilter.filterStories(stories);
      print('Sau lọc người lớn còn lại ${stories.length} truyện');

      setState(() {
        _searchResults = stories;
        _isLoading = false;
        _debugInfo = 'Tìm được ${stories.length} truyện từ "$keyword"';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tìm kiếm: $e';
        _isLoading = false;
      });
    }
  }

  List<Story> _parseStories(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => Story.fromJson(e))
        .toList();
  }

  Future<void> _filterByGenres() async {
    if (_selectedSlugs.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _isFiltering = true;
      _searchResults = [];
      _debugInfo = 'Đang lọc truyện...';
    });

    final List<Story> combined = [];

    for (String slug in _selectedSlugs) {
      try {
        final result = await OTruyenApi.getComicsByCategory(slug);
        if (result.containsKey('items') && result['items'] is List) {
          final stories = _parseStories(result['items']);
          print('Slug [$slug] trả về ${stories.length} truyện');
          combined.addAll(stories);
        } else {
          print('Slug [$slug] không có items trong API');
        }
      } catch (e) {
        print('Lỗi khi gọi truyện theo thể loại [$slug]: $e');
      }
    }

    // Loại bỏ trùng bằng slug
    final Map<String, Story> uniqueMap = {};
    for (var story in combined) {
      uniqueMap[story.slug] = story;
    }

    // Lọc người lớn
    final safeStories = ContentFilter.filterStories(uniqueMap.values.toList());

    // Lọc chỉ lấy truyện có đầy đủ tất cả slug đã chọn
    final filteredByAllGenres = safeStories.where((story) {
      final storySlugs = story.categories.map((c) => c.toLowerCase()).toSet();
      return _selectedSlugs.every((slug) => storySlugs.contains(slug));
    }).toList();

    print('Tổng số truyện sau lọc là: ${filteredByAllGenres.length}');

    setState(() {
      _searchResults = filteredByAllGenres;
      _isLoading = false;
      _debugInfo =
          'Đã lọc ${_selectedSlugs.length} thể loại. Kết quả: ${filteredByAllGenres.length} truyện.';
    });
  }

  void _showGenreFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const Text('Chọn thể loại',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView(
                        children: _allGenres.map((genre) {
                          final selected = _selectedSlugs.contains(genre.slug);
                          return CheckboxListTile(
                            title: Text(genre.name),
                            value: selected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  _selectedSlugs.add(genre.slug);
                                } else {
                                  _selectedSlugs.remove(genre.slug);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterByGenres();
                      },
                      icon: const Icon(
                        Icons.filter_alt,
                        color: Colors.grey,
                      ),
                      label: const Text(
                        'Lọc truyện',
                        style: TextStyle(
                          color: Colors.grey, // Hoặc màu khác bạn muốn
                          fontWeight: FontWeight.bold, // tuỳ chọn
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: "Tìm kiếm truyện...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              if (_allGenres.isEmpty) {
                _loadGenres().then((_) => _showGenreFilter());
              } else {
                _showGenreFilter();
              }
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
                      child:
                          Text('Nhập từ khóa hoặc chọn thể loại để tìm truyện'))
                  : Column(
                      children: [
                        if (_debugInfo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _debugInfo,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        Expanded(
                          child: _searchResults.isEmpty
                              ? const Center(
                                  child: Text('Không tìm thấy truyện phù hợp'),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: GridView.builder(
                                    itemCount: _searchResults.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.5,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      final story = _searchResults[index];
                                      return StoryTile(
                                        story: story,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StoryDetailPage(story: story),
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
}
