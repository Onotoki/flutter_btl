import 'dart:math';

import 'package:btl/components/info_book_widgets.dart/comments.dart';
import 'package:btl/components/info_book_widgets.dart/rate_list_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RateAllWidget extends StatefulWidget {
  String idBook;
  String slug;
  String title;
  RateAllWidget({
    super.key,
    required this.slug,
    required this.idBook,
    required this.title,
  });

  @override
  State<RateAllWidget> createState() => _RateAllWidgetState();
}

class _RateAllWidgetState extends State<RateAllWidget> {
  bool isFavorite = false;
  Future<void> addToFavorite(
    String idBook,
    String uid,
    String slug,
  ) async {
    await FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .doc(idBook)
        .set(
      {
        'process': 0,
        'slug': slug,
        'isfavorite': true,
      },
    );
  }

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _rate;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _favorite;
  Future<DocumentSnapshot<Map<String, dynamic>>> checkIsFavorite() async {
    return await FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .doc(widget.idBook)
        .get();
  }

  String? uid;

  @override
  void initState() {
    super.initState();
    _rate = FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .snapshots();
    _favorite = checkIsFavorite();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _rate,
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }
        // Lấy điểm và số lượng đánh giá
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final currentRate = data?['rate'] != null ? data!['rate'] : 0;
        final countRate = data?['counts'] != null ? data!['counts'] : 0;

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
                              SizedBox(
                                height: 5,
                              ),
                              Text(widget.title,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              Text(
                                currentRate != 0
                                    ? '$currentRate/ $countRate đánh giá'
                                    : 'Chưa có đánh giá nào',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                height: 18,
                              ),
                              Expanded(
                                flex: 0,
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
                  // color: Colors.amber,
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
                          Text(
                            'Đánh giá',
                            style: TextStyle(fontSize: 14),
                          )
                        ],
                      ),
                      Positioned(
                        top: 0,
                        left: currentRate != 0 ? 90 : -1000,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.transparent, width: 0.0),
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: Text(
                            currentRate.toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
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
                  // color: Colors.deepOrange,
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
                      Text('Bình luận')
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: GestureDetector(
                  onTap: () {
                    if (uid != null) {
                      addToFavorite(widget.idBook, uid!, widget.slug);
                    } else if (uid == null) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text('Vui lòng đăng nhập'),
                          );
                        },
                      );
                    }
                  },
                  child: FutureBuilder(
                    future: checkIsFavorite(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Something went wrong");
                      }

                      if (snapshot.hasData && !snapshot.data!.exists) {
                        // Map<String, dynamic> data =
                        //     snapshot.data!.data() as Map<String, dynamic>;

                        print(data);
                      }

                      return Container(
                        height: 60,
                        // color: Colors.deepOrange,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: isFavorite
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            Text('Yêu thích')
                          ],
                        ),
                      );
                    },
                  )),
            ),
          ],
        );
      },
    );
  }
}
