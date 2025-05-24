import 'package:btl/api/otruyen_api.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChapterPage extends StatefulWidget {
  final String storySlug;
  final String chapterTitle;
  final int chapterNumber;
  final String chapterApiData; // API URL để tải nội dung chương

  const ChapterPage({
    super.key,
    required this.storySlug,
    required this.chapterApiData,
    required this.chapterTitle,
    required this.chapterNumber,
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

  @override
  void initState() {
    super.initState();
    _loadChapterContent();
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
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.fitWidth,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.image_not_supported),
                                        const SizedBox(height: 8),
                                        const Text('Không thể tải ảnh',
                                            style: TextStyle(fontSize: 14)),
                                        Text(
                                          imageUrl.length > 50
                                              ? '${imageUrl.substring(0, 50)}...'
                                              : imageUrl,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
