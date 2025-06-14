import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/chapter.dart';
import 'package:btl/pages/chapter_page.dart';
import 'package:btl/pages/epub_chapter_page.dart';

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
  Map<String, dynamic> storyDetail = {};
  List<Chapter> chapters = [];
  String debugInfo = '';
  String storyDescription = '';
  String novelContent = ''; // Nội dung đầy đủ của truyện chữ (nếu có)

  // Firebase variables for reading progress
  String? uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? readingProgressStream;
  int continueReadingChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    storyDescription = widget.story.description; // Lưu mô tả ban đầu

    // Initialize Firebase auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      _initializeReadingProgressStream();
    }

    _loadDetail();
  }

  void _initializeReadingProgressStream() {
    if (uid == null) return;

    readingProgressStream = FirebaseFirestore.instance
        .collection('user_reading')
        .doc(uid)
        .collection('books_reading')
        .doc(widget.story.slug)
        .snapshots();
  }

  Future<void> _loadDetail() async {
    String logs = '';
    try {
      logs += 'Đang tải thông tin chi tiết: ${widget.story.slug}\n';
      logs += 'Loại truyện: ${widget.story.itemType}\n';

      // Xử lý dựa trên loại truyện
      if (widget.story.isNovel) {
        await _loadNovelDetail(logs);
      } else {
        await _loadComicDetail(logs);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải thông tin: $e';
        debugInfo = '$logs\nLỗi: $e';
        isLoading = false;
        print('Lỗi khi tải chi tiết: $e');
      });
    }
  }

  // Tải thông tin truyện tranh
  Future<void> _loadComicDetail(String logs) async {
    try {
      // Lưu ý: trong API mới, cần truyền slug của truyện thay vì id
      final result = await OTruyenApi.getComicDetail(widget.story.slug);
      logs += 'Chi tiết API Response keys: ${result.keys.toList()}\n';

      setState(() {
        // Nếu có sẵn chaptersData từ Story, sử dụng ngay
        if (widget.story.chaptersData.isNotEmpty) {
          logs += 'Sử dụng chaptersData có sẵn từ story\n';
          chapters = Chapter.fromStoryChapters(widget.story.chaptersData);
          logs += 'Đã tạo ${chapters.length} chapter từ chaptersData\n';
        }
        // Nếu không, phân tích từ kết quả API
        else {
          // Kiểm tra item.chapters trong API
          if (result.containsKey('item') &&
              result['item'] is Map &&
              result['item'].containsKey('chapters')) {
            logs += 'Tìm thấy chapters trong item\n';
            var chaptersData = result['item']['chapters'];

            // Chuyển đổi chaptersData thành danh sách Chapter
            if (chaptersData is List) {
              chapters = Chapter.fromStoryChapters(chaptersData);
              logs += 'Đã tạo ${chapters.length} chapter từ item.chapters\n';
            }
          }
          // Nếu không có chapters, tạo mẫu
          else {
            logs += 'Không tìm thấy cấu trúc chapters từ API, tạo mẫu\n';
            _createSampleChapters();
          }
        }

        // Cập nhật mô tả nếu có trong API
        if (result.containsKey('item') &&
            result['item'] is Map &&
            result['item'].containsKey('content') &&
            result['item']['content'].toString().isNotEmpty) {
          storyDescription = result['item']['content'].toString();
          logs += 'Đã cập nhật mô tả từ API\n';
        }

        debugInfo = logs;
        isLoading = false;
      });
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết truyện tranh: $e');
    }
  }

  // Tải thông tin truyện chữ
  Future<void> _loadNovelDetail(String logs) async {
    try {
      // Đối với truyện chữ, sử dụng endpoint riêng
      final result = await OTruyenApi.getNovelContent(widget.story.slug);
      logs += 'Chi tiết API Response keys: ${result.keys.toList()}\n';

      // Xử lý kết quả API
      if (result.containsKey('item') && result['item'] is Map) {
        final item = result['item'];

        // Cập nhật thông tin cơ bản của truyện
        if (item.containsKey('description') &&
            item['description'].toString().isNotEmpty) {
          storyDescription = item['description'].toString();
          logs += 'Đã cập nhật mô tả từ API\n';
        }
      }

      // Xử lý nội dung truyện chữ
      if (result.containsKey('content') && result['content'] is Map) {
        final content = result['content'];

        // Xử lý các chương
        if (content.containsKey('chapters') && content['chapters'] is List) {
          final chaptersData = content['chapters'];
          chapters = Chapter.fromNovelChapters(chaptersData);
          logs += 'Đã tạo ${chapters.length} chapter từ nội dung truyện chữ\n';
        }

        // Xử lý nội dung đầy đủ (nếu không chia chương)
        if (content.containsKey('content') &&
            content['content'].toString().isNotEmpty) {
          novelContent = content['content'].toString();
          logs += 'Đã lưu nội dung đầy đủ của truyện chữ\n';

          // Nếu không có chương nhưng có nội dung, tạo một chương duy nhất
          if (chapters.isEmpty) {
            chapters = [
              Chapter(
                id: 'full_content',
                title: 'Nội dung đầy đủ',
                name: '1',
                apiData: '',
                fileName: '',
                content: novelContent,
                isTextContent: true,
              )
            ];
            logs += 'Đã tạo một chương duy nhất từ nội dung đầy đủ\n';
          }
        }
      }

      setState(() {
        storyDetail = result; // Lưu toàn bộ result để sử dụng sau này
        debugInfo = logs;
        isLoading = false;
      });
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết truyện chữ: $e');
    }
  }

  // Tạo dữ liệu mẫu khi không tải được từ API
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

  void _navigateToChapter(Chapter chapter, int index) {
    if (widget.story.isNovel) {
      // Tất cả truyện chữ đều sử dụng EPUB reader
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubChapterPage(
            story: widget.story,
            chapterNumber: index + 1, // Chuyển từ index thành chapter number
            chapterTitle: chapter.title,
          ),
        ),
      );
    } else {
      // Điều hướng đến trang đọc truyện tranh với idBook
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterPage(
            storySlug: widget.story.slug,
            chapterTitle: chapter.title,
            chapterNumber: int.tryParse(chapter.name) ?? 0,
            chapterApiData: chapter.apiData,
            allChapters: chapters,
            currentChapterIndex: index,
            idBook: widget.story.slug, // Truyền idBook để lưu tiến độ đọc
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //Hàm tính kích thước ảnh responsive theo màn hình
    Size _getResponsiveSize(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final width = (screenWidth - 40) / 2.5; // trừ padding + khoảng cách
      final height = width * 4 / 2.5;
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
                      // Debug info button
                      // if (debugInfo.isNotEmpty)
                      //   GestureDetector(
                      //     onTap: () {
                      //       showDialog(
                      //         context: context,
                      //         builder: (context) => AlertDialog(
                      //           title: const Text('Debug Info'),
                      //           content: SingleChildScrollView(
                      //             child: Text(debugInfo),
                      //           ),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () => Navigator.pop(context),
                      //               child: const Text('Đóng'),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //     },
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(8.0),
                      //       child: Container(
                      //         padding: const EdgeInsets.all(8),
                      //         color: Colors.amber.withOpacity(0.3),
                      //         child: const Text('Xem thông tin Debug'),
                      //       ),
                      //     ),
                      //   ),

                      // Story info section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
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
                                    child: const Center(
                                      child: Icon(Icons.error),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Story details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.story.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Số chương: ${widget.story.chapters}'),

                                  // Hiển thị tác giả
                                  if (widget.story.authors.isNotEmpty)
                                    Text(
                                        'Tác giả: ${widget.story.authors.join(", ")}'),

                                  Text('Lượt xem: ${widget.story.views}'),
                                  Text('Trạng thái: ${widget.story.status}'),
                                  Text(
                                      'Loại: ${widget.story.isNovel ? 'Truyện chữ' : 'Truyện tranh'}'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        widget.story.categories.map((category) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Reading progress and action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: uid != null && readingProgressStream != null
                            ? StreamBuilder<DocumentSnapshot>(
                                stream: readingProgressStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final data = snapshot.data!.data()
                                        as Map<String, dynamic>;
                                    final chaptersReading =
                                        data['chapters_reading']
                                                as Map<String, dynamic>? ??
                                            {};

                                    if (chaptersReading.isNotEmpty) {
                                      // Tìm chương cuối cùng đã đọc
                                      final lastChapterKey = chaptersReading
                                          .entries
                                          .map((e) => int.tryParse(e.key) ?? 0)
                                          .reduce((a, b) => a > b ? a : b);
                                      continueReadingChapterIndex =
                                          lastChapterKey;

                                      return Row(
                                        children: [
                                          Button_Info(
                                            text: "Đọc tiếp",
                                            backgroundColor: const Color(
                                                0xFF2E7D32), // Màu xanh lá đậm hơn
                                            foregroundColor: Colors.white,
                                            flex: 3,
                                            icon: Icons.play_arrow,
                                            ontap: () {
                                              if (chaptersReading.isNotEmpty) {
                                                // Tìm chương đã đọc cuối cùng
                                                final lastChapterKey =
                                                    chaptersReading.entries
                                                        .map((e) =>
                                                            int.tryParse(
                                                                e.key) ??
                                                            0)
                                                        .reduce((a, b) =>
                                                            a > b ? a : b);

                                                // Tìm index thực tế của chương trong mảng chapters
                                                final actualIndex = chapters
                                                    .indexWhere((chapter) {
                                                  // Chuyển đổi chapter.name thành số để so sánh
                                                  final chapterNumber =
                                                      int.tryParse(
                                                              chapter.name) ??
                                                          0;
                                                  return chapterNumber ==
                                                      lastChapterKey;
                                                });

                                                print(
                                                    'Tìm thấy chương $lastChapterKey ở index: $actualIndex');

                                                // Nếu tìm thấy chương trong danh sách
                                                if (actualIndex != -1) {
                                                  _navigateToChapter(
                                                      chapters[actualIndex],
                                                      actualIndex);
                                                } else {
                                                  // Trường hợp không tìm thấy chương, áp dụng cách đơn giản
                                                  final fallbackIndex =
                                                      (lastChapterKey - 1)
                                                          .clamp(
                                                              0,
                                                              chapters.length -
                                                                  1);
                                                  print(
                                                      'Không tìm thấy chương $lastChapterKey, sử dụng fallback index: $fallbackIndex');
                                                  _navigateToChapter(
                                                      chapters[fallbackIndex],
                                                      fallbackIndex);

                                                  // Hiển thị thông báo
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Không tìm thấy chương $lastChapterKey, mở chương gần nhất')),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 20),
                                          Button_Info(
                                            text: "Chương",
                                            backgroundColor: const Color(
                                                0xFF0277BD), // Màu xanh dương đậm
                                            foregroundColor: Colors.white,
                                            flex: 2,
                                            icon: Icons.format_list_bulleted,
                                            ontap: () {
                                              // Cuộn xuống phần danh sách chương
                                              Scrollable.ensureVisible(
                                                context,
                                                duration: const Duration(
                                                    milliseconds: 500),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                  }

                                  // Default buttons when no reading progress
                                  return Row(
                                    children: [
                                      Button_Info(
                                        text: "Đọc ngay",
                                        backgroundColor: const Color(
                                            0xFF2E7D32), // Màu xanh lá đậm hơn
                                        foregroundColor: Colors.white,
                                        flex: 1,
                                        icon: Icons.book,
                                        ontap: () {
                                          if (chapters.isNotEmpty) {
                                            _navigateToChapter(
                                                chapters.first, 0);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 20),
                                      Button_Info(
                                        text: "Chương",
                                        backgroundColor: const Color(
                                            0xFF0277BD), // Màu xanh dương đậm
                                        foregroundColor: Colors.white,
                                        flex: 1,
                                        icon: Icons.format_list_bulleted,
                                        ontap: () {
                                          // Cuộn xuống phần danh sách chương
                                          Scrollable.ensureVisible(
                                            context,
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              )
                            : Row(
                                children: [
                                  Button_Info(
                                    text: "Đọc ngay",
                                    backgroundColor: const Color(
                                        0xFF2E7D32), // Màu xanh lá đậm hơn
                                    foregroundColor: Colors.white,
                                    flex: 1,
                                    icon: Icons.book,
                                    ontap: () {
                                      if (chapters.isNotEmpty) {
                                        _navigateToChapter(chapters.first, 0);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  Button_Info(
                                    text: "Chương",
                                    backgroundColor: const Color(
                                        0xFF0277BD), // Màu xanh dương đậm
                                    foregroundColor: Colors.white,
                                    flex: 1,
                                    icon: Icons.format_list_bulleted,
                                    ontap: () {
                                      // Cuộn xuống phần danh sách chương
                                      Scrollable.ensureVisible(
                                        context,
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),

                      // Rating and Favorite widget
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: RateAllWidget(
                          idBook: widget.story.slug,
                          slug: widget.story.slug,
                          title: widget.story.title,
                          totalChapter: chapters.length,
                        ),
                      ),

                      // Description section
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       const Text(
                      //         'Giới thiệu',
                      //         style: TextStyle(
                      //           fontSize: 18,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       Text(storyDescription),
                      //     ],
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mô tả',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Phần mô tả rút gọn
                            Text(
                              storyDescription.isNotEmpty
                                  ? storyDescription
                                  : widget.story.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 4),

                            // Nút "Chi tiết"
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
                                            Text(
                                              'Tóm tắt đầy đủ',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 10),
                                            Divider(),
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
                                child: Text('Chi tiết'),
                              ),
                            )
                          ],
                        ),
                      ),

                      // Chapters section
                      if (chapters.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Danh sách chương',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('${chapters.length} chương'),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Hiển thị danh sách chương khác nhau cho truyện tranh và truyện chữ
                              widget.story.isNovel
                                  ? _buildNovelChaptersList()
                                  : _buildComicChaptersList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  // Hiển thị danh sách chương truyện chữ
  Widget _buildNovelChaptersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: readingProgressStream,
      builder: (context, snapshot) {
        // Khởi tạo map lưu tiến độ đọc
        final Map<String, num> readingProgress = {};

        // Lấy dữ liệu từ Firebase nếu có
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('chapters_reading') &&
              data['chapters_reading'] is Map) {
            // Chuyển đổi chapters_reading thành Map<String, num>
            final chaptersReading =
                data['chapters_reading'] as Map<String, dynamic>;
            chaptersReading.forEach((key, value) {
              // Lưu dạng: index -> phần trăm đọc (từ 0-100)
              if (value is num) {
                readingProgress[key] = value;
              } else if (value is Map && value.containsKey('progress')) {
                readingProgress[key] = value['progress'] ?? 0;
              }
            });
          }
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            // Tính toán phần trăm đã đọc (từ 0 đến 1)
            double readPercentage = 0.0;
            // Sửa lỗi: sử dụng (index + 1) để khớp với chapterNumber
            final chapterIndex = (index + 1).toString();

            if (readingProgress.containsKey(chapterIndex)) {
              readPercentage = readingProgress[chapterIndex]! / 100.0;
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Phần đã đọc
                    FractionallySizedBox(
                      widthFactor: readPercentage,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: Colors.blue.withOpacity(0.2),
                        height: 56, // Chiều cao của ListTile
                      ),
                    ),
                    // ListTile hiển thị thông tin chương
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          chapter.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        chapter.title.isEmpty
                            ? 'Chương ${chapter.name}'
                            : chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _navigateToChapter(chapter, index);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Hiển thị danh sách chương truyện tranh
  Widget _buildComicChaptersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: readingProgressStream,
      builder: (context, snapshot) {
        // Khởi tạo map lưu tiến độ đọc
        final Map<String, num> readingProgress = {};

        // Lấy dữ liệu từ Firebase nếu có
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data.containsKey('chapters_reading') &&
              data['chapters_reading'] is Map) {
            // Chuyển đổi chapters_reading thành Map<String, num>
            final chaptersReading =
                data['chapters_reading'] as Map<String, dynamic>;
            chaptersReading.forEach((key, value) {
              // Lưu dạng: index -> phần trăm đọc (từ 0-100)
              if (value is num) {
                readingProgress[key] = value;
              } else if (value is Map && value.containsKey('progress')) {
                readingProgress[key] = value['progress'] ?? 0;
              }
            });
          }
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            // Tính toán phần trăm đã đọc (từ 0 đến 1)
            double readPercentage = 0.0;
            // Sửa lỗi: sử dụng (index + 1) để khớp với chapterNumber
            final chapterIndex = (index + 1).toString();

            if (readingProgress.containsKey(chapterIndex)) {
              readPercentage = readingProgress[chapterIndex]! / 100.0;
            }

            return InkWell(
              onTap: () {
                _navigateToChapter(chapter, index);
              },
              borderRadius: BorderRadius.circular(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Nền ban đầu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Phần đã đọc
                    FractionallySizedBox(
                      widthFactor: readPercentage,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        color: Colors.green.withOpacity(0.5),
                      ),
                    ),
                    // Nội dung chương
                    Center(
                      child: Text(
                        'Chương ${chapter.name}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
