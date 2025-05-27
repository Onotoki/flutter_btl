import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/pages/categories_page.dart';
import 'package:flutter/services.dart';

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
  List<double> progressRead = [];

  Future<Map<String, List<String>>> getSlug(String uid) async {
    Map<String, List<String>> slug = {
      'Đang đọc': [],
      'Yêu thích': [],
    };
    await FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (doc['isreading'] == true) {
          slug['Đang đọc']!.add(doc['slug']);
          progressRead.add(doc['process']);
        } else {
          slug['Yêu thích']!.add(doc['slug']);
        }
        // print('du lieu tu slug: ${doc["slug"]}');
      });
    });
    return slug;
  }

  String? uid;
  void getdata() async {
    Map<String, List<String>> listSlug = await getSlug(uid!);
    if (listSlug.isNotEmpty) {
      print('co du lieu $listSlug');
      _loadMultipleComics(listSlug['Đang đọc']!, 'Đang đọc');
      _loadMultipleComics(listSlug['Yêu thích']!, 'Yêu thích');
    } else {
      print('mang rong');
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
    }
    getdata();
  }

  Future<Story?> _loadHomeData(String slug) async {
    final debugLogs = StringBuffer('Đang tải truyện từ mục $slug...\n');
    try {
      final newUpdateResult = await OTruyenApi.getComicDetail(slug);
      debugLogs.write('API Response: $newUpdateResult\n');
      print('API Response for $slug: $newUpdateResult');

      if (newUpdateResult == null || newUpdateResult is! Map<String, dynamic>) {
        debugLogs.write('API trả về dữ liệu không hợp lệ hoặc null\n');
        print(debugLogs);
        return null;
      }

      Story? story = _parseStoriesData(newUpdateResult, debugLogs);
      if (story == null) {
        debugLogs.write('No story parsed\n');
      }
      print(debugLogs);
      return story;
    } catch (e) {
      debugLogs.write('Lỗi khi tải dữ liệu truyện $slug: $e\n');
      print(debugLogs);
      return null;
    }
  }

  Future<void> _loadMultipleComics(List<String> slugs, String category) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _debugInfo = '';
    });

    final debugLogs = StringBuffer('Đang lấy tất cả dữ liệu danh mục...\n');
    final List<Story> stories = [];

    try {
      for (String slug in slugs) {
        Story? story = await _loadHomeData(slug);
        if (story != null) {
          stories.add(story);
        } else {
          debugLogs.write('Failed to load story for slug: $slug\n');
        }
      }

      setState(() {
        _categories[category] = stories;
        _isLoading = false;
        _debugInfo = debugLogs.toString();
        print(debugLogs);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu trang chủ: $e';
        _isLoading = false;
        _debugInfo = debugLogs.toString();
        print('Lỗi khi tải dữ liệu trang chủ: $e');
      });
    }
  }

  Story? _parseStoriesData(
      Map<String, dynamic>? result, StringBuffer debugLogs) {
    if (result == null) {
      debugLogs.write('Dữ liệu API là null\n');
      return null;
    }
    try {
      // Handle single comic from getComicDetail
      if (result != null && result is Map<String, dynamic>) {
        print('result.containsKey: $result');
        // final data = result['data'] as Map<String, dynamic>;
        if (result.containsKey('item') &&
            result['item'] is Map<String, dynamic>) {
          debugLogs.write('Parsing single item: ${result['item']}\n');
          return Story.fromJson(result['item']);
        } else {
          debugLogs.write('No item found in data\n');
        }
      }
      // Handle list of comics
      else if (result.containsKey('data') && result['data'] is Map) {
        return _parseStories(result['data']);
        // print('json11 data: $stories');
      } else if (result.containsKey('items') && result['items'] is Map) {
        // print('json11 item: $stories');
        return _parseStories(result['items']);
      } else {
        // result.forEach((key, value) {
        //   if (value is List && stories.isEmpty) {
        //     debugLogs.write('Parsing list from key: $key\n');
        //     print('json11 foreach: $value');
        //     return _parseStories(value);

        //   }
        // });
        return null;
      }
    } catch (e) {
      debugLogs.write('Lỗi khi phân tích dữ liệu truyện: $e\n');
    }

    // debugLogs.write('Parsed ${stories.length} stories\n');
    return null;
  }

  Story? _parseStories(dynamic data) {
    // List<Story> stories = [];
    if (data == null) {
      // debugLogs.write('Dữ liệu API là null\n');
      return null;
    }
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
              // stories.add(Story.fromJson(item));

              // print('Dữ liệu lấy ảnh $item');
              return (Story.fromJson(item));
            }
          } catch (e) {
            print('Error parsing story item: $e, item: $item');
          }
        }
        // print('Successfully parsed ${stories.length} stories');
      }
    } catch (e) {
      print('Error parsing stories data: $e');
    }

    return null;
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
                return Stack(
                  children: [
                    StoryTile(
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
                      onLongPress: () async {
                        await HapticFeedback.vibrate();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                                content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(stories[index].title),
                                ElevatedButton(
                                    onPressed: () {}, child: Text('Xoá truyện'))
                              ],
                            ));
                          },
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      left: 15,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4)),
                        child: Center(child: Text('${progressRead[index]}%')),
                      ),
                    )
                  ],
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
