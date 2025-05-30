import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/models/chapter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChapterPage extends StatefulWidget {
  final String storySlug;
  final List<Chapter> chapters;
  final String idBook;
  final String chapterTitle;
  final num chapterNumber;
  final int chapterTotal;
  final int chapterIndex;
  final String chapterApiData; // API URL để tải nội dung chương

  const ChapterPage({
    super.key,
    required this.storySlug,
    required this.idBook,
    required this.chapters,
    required this.chapterApiData,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.chapterIndex,
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
  bool isEndChapter = false;

  double _scrollPercentage = 0.0;
  void _updateScrollPercentage() async {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final percentage =
          maxScrollExtent > 0 ? (offset / maxScrollExtent) * 100 : 0.0;
      _scrollPercentage = double.parse(percentage.toStringAsFixed(2));
      // if (offset == maxScrollExtent) {
      //   nextChapter();
      // }
      print('chạy scoll: $_scrollPercentage');
    }
  }

  num _getChapterNumber(String chapterName) {
    final numberPattern = RegExp(r'^(\d+(\.\d+)?)');
    final match = numberPattern.firstMatch(chapterName);
    if (match != null && match.group(1) != null) {
      final value = double.parse(match.group(1)!);
      // Nếu value là số nguyên (phần thập phân = 0) thì trả về int
      if (value == value.toInt()) {
        return value.toInt();
      }
      // Ngược lại trả về double
      return value;
    }
    return 0; // 0 là int, cũng hợp với num
  }

  void nextChapter() async {
    final currentIndex = widget.chapters
        .indexWhere((chapter) => chapter.apiData == widget.chapterApiData);
    if (currentIndex < 0 || currentIndex + 1 >= widget.chapters.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là chương cuối cùng')),
      );
      return;
    }

    final chapter = widget.chapters[currentIndex + 1];
    await Future.delayed(Duration(seconds: 1));
    // print();
    if (chapter.apiData.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterPage(
            chapters: widget.chapters,
            storySlug: widget.storySlug,
            chapterTotal: widget.chapterTotal,
            chapterIndex: widget.chapterIndex + 1,
            chapterApiData: chapter.apiData,
            idBook: widget.idBook,
            chapterTitle:
                chapter.title.isNotEmpty ? chapter.title : chapter.name,
            chapterNumber: _getChapterNumber(chapter.name),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đọc chương này')),
      );
    }
  } // Kiểm tra đăng nhập trước
  // Phải kt dl trên firebase có không : nếu có dựa vào tham số trong chapter_reading để kéo đến vị trí trước đó rồi tiếp tục đọc
  // th1: chưa có truyện trên firebase và ui đã đăng nhập lưu vào firebase

  Future<void> getData(String uid) async {
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_reading')
        .doc(widget.idBook)
        .get();
    if (documentSnapshot.exists) {
      print('có dữ liệu trên firebase');
      isFirebase = true;
      print('Document data: ${documentSnapshot.data()}');
      final data = documentSnapshot.data() as Map;
      final currentIndex = data['chapters_reading'] as Map;
      if (currentIndex.containsKey(widget.chapterIndex.toString())) {
        indexChapter = currentIndex[widget.chapterIndex.toString()] ?? 0.0;
        isChapter = true;
        print('hellllllllll $indexChapter, ${widget.chapterIndex}');
      }
      if (currentIndex.isNotEmpty) {
        sum = currentIndex.entries
            .where((e) => e.key != widget.chapterIndex.toString())
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
          _restoreScrollPosition(indexChapter);
          print('Đã gán được _scrollController $indexChapter');
          _scrollController.addListener(_updateScrollPercentage);
        } else {
          _scrollController.addListener(_updateScrollPercentage);

          print('chưa gán được controller');
        }
      });
    }
  }

  void updateLast(
    double newProgress,
  ) async {
    final rawProgress = (sum + newProgress) / widget.chapterTotal;
    final progress = double.parse(rawProgress.toStringAsFixed(2));

    if (isFirebase == false) {
      print('chạy hàm tạo mới');
      await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.idBook)
          .set({
        'chapters_reading': {widget.chapterIndex.toString(): newProgress},
        'process': progress,
        'slug': widget.storySlug,
        'id_book': widget.idBook,
        'totals_chapter': widget.chapterTotal
      });
    } else if (isFirebase) {
      final key = widget.chapterIndex.toString();
      print('chạy hàm update');
      await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.idBook)
          .set({
        'chapters_reading': {key: newProgress},
        'process': progress,
      }, SetOptions(merge: true));
    }
  }

  void _restoreScrollPosition(double percentage) async {
    print('percentage $percentage');
    print('chạy hàm delay');
    await Future.delayed(Duration(seconds: 1));
    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (percentage / 100.0) * maxExtent;
    print('Restoring: maxExtent=$maxExtent, targetOffset=$percentage');
    print('max $maxExtent');
    _scrollController.jumpTo(
      targetOffset,
    );
    ;
  }

  @override
  void initState() {
    super.initState();
    print('hello');
    loadData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print('thoát  ${widget.chapterNumber}');
    updateLast(_scrollPercentage);
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
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      SizedBox(
                        height: 5,
                      )
                    ],
                  ),
                ),
    );
  }
}
