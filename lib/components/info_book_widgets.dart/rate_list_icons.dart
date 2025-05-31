import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RatingSelector extends StatefulWidget {
  String idBook;
  double currentRate;
  int countRate;

  RatingSelector(
      {super.key,
      required this.idBook,
      required this.currentRate,
      required this.countRate});

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  int? selectedIndex;
  String? uid;
  bool isRate = false;
  late Future<QuerySnapshot> checkUserRate;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
    }
    checkUserRate = FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .collection('rate')
        .where('user_id', isEqualTo: uid)
        .get();
  }

  final List<Map<String, dynamic>> items = [
    {
      'icon': 'lib/images/rate_icons/rate-5.webp',
      'text': 'Tuyệt vời',
      'color': Colors.green,
      'point': 10,
    },
    {
      'icon': 'lib/images/rate_icons/rate-4.webp',
      'text': 'Hay nha',
      'color': Colors.green,
      'point': 8,
    },
    {
      'icon': 'lib/images/rate_icons/rate-3.webp',
      'text': 'Khá ổn',
      'color': Colors.green,
      'point': 6,
    },
    {
      'icon': 'lib/images/rate_icons/rate-2.webp',
      'text': 'Chán ngắt',
      'color': Colors.green,
      'point': 4,
    },
    {
      'icon': 'lib/images/rate_icons/rate-1.webp',
      'text': 'Dở tệ',
      'color': Colors.green,
      'point': 2,
    },
  ];

  Future<void> _rate({
    required String userID,
    required String bookID,
    required double oldTotal,
    required int newRating,
    required int oldCount,
  }) async {
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookID)
        .collection('rate')
        .add(
      {
        'user_id': userID,
        'user_rate': newRating,
      },
    );
    final newCount = oldCount + 1;
    final newPoint = (oldTotal + newRating) / newCount;
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookID)
        .set({'rate': newPoint, 'count': newCount});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: checkUserRate,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("Something went wrong");
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              // Map<String, dynamic> data = snapshot.data!.docs.first.data();
              final data =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              selectedIndex = data['user_rate'];
              isRate = true;
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Expanded(
                child: Row(
                  children: List.generate(
                    items.length,
                    (index) {
                      final item = items[index];
                      return RateWidget(
                        isSelected: (selectedIndex == index) ||
                            (isRate && selectedIndex == index),
                        onTap: () {
                          if (!isRate) {
                            setState(() {
                              selectedIndex = index;
                            });
                          }
                        },
                        imageIcon: item['icon'],
                        textIcon: item['text'],
                        activeColor: item['color'],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(
          height: 30,
        ),
        Row(
          children: [
            Button_Info(
              text: 'Gửi đánh giá',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              flex: 1,
              ontap: () {
                if (selectedIndex != null && uid != null) {
                  final itemIcon = items[selectedIndex!];
                  _rate(
                    userID: uid!,
                    bookID: widget.idBook,
                    newRating: itemIcon['point'],
                    oldTotal: widget.currentRate,
                    oldCount: widget.countRate,
                  );
                  Navigator.pop(context);
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
            ),
            const SizedBox(
              width: 10,
            ),
            Button_Info(
              text: 'Huỷ',
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              flex: 1,
              ontap: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ],
    );
  }
}
