import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/highlight.dart';
import '../models/bookmark.dart';
import '../services/reading_service.dart';
import '../services/tts_service.dart';
import 'translate_popup.dart';

/// Widget văn bản có thể chọn với các tính năng nâng cao
/// Hỗ trợ highlight, bookmark, dịch thuật, TTS và menu ngữ cảnh
/// Được thiết kế để sử dụng trong ứng dụng đọc truyện
class SelectableTextWidget extends StatefulWidget {
  final String text; // Nội dung văn bản hiển thị
  final TextStyle style; // Kiểu dáng chữ
  final String storySlug; // Mã định danh của truyện
  final String chapterTitle; // Tiêu đề chương
  final int chapterNumber; // Số thứ tự chương
  final List<Highlight> highlights; // Danh sách các đoạn text đã được highlight
  final Function(Highlight) onHighlightAdded; // Callback khi thêm highlight mới
  final Function(Bookmark) onBookmarkAdded; // Callback khi thêm bookmark mới
  final Function(bool)?
      onTextSelectionChanged; // Callback khi thay đổi trạng thái chọn text
  final int? tempHighlightStart; // Vị trí bắt đầu highlight tạm thời
  final int? tempHighlightEnd; // Vị trí kết thúc highlight tạm thời
  final bool isHorizontalReading; // Chế độ đọc ngang (phân trang)
  final int pageIndex; // Chỉ số trang hiện tại
  final int
      pageStartInFullContent; // Vị trí bắt đầu trang trong toàn bộ nội dung
  final int? ttsHighlightStart; // Vị trí bắt đầu highlight TTS
  final int? ttsHighlightEnd; // Vị trí kết thúc highlight TTS

  const SelectableTextWidget({
    Key? key,
    required this.text,
    required this.style,
    required this.storySlug,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.highlights,
    required this.onHighlightAdded,
    required this.onBookmarkAdded,
    this.onTextSelectionChanged,
    this.tempHighlightStart,
    this.tempHighlightEnd,
    this.isHorizontalReading = false,
    this.pageIndex = 0,
    this.pageStartInFullContent = 0,
    this.ttsHighlightStart,
    this.ttsHighlightEnd,
  }) : super(key: key);

  @override
  State<SelectableTextWidget> createState() => _SelectableTextWidgetState();
}

/// State class cho SelectableTextWidget
/// Quản lý trạng thái lựa chọn văn bản và các tương tác người dùng
class _SelectableTextWidgetState extends State<SelectableTextWidget> {
  final ReadingService _readingService =
      ReadingService(); // Service quản lý đọc truyện
  final TTSService _ttsService = TTSService(); // Service text-to-speech
  String? _selectedText; // Văn bản được chọn
  int _selectionStart = -1; // Vị trí bắt đầu lựa chọn
  int _selectionEnd = -1; // Vị trí kết thúc lựa chọn
  Timer? _selectionDebounceTimer; // Timer để debounce sự kiện chọn text
  bool _isSelectionActive = false; // Trạng thái có đang chọn text hay không
  bool _isDragging = false; // Trạng thái có đang kéo để chọn text hay không

  @override
  void dispose() {
    _selectionDebounceTimer?.cancel();
    super.dispose();
  }

