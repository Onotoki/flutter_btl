import 'package:flutter/material.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';
import '../services/reading_service.dart';

class HighlightsBookmarksPage extends StatefulWidget {
  final String storySlug;
  final String storyTitle;
  final Function(int chapterNumber)? onNavigateToChapter;
  final Function(Bookmark bookmark)? onNavigateToBookmark;
  final Function(Highlight highlight)? onNavigateToHighlight;

  const HighlightsBookmarksPage({
    Key? key,
    required this.storySlug,
    required this.storyTitle,
    this.onNavigateToChapter,
    this.onNavigateToBookmark,
    this.onNavigateToHighlight,
  }) : super(key: key);

  @override
  State<HighlightsBookmarksPage> createState() =>
      _HighlightsBookmarksPageState();
}

class _HighlightsBookmarksPageState extends State<HighlightsBookmarksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReadingService _readingService = ReadingService();
  List<Highlight> _highlights = [];
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final highlights = await _readingService.getHighlights(widget.storySlug);
      final bookmarks = await _readingService.getBookmarks(widget.storySlug);

      setState(() {
        _highlights = highlights;
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.storyTitle} - Ghi chú'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.highlight), text: 'Highlights'),
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarks'),
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

  Widget _buildHighlightsTab() {
    if (_highlights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.highlight_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có highlight nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Chọn text và highlight để lưu lại',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group highlights by chapter
    final groupedHighlights = <int, List<Highlight>>{};
    for (final highlight in _highlights) {
      groupedHighlights
          .putIfAbsent(highlight.chapterNumber, () => [])
          .add(highlight);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedHighlights.length,
      itemBuilder: (context, index) {
        final chapterNumber = groupedHighlights.keys.elementAt(index);
        final highlights = groupedHighlights[chapterNumber]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        highlights.first.chapterTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.launch, size: 20),
                      onPressed: () {
                        if (widget.onNavigateToChapter != null) {
                          widget.onNavigateToChapter!(chapterNumber);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              ...highlights.map((highlight) => _buildHighlightItem(highlight)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightItem(Highlight highlight) {
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
          InkWell(
            onTap: () {
              // Navigate to highlight position first, then pop
              if (widget.onNavigateToHighlight != null) {
                Navigator.pop(context); // Pop highlights page first
                // Use a slight delay to ensure navigation completes
                Future.delayed(const Duration(milliseconds: 100), () {
                  widget.onNavigateToHighlight!(highlight);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.highlight, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      highlight.text,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(highlight.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
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

  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có bookmark nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Chọn text và bookmark để lưu lại',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group bookmarks by chapter
    final groupedBookmarks = <int, List<Bookmark>>{};
    for (final bookmark in _bookmarks) {
      groupedBookmarks
          .putIfAbsent(bookmark.chapterNumber, () => [])
          .add(bookmark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedBookmarks.length,
      itemBuilder: (context, index) {
        final chapterNumber = groupedBookmarks.keys.elementAt(index);
        final bookmarks = groupedBookmarks[chapterNumber]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        bookmarks.first.chapterTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.launch, size: 20),
                      onPressed: () {
                        if (widget.onNavigateToChapter != null) {
                          widget.onNavigateToChapter!(chapterNumber);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
              ...bookmarks.map((bookmark) => _buildBookmarkItem(bookmark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              // Navigate to bookmark position first, then pop
              if (widget.onNavigateToBookmark != null) {
                Navigator.pop(context); // Pop highlights page first
                // Use a slight delay to ensure navigation completes
                Future.delayed(const Duration(milliseconds: 100), () {
                  widget.onNavigateToBookmark!(bookmark);
                });
              }
            },
            child: Container(
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
                      bookmark.text,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.blue),
                ],
              ),
            ),
          ),
          if (bookmark.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bookmark.note,
              style: TextStyle(
                  color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(bookmark.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                onPressed: () => _editBookmarkNote(bookmark),
              ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _deleteHighlight(Highlight highlight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa highlight'),
        content: const Text('Bạn có chắc muốn xóa highlight này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await _readingService.removeHighlight(highlight.id);
              setState(() {
                _highlights.removeWhere((h) => h.id == highlight.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa highlight')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _deleteBookmark(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bookmark'),
        content: const Text('Bạn có chắc muốn xóa bookmark này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await _readingService.removeBookmark(bookmark.id);
              setState(() {
                _bookmarks.removeWhere((b) => b.id == bookmark.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa bookmark')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _editBookmarkNote(Bookmark bookmark) {
    final controller = TextEditingController(text: bookmark.note);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa ghi chú'),
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
              // Update bookmark note (you might need to add this method to ReadingService)
              // For now, we'll just update the local state
              final updatedBookmark = Bookmark(
                id: bookmark.id,
                text: bookmark.text,
                chapterTitle: bookmark.chapterTitle,
                chapterNumber: bookmark.chapterNumber,
                storySlug: bookmark.storySlug,
                startIndex: bookmark.startIndex,
                endIndex: bookmark.endIndex,
                note: controller.text,
                createdAt: bookmark.createdAt,
              );

              setState(() {
                final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
                if (index != -1) {
                  _bookmarks[index] = updatedBookmark;
                }
              });

              Navigator.pop(context);
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
