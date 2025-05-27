import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Comment extends StatefulWidget {
  String idBook;
  Comment({super.key, required this.idBook});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  String? userName;
  Future<void> addComment({
    required String userName,
    required String userID,
    required String bookID,
    String? parentID,
    required String content,
  }) async {
    print('Chạy hàm add comemnt');
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookID)
        .collection('comments')
        .add(
      {
        'userName': userName,
        'userID': userID,
        'parentID': parentID,
        'content': content,
        'timestamp': Timestamp.now(),
        'likeCount': 0,
        'disLikeCount': 0,
        'replyCount': 0,
        'likeBy': <String>[],
        'disLikeBy': <String>[],
      },
    );
  }

  Stream<QuerySnapshot> getComments({String? parentID}) {
    if (parentID == null) {
      return FirebaseFirestore.instance
          .collection('books')
          .doc(widget.idBook)
          .collection('comments')
          .where('parentID', isNull: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('books')
          .doc(widget.idBook)
          .collection('comments')
          .where('parentID', isEqualTo: parentID)
          .snapshots();
    }
  }

  Future<void> getNameUser(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        print('Document data: ${documentSnapshot.data()}');

        final data = documentSnapshot.data() as Map<String, dynamic>;
        userName = data['nickname'];
        print('username: ${data['nickname']}');
      } else {
        print('Document does not exist on the database');
      }
    });
  }

  String? userTag;
  String? rootCommentID;
  TextEditingController commentController = TextEditingController();

  void replyFuction(QueryDocumentSnapshot comment) {
    setState(() {
      userTag = comment['userName'];
      rootCommentID = comment.id;
      commentController.text = ' ';
    });
    // print(currentUid);
  }

  String? uid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      if (user.email != null) {
        getNameUser(user.email!);
      } else {
        getNameUser(user.phoneNumber!);
      }
      // print('email user: ${user.displayName}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: getComments(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // giữ nguyên snapshot có thể lây ra các id,...
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('Chưa có bình luận nào'));
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 14),
                    child: ListView.builder(
                      // physics: NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final comment = docs[index];
                        return CommentWidget(
                          comment: comment,
                          rootCommentID: comment.id,
                          replyFuction: replyFuction,
                          idBook: widget.idBook,
                        );
                      },
                    ),
                  );
                }
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
        Container(
          // color: Colors.grey[100],
          padding: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 20),
          child: Material(
            elevation: 4.0,
            shadowColor: Colors.black,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: TextField(
                autofocus: false,
                controller: commentController,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) async {
                  if (commentController.text.isNotEmpty && uid != null) {
                    print('object1');
                    if (rootCommentID != null) {
                      addComment(
                          userName: userName!,
                          userID: uid!,
                          bookID: widget.idBook,
                          content: '@$userTag ${commentController.text}',
                          parentID: rootCommentID);
                      await FirebaseFirestore.instance
                          .collection('books')
                          .doc(widget.idBook)
                          .collection('comments')
                          .doc(rootCommentID)
                          .update({
                        'replyCount': FieldValue.increment(1),
                      });
                      print('object12');
                    } else {
                      addComment(
                        userName: userName!,
                        userID: uid!,
                        bookID: widget.idBook,
                        content: commentController.text,
                      );
                      print('object13');
                    }
                    setState(() {
                      commentController.clear();
                      rootCommentID = null;
                      userTag = null;
                    });
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
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      rootCommentID = null;
                      userTag = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  fillColor: Theme.of(context).colorScheme.secondary,
                  prefixText: userTag != null ? '@$userTag' : null,
                  prefixStyle: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  filled: true,
                  hintText: 'Viết bình luận...',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CommentWidget extends StatefulWidget {
  final String idBook;
  final QueryDocumentSnapshot comment;
  final String rootCommentID;
  final Function(QueryDocumentSnapshot) replyFuction;

  const CommentWidget(
      {Key? key,
      required this.comment,
      required this.rootCommentID,
      required this.idBook,
      required this.replyFuction});
  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool _visible = false;

  String getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Không rõ';

    DateTime commentDate = timestamp.toDate();
    DateTime now = DateTime.now();

    Duration difference = now.difference(commentDate);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút ';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ ';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trớc';
    } else if (difference.inDays < 30) {
      double weeks = difference.inDays / 7;
      return '${weeks.toStringAsFixed(0)} tuần ';
    } else if (difference.inDays < 365) {
      double months = difference.inDays / 30.42;
      return '${months.toStringAsFixed(0)} tháng ';
    } else {
      double years = difference.inDays / 365.25;
      return '${years.toStringAsFixed(0)} năm ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final rootCommentID = widget.rootCommentID;
    bool reply = false;
    String content = comment['content'];
    RegExp mentionRegExp = RegExp(r'^@(\w+)\s');
    bool hasMention = mentionRegExp.hasMatch(content);
    String mention = '';
    String remainingContent = content;
    if (hasMention) {
      mention = mentionRegExp.firstMatch(content)!.group(0)!;
      remainingContent = content.substring(mention.length);
    }
    if (widget.comment['replyCount'] > 0) {
      reply = true;
    }
    final timeComment = getTimeAgo(comment['timestamp']);

    final user = FirebaseAuth.instance.currentUser;
    String? currentUid;
    if (user != null) {
      currentUid = user.uid;
    }

    final listUserLike = comment['likeBy'] as List;
    bool isLike = listUserLike.contains(currentUid);

    final listUserDisLike = comment['disLikeBy'] as List;
    bool isDisLike = listUserDisLike.contains(currentUid);
    final commentRef = FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .collection('comments')
        .doc(comment.id);

    void toggleLike() async {
      final updates = <String, dynamic>{};
      if (isLike) {
        updates['likeCount'] = FieldValue.increment(-1);
        updates['likeBy'] = FieldValue.arrayRemove([currentUid]);
      } else {
        updates['likeCount'] = FieldValue.increment(1);
        updates['likeBy'] = FieldValue.arrayUnion([currentUid]);
        if (isDisLike) {
          updates['disLikeCount'] = FieldValue.increment(-1);
          updates['disLikeBy'] = FieldValue.arrayRemove([currentUid]);
        }
      }
      await commentRef.update(updates);
    }

    void toggleDisLike() async {
      final updates = <String, dynamic>{};
      if (isDisLike) {
        updates['disLikeCount'] = FieldValue.increment(-1);
        updates['disLikeBy'] = FieldValue.arrayRemove([currentUid]);
      } else {
        updates['disLikeCount'] = FieldValue.increment(1);
        updates['disLikeBy'] = FieldValue.arrayUnion([currentUid]);
        if (isLike) {
          updates['likeCount'] = FieldValue.increment(-1);
          updates['likeBy'] = FieldValue.arrayRemove([currentUid]);
        }
      }
      await commentRef.update(updates);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: AssetImage('assets/image/avatar.jpg'),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment['userName'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            ' $timeComment',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      hasMention
                          ? RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: mention,
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                      text: remainingContent,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                                ],
                              ),
                            )
                          : Text(content), //
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  if (currentUid != null) {
                                    toggleLike();
                                  } else {
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
                                child: Icon(
                                  Icons.thumb_up_alt_rounded,
                                  size: 18,
                                  color: isLike ? Colors.green : Colors.grey,
                                )),
                            Text(comment['likeCount'].toString()),
                            const SizedBox(width: 10),
                            GestureDetector(
                                onTap: () {
                                  if (currentUid != null) {
                                    toggleDisLike();
                                  } else {
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
                                child: Icon(
                                  Icons.thumb_down_alt_rounded,
                                  size: 18,
                                  color: isDisLike
                                      ? Colors.deepOrange
                                      : Colors.grey,
                                )),
                            Text(comment['disLikeCount'].toString()),
                            const SizedBox(width: 10),
                            GestureDetector(
                                onTap: () {
                                  // widget.replyFuction(comment);
                                  widget.replyFuction(comment);
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.message_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    Text('Trả lời'),
                                  ],
                                )),
                          ],
                        ),
                      ),

                      Visibility(
                          visible: reply,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _visible = !_visible;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  spacing: 0,
                                  children: [
                                    Text(
                                      '${comment['replyCount']} bình luận',
                                    ),
                                    Icon(
                                        _visible
                                            ? Icons.arrow_drop_up_sharp
                                            : Icons.arrow_drop_down_sharp,
                                        size: 28,
                                        color: Colors.grey),
                                  ]),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Text(timeComment.toString()),
            ],
          ),
          // Replies
          Visibility(
            visible: _visible,
            child: Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 10),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('books')
                    .doc(widget.idBook)
                    .collection('comments')
                    .where('parentID', isEqualTo: comment.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final replies = snapshot.data!.docs;
                    return Column(
                      children: replies.map((replyDoc) {
                        return CommentWidget(
                          comment: replyDoc,
                          rootCommentID: rootCommentID,
                          replyFuction: widget.replyFuction,
                          idBook: widget.idBook,
                        );
                      }).toList(),
                    );
                  }
                  return SizedBox
                      .shrink(); // Không hiển thị nếu không có replies
                },
              ),
            ),
          ),
          // Divider(),
        ],
      ),
    );
  }
}
