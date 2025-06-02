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
  bool hasFavorite = false;
  String? uid;

  Future<void> updateFavor(
    String idBook,
    String uid,
    String slug,
    bool hasFavorite,
    bool isFavorite,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_favorite')
          .doc(idBook);
      if (hasFavorite != true && isFavorite == true) {
        docRef.set({'slug': slug, 'id_book': idBook});
      } else if (hasFavorite == true && isFavorite == false) {
        docRef.delete();
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  Future<void> checkIsFavorite() async {
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_favorite')
          .doc(widget.idBook)
          .get();

      if (doc.exists) {
        setState(() {
          hasFavorite = true;
          isFavorite = true;
        });
      }
    } catch (e) {
      print('Lỗi khi kiểm tra yêu thích: $e');
    }
  }

  void getDataFirebase() {
    _rate = FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .snapshots();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      uid = user.uid;
      checkIsFavorite(); // Gọi để khởi tạo trạng thái
    }
  }

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _rate;

  @override
  void initState() {
    super.initState();
    getDataFirebase();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    updateFavor(widget.idBook, uid!, widget.slug, hasFavorite, isFavorite);
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
          return Rate();
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final currentRate = data!['rate'];
          final countRate = data['count'];
          return Rate(currentRate: currentRate, countRate: countRate);
        }
        // Lấy điểm và số lượng đánh giá
        return Rate();
      },
    );
  }

  Widget Rate({double currentRate = 0, int countRate = 0}) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 8.0, left: 8, right: 8, bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        RatingSelector(
                          idBook: widget.idBook,
                          currentRate: double.parse(currentRate.toString()),
                          countRate: countRate,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: SizedBox(
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
                    left: currentRate != 0 ? 85 : -1000,
                    child: Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                          child: Text('$currentRate',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11))),
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
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return FractionallySizedBox(
                    heightFactor: 0.7,
                    child: CommentsWidget(
                      idBook: widget.idBook,
                    ),
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
                // toggleFavorite(widget.idBook, uid!, widget.slug);
                setState(() {
                  isFavorite = !isFavorite;
                });
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
  }
}
