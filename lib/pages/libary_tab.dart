import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/pages/story_detail_page.dart';
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

      // if (newUpdateResult == null || newUpdateResult is! Map<String, dynamic>) {
      //   debugLogs.write('API trả về dữ liệu không hợp lệ hoặc null\n');
      //   print(debugLogs);
      //   return null;
      // }

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
          // Xóa listBooks nếu không có dữ liệu
          // listBooks.clear();
          print('Chạy hàm rỗng');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 38.0),
            child: Center(child: const Text('Danh sách rỗng')),
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

        // dùng được nhưng phải xoá đi nạp lại
        // final data = snapshot.data!.docs;
        // if (data.isNotEmpty) {
        //   listBooks.clear();
        //   for (var book1 in data) {
        //     final book = book1.data() as Map<String, dynamic>;
        //     listBooks.add({
        //       'slug': book['slug'],
        //       'idBook': book['id_book'],
        //       'progress': book.containsKey('process') ? book['process'] : 0,
        //     });
        //   }
        // }

        // Hiển thị danh sách
        if (listBooks.isEmpty) {
          return const Text('Không có sách để hiển thị');
        }

        // return Expanded(
        //   child: SizedBox(
        //     height: 220,
        //     child: ListView(
        //       scrollDirection: Axis.horizontal,
        //       children: List.generate( listBooks.length, (index) {
        //               return SizedBox(
        //                   height: 140,
        //                   width: 120,
        //                   child: _buildBookFutureBuilder(listBooks[index], category));
        //       },),
        //     ),
        //   ),
        // );

        return Expanded(
          child: AnimationLimiter(
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
          ),
        );
      },
    );
  }

  // Ở lớp State hoặc ngoài widget, định nghĩa method sau:
  Widget _buildBookFutureBuilder(Map<String, dynamic> book, String category) {
    // Nếu muốn log mỗi lần lặp, in ở đây
    print('chạy hàm for với slug = ${book['slug']}');

    return FutureBuilder<Story?>(
      future: _loadHomeData(book['slug']),
      builder: (context, apiSnapshot) {
        if (apiSnapshot.hasError) {
          print('Lỗi _loadHomeData: ${apiSnapshot.error}');
          // return ListTile(title: Text('Error: ${apiSnapshot.error}'));
          return ListTile(title: Text('Error:apiSnapshot.error'));
        }
        if (!apiSnapshot.hasData) {
          return Container(
            width: 130,
            color: Colors.transparent,
          );
        }

        final story = apiSnapshot.data!;
        print('chạy hàm build ảnh');
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
                return showDialog(
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
            ),
            category == 'books_reading'
                ? Positioned(
                    top: 10,
                    left: 15,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${book['progress'].toStringAsFixed(2)}%',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
