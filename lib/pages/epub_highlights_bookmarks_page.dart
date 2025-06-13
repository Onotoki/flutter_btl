import 'package:flutter/material.dart';
import '../models/epub_highlight.dart';
import '../models/epub_bookmark.dart';
import '../services/epub_reading_service.dart';

/// Trang hiển thị danh sách highlights (đoạn văn bản được tô sáng) và bookmarks (dấu trang) của sách EPUB
/// Cho phép người dùng xem, chỉnh sửa ghi chú và xóa các highlights/bookmarks đã lưu
class EpubHighlightsBookmarksPage extends StatefulWidget {
  final String bookId; // ID của cuốn sách
  final String bookTitle; // Tiêu đề cuốn sách
  final VoidCallback? onRefresh; // Callback được gọi khi cần refresh dữ liệu

  const EpubHighlightsBookmarksPage({
    Key? key,
    required this.bookId,
    required this.bookTitle,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<EpubHighlightsBookmarksPage> createState() =>
      _EpubHighlightsBookmarksPageState();
}

/// State class cho trang highlights và bookmarks
/// Sử dụng TabController để chuyển đổi giữa 2 tab: highlights và bookmarks
class _EpubHighlightsBookmarksPageState
    extends State<EpubHighlightsBookmarksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Controller cho TabBar
  final EpubReadingService _readingService =
      EpubReadingService(); // Service để thao tác với dữ liệu đọc sách
  List<EpubHighlight> _highlights = []; // Danh sách các highlights
  List<EpubBookmark> _bookmarks = []; // Danh sách các bookmarks
  bool _isLoading = true; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 2 tab
    _tabController = TabController(length: 2, vsync: this);
    // Tải dữ liệu khi widget được khởi tạo
    _loadData();
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên khi widget bị hủy
    _tabController.dispose();
    super.dispose();
  }

  /// Phương thức tải dữ liệu highlights và bookmarks từ service
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Lấy danh sách highlights và bookmarks từ service
      final highlights = await _readingService.getHighlights(widget.bookId);
      final bookmarks = await _readingService.getBookmarks(widget.bookId);