  /// Xử lý sự kiện thay đổi lựa chọn văn bản
  /// Quản lý trạng thái kéo và debounce cho hiệu suất tốt hơn
  void _handleSelectionChanged(
      TextSelection? selection, SelectionChangedCause? cause) {
    // Hủy timer trước đó
    _selectionDebounceTimer?.cancel();

    // Thiết lập trạng thái kéo dựa trên nguyên nhân
    _isDragging = cause == SelectionChangedCause.drag;

    if (selection != null && !selection.isCollapsed) {
      _selectionStart = selection.start;
      _selectionEnd = selection.end;
      _selectedText = widget.text.substring(selection.start, selection.end);
      _isSelectionActive = true;

      // Debounce thông báo thay đổi lựa chọn
      _selectionDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onTextSelectionChanged?.call(true);
        }
      });
    } else {
      _selectionStart = -1;
      _selectionEnd = -1;
      _selectedText = null;
      _isSelectionActive = false;
      _isDragging = false;

      // Thông báo ngay lập tức khi bỏ chọn
      widget.onTextSelectionChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _buildTextWithHighlights(),
      style: widget.style,
      onSelectionChanged: _handleSelectionChanged,
      // Cải thiện hành vi chọn text cho văn bản nhiều dòng
      scrollPhysics: const ClampingScrollPhysics(),
      textAlign: TextAlign.justify,
      contextMenuBuilder: (context, editableTextState) {
        // Luôn kiểm tra lựa chọn hợp lệ, ngay cả trong thao tác kéo
        final hasValidSelection = _selectedText != null &&
            _selectedText!.isNotEmpty &&
            _selectionStart != -1 &&
            _selectionEnd != -1 &&
            _isSelectionActive;

        if (hasValidSelection) {
          return _buildCompactContextMenu(context, editableTextState);
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Xây dựng TextSpan với các highlight và hiệu ứng đặc biệt
  /// Kết hợp highlight thường, highlight tạm thời và highlight TTS
  TextSpan _buildTextWithHighlights() {
    // Ghi log debug
    print('=== Debug _buildTextWithHighlights ===');
    print('Tổng số highlight nhận được: ${widget.highlights.length}');
    print(
        'Highlight tạm thời: ${widget.tempHighlightStart}-${widget.tempHighlightEnd}');
    print(
        'Highlight TTS: ${widget.ttsHighlightStart}-${widget.ttsHighlightEnd}');
    print('Độ dài văn bản: ${widget.text.length}');

    if (widget.highlights.isEmpty &&
        widget.tempHighlightStart == null &&
        widget.ttsHighlightStart == null &&
        widget.text.isEmpty) {
      print(
          'Không có highlight, highlight tạm thời, highlight TTS hoặc văn bản rỗng - trả về văn bản thuần');
      return TextSpan(text: widget.text, style: widget.style);
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;
    final textLength = widget.text.length;

    // Dữ liệu cho từng điểm trong văn bản
    List<Map<String, dynamic>> textSegments = [];

    // Đánh dấu vị trí bắt đầu và kết thúc của mỗi highlight
    for (final highlight in widget.highlights) {
      // Kiểm tra highlight có hợp lệ không
      if (highlight.startIndex < 0 ||
          highlight.endIndex > textLength ||
          highlight.startIndex >= highlight.endIndex) {
        continue;
      }

      textSegments.add({
        'position': highlight.startIndex,
        'isStart': true,
        'color': highlight.color,
        'type': 'highlight',
      });

      textSegments.add({
        'position': highlight.endIndex,
        'isStart': false,
        'color': highlight.color,
        'type': 'highlight',
      });
    }

    // Thêm temporary highlight nếu có
    if (widget.tempHighlightStart != null &&
        widget.tempHighlightEnd != null &&
        widget.tempHighlightStart! >= 0 &&
        widget.tempHighlightEnd! <= textLength &&
        widget.tempHighlightStart! < widget.tempHighlightEnd!) {
      textSegments.add({
        'position': widget.tempHighlightStart!,
        'isStart': true,
        'color': '0xFFFF5722',
        'type': 'temp',
      });

      textSegments.add({
        'position': widget.tempHighlightEnd!,
        'isStart': false,
        'color': '0xFFFF5722',
        'type': 'temp',
      });
    }

    // Thêm TTS highlight nếu có
    if (widget.ttsHighlightStart != null &&
        widget.ttsHighlightEnd != null &&
        widget.ttsHighlightStart! >= 0 &&
        widget.ttsHighlightEnd! <= textLength &&
        widget.ttsHighlightStart! < widget.ttsHighlightEnd!) {
      textSegments.add({
        'position': widget.ttsHighlightStart!,
        'isStart': true,
        'color': '0xFF2196F3', // Blue color for TTS
        'type': 'tts',
      });

      textSegments.add({
        'position': widget.ttsHighlightEnd!,
        'isStart': false,
        'color': '0xFF2196F3', // Blue color for TTS
        'type': 'tts',
      });
    }

    // Sắp xếp các phân đoạn theo vị trí
    textSegments.sort((a, b) => a['position'].compareTo(b['position']));

    // Danh sách các màu highlight hiện tại với loại
    List<Map<String, dynamic>> activeHighlights = [];

    int lastPosition = 0;

    // Tạo spans từ các phân đoạn
    for (int i = 0; i < textSegments.length; i++) {
      final segment = textSegments[i];
      final position = segment['position'] as int;

      // Thêm văn bản từ vị trí cuối cùng đến vị trí hiện tại
      if (position > lastPosition) {
        String textPart = widget.text.substring(lastPosition, position);

        if (activeHighlights.isEmpty) {
          // Không có highlight
          spans.add(TextSpan(
            text: textPart,
            style: widget.style,
          ));
        } else {
          // Có highlight - ưu tiên TTS highlight nếu có
          Map<String, dynamic> primaryHighlight = activeHighlights.last;

          // Tìm TTS highlight nếu có (ưu tiên cao nhất)
          for (final h in activeHighlights) {
            if (h['type'] == 'tts') {
              primaryHighlight = h;
              break;
            }
          }

          String currentColor = primaryHighlight['color'] as String;

          int colorValue;
          if (currentColor.startsWith('0x')) {
            colorValue = int.parse(currentColor.substring(2), radix: 16);
          } else {
            colorValue = int.parse(currentColor, radix: 16);
          }

          // Sử dụng màu nền nhạt hơn cho TTS để dễ đọc
          Color backgroundColor = Color(colorValue);
          if (primaryHighlight['type'] == 'tts') {
            backgroundColor =
                backgroundColor.withOpacity(0.3); // Nhạt hơn cho TTS
          }

          spans.add(TextSpan(
            text: textPart,
            style: widget.style.copyWith(
              backgroundColor: backgroundColor,
              // Thêm border cho TTS để dễ nhận biết
              decoration: primaryHighlight['type'] == 'tts'
                  ? TextDecoration.underline
                  : null,
              decorationColor:
                  primaryHighlight['type'] == 'tts' ? Colors.blue : null,
              decorationThickness:
                  primaryHighlight['type'] == 'tts' ? 2.0 : null,
            ),
          ));
        }

        lastPosition = position;
      }

      // Cập nhật danh sách highlight hiện tại
      if (segment['isStart'] as bool) {
        // Bắt đầu highlight mới
        activeHighlights.add({
          'color': segment['color'] as String,
          'type': segment['type'] as String,
        });
      } else {
        // Kết thúc highlight
        activeHighlights.removeWhere((h) =>
            h['color'] == segment['color'] && h['type'] == segment['type']);
      }
    }

    // Thêm phần văn bản còn lại
    if (lastPosition < textLength) {
      spans.add(TextSpan(
        text: widget.text.substring(lastPosition),
        style: widget.style,
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildCompactContextMenu(
      BuildContext context, EditableTextState editableTextState) {
    if (_selectedText == null || _selectedText!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Tạo một thanh công cụ gọn gàng và cân bằng
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        // Nút copy
        ContextMenuButtonItem(
          onPressed: () => _copyText(_selectedText!),
          label: '📋 Copy',
        ),

        // Nút dịch
        ContextMenuButtonItem(
          onPressed: () => _translateText(_selectedText!),
          label: '🌐 Dịch',
        ),

        // Nút tìm kiếm
        ContextMenuButtonItem(
          onPressed: () => _searchGoogle(_selectedText!),
          label: '🔍 Tìm kiếm',
        ),

        // Nút highlight
        ContextMenuButtonItem(
          onPressed: () => _showHighlightColors(_selectedText!, context),
          label: '🎨 Hightlight',
        ),

        // Nút bookmark
        ContextMenuButtonItem(
          onPressed: () => _addBookmark(_selectedText!, context),
          label: '📑 Bookmark',
        ),

        // Nút TTS
        ContextMenuButtonItem(
          onPressed: () => _speakSelectedText(_selectedText!),
          label: '🎧 Nghe',
        ),
      ],
    );
  }

  /// Sao chép văn bản đã chọn vào clipboard
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));

    // Sử dụng Future.microtask để tránh xung đột điều hướng
    Future.microtask(() {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã copy vào clipboard')),
        );
      }
    });

    // Xóa lựa chọn văn bản
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  /// Dịch văn bản đã chọn bằng Google Translate
  void _translateText(String text) async {
    // Xóa lựa chọn văn bản trước
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    try {
      // Hiển thị popup dịch trực tiếp
      Future.microtask(() {
        if (mounted) {
          showTranslatePopup(context, text);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã mở Google Dịch')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dịch: $e')),
        );
      }
    }
  }

  /// Tìm kiếm văn bản đã chọn trên Google
  void _searchGoogle(String text) async {
    // Xóa lựa chọn văn bản trước
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    try {
      await _readingService.searchOnGoogle(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã mở Google Search')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tìm kiếm: $e')),
        );
      }
    }
  }

  /// Hiển thị bảng chọn màu highlight
  void _showHighlightColors(String selectedText, BuildContext context) async {
    // Debug thông tin lựa chọn đã capture
    print('=== Debug _showHighlightColors ===');
    print('Văn bản đã chọn: "$selectedText"');
    print('Vị trí capture: bắt đầu=$_selectionStart, kết thúc=$_selectionEnd');

    // Sử dụng lựa chọn đã capture
    final startIndex = _selectionStart;
    final endIndex = _selectionEnd;

    print(
        'Sử dụng lựa chọn: bắt đầu=$startIndex, kết thúc=$endIndex, văn bản="$selectedText"');

    // Xóa lựa chọn văn bản trước
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    // Hiển thị bộ chọn màu dưới dạng bottom sheet thay vì dialog đầy đủ
    Future.microtask(() {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chọn màu highlight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ReadingService.highlightColors.map((colorData) {
                    return GestureDetector(
                      onTap: () {
                        _addHighlight(
                            selectedText, startIndex, endIndex, colorData);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorData['color']),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[300]!, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    });
  }

  /// Thêm highlight mới cho văn bản đã chọn
  void _addHighlight(String selectedText, int startIndex, int endIndex,
      Map<String, dynamic> colorData) async {
    print('Chỉ số tương đối trang: bắt đầu=$startIndex, kết thúc=$endIndex');
    print('Đọc ngang: ${widget.isHorizontalReading}');
    print('Chỉ số trang: ${widget.pageIndex}');
    print(
        'Bắt đầu trang trong toàn bộ nội dung: ${widget.pageStartInFullContent}');

    // Chuyển đổi vị trí tương đối trang thành vị trí toàn bộ nội dung cho đọc ngang
    int fullContentStart = startIndex;
    int fullContentEnd = endIndex;

    if (widget.isHorizontalReading) {
      fullContentStart = widget.pageStartInFullContent + startIndex;
      fullContentEnd = widget.pageStartInFullContent + endIndex;
      print(
          'Đã chuyển đổi thành chỉ số toàn bộ nội dung: bắt đầu=$fullContentStart, kết thúc=$fullContentEnd');
    }

    // Kiểm tra highlight đã tồn tại
    bool hasOverlappingHighlight = false;
    List<Highlight> overlappingHighlights = [];

    for (var highlight in widget.highlights) {
      // Kiểm tra các trường hợp chồng lấn
      bool isOverlapping = (fullContentStart <= highlight.endIndex &&
          fullContentEnd >= highlight.startIndex);

      if (isOverlapping) {
        overlappingHighlights.add(highlight);
        hasOverlappingHighlight = true;
      }
    }

    // Xóa highlight cũ nếu có chồng lấn
    if (hasOverlappingHighlight) {
      for (var highlight in overlappingHighlights) {
        await _readingService.removeHighlight(highlight.id);
      }
    }

    final highlight = Highlight(
      id: _readingService.generateId(),
      text: selectedText,
      chapterTitle: widget.chapterTitle,
      chapterNumber: widget.chapterNumber,
      storySlug: widget.storySlug,
      startIndex: fullContentStart,
      endIndex: fullContentEnd,
      color: '0x${colorData['color'].toRadixString(16).padLeft(8, '0')}',
      createdAt: DateTime.now(),
    );

    await _readingService.addHighlight(highlight);
    widget.onHighlightAdded(highlight);

    if (mounted) {
      String message = hasOverlappingHighlight
          ? 'Đã cập nhật highlight sang màu ${colorData['name']}'
          : 'Đã highlight với màu ${colorData['name']}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Thêm bookmark cho văn bản đã chọn
  void _addBookmark(String selectedText, BuildContext context) async {
    print('=== Đang thêm bookmark ===');
    print(
        'Chỉ số tương đối trang: bắt đầu=$_selectionStart, kết thúc=$_selectionEnd');
    print('Đọc ngang: ${widget.isHorizontalReading}');
    print('Chỉ số trang: ${widget.pageIndex}');
    print(
        'Bắt đầu trang trong toàn bộ nội dung: ${widget.pageStartInFullContent}');

    // Sử dụng lựa chọn đã capture
    final startIndex = _selectionStart;
    final endIndex = _selectionEnd;

    // Chuyển đổi vị trí tương đối trang thành vị trí toàn bộ nội dung cho đọc ngang
    int fullContentStart = startIndex;
    int fullContentEnd = endIndex;

    if (widget.isHorizontalReading) {
      fullContentStart = widget.pageStartInFullContent + startIndex;
      fullContentEnd = widget.pageStartInFullContent + endIndex;
      print(
          'Đã chuyển đổi thành chỉ số toàn bộ nội dung: bắt đầu=$fullContentStart, kết thúc=$fullContentEnd');
    }

    final bookmark = Bookmark(
      id: _readingService.generateId(),
      text: selectedText,
      chapterTitle: widget.chapterTitle,
      chapterNumber: widget.chapterNumber,
      storySlug: widget.storySlug,
      startIndex: fullContentStart,
      endIndex: fullContentEnd,
      createdAt: DateTime.now(),
    );

    await _readingService.addBookmark(bookmark);
    widget.onBookmarkAdded(bookmark);

    // Xóa lựa chọn văn bản sau khi tạo bookmark
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm bookmark')),
      );
    }
  }

  /// Đọc to văn bản đã chọn bằng TTS
  void _speakSelectedText(String text) async {
    final displayText = text.length > 50 ? text.substring(0, 50) + "..." : text;
    print('Phương thức _speakSelectedText được gọi với: "$displayText"');

    // Xóa lựa chọn văn bản trước
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    try {
      print('Đang gọi _ttsService.speakText...');
      await _ttsService.speakText(text);
      if (mounted) {
        print('TTS đọc hoàn thành thành công');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang nghe văn bản...')),
        );
      }
    } catch (e) {
      print('Lỗi trong _speakSelectedText: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi nghe: $e')),
        );
      }
    }
  }
}
