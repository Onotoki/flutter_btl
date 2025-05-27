import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/pages/categories_page.dart';
import 'package:flutter/services.dart';

// Define a class to represent the state of slug data from Firebase
class SlugDataState {
  final Map<String, List<String>> slug;
  final Map<String, double> progressMap; // Map slug to progress
  final Map<String, String> idBook; // Map slug to progress

  SlugDataState({
    required this.slug,
    required this.idBook,
    required this.progressMap,
  });
}

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
  Map<String, double> _progressMap = {}; // Map slug to progress
  Map<String, String> _idBookMap = {}; // Map slug to progress
  String? uid;
  String _debugInfo = '';
  bool hasReading = false;
  bool hasFavorite = false;

  // Convert getSlug to Stream
  Stream<SlugDataState> getSlug(String uid) {
    print("uid $uid");
    return FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      Map<String, List<String>> slug = {
        'Đang đọc': [],
        'Yêu thích': [],
      };
      Map<String, double> progressMap = {};
      Map<String, String> idBook = {};

      for (var doc in querySnapshot.docs) {
        String docSlug = doc['slug'];
        if (doc['isreading'] == true) {
          slug['Đang đọc']!.add(docSlug);
          progressMap[docSlug] = doc['process']?.toDouble() ?? 0.0;
          idBook[docSlug] = doc['id_book'];
        }
        if (doc['isfavorite'] == true) {
          slug['Yêu thích']!.add(docSlug);
        }
      }

      print('Stream emitted: slug=$slug, progressMap=$progressMap');
      return SlugDataState(
          slug: slug, progressMap: progressMap, idBook: idBook);
    }).handleError((e) {
      print('Lỗi khi lấy dữ liệu Firebase: $e');
      return SlugDataState(
          slug: {'Đang đọc': [], 'Yêu thích': []}, progressMap: {}, idBook: {});
    });
  }

  Future<void> deleteSlug(String idBook) async {
    FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .doc(idBook)
        .delete();
  }

  void getData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Chưa đăng nhập';
        _isLoading = false;
      });
      return;
    }

    uid = user.uid;
    getSlug(uid!).listen((SlugDataState state) {
      // Only reload comics if slugs have changed
      bool slugsChanged = _categories['Đang đọc']!.length !=
              state.slug['Đang đọc']!.length ||
          _categories['Yêu thích']!.length != state.slug['Yêu thích']!.length ||
          !_categories['Đang đọc']!
              .every((story) => state.slug['Đang đọc']!.contains(story.slug)) ||
          !_categories['Yêu thích']!
              .every((story) => state.slug['Yêu thích']!.contains(story.slug));

      setState(() {
        _progressMap = state.progressMap;
        _idBookMap = state.idBook;
        if (slugsChanged && state.slug.isNotEmpty) {
          _isLoading = true;
          _loadMultipleComics(state.slug['Đang đọc']!, 'Đang đọc');
          _loadMultipleComics(state.slug['Yêu thích']!, 'Yêu thích');
        } else if (state.slug['Đang đọc']!.isEmpty &&
            state.slug['Yêu thích']!.isEmpty) {
          _isLoading = false;
          _categories['Đang đọc'] = [];
          _categories['Yêu thích'] = [];
        }
      });
    }, onError: (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách slug: $e';
        _isLoading = false;
        _debugInfo = 'Lỗi khi tải slug: $e';
      });
    });
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

    final debugLogs =
        StringBuffer('Đang lấy tất cả dữ liệu danh mục $category...\n');
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
        _errorMessage = 'Không thể tải dữ liệu danh mục $category: $e';
        _isLoading = false;
        _debugInfo = debugLogs.toString();
        print('Lỗi khi tải dữ liệu danh mục $category: $e');
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
      if (result.containsKey('item') &&
          result['item'] is Map<String, dynamic>) {
        debugLogs.write('Parsing single item: ${result['item']}\n');
        return Story.fromJson(result['item']);
      } else {
        debugLogs.write('No item found in data\n');
      }
    } catch (e) {
      debugLogs.write('Lỗi khi phân tích dữ liệu truyện: $e\n');
    }
    return null;
  }

  Story? _parseStories(dynamic data) {
    if (data == null) {
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
              return Story.fromJson(item);
            }
          } catch (e) {
            print('Error parsing story item: $e, item: $item');
          }
        }
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

  Widget _buildHorizontalStoryList(List<Story> stories, String type) {
    double a = 15;
    if (type != 'Đang đọc') {
      a = -100;
    }
    return SizedBox(
      height: 220,
      child: stories.isEmpty
          ? const Center(child: Text('Chưa có chuyện nào'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                final progress = _progressMap[story.slug] ?? 0.0;
                final idBook = _idBookMap[story.slug] ?? '';
                return Stack(
                  children: [
                    StoryTile(
                      story: story,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoryDetailPage(story: story),
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
                                  Text(
                                    story.title,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      Button_Info(
                                        text: 'Xoá truyện',
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        flex: 1,
                                        ontap: () {
                                          deleteSlug(idBook);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Positioned(
                      top: 10,
                      left: a,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${progress.toStringAsFixed(2)}%',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    print('chạy init');
    getData();
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
                          _buildHorizontalStoryList(
                              category.value, category.key),
                        ],
                      ],
                    ),
                  ),
                ),
              );
  }
}
