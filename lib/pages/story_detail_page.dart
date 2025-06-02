import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/chapter.dart';
import 'package:btl/pages/chapter_page.dart';

class StoryDetailPage extends StatefulWidget {
  final Story story;

  const StoryDetailPage({
    super.key,
    required this.story,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> comicDetail = {};
  List<Chapter> chapters = [];
  String debugInfo = '';
  String storyDescription = '';
  Map? currentIndex;
  int continueRead = 0;
  final GlobalKey _chaptersKey = GlobalKey();

  String? uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? docStream;
  late String idBook;

  void _scrollToChapters() {
    final context = _chaptersKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    storyDescription = widget.story.description; // Lưu mô tả ban đầu
    _loadComicDetail();
    final user = FirebaseAuth.instance.currentUser;
    idBook = widget.story.slug;

    if (user != null) {
      uid = user.uid;
      docStream = FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(idBook)
          .snapshots();
    } else {
      docStream = null; // Không cần stream nếu chưa đăng nhập
    }
  }

  Future<void> _loadComicDetail() async {
    String logs = '';
    try {
      logs += 'Đang tải thông tin chi tiết truyện: ${widget.story.slug}\n';
      final result = await OTruyenApi.getComicDetail(widget.story.slug);
      logs += 'Chi tiết API Response keys: ${result.keys.toList()}\n';

      setState(() {
        if (widget.story.chaptersData.isNotEmpty) {
          logs += 'Sử dụng chaptersData có sẵn từ story\n';
          chapters = Chapter.fromStoryChapters(widget.story.chaptersData);
          logs += 'Đã tạo ${chapters.length} chapter từ chaptersData\n';
        } else {
          if (result.containsKey('item') &&
              result['item'] is Map &&
              result['item'].containsKey('chapters')) {
            logs += 'Tìm thấy chapters trong item\n';
            var chaptersData = result['item']['chapters'];
            if (chaptersData is List) {
              chapters = Chapter.fromStoryChapters(chaptersData);
              logs += 'Đã tạo ${chapters.length} chapter từ item.chapters\n';
            }
          } else {
            logs += 'Không tìm thấy cấu trúc chapters từ API, tạo mẫu\n';
            _createSampleChapters();
          }
        }

        if (result.containsKey('item') &&
            result['item'] is Map &&
            result['item'].containsKey('content') &&
            result['item']['content'].toString().isNotEmpty) {
          storyDescription = result['item']['content'].toString();
          logs += 'Đã cập nhật mô tả từ API\n';
        }

        debugInfo = logs;
        isLoading = false;
        print(logs);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải thông tin truyện: $e';
        debugInfo = '$logs\nLỗi: $e';
        isLoading = false;
        print('Lỗi khi tải chi tiết truyện: $e');
      });
    }
  }

  void _createSampleChapters() {
    List<Chapter> sampleChapters = [];
    for (int i = 1; i <= 10; i++) {
      sampleChapters.add(Chapter(
        id: 'sample_$i',
        title: 'Chương $i',
        name: '$i',
        apiData: 'sample_chapter_$i',
        fileName: widget.story.title,
      ));
    }
    chapters = sampleChapters;
  }

  @override
  Widget build(BuildContext context) {
    Size _getResponsiveSize(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final width = (screenWidth - 40) / 3;
      final height = width * 4 / 3;
      return Size(width, height);
    }

    final size = _getResponsiveSize(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.title),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
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
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Đóng'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.amber.withOpacity(0.3),
                              child: const Text('Xem thông tin Debug'),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.story.thumbnail,
                                width: size.width,
                                height: size.height,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 160,
                                    color: Colors.grey[300],
                                    child:
                                        const Center(child: Icon(Icons.error)),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.story.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Số chương: ${widget.story.chapters}'),
                                  if (widget.story.authors.isNotEmpty)
                                    Text(
                                        'Tác giả: ${widget.story.authors.join(", ")}'),
                                  Text('Lượt xem: ${widget.story.views}'),
                                  Text('Trạng thái: ${widget.story.status}'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        widget.story.categories.map((category) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(category,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            // Chỉ sử dụng StreamBuilder nếu đã đăng nhập
                            if (uid != null && docStream != null)
                              StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>>(
                                stream: docStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Something went wrong');
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return _buildReadNowButton(idBook);
                                  }
                                  // if (snapshot.hasData &&
                                  //     snapshot.data != null &&
                                  //     snapshot.data!.exists &&
                                  //     snapshot.data!.data() != null) {
                                  // không thể gọi snapshot.exists, vì exists là thuộc tính của lớp DocumentSnapshot, chứ không phải của AsyncSnapshot<DocumentSnapshot>.
                                  // snapshot.data mới chính là DocumentSnapshot
                                  // snapshot.data!.exists để phân biệt “document có thật sự tồn tại hay chưa
                                  if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final data = snapshot.data!.data()!;
                                    continueRead = int.parse(
                                        data['chapters_reading']
                                            .entries
                                            .last
                                            .key);
                                    final chapter = chapters[continueRead];
                                    return Button_Info(
                                      text: 'Đọc tiếp',
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      flex: 3,
                                      ontap: () {
                                        if (chapter.apiData.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChapterPage(
                                                chapterIndex: continueRead,
                                                chapters: chapters,
                                                storySlug: widget.story.slug,
                                                chapterTotal: chapters.length,
                                                chapterApiData: chapter.apiData,
                                                idBook:
                                                    idBook, // Sử dụng idBook hợp lệ
                                                chapterTitle:
                                                    chapter.title.isNotEmpty
                                                        ? chapter.title
                                                        : chapter.name,
                                                chapterNumber:
                                                    _getChapterNumber(
                                                        chapter.name),
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Không thể đọc chương này')),
                                          );
                                        }
                                      },
                                    );
                                  }
                                  return _buildReadNowButton(idBook);
                                },
                              )
                            else
                              _buildReadNowButton(idBook),
                            const SizedBox(width: 10),
                            Button_Info(
                              text: 'Chương',
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              flex: 2,
                              ontap: _scrollToChapters,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mô tả',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              storyDescription.isNotEmpty
                                  ? storyDescription
                                  : widget.story.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Tóm tắt đầy đủ',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 10),
                                            const Divider(thickness: 0.3),
                                            Text(
                                              storyDescription.isNotEmpty
                                                  ? storyDescription
                                                  : widget.story.description,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Text('Chi tiết',
                                    style: TextStyle(color: Colors.green[300])),
                              ),
                            ),
                          ],
                        ),
                      ),
                      RateAllWidget(
                        idBook: idBook, // Sử dụng idBook hợp lệ
                        title: widget.story.title,
                        slug: widget.story.slug,
                        totalChapter: chapters.length,
                      ),
                      const Divider(thickness: 0.5),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              key: _chaptersKey,
                              child: Text('Danh sách chương',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            if (chapters.isEmpty)
                              const Center(child: Text('Không có chương nào')),
                            if (uid == null)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: chapters.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  mainAxisExtent: 40,
                                ),
                                itemBuilder: (context, index) {
                                  final chapter = chapters[index];
                                  final chapterTitle =
                                      _getChapterTitle(chapter);
                                  return GestureDetector(
                                    onTap: () {
                                      print('idBoook: ${idBook}');
                                      if (chapter.apiData.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChapterPage(
                                              chapterIndex: index,
                                              chapters: chapters,
                                              storySlug: widget.story.slug,
                                              chapterTotal: chapters.length,
                                              chapterApiData: chapter.apiData,
                                              idBook:
                                                  idBook, // Sử dụng idBook hợp lệ
                                              chapterTitle:
                                                  chapter.title.isNotEmpty
                                                      ? chapter.title
                                                      : chapter.name,
                                              chapterNumber: _getChapterNumber(
                                                  chapter.name),
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Không thể đọc chương này')),
                                        );
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: Center(
                                          child: Text(
                                            chapterTitle,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (uid != null)
                              StreamBuilder<DocumentSnapshot>(
                                stream: docStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Center(
                                        child: Text('Something went wrong'));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  final raw = snapshot.data?.data()
                                          as Map<String, dynamic>? ??
                                      {};
                                  final reading =
                                      (raw['chapters_reading'] is Map)
                                          ? Map<String, num>.from(
                                              raw['chapters_reading'])
                                          : <String, num>{};
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: chapters.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 6,
                                      crossAxisSpacing: 6,
                                      mainAxisExtent: 40,
                                    ),
                                    itemBuilder: (context, index) {
                                      final chapter = chapters[index];
                                      final chapterTitle =
                                          _getChapterTitle(chapter);
                                      double fraction = 0.0;
                                      if (reading != null) {
                                        final progress =
                                            reading['${index}'] ?? 0.0;
                                        fraction = progress / 100.0;
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          if (chapter.apiData.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChapterPage(
                                                  chapterIndex: index,
                                                  chapters: chapters,
                                                  storySlug: widget.story.slug,
                                                  chapterTotal: chapters.length,
                                                  chapterApiData:
                                                      chapter.apiData,
                                                  idBook:
                                                      idBook, // Sử dụng idBook hợp lệ
                                                  chapterTitle:
                                                      chapter.title.isNotEmpty
                                                          ? chapter.title
                                                          : chapter.name,
                                                  chapterNumber:
                                                      _getChapterNumber(
                                                          chapter.name),
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Không thể đọc chương này')),
                                            );
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Stack(
                                            children: [
                                              Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              FractionallySizedBox(
                                                widthFactor: fraction,
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                    color: Colors.green),
                                              ),
                                              Center(
                                                child: Text(
                                                  chapterTitle,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Widget nút "Đọc ngay" dùng chung
  Widget _buildReadNowButton(String idBook) {
    return Button_Info(
      text: 'Đọc ngay',
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      flex: 3,
      ontap: () {
        if (chapters.isNotEmpty) {
          final chapter = chapters[0]; // Bắt đầu từ chương đầu tiên
          if (chapter.apiData.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapterPage(
                  chapterIndex: 0,
                  chapters: chapters,
                  storySlug: widget.story.slug,
                  chapterTotal: chapters.length,
                  chapterApiData: chapter.apiData,
                  idBook: idBook,
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có chương nào để đọc')),
          );
        }
      },
    );
  }

  String _getChapterTitle(Chapter chapter) {
    final number = _getChapterNumber(chapter.name);
    final title = chapter.title.isNotEmpty ? chapter.title : '';
    if (number > 0) {
      return title.isNotEmpty ? 'Chương $number: $title' : 'Chương $number';
    }
    return title.isNotEmpty ? title : chapter.name;
  }

  num _getChapterNumber(String chapterName) {
    final numberPattern = RegExp(r'^(\d+(\.\d+)?)');
    final match = numberPattern.firstMatch(chapterName);
    if (match != null && match.group(1) != null) {
      final value = double.parse(match.group(1)!);
      return value == value.toInt() ? value.toInt() : value;
    }
    return 0;
  }
}
