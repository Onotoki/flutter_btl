// Import các thư viện cần thiết
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget hiển thị popup dịch văn bản bằng WebView (Google Translate)
class TranslatePopup extends StatefulWidget {
  final String text; // Văn bản cần dịch
  final String sourceLang; // Ngôn ngữ gốc (mặc định: 'auto' = tự phát hiện)
  final String targetLang; // Ngôn ngữ đích (mặc định: 'vi' = tiếng Việt)

  const TranslatePopup({
    Key? key,
    required this.text,
    this.sourceLang = 'auto',
    this.targetLang = 'vi',
  }) : super(key: key);

  @override
  State<TranslatePopup> createState() => _TranslatePopupState();
}

class _TranslatePopupState extends State<TranslatePopup> {
  late final WebViewController _controller; // Bộ điều khiển WebView
  bool _isLoading = true; // Cờ kiểm tra trạng thái đang tải

  @override
  void initState() {
    super.initState();
    _initializeWebView(); // Khởi tạo và tải WebView khi widget bắt đầu
  }

  /// Khởi tạo WebView và nạp URL Google Translate
  void _initializeWebView() {
    // Mã hóa văn bản đầu vào để đưa vào URL
    final encodedText = Uri.encodeComponent(widget.text);

    // Tạo URL Google Translate với các tham số ngôn ngữ và văn bản
    final translateUrl =
        'https://translate.google.com/?sl=${widget.sourceLang}&tl=${widget.targetLang}&text=$encodedText&op=translate';

    // Cấu hình WebView
    _controller = WebViewController()
      //Bật JavaScript để trang web hoạt động đúng
      ..setJavaScriptMode(
          JavaScriptMode.unrestricted) // Cho phép chạy JavaScript
      //Quản lý các sự kiện khi điều hướng/truy cập trang web
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Có thể hiển thị tiến trình nếu cần
          },
          onPageStarted: (String url) {
            // Khi bắt đầu tải trang
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // Khi tải trang xong
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Xử lý khi xảy ra lỗi tải trang
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(translateUrl)); // Tải URL vào WebView
  }

  /// Xây dựng giao diện chính của hộp thoại
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Làm trong suốt nền ngoài
      insetPadding: const EdgeInsets.all(16), // Khoảng cách với viền màn hình
      child: Container(
        width:
            MediaQuery.of(context).size.width * 0.95, // 95% chiều rộng màn hình
        height:
            MediaQuery.of(context).size.height * 0.8, // 80% chiều cao màn hình
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Đổ bóng nhẹ
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ---------- HEADER ----------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, color: Colors.white), // Icon dịch
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Google Dịch', // Tiêu đề
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Nút đóng hộp thoại
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(), // Đóng dialog
                  ),
                ],
              ),
            ),

            // ---------- HIỂN THỊ VĂN BẢN GỐC ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Văn bản gốc:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Cắt văn bản nếu dài quá 100 ký tự
                  Text(
                    widget.text.length > 100
                        ? '${widget.text.substring(0, 100)}...'
                        : widget.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- WEBVIEW DỊCH ----------
            Expanded(
              child: Stack(
                children: [
                  // WebView chính (bọc bo góc dưới)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: WebViewWidget(
                        controller: _controller), // Hiển thị Google Translate
                  ),

                  // Hiển thị overlay loading khi đang tải
                  if (_isLoading)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(), // Vòng tròn loading
                            SizedBox(height: 16),
                            Text(
                              'Đang tải Google Dịch...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàm tiện ích để gọi hiển thị popup dịch
void showTranslatePopup(BuildContext context, String text) {
  showDialog(
    context: context,
    barrierDismissible: true, // Cho phép đóng khi bấm ra ngoài
    builder: (context) => TranslatePopup(
      text: text,
      sourceLang: 'auto', // Tự phát hiện ngôn ngữ gốc
      targetLang: 'vi', // Dịch sang tiếng Việt
    ),
  );
}
