import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/pages/story_detail_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LibraryTab extends StatefulWidget {
  final String uid;
  final String category;
  const LibraryTab({super.key, required this.category, required this.uid});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with AutomaticKeepAliveClientMixin<LibraryTab> {
  List<Map<String, dynamic>> listBooks = [];

  Widget? listReading;
  Widget? listFavorite;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
  }

  Future<void> deleteSlug(String idBook, String subCollection) async {
    FirebaseFirestore.instance
        .collection('user_reading')
        .doc(widget.uid)
        .collection(subCollection)
        .doc(idBook)
        .delete();
  }

  Future<Story?> _loadHomeData(String slug) async {
    final debugLogs = StringBuffer('Đang tải truyện từ mục $slug...\n');
    try {
      final newUpdateResult = await OTruyenApi.getComicDetail(slug);
      debugLogs.write('API Response: $newUpdateResult\n');
      print('API Response for $slug: $newUpdateResult');

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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_reading')
          .doc(widget.uid) // Sử dụng UID động
          .collection(widget.category)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Lỗi Firestore: ${snapshot.error}');
          return const Text('Đã xảy ra lỗi khi tải dữ liệu');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('Chạy hàm rỗng');
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 38.0),
            child: Center(child: Text('Danh sách rỗng')),
          );
        }

        // Xử lý docChanges để chỉ cập nhật thay đổi
        for (var change in snapshot.data!.docChanges) {
          final data = change.doc.data() as Map<String, dynamic>?;
          if (data == null) {
            print('Tài liệu null: ${change.doc.id}');
            continue;
          }
          print('Chạy hàm thay đổi docChanges 1');

          // Kiểm tra dữ liệu hợp lệ
          if (!data.containsKey('slug') || !data.containsKey('id_book')) {
            print('Tài liệu thiếu trường: ${change.doc.id}');
            continue;
          }

          final book = {
            'slug': data['slug'],
            'idBook': data['id_book'],
            'progress': data.containsKey('process') ? data['process'] : 0,
          };

          if (change.type == DocumentChangeType.added) {
            // Kiểm tra trùng lặp trước khi thêm
            if (!listBooks.any((b) => b['idBook'] == book['idBook'])) {
              listBooks.add(book);
            }
          } else if (change.type == DocumentChangeType.modified) {
            final index =
                listBooks.indexWhere((b) => b['idBook'] == book['idBook']);
            if (index != -1) {
              listBooks[index] = book;
              print('Cập nhật book: ${book['slug']}');
            }
          } else if (change.type == DocumentChangeType.removed) {
            listBooks.removeWhere((b) => b['idBook'] == book['idBook']);
            print('Xóa book: ${book['idBook']}');
          }
        }

        // Hiển thị danh sách
        if (listBooks.isEmpty) {
          return const Text('Không có sách để hiển thị');
        }

        return AnimationLimiter(
          child: GridView.count(
            mainAxisSpacing: 2,
            crossAxisSpacing: 3,
            childAspectRatio: 0.6,
            crossAxisCount: 3,
            children: List.generate(
              listBooks.length,
              (index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 800),
                  columnCount: 3,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildBookFutureBuilder(
                          listBooks[index], widget.category),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookFutureBuilder(Map<String, dynamic> book, String category) {
    return FutureBuilder<Story?>(
      future: _loadHomeData(book['slug']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Lỗi')),
          );
        }

        final story = snapshot.data!;
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryDetailPage(story: story),
                  ),
                );
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            story.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Button_Info(
                                text: 'Xoá truyện',
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                flex: 1,
                                ontap: () {
                                  print('chạy hàm xoá truyện');
                                  if (category == 'books_reading') {
                                    deleteSlug(story.slug, 'books_reading');
                                  } else {
                                    deleteSlug(story.slug, 'books_favorite');
                                  }
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
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh bìa truyện
                      Image.network(
                        story.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported, size: 30),
                                const SizedBox(height: 4),
                                Text(
                                  story.title,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),

                      // Overlay gradient cho text dễ đọc
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hiển thị % tiến độ cho truyện đang đọc
            category == 'books_reading'
                ? Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${book['progress'].toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}