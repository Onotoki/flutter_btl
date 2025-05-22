import 'package:btl/components/info_book_widgets.dart/comments.dart';
import 'package:btl/components/info_book_widgets.dart/rate_list_icons.dart';
import 'package:flutter/material.dart';

class RateAllWidget extends StatelessWidget {
  String idBook;
  RateAllWidget({super.key, required this.idBook});

  @override
  Widget build(BuildContext context) {
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
                      height: 300,
                      width: double.infinity,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          Text('Siêu Năng Lập Phương',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          Text('9,0/ 2 đánh giá'),
                          SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            flex: 1,
                            child: RatingSelector(),
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
                    left: 100,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.transparent, width: 0.0),
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 242, 184, 58),
                      ),
                      child: Text(
                        '9.0',
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
                    idBook: idBook,
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
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (context) {
                  return CommentsWidget(
                    idBook: '',
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
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Text('Yêu thích')
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
