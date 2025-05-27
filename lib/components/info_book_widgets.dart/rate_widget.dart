import 'dart:math';

import 'package:btl/components/info_book_widgets.dart/comments.dart';
import 'package:btl/components/info_book_widgets.dart/rate_list_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RateAllWidget extends StatefulWidget {
  final String idBook;
  final String slug;
  final String title;
  final int totalChapter;

  const RateAllWidget({
    super.key,
    required this.totalChapter,
    required this.slug,
    required this.idBook,
    required this.title,
  });

  @override
  State<RateAllWidget> createState() => _RateAllWidgetState();
}

class _RateAllWidgetState extends State<RateAllWidget> {
  bool isFavorite = false;
  bool isReading = false;
  String? uid;

  Future<void> toggleFavorite(
    String idBook,
    String uid,
    String slug,
  ) async {
    try {
      // Lấy tài liệu hiện tại từ Firestore
      final docRef = FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_of_user')
          .doc(idBook);

      final doc = await docRef.get();
      bool newFavoriteStatus = !isFavorite;

      if (doc.exists) {
        final data = doc.data();
        bool currentIsReading = data?['isreading'] == true;

        // Nếu không đọc và bỏ yêu thích, xóa tài liệu
        if (!currentIsReading && !newFavoriteStatus) {
          await docRef.delete();
        } else {
          // Cập nhật trạng thái yêu thích
          await docRef.update({'isfavorite': newFavoriteStatus});
        }
      } else {
        // Nếu tài liệu không tồn tại, tạo mới
        // await docRef.set({
        //   'process': 0,
        //   'slug': slug,
        //   'isfavorite': newFavoriteStatus,
        //   'isreading': false,
        // });

        await docRef.set({
          'chapters_reading': {},
          'process': 0,
          'slug': slug,
          'isfavorite': newFavoriteStatus,
          'isreading': false,
          'totals_chapter': widget.totalChapter,
        });
      }

      // Cập nhật trạng thái UI sau khi Firestore thành công
      setState(() {
        isFavorite = newFavoriteStatus;
      });
    } catch (e) {
      // Xử lý lỗi và khôi phục trạng thái UI
      setState(() {
        isFavorite = !isFavorite; // Hoàn nguyên trạng thái
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật yêu thích: $e')),
      );
    }
  }

  Future<void> checkIsFavorite() async {
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_of_user')
          .doc(widget.idBook)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          isFavorite = data?['isfavorite'] == true;
          isReading = data?['isreading'] == true;
        });
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  void getDataFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      await checkIsFavorite(); // Gọi để khởi tạo trạng thái
    }
  }

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _rate;

  @override
  void initState() {
    super.initState();
    _rate = FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .snapshots();
    getDataFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _rate,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        // Lấy điểm và số lượng đánh giá
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final currentRate = data?['rate'] ?? 0;
        final countRate = data?['counts'] ?? 0;

        return Row(
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: min(300, 300),
                          width: double.infinity,
                          child: Column(
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                currentRate != 0
                                    ? '$currentRate/ $countRate đánh giá'
                                    : 'Chưa có đánh giá nào',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 18),
                              Expanded(
                                flex: 1,
                                child: RatingSelector(
                                  idBook: widget.idBook,
                                  currentRate:
                                      double.parse(currentRate.toString()),
                                  countRate: countRate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  height: 60,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tag_faces_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const Text(
                            'Đánh giá',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        left: currentRate != 0 ? 90 : -1000,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.transparent, width: 0.0),
                            ),
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: Text(
                            currentRate.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (context) {
                      return CommentsWidget(
                        idBook: widget.idBook,
                      );
                    },
                  );
                },
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(50)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.messenger,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const Text('Bình luận'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  if (uid == null) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return const AlertDialog(
                          content: Text('Vui lòng đăng nhập'),
                        );
                      },
                    );
                  } else {
                    toggleFavorite(widget.idBook, uid!, widget.slug);
                  }
                },
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(50)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: isFavorite
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const Text('Yêu thích'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
