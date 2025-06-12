import 'dart:math';

import 'package:btl/components/info_book_widgets.dart/comment.dart';
import 'package:flutter/material.dart';

class CommentsWidget extends StatelessWidget {
  String idBook;
  CommentsWidget({super.key, required this.idBook});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bình luận',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 0.1,
        ),
        Expanded(
          child: Comment(idBook: idBook),
        )
      ],
    );
  }
}
