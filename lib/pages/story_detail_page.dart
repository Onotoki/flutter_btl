import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_widget.dart';
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

// để thực hiện đánh giá và comment có 2 trường hợp
// th1: chưa có bất cứ ai comment hay đánh giá(khi có người đầu tiên thực hiện thì sẽ gửi id sách kèm thông tin comment hay đánh lên firebase)
// th2: đã comment hoặc đánh giá (kéo về để hiển thị và thêm mới)
// Kiểm tra xem id của sách đã có trên firebase chưa - nếu chưa hiển thị chưa có đánh giá, comment - nếu có thì kéo về hiển thị

class _StoryDetailPageState extends State<StoryDetailPage> {
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> comicDetail = {};
  List<Chapter> chapters = [];
  String debugInfo = '';
  String storyDescription = '';

  @override
  void initState() {
    super.initState();
    storyDescription = widget.story.description; // Lưu mô tả ban đầu
    _loadComicDetail();
  }

  Future<void> _loadComicDetail() async {
    String logs = '';
    try {
      logs += 'Đang tải thông tin chi tiết truyện: ${widget.story.slug}\n';

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

  @override
  Widget build(BuildContext context) {
    //Hàm tính kích thước ảnh responsive theo màn hình
    Size _getResponsiveSize(BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final width = (screenWidth - 40) / 3; // trừ padding + khoảng cách
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
                      // Debug info button
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Button_Info(
                              text: 'Đọc ngay',
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              flex: 3,
                              ontap: () {},
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Button_Info(
                              text: 'Chương',
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              flex: 2,
                              ontap: () {},
                            )
                          ],
                        ),
                      ),

                      // Description
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
                                child: Text(
                                  'Chi tiết',
                                  style: TextStyle(color: Colors.green[300]),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      RateAllWidget(
                        idBook: widget.story.id,
                      ),
                      Divider(),
                      // Chapters list
                      // Danh sách chương dạng Grid

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Danh sách chương',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (chapters.isEmpty)
                              const Center(child: Text('Không có chương nào'))
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: chapters.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  mainAxisExtent: 40, // chiều cao mỗi ô
                                ),
                                itemBuilder: (context, index) {
                                  final chapter = chapters[index];
                                  final chapterTitle = _getChapterTitle(
                                      chapter); // ví dụ: 'Chương 1'

                                  return GestureDetector(
                                    onTap: () {
                                      if (chapter.apiData.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChapterPage(
                                              storySlug: widget.story.slug,
                                              chapterApiData: chapter.apiData,
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
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          chapterTitle,
                                          style: TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
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

  // Helper method để tạo tiêu đề chương
  String _getChapterTitle(Chapter chapter) {
    final number = _getChapterNumber(chapter.name);
    final title = chapter.title.isNotEmpty ? chapter.title : '';

    if (number > 0) {
      return title.isNotEmpty ? 'Chương $number: $title' : 'Chương $number';
    } else {
      return title.isNotEmpty ? title : chapter.name;
    }
  }

  // Chuyển đổi tên chương thành số
  int _getChapterNumber(String chapterName) {
    // Giữ lại phần số từ tên chương (ví dụ: "10", "10.5")
    final numberPattern = RegExp(r'^(\d+(\.\d+)?)');
    final match = numberPattern.firstMatch(chapterName);
    if (match != null && match.group(1) != null) {
      try {
        return double.parse(match.group(1)!).toInt();
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}
