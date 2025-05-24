import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsWidget extends StatelessWidget {
  CommentsWidget({super.key});
  String? currentUid = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 750,
      // padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bình luận',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.expand_circle_down_outlined,
                        size: 35,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: ListView(
                    children: [
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('comment'),
                      Text('$currentUid'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 0,
              ),
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.only(
                    bottom: 20, top: 8, left: 8, right: 8),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    hintText: 'Hãy viết gì đó...',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