      setState(() {
        _highlights = highlights;
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Hiển thị thông báo lỗi nếu không tải được dữ liệu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookTitle} - Ghi chú'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.highlight), text: 'Đoạn tô sáng'),
            Tab(icon: Icon(Icons.bookmark), text: 'Dấu trang'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHighlightsTab(),
                _buildBookmarksTab(),
              ],
            ),
    );
  }

  /// Xây dựng tab hiển thị danh sách highlights
  Widget _buildHighlightsTab() {
    // Hiển thị thông báo khi chưa có highlights nào
    if (_highlights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.highlight_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có đoạn tô sáng nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Chọn văn bản và tô sáng để lưu lại',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Nhóm các highlights theo số trang để hiển thị
    final groupedHighlights = <int, List<EpubHighlight>>{};
    for (final highlight in _highlights) {
      groupedHighlights
          .putIfAbsent(highlight.pageNumber, () => [])
          .add(highlight);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedHighlights.length,
      itemBuilder: (context, index) {
        final pageNumber = groupedHighlights.keys.elementAt(index);
        final highlights = groupedHighlights[pageNumber]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header hiển thị số trang và nút điều hướng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trang $pageNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.launch, size: 20),
                      onPressed: () {
                        // TODO: Điều hướng đến trang cụ thể trong trình đọc EPUB
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Điều hướng đến trang $pageNumber')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Hiển thị danh sách highlights trong trang
              ...highlights.map((highlight) => _buildHighlightItem(highlight)),
            ],
          ),
        );
      },
    );
  }

  /// Xây dựng widget hiển thị một highlight item
  Widget _buildHighlightItem(EpubHighlight highlight) {
    // Chuyển đổi mã màu hex thành Color object
    final color =
        Color(int.parse(highlight.color.substring(2), radix: 16) + 0xFF000000);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container hiển thị nội dung highlight với màu nền
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              highlight.content,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Hiển thị ghi chú nếu có
          if (highlight.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Text(
                'Ghi chú: ${highlight.note}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Row chứa thời gian tạo và các nút hành động
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(highlight.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              // Nút chỉnh sửa ghi chú
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _editHighlightNote(highlight),
              ),
              // Nút xóa highlight
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteHighlight(highlight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng tab hiển thị danh sách bookmarks
  Widget _buildBookmarksTab() {
    // Hiển thị thông báo khi chưa có bookmarks nào
    if (_bookmarks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có dấu trang nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Chọn văn bản và đánh dấu trang để lưu lại',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Nhóm các bookmarks theo số trang để hiển thị
    final groupedBookmarks = <int, List<EpubBookmark>>{};
    for (final bookmark in _bookmarks) {
      groupedBookmarks.putIfAbsent(bookmark.pageNumber, () => []).add(bookmark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedBookmarks.length,
      itemBuilder: (context, index) {
        final pageNumber = groupedBookmarks.keys.elementAt(index);
        final bookmarks = groupedBookmarks[pageNumber]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header hiển thị số trang và nút điều hướng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trang $pageNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.launch, size: 20),
                      onPressed: () {
                        // TODO: Điều hướng đến trang cụ thể trong trình đọc EPUB
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Điều hướng đến trang $pageNumber')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Hiển thị danh sách bookmarks trong trang
              ...bookmarks.map((bookmark) => _buildBookmarkItem(bookmark)),
            ],
          ),
        );
      },
    );
  }

  /// Xây dựng widget hiển thị một bookmark item
  Widget _buildBookmarkItem(EpubBookmark bookmark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container hiển thị nội dung bookmark với icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookmark.content,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Hiển thị ghi chú nếu có
          if (bookmark.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bookmark.note,
              style: TextStyle(
                  color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          // Row chứa thời gian tạo và các nút hành động
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(bookmark.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              // Nút chỉnh sửa ghi chú
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _editBookmarkNote(bookmark),
              ),
              // Nút xóa bookmark
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => _deleteBookmark(bookmark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Định dạng ngày tháng để hiển thị
  /// Trả về chuỗi có định dạng: dd/mm/yyyy hh:mm
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Hiển thị dialog xác nhận xóa highlight
  void _deleteHighlight(EpubHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đoạn tô sáng'),
        content:
            const Text('Bạn có chắc chắn muốn xóa đoạn tô sáng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Xóa highlight thông qua service
              await _readingService.removeHighlight(highlight.id);
              setState(() {
                _highlights.removeWhere((h) => h.id == highlight.id);
              });
              Navigator.pop(context);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa đoạn tô sáng')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog xác nhận xóa bookmark
  void _deleteBookmark(EpubBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dấu trang'),
        content: const Text('Bạn có chắc chắn muốn xóa dấu trang này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Xóa bookmark thông qua service
              await _readingService.removeBookmark(bookmark.id);
              setState(() {
                _bookmarks.removeWhere((b) => b.id == bookmark.id);
              });
              Navigator.pop(context);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa dấu trang')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog chỉnh sửa ghi chú của highlight
  void _editHighlightNote(EpubHighlight highlight) {
    final controller = TextEditingController(text: highlight.note);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa ghi chú đoạn tô sáng'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Tạo highlight mới với ghi chú đã cập nhật
              final updatedHighlight = EpubHighlight(
                id: highlight.id,
                bookId: highlight.bookId,
                content: highlight.content,
                pageNumber: highlight.pageNumber,
                pageId: highlight.pageId,
                rangy: highlight.rangy,
                note: controller.text,
                color: highlight.color,
                createdAt: highlight.createdAt,
              );

              // Xóa highlight cũ và thêm highlight mới (do không có phương thức update)
              await _readingService.removeHighlight(highlight.id);
              await _readingService.addHighlight(updatedHighlight);

              setState(() {
                final index =
                    _highlights.indexWhere((h) => h.id == highlight.id);
                if (index != -1) {
                  _highlights[index] = updatedHighlight;
                }
              });

              Navigator.pop(context);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật ghi chú')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog chỉnh sửa ghi chú của bookmark
  void _editBookmarkNote(EpubBookmark bookmark) {
    final controller = TextEditingController(text: bookmark.note);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa ghi chú dấu trang'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // Tạo bookmark mới với ghi chú đã cập nhật
              final updatedBookmark = EpubBookmark(
                id: bookmark.id,
                bookId: bookmark.bookId,
                content: bookmark.content,
                pageNumber: bookmark.pageNumber,
                pageId: bookmark.pageId,
                href: bookmark.href,
                cfi: bookmark.cfi,
                note: controller.text,
                createdAt: bookmark.createdAt,
              );

              // Xóa bookmark cũ và thêm bookmark mới (do không có phương thức update)
              await _readingService.removeBookmark(bookmark.id);
              await _readingService.addBookmark(updatedBookmark);

              setState(() {
                final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
                if (index != -1) {
                  _bookmarks[index] = updatedBookmark;
                }
              });

              Navigator.pop(context);
              widget.onRefresh?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật ghi chú')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
