import 'package:btl/api/otruyen_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChapterPage extends StatefulWidget {
  final String storySlug;
  final String idBook;
  final String chapterTitle;
  final int chapterNumber;
  final int chapterTotal;
  final String chapterApiData; // API URL để tải nội dung chương

  const ChapterPage({
    super.key,
    required this.storySlug,
    required this.idBook,
    required this.chapterApiData,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.chapterTotal,
  });

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  bool isLoading = true;
  String errorMessage = '';
  List<String> contentImages = [];
  String textContent = '';
  String debugInfo = '';
  // double process = 0;
  double indexChapter = 0;
  bool isFirebase = false;
  bool isChapter = false;
  final ScrollController _scrollController = ScrollController();
  String? uid;
  double sum = 0.0;
  // ScrollController  _scrollController = ScrollController();

  double _scrollPercentage = 0.0;
  void _updateScrollPercentage() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final percentage =
          maxScrollExtent > 0 ? (offset / maxScrollExtent) * 100 : 0.0;
      _scrollPercentage = double.parse(percentage.toStringAsFixed(2));
      print('chạy scoll: $_scrollPercentage');
    }
  }
  // Kiểm tra đăng nhập trước
  // Phải kt dl trên firebase có không : nếu có dựa vào tham số trong chapter_reading để kéo đến vị trí trước đó rồi tiếp tục đọc
  // th1: chưa có truyện trên firebase và ui đã đăng nhập lưu vào firebase

  Future<void> getData(String uid) async {
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_of_user')
        .doc(widget.idBook)
        .get();
    if (documentSnapshot.exists) {
      print('có dữ liệu trên firebase');
      isFirebase = true;
      print('Document data: ${documentSnapshot.data()}');
      final data = documentSnapshot.data() as Map;
      final currentIndex = data['chapters_reading'] as Map;
      // process = data['process'] ?? 0.0;
      if (currentIndex.containsKey(widget.chapterNumber.toString())) {
        indexChapter =
            currentIndex[widget.chapterNumber.toString()]?.toDouble() ?? 0.0;
        isChapter = true;
      }
      if (currentIndex.isNotEmpty) {
        sum = currentIndex.entries
            .where((e) => e.key != widget.chapterNumber)
            .fold(0.0, (sum, e) => sum + e.value);
      }
    } else {
      print('Document does not exist on the database');
    }
  }

  void loadData() async {
    await _loadChapterContent();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      await getData(uid!);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_scrollController.hasClients && indexChapter > 0) {
          print('Đã gán được _scrollController $indexChapter');
          _restoreScrollPosition(indexChapter);
          _scrollController.addListener(_updateScrollPercentage);
        } else {
          _scrollController.addListener(_updateScrollPercentage);

          print('chưa gán được controller');
        }
      });
    }
  }

  void updateLast(
    int chapterNumber,
    double newProgress,
  ) {
    final rawProgress = (sum + newProgress) / widget.chapterTotal;
    final progress = double.parse(rawProgress.toStringAsFixed(2));

    if (isFirebase == false) {
      print('chạy hàm tạo mới');
      FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_of_user')
          .doc(widget.idBook)
          .set({
        'chapters_reading': {widget.chapterNumber.toString(): newProgress},
        'process': progress,
        'slug': widget.storySlug,
        'isfavorite': false,
        'isreading': true,
        'id_book': widget.idBook,
        'totals_chapter': widget.chapterTotal
      });
    } else if (isFirebase) {
      print('chạy hàm update');
      FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_of_user')
          .doc(widget.idBook)
          .update({
        'isreading': true,
        'chapters_reading.$chapterNumber': newProgress,
        'process': progress,
      });
    }
  }

  Future<void> _restoreScrollPosition(double percentage) async {
    final pct = percentage.clamp(0.0, 100.0);
    print('pct $pct');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(seconds: 2));
      final maxExtent = _scrollController.position.maxScrollExtent;
      final targetOffset = (pct / 100.0) * maxExtent;
      print('Restoring: maxExtent=$maxExtent, targetOffset=$targetOffset');
      print('max $maxExtent');
      _scrollController.jumpTo(
        targetOffset,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print('thoát  ${widget.chapterNumber}');
    updateLast(widget.chapterNumber, _scrollPercentage);
  }

  Future<void> _loadChapterContent() async {
    String logs = '';
    try {
      logs += 'Đang tải nội dung chương từ: ${widget.chapterApiData}\n';

      if (widget.chapterApiData.startsWith('http')) {
        logs += 'URL hợp lệ, đang gọi API để tải nội dung...\n';

        // Sử dụng phương thức API mới để tải nội dung chương
        final chapterContent =
            await OTruyenApi.getChapterContent(widget.chapterApiData);
        logs += 'Đã nhận phản hồi từ API\n';
        logs += 'Dữ liệu nhận được: ${chapterContent.keys.toList()}\n';

        // Hiển thị nội dung chương (ảnh hoặc văn bản)
        if (chapterContent.containsKey('images') &&
            chapterContent['images'] is List<String> &&
            (chapterContent['images'] as List<String>).isNotEmpty) {
          final images = chapterContent['images'] as List<String>;
          logs += 'Tìm thấy ${images.length} ảnh để hiển thị\n';
          logs += 'URL ảnh đầu tiên: ${images[0]}\n';

          setState(() {
            contentImages = images;
            isLoading = false;
            debugInfo = logs;
          });
        }
        // Hiển thị nội dung văn bản nếu không có ảnh
        else if (chapterContent.containsKey('content') &&
            chapterContent['content'].toString().isNotEmpty) {
          logs += 'Tìm thấy nội dung văn bản\n';

          setState(() {
            textContent = chapterContent['content'].toString();
            isLoading = false;
            debugInfo = logs;
          });
        }
        // Không có nội dung
        else {
          logs += 'Không tìm thấy nội dung trong phản hồi API\n';
          if (chapterContent.containsKey('images')) {
            logs +=
                'Trường images tồn tại nhưng ${chapterContent['images'] is List ? "là danh sách rỗng" : "không phải danh sách"}\n';
          } else {
            logs += 'Không có trường images trong phản hồi\n';
          }

          setState(() {
            textContent = 'Không tìm thấy nội dung cho chương này.';
            isLoading = false;
            debugInfo = logs;
          });
        }
      } else {
        logs += 'URL không hợp lệ: ${widget.chapterApiData}\n';

        setState(() {
          textContent = 'URL không hợp lệ để tải nội dung chương.';
          isLoading = false;
          debugInfo = logs;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải nội dung chương: $e';
        isLoading = false;
        debugInfo = '$logs\nLỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chương ${widget.chapterNumber}: ${widget.chapterTitle}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding chỉ áp dụng cho text/info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (debugInfo.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Debug Info'),
                                      content: SingleChildScrollView(
                                        child: Text(debugInfo),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Đóng'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.amber.withOpacity(0.3),
                                  child: const Text('Xem thông tin Debug'),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Chương ${widget.chapterNumber}: ${widget.chapterTitle}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // PHẦN ẢNH không có padding để ảnh full width
                      if (contentImages.isNotEmpty) ...[
                        for (var imageUrl in contentImages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 0.0),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.fitWidth,
                              width: double.infinity,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                      ] else
                        // Nếu là văn bản thì thêm padding riêng
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            textContent,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
