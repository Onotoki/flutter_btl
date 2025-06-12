import 'package:flutter/material.dart';
import '../api/otruyen_api.dart';
import '../models/story.dart';
import '../models/highlight.dart';
import '../models/bookmark.dart';
import '../services/reading_service.dart';
import '../services/reading_settings_service.dart';
import '../services/chapter_cache_service.dart';
import '../components/selectable_text_widget.dart';
import 'highlights_bookmarks_page.dart';

class EpubChapterPage extends StatefulWidget {
  final Story story;
  final int chapterNumber;
  final String chapterTitle;
  final int? initialScrollPosition;
  final String? searchText;
  final String? bookmarkText; // For bookmark highlighting

  const EpubChapterPage({
    Key? key,
    required this.story,
    required this.chapterNumber,
    required this.chapterTitle,
    this.initialScrollPosition,
    this.searchText,
    this.bookmarkText, // For bookmark highlighting
  }) : super(key: key);

  @override
  State<EpubChapterPage> createState() => _EpubChapterPageState();
}

class _EpubChapterPageState extends State<EpubChapterPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _chapterData;
  List<Map<String, dynamic>> _allChapters = [];
  bool _settingsLoaded = false;

  // Services
  final ReadingSettingsService _settingsService = ReadingSettingsService();
  final ChapterCacheService _cacheService = ChapterCacheService();
  final ReadingService _readingService = ReadingService();

  // Reading settings - sẽ được load từ SharedPreferences
  double _fontSize = 16.0;
  double _lineHeight = 1.6;
  String _fontFamily = 'Roboto';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  bool _isFullScreen = false;
  bool _isHorizontalReading = false;
  List<String> _pages = [];
  int _currentPageIndex = 0;
  late ScrollController _scrollController;
  late PageController _pageController;

  // Reading progress tracking
  double _readingProgress = 0.0; // Percentage of chapter read

  // Highlights and bookmarks
  List<Highlight> _highlights = [];
  List<Bookmark> _bookmarks = [];

  // Search functionality
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  int _currentSearchIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  bool _isGlobalSearch =
      false; // true for searching all chapters, false for current chapter only
  List<Map<String, dynamic>> _globalSearchResults =
      []; // Results from multiple chapters

  // Temporary highlight for search result navigation
  int? _tempHighlightStart;
  int? _tempHighlightEnd;
  String? _tempHighlightText;

  // Fullscreen toggle debouncing
  DateTime? _lastTapTime;
  static const _tapDebounceTime = Duration(milliseconds: 300);

  // Danh sách font chữ
  final List<String> _availableFonts = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Georgia',
    'Courier New',
    'Verdana',
    'Tahoma',
    'Comic Sans MS',
    'Palatino',
    'Garamond'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pageController = PageController();

    // Add listener to track reading progress
    _scrollController.addListener(_updateReadingProgress);

    _loadSettings();
  }

  // Update reading progress based on scroll position
  void _updateReadingProgress() {
    if (!_scrollController.hasClients) return;

    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    if (maxScrollExtent > 0) {
      setState(() {
        _readingProgress =
            (scrollOffset / maxScrollExtent * 100).clamp(0.0, 100.0);
      });
    }
  }

  // Calculate estimated page for vertical reading
  int _getCurrentEstimatedPage() {
    if (!_scrollController.hasClients) return 1;

    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (maxScrollExtent <= 0) return 1;

    // Estimate total pages based on content height
    final totalContentHeight = maxScrollExtent + viewportHeight;
    final estimatedTotalPages = (totalContentHeight / viewportHeight).ceil();

    // Calculate current page
    final currentPage =
        ((scrollOffset / maxScrollExtent) * (estimatedTotalPages - 1)).floor() +
            1;

    return currentPage.clamp(1, estimatedTotalPages);
  }

  int _getTotalEstimatedPages() {
    if (!_scrollController.hasClients) return 1;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (maxScrollExtent <= 0) return 1;

    final totalContentHeight = maxScrollExtent + viewportHeight;
    return (totalContentHeight / viewportHeight).ceil();
  }

  // Load settings từ SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();

      setState(() {
        _fontSize = settings['fontSize']?.toDouble() ?? 16.0;
        _lineHeight = settings['lineHeight']?.toDouble() ?? 1.6;
        _fontFamily = settings['fontFamily'] ?? 'Roboto';
        _backgroundColor = Color(settings['backgroundColor'] ?? 0xFFFFFFFF);
        _textColor = Color(settings['textColor'] ?? 0xFF000000);
        _isFullScreen = settings['isFullScreen'] ?? false;
        _isHorizontalReading = settings['isHorizontalReading'] ?? false;
        _settingsLoaded = true;
      });

      print('EPUB Settings loaded successfully');
    } catch (e) {
      print('Error loading EPUB settings: $e');
      setState(() {
        _settingsLoaded = true;
      });
    }

    _loadChapterContent();
    _loadTableOfContents();
    _loadHighlightsAndBookmarks();
  }

  // Save settings khi có thay đổi
  Future<void> _saveSettings() async {
    try {
      await _settingsService.saveSettings({
        'fontSize': _fontSize,
        'lineHeight': _lineHeight,
        'fontFamily': _fontFamily,
        'backgroundColor': _backgroundColor.value,
        'textColor': _textColor.value,
        'isFullScreen': _isFullScreen,
        'isHorizontalReading': _isHorizontalReading,
        // Note: autoScrollSpeed not used in EPUB reader
      });

      // Nếu đang ở chế độ đọc ngang, tính toán lại trang khi font thay đổi
      if (_isHorizontalReading && _chapterData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePagesBasedOnScreenSize();
        });
      }

      print('EPUB Settings saved successfully');
    } catch (e) {
      print('Error saving EPUB settings: $e');
    }
  }

  // Hàm tiện ích để tính toán lại trang
  void _recalculatePages() {
    if (_isHorizontalReading && _chapterData != null) {
      _calculatePagesBasedOnScreenSize();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapterContent() async {
    try {
      // Try to get from cache first
      final cachedData = await _cacheService.getCachedChapter(
          widget.story.slug, widget.chapterNumber);

      if (cachedData != null) {
        print('Using cached data for chapter ${widget.chapterNumber}');
        setState(() {
          _chapterData = cachedData;
          _isLoading = false;
          _error = null;
        });

        // Chia nội dung thành trang sau khi tải xong
        _splitContentIntoPages();

        // Auto-scroll to bookmark position if provided
        _handleAutoScroll();

        // Preload adjacent chapters in background
        _preloadAdjacentChapters();
        return;
      }

      // If not in cache, load from API
      print('Loading chapter ${widget.chapterNumber} from API...');
      final result = await OTruyenApi.getEpubChapterContent(
          widget.story.slug, widget.chapterNumber);

      setState(() {
        _chapterData = result;
        _isLoading = false;
        _error = null;
      });

      // Cache the loaded data
      await _cacheService.cacheChapter(
          widget.story.slug, widget.chapterNumber, result);

      // Chia nội dung thành trang sau khi tải xong
      _splitContentIntoPages();

      // Auto-scroll to bookmark position if provided
      _handleAutoScroll();

      // Preload adjacent chapters in background
      _preloadAdjacentChapters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTableOfContents() async {
    try {
      final result = await OTruyenApi.getEpubTableOfContents(widget.story.slug);

      if (result.containsKey('chapters')) {
        setState(() {
          _allChapters = List<Map<String, dynamic>>.from(result['chapters']);
        });
      }
    } catch (e) {
      print('Lỗi tải mục lục: $e');
    }
  }

  Future<void> _loadHighlightsAndBookmarks() async {
    try {
      final highlights = await _readingService.getHighlights(widget.story.slug);
      final bookmarks = await _readingService.getBookmarks(widget.story.slug);

      setState(() {
        _highlights = highlights
            .where((h) => h.chapterNumber == widget.chapterNumber)
            .toList();
        _bookmarks = bookmarks
            .where((b) => b.chapterNumber == widget.chapterNumber)
            .toList();
      });
    } catch (e) {
      print('Lỗi tải highlights/bookmarks: $e');
    }
  }

  // Chia nội dung thành các trang cho chế độ đọc ngang
  void _splitContentIntoPages() {
    final content = _chapterData?['chapter']?['content'] ?? '';
    if (content.isEmpty) {
      _pages = ['Không có nội dung'];
      return;
    }

    // Đợi một frame để có thể lấy kích thước màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatePagesBasedOnScreenSize();
    });

    // Tạm thời sử dụng phương pháp cũ cho đến khi tính toán xong
    final words = content.split(' ');
    final List<String> pages = [];
    final int wordsPerPage = 150; // Giảm từ 200 xuống 150 để trang ngắn hơn

    for (int i = 0; i < words.length; i += wordsPerPage) {
      final endIndex =
          (i + wordsPerPage < words.length) ? i + wordsPerPage : words.length;
      pages.add(words.sublist(i, endIndex).join(' '));
    }

    setState(() {
      _pages = pages.isNotEmpty ? pages : ['Không có nội dung'];
      _currentPageIndex = 0;
    });
  }

  // Tính toán số trang dựa trên kích thước màn hình thực tế
  void _calculatePagesBasedOnScreenSize() {
    final content = _chapterData?['chapter']?['content'] ?? '';
    if (content.isEmpty || !mounted) return;

    // Lấy kích thước màn hình
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Tính toán chiều cao có sẵn cho nội dung
    final appBarHeight = _isFullScreen ? 0.0 : kToolbarHeight;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomBarHeight = _isFullScreen ? 0.0 : 80.0; // Bottom navigation bar
    final contentPadding = 32.0; // Top + bottom padding
    final titleHeight =
        _isFullScreen ? 0.0 : (_fontSize + 4) * 1.2 + 24; // Title + spacing

    final availableHeight = screenHeight -
        appBarHeight -
        statusBarHeight -
        bottomBarHeight -
        contentPadding -
        titleHeight;

    // Tính toán số dòng có thể hiển thị
    final lineHeight = _fontSize * _lineHeight;
    final maxLines = (availableHeight / lineHeight).floor();

    // Ước tính số ký tự trên mỗi dòng (tạm thời)
    final avgCharWidth =
        _fontSize * 0.6; // Ước tính chiều rộng trung bình của 1 ký tự
    final contentWidth = screenWidth - 32.0; // Trừ padding trái phải
    final charsPerLine = (contentWidth / avgCharWidth).floor();

    // Tính số ký tự tối đa trên một trang
    final charsPerPage = maxLines * charsPerLine;

    print('Screen calculation:');
    print('Available height: $availableHeight');
    print('Max lines: $maxLines');
    print('Chars per line: $charsPerLine');
    print('Chars per page: $charsPerPage');

    // Chia nội dung dựa trên số ký tự
    final List<String> newPages = [];
    int currentIndex = 0;

    while (currentIndex < content.length) {
      int endIndex = currentIndex + charsPerPage;

      // Nếu vượt quá độ dài nội dung
      if (endIndex >= content.length) {
        newPages.add(content.substring(currentIndex));
        break;
      }

      // Tìm điểm ngắt phù hợp (cuối câu hoặc khoảng trắng)
      int breakPoint = endIndex;

      // Tìm ngược về cuối câu gần nhất
      for (int i = endIndex;
          i > currentIndex + (charsPerPage * 0.8).round();
          i--) {
        if (content[i] == '.' || content[i] == '!' || content[i] == '?') {
          breakPoint = i + 1;
          break;
        }
      }

      // Nếu không tìm thấy cuối câu, tìm khoảng trắng
      if (breakPoint == endIndex) {
        for (int i = endIndex;
            i > currentIndex + (charsPerPage * 0.9).round();
            i--) {
          if (content[i] == ' ') {
            breakPoint = i;
            break;
          }
        }
      }

      newPages.add(content.substring(currentIndex, breakPoint).trim());
      currentIndex = breakPoint;

      // Bỏ qua khoảng trắng ở đầu trang mới
      while (currentIndex < content.length && content[currentIndex] == ' ') {
        currentIndex++;
      }
    }

    // Cập nhật state với các trang mới
    if (mounted) {
      setState(() {
        _pages = newPages.isNotEmpty ? newPages : ['Không có nội dung'];
        _currentPageIndex = 0;
      });
      print('Pages recalculated: ${_pages.length} pages');
    }
  }

  void _navigateToChapter(int chapterNumber,
      {int? initialScrollPosition, String? searchText, String? bookmarkText}) {
    if (chapterNumber == widget.chapterNumber) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EpubChapterPage(
          story: widget.story,
          chapterNumber: chapterNumber,
          chapterTitle: _getChapterTitle(chapterNumber),
          initialScrollPosition: initialScrollPosition,
          searchText: searchText,
          bookmarkText: bookmarkText,
        ),
      ),
    );
  }

  String _getChapterTitle(int chapterNumber) {
    print('Getting chapter title for chapter: $chapterNumber');
    print('Available chapters: ${_allChapters.length}');

    for (var chapter in _allChapters) {
      if (chapter['number'] == chapterNumber) {
        final title = chapter['title'] ?? 'Chương $chapterNumber';
        print('Found title: $title');
        return title;
      }
    }

    final fallbackTitle = 'Chương $chapterNumber';
    print('Using fallback title: $fallbackTitle');
    return fallbackTitle;
  }

  void _toggleReadingDirection() {
    setState(() {
      _isHorizontalReading = !_isHorizontalReading;
      if (_isHorizontalReading) {
        _splitContentIntoPages();
      }
    });
    _saveSettings(); // Save setting change immediately
  }

  int? _getNextChapterNumber() {
    final navigation = _chapterData?['navigation'];
    return navigation?['nextChapter'];
  }

  int? _getPreviousChapterNumber() {
    final navigation = _chapterData?['navigation'];
    return navigation?['previousChapter'];
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Danh sách chương',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _allChapters.length,
                itemBuilder: (context, index) {
                  final chapter = _allChapters[index];
                  final isCurrentChapter =
                      chapter['number'] == widget.chapterNumber;

                  return ListTile(
                    title: Text(
                      chapter['title'] ?? 'Chương ${chapter['number']}',
                      style: TextStyle(
                        fontWeight: isCurrentChapter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentChapter
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCurrentChapter
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      child: Text(
                        '${chapter['number']}',
                        style: TextStyle(
                          color:
                              isCurrentChapter ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isCurrentChapter) {
                        _navigateToChapter(chapter['number']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cài đặt đọc sách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Font Family Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font chữ:'),
                  DropdownButton<String>(
                    value: _fontFamily,
                    items: _availableFonts.map((String font) {
                      return DropdownMenuItem<String>(
                        value: font,
                        child: Text(font, style: TextStyle(fontFamily: font)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          _fontFamily = newValue;
                          setState(() {});
                        });
                        _saveSettings(); // Save immediately
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reading Direction Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hướng đọc:'),
                  Row(
                    children: [
                      Text(_isHorizontalReading ? 'Ngang' : 'Dọc'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isHorizontalReading,
                        onChanged: (bool value) {
                          setModalState(() {
                            _toggleReadingDirection();
                          });
                          // _saveSettings already called in _toggleReadingDirection
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Font size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cỡ chữ:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_fontSize > 12) {
                            setModalState(() {
                              setState(() {
                                _fontSize -= 1.0;
                              });
                            });
                            _saveSettings(); // Save immediately
                          }
                        },
                      ),
                      Text('${_fontSize.toInt()}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_fontSize < 28) {
                            setModalState(() {
                              setState(() {
                                _fontSize += 1.0;
                              });
                            });
                            _saveSettings(); // Save immediately
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Line Height
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Khoảng cách dòng:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_lineHeight > 1.2) {
                            setModalState(() {
                              setState(() {
                                _lineHeight -= 0.1;
                              });
                            });
                            _saveSettings(); // Save immediately
                          }
                        },
                      ),
                      Text(_lineHeight.toStringAsFixed(1)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_lineHeight < 2.5) {
                            setModalState(() {
                              setState(() {
                                _lineHeight += 0.1;
                              });
                            });
                            _saveSettings(); // Save immediately
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Theme options
              const SizedBox(height: 16),
              const Text('Giao diện:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(
                      'Sáng', Colors.white, Colors.black, setModalState),
                  _buildThemeOption(
                      'Tối', Colors.black, Colors.white, setModalState),
                  _buildThemeOption('Sepia', const Color(0xFFF5F1E4),
                      Colors.brown.shade800, setModalState),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      String label, Color bgColor, Color textColor, StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          setState(() {
            _backgroundColor = bgColor;
            _textColor = textColor;
          });
        });
        _saveSettings(); // Save immediately when theme changes
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: _backgroundColor == bgColor ? Colors.blue : Colors.grey,
            width: _backgroundColor == bgColor ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: _backgroundColor == bgColor
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _openHighlightsBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HighlightsBookmarksPage(
          storySlug: widget.story.slug,
          storyTitle: widget.story.title,
          onNavigateToChapter: (chapterNumber) {
            _navigateToChapter(chapterNumber);
          },
          onNavigateToBookmark: (bookmark) {
            _navigateToBookmark(bookmark);
          },
          onNavigateToHighlight: (highlight) {
            _navigateToHighlight(highlight);
          },
        ),
      ),
    );
  }

  void _navigateToBookmark(Bookmark bookmark) {
    print('=== Navigating to bookmark ===');
    print('Bookmark text: "${bookmark.text}"');
    print('Bookmark chapter: ${bookmark.chapterNumber}');
    print('Current chapter: ${widget.chapterNumber}');
    print('Bookmark startIndex: ${bookmark.startIndex}');
    print('Bookmark endIndex: ${bookmark.endIndex}');

    // If it's the current chapter, scroll to bookmark position
    if (bookmark.chapterNumber == widget.chapterNumber) {
      print('Same chapter - scrolling to position');
      _scrollToPosition(bookmark.startIndex, bookmarkText: bookmark.text);
    } else {
      print(
          'Different chapter - navigating to chapter ${bookmark.chapterNumber}');
      print('Passing initialScrollPosition: ${bookmark.startIndex}');
      print('Passing bookmarkText: "${bookmark.text}"');

      // Navigate to the chapter containing the bookmark and pass bookmark text
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubChapterPage(
            story: widget.story,
            chapterNumber: bookmark.chapterNumber,
            chapterTitle: _getChapterTitle(bookmark.chapterNumber),
            initialScrollPosition:
                bookmark.startIndex, // Pass bookmark position
            bookmarkText: bookmark.text, // Pass bookmark text for highlighting
          ),
        ),
      );
    }
  }

  void _navigateToHighlight(Highlight highlight) {
    print('=== Navigating to highlight ===');
    print('Highlight text: "${highlight.text}"');
    print('Highlight chapter: ${highlight.chapterNumber}');
    print('Current chapter: ${widget.chapterNumber}');
    print('Highlight startIndex: ${highlight.startIndex}');
    print('Highlight endIndex: ${highlight.endIndex}');

    // If it's the current chapter, scroll to highlight position
    if (highlight.chapterNumber == widget.chapterNumber) {
      print('Same chapter - scrolling to position');
      _scrollToPosition(highlight.startIndex, searchText: highlight.text);
    } else {
      print(
          'Different chapter - navigating to chapter ${highlight.chapterNumber}');
      print('Passing initialScrollPosition: ${highlight.startIndex}');
      print('Passing searchText: "${highlight.text}"');

      // Navigate to the chapter containing the highlight and pass highlight text
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubChapterPage(
            story: widget.story,
            chapterNumber: highlight.chapterNumber,
            chapterTitle: _getChapterTitle(highlight.chapterNumber),
            initialScrollPosition:
                highlight.startIndex, // Pass highlight position
            searchText: highlight.text, // Pass highlight text for highlighting
          ),
        ),
      );
    }
  }

  // Check if there's already a highlight at the given position
  bool _hasExistingHighlightAt(int startIndex, int endIndex) {
    for (final highlight in _highlights) {
      // Check if there's any overlap between existing highlight and new temp highlight
      if (highlight.startIndex < endIndex && highlight.endIndex > startIndex) {
        print(
            'Found existing highlight overlap: ${highlight.startIndex}-${highlight.endIndex} vs $startIndex-$endIndex');
        return true;
      }
    }
    return false;
  }

  void _scrollToPosition(int textIndex,
      {String? searchText, String? bookmarkText}) {
    print('=== Scrolling to position ===');
    print('Target index: $textIndex');
    print('Search text: $searchText');
    print('Bookmark text: $bookmarkText');
    print('Reading mode: ${_isHorizontalReading ? "horizontal" : "vertical"}');
    print('ScrollController hasClients: ${_scrollController.hasClients}');

    final chapter = _chapterData?['chapter'];
    final content = chapter?['content'] ?? '';

    // Set temporary highlight - prioritize bookmark text over search text
    final highlightText = bookmarkText ?? searchText;
    print('=== Highlight Text Decision ===');
    print('bookmarkText: "$bookmarkText"');
    print('searchText: "$searchText"');
    print('Selected highlightText: "$highlightText"');

    if (highlightText != null &&
        highlightText.isNotEmpty &&
        content.isNotEmpty) {
      final tempStart = textIndex;
      final tempEnd = textIndex + highlightText.length;

      // Check if there's already a highlight at this position
      if (_hasExistingHighlightAt(tempStart, tempEnd)) {
        print(
            '❌ Skipping temp highlight - already highlighted at this position');
        print('Existing highlight found at range: $tempStart-$tempEnd');
      } else {
        print('✅ Setting temporary highlight');
        print('Start: $tempStart, End: $tempEnd');
        setState(() {
          _tempHighlightStart = tempStart;
          _tempHighlightEnd = tempEnd;
          _tempHighlightText = highlightText;
        });

        // Clear highlight after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _clearTempHighlight();
          }
        });
      }
    } else {
      print('❌ Not setting highlight - conditions not met');
      print(
          'highlightText is null or empty: ${highlightText == null || highlightText.isEmpty}');
      print('content is empty: ${content.isEmpty}');
    }

    if (!_isHorizontalReading && _scrollController.hasClients) {
      // For vertical reading, estimate scroll position based on text index
      print('Content length: ${content.length}');
      print('MaxScrollExtent: ${_scrollController.position.maxScrollExtent}');

      if (content.isNotEmpty && textIndex >= 0 && textIndex < content.length) {
        // More accurate calculation for bookmark/search positioning
        final scrollRatio = textIndex / content.length;

        // Calculate target offset with better accuracy
        var targetOffset =
            scrollRatio * _scrollController.position.maxScrollExtent;

        // For bookmark navigation, be more conservative with scroll positioning
        // to avoid overshooting the target
        if (bookmarkText != null) {
          print('=== Bookmark Scroll Calculation ===');
          print('Original targetOffset: $targetOffset');
          print('Scroll ratio: $scrollRatio');
          print('Content position: ${textIndex}/${content.length}');

          // For bookmarks, use a more conservative approach
          // but don't reduce too much to avoid under-scrolling
          if (scrollRatio <= 0.1) {
            // For content in first 10%, scroll normally but ensure minimum
            targetOffset = (scrollRatio * 1.0) *
                _scrollController.position.maxScrollExtent;
          } else if (scrollRatio >= 0.9) {
            // For content in last 10%, scroll close to end
            targetOffset =
                scrollRatio * 0.95 * _scrollController.position.maxScrollExtent;
          } else {
            // For middle content, reduce slightly to account for headers
            targetOffset = (scrollRatio * 0.9 + 0.05) *
                _scrollController.position.maxScrollExtent;
          }

          print('Adjusted bookmark targetOffset: $targetOffset');
        } else {
          print('=== Search Scroll Calculation ===');
          print('Original targetOffset: $targetOffset');

          // For search results, use the original logic with slight adjustment
          if (targetOffset < 100 && textIndex > 0) {
            targetOffset = (scrollRatio * 0.8 + 0.05) *
                _scrollController.position.maxScrollExtent;
          }

          print('Adjusted search targetOffset: $targetOffset');
        }

        print('Scroll ratio: $scrollRatio');
        print(
            'Target offset (${bookmarkText != null ? "bookmark" : "search"}): $targetOffset');
        print('MaxScrollExtent: ${_scrollController.position.maxScrollExtent}');

        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 800), // Slightly faster
          curve: Curves.easeInOut,
        );

        // Show different feedback for bookmark vs search
        final verticalFeedbackText = bookmarkText != null
            ? 'Đã nhảy đến bookmark (vị trí ${(scrollRatio * 100).toStringAsFixed(1)}%)'
            : 'Đã nhảy đến kết quả (vị trí ${(scrollRatio * 100).toStringAsFixed(1)}%)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verticalFeedbackText),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('Invalid textIndex or empty content');
        print('textIndex: $textIndex, content.length: ${content.length}');

        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể nhảy đến kết quả - vị trí không hợp lệ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (_isHorizontalReading) {
      // For horizontal reading, find which page contains the search result
      final fullContent = chapter?['content'] ?? '';

      print('Pages count: ${_pages.length}');
      print('Full content length: ${fullContent.length}');

      int currentIndex = 0;
      bool found = false;
      for (int i = 0; i < _pages.length; i++) {
        final pageLength = _pages[i].length;
        print(
            'Page $i: currentIndex=$currentIndex, pageLength=$pageLength, range=${currentIndex}-${currentIndex + pageLength}');

        if (textIndex >= currentIndex &&
            textIndex < currentIndex + pageLength) {
          // Found the page containing the search result
          print('Found result on page $i');
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );

          // Show different feedback for bookmark vs search
          final horizontalFeedbackText = bookmarkText != null
              ? 'Đã nhảy đến bookmark ở trang ${i + 1}/${_pages.length}'
              : 'Đã nhảy đến kết quả ở trang ${i + 1}/${_pages.length}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(horizontalFeedbackText),
              duration: const Duration(seconds: 2),
            ),
          );
          found = true;
          break;
        }
        currentIndex += pageLength;
        // Add space between pages (from split/join process)
        if (i < _pages.length - 1) currentIndex += 1;
      }

      if (!found) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy trang chứa kết quả'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      print('ScrollController does not have clients');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa sẵn sàng để scroll - thử lại sau'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearTempHighlight() {
    setState(() {
      _tempHighlightStart = null;
      _tempHighlightEnd = null;
      _tempHighlightText = null;
    });
  }

  void _onHighlightAdded(Highlight highlight) {
    setState(() {
      _highlights.add(highlight);
    });
    // Force rebuild to show the new highlight
    print('Highlight added, total highlights: ${_highlights.length}');
  }

  void _onBookmarkAdded(Bookmark bookmark) {
    setState(() {
      _bookmarks.add(bookmark);
    });
    print('Bookmark added, total bookmarks: ${_bookmarks.length}');
  }

  // Get highlights for specific page in horizontal reading mode - FIXED VERSION
  List<Highlight> _getHighlightsForPage(String pageContent, int pageIndex) {
    if (!_isHorizontalReading || _highlights.isEmpty) {
      return _highlights;
    }

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty ||
        pageIndex >= _pages.length ||
        pageIndex < 0 ||
        pageContent.isEmpty) {
      return [];
    }

    // Find the starting position of this page in the full content
    int pageStartInFullContent = 0;
    for (int i = 0; i < pageIndex; i++) {
      if (i < _pages.length) {
        pageStartInFullContent += _pages[i].length;
        // Add space between pages (from split/join process)
        if (i < _pages.length - 1) pageStartInFullContent += 1;
      }
    }

    int pageEndInFullContent = pageStartInFullContent + pageContent.length;

    // Debug logging
    print(
        'Page $pageIndex: Start=$pageStartInFullContent, End=$pageEndInFullContent, PageLength=${pageContent.length}');

    // Filter highlights that fall within this page and adjust indices
    List<Highlight> pageHighlights = [];

    for (final highlight in _highlights) {
      print(
          'Checking highlight: Start=${highlight.startIndex}, End=${highlight.endIndex}');

      // Check if highlight overlaps with this page
      if (highlight.startIndex < pageEndInFullContent &&
          highlight.endIndex > pageStartInFullContent) {
        // Calculate adjusted indices with extra safety
        final rawStart = highlight.startIndex - pageStartInFullContent;
        final rawEnd = highlight.endIndex - pageStartInFullContent;

        final adjustedStart = rawStart.clamp(0, pageContent.length);
        final adjustedEnd = rawEnd.clamp(0, pageContent.length);

        print(
            'Adjusted: Start=$adjustedStart, End=$adjustedEnd, PageContentLength=${pageContent.length}');

        // Only add if we have a valid range
        if (adjustedStart >= 0 &&
            adjustedEnd > adjustedStart &&
            adjustedEnd <= pageContent.length) {
          pageHighlights.add(Highlight(
            id: highlight.id,
            text: highlight.text,
            chapterTitle: highlight.chapterTitle,
            chapterNumber: highlight.chapterNumber,
            storySlug: highlight.storySlug,
            startIndex: adjustedStart,
            endIndex: adjustedEnd,
            color: highlight.color,
            createdAt: highlight.createdAt,
          ));
          print('Added valid highlight: $adjustedStart-$adjustedEnd');
        } else {
          print('Skipped invalid highlight: $adjustedStart-$adjustedEnd');
        }
      }
    }

    print('Returning ${pageHighlights.length} highlights for page $pageIndex');
    return pageHighlights;
  }

  // Widget nội dung cho chế độ đọc dọc
  Widget _buildVerticalContent() {
    final chapter = _chapterData?['chapter'];
    final content = chapter?['content'] ?? 'Không có nội dung';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        print(
            '🖱️ Vertical content tap down detected at: ${details.globalPosition}');
        _handleTapAtPosition(details.globalPosition, 'vertical');
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isFullScreen) ...[
              Text(
                chapter?['title'] ?? widget.chapterTitle,
                style: TextStyle(
                  fontSize: _fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: _fontFamily,
                ),
              ),
              const SizedBox(height: 24),
            ],
            SelectableTextWidget(
              text: content,
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeight,
                color: _textColor,
                fontFamily: _fontFamily,
              ),
              storySlug: widget.story.slug,
              chapterTitle: chapter?['title'] ?? widget.chapterTitle,
              chapterNumber: widget.chapterNumber,
              highlights: _highlights,
              tempHighlightStart: _tempHighlightStart,
              tempHighlightEnd: _tempHighlightEnd,
              onHighlightAdded: _onHighlightAdded,
              onBookmarkAdded: _onBookmarkAdded,
            ),
          ],
        ),
      ),
    );
  }

  // Widget nội dung cho chế độ đọc ngang
  Widget _buildHorizontalContent() {
    final chapter = _chapterData?['chapter'];
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Handle overscroll for chapter navigation in horizontal mode
        if (notification is OverscrollNotification) {
          final overscroll = notification.overscroll;

          // Overscroll to the left (positive overscroll) when at first page - previous chapter
          if (overscroll > 20 && _currentPageIndex == 0) {
            final prevChapter = _getPreviousChapterNumber();
            if (prevChapter != null) {
              _navigateToChapter(prevChapter);
              return true;
            }
          }
          // Overscroll to the right (negative overscroll) when at last page - next chapter
          else if (overscroll < -20 && _currentPageIndex == _pages.length - 1) {
            final nextChapter = _getNextChapterNumber();
            if (nextChapter != null) {
              _navigateToChapter(nextChapter);
              return true;
            }
          }
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          print(
              '🖱️ Horizontal content tap down detected at: ${details.globalPosition}');
          _handleTapAtPosition(details.globalPosition, 'horizontal');
        },
        onTap: () {
          print('🖱️ Horizontal content tap detected!');
          _clearTempHighlight();
          _toggleFullScreenWithDebounce('horizontal');
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isFullScreen) ...[
                    Text(
                      chapter?['title'] ?? widget.chapterTitle,
                      style: TextStyle(
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        fontFamily: _fontFamily,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Expanded(
                    child: SelectableTextWidget(
                      text: _pages[index],
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: _lineHeight,
                        color: _textColor,
                        fontFamily: _fontFamily,
                      ),
                      storySlug: widget.story.slug,
                      chapterTitle: chapter?['title'] ?? widget.chapterTitle,
                      chapterNumber: widget.chapterNumber,
                      highlights: _getHighlightsForPage(_pages[index], index),
                      tempHighlightStart:
                          _getPageRelativeTempHighlight(index)?['start'],
                      tempHighlightEnd:
                          _getPageRelativeTempHighlight(index)?['end'],
                      onHighlightAdded: _onHighlightAdded,
                      onBookmarkAdded: _onBookmarkAdded,
                    ),
                  ),
                  if (!_isFullScreen) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Trang ${index + 1} / ${_pages.length}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Get temporary highlight relative to page for horizontal reading
  Map<String, int>? _getPageRelativeTempHighlight(int pageIndex) {
    if (_tempHighlightStart == null || _tempHighlightEnd == null) {
      return null;
    }

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty || pageIndex >= _pages.length || pageIndex < 0) {
      return null;
    }

    // Find the starting position of this page in the full content
    int pageStartInFullContent = 0;
    for (int i = 0; i < pageIndex; i++) {
      if (i < _pages.length) {
        pageStartInFullContent += _pages[i].length;
        // Add space between pages (from split/join process)
        if (i < _pages.length - 1) pageStartInFullContent += 1;
      }
    }

    int pageEndInFullContent =
        pageStartInFullContent + _pages[pageIndex].length;

    // Check if temp highlight overlaps with this page
    if (_tempHighlightStart! < pageEndInFullContent &&
        _tempHighlightEnd! > pageStartInFullContent) {
      // Calculate adjusted indices
      final adjustedStart = (_tempHighlightStart! - pageStartInFullContent)
          .clamp(0, _pages[pageIndex].length);
      final adjustedEnd = (_tempHighlightEnd! - pageStartInFullContent)
          .clamp(0, _pages[pageIndex].length);

      if (adjustedStart >= 0 &&
          adjustedEnd > adjustedStart &&
          adjustedEnd <= _pages[pageIndex].length) {
        // Check if there's already a highlight at this position
        if (_hasExistingHighlightAtPage(
            pageIndex, adjustedStart, adjustedEnd)) {
          print(
              '❌ Skipping temp highlight on page $pageIndex - already highlighted at position $adjustedStart-$adjustedEnd');
          return null;
        }

        return {
          'start': adjustedStart,
          'end': adjustedEnd,
        };
      }
    }

    return null;
  }

  // Handle auto-scroll to initial position
  void _handleAutoScroll() {
    if (widget.initialScrollPosition != null) {
      print('=== Auto-scroll Setup ===');
      print('Initial scroll position: ${widget.initialScrollPosition}');
      print('Search text: ${widget.searchText}');
      print('Bookmark text: ${widget.bookmarkText}');

      // Use multiple frame callbacks to ensure UI is fully ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('First frame callback executed');
        Future.delayed(const Duration(milliseconds: 500), () {
          print('Delayed auto-scroll executing...');
          print('ScrollController hasClients: ${_scrollController.hasClients}');
          if (_scrollController.hasClients) {
            print(
                'ScrollController maxScrollExtent: ${_scrollController.position.maxScrollExtent}');
          }
          _scrollToPosition(
            widget.initialScrollPosition!,
            searchText: widget.searchText,
            bookmarkText: widget.bookmarkText,
          );
        });
      });
    }
  }

  // Preload adjacent chapters for smoother navigation
  void _preloadAdjacentChapters() {
    _cacheService.preloadAdjacentChapters(
      widget.story.slug,
      widget.chapterNumber,
      (storySlug, chapterNumber) async {
        return await OTruyenApi.getEpubChapterContent(storySlug, chapterNumber);
      },
    );
  }

  // Search functionality methods
  void _showSearchDialog() {
    setState(() {
      _isSearching = true;
    });

    // Focus on search after UI update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _performSearch(String query, bool isGlobal) {
    print('🚀 _performSearch called with query: "$query", isGlobal: $isGlobal');

    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _globalSearchResults = [];
        _currentSearchIndex = -1;
        _isGlobalSearch = false;
      });
      return;
    }

    setState(() {
      _isGlobalSearch = isGlobal;
      _searchQuery = query;
    });

    if (isGlobal) {
      print('🌐 Calling global search...');
      _performGlobalSearch(query);
    } else {
      print('📄 Calling local search...');
      _performCurrentChapterSearch(query);
    }
  }

  void _performCurrentChapterSearch(String query) {
    final chapter = _chapterData?['chapter'];
    final content = chapter?['content'] ?? '';

    if (content.isEmpty) {
      setState(() {
        _searchResults = [];
        _globalSearchResults = [];
        _currentSearchIndex = -1;
      });
      return;
    }

    // Find all occurrences of the search query
    final List<Map<String, dynamic>> results = [];
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();

    int index = 0;
    while (index < contentLower.length) {
      final foundIndex = contentLower.indexOf(queryLower, index);
      if (foundIndex == -1) break;

      // Get surrounding context (50 chars before and after)
      final start = (foundIndex - 50).clamp(0, content.length);
      final end = (foundIndex + query.length + 50).clamp(0, content.length);
      final context = content.substring(start, end);

      results.add({
        'index': foundIndex,
        'context': context,
        'matchStart': foundIndex - start,
        'matchEnd': foundIndex - start + query.length,
        'chapterNumber': widget.chapterNumber,
        'chapterTitle': chapter?['title'] ?? widget.chapterTitle,
      });

      index = foundIndex + 1;
    }

    setState(() {
      _searchResults = results;
      _globalSearchResults = [];
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });
  }

  Future<void> _performGlobalSearch(String query) async {
    print('🔍 Starting global search for: "$query"');
    print('📚 Total chapters to search: ${_allChapters.length}');

    // Clear previous results immediately and show loading
    setState(() {
      _searchResults = [];
      _globalSearchResults = [];
      _currentSearchIndex = -1;
    });

    try {
      final List<Map<String, dynamic>> globalResults = [];
      final queryLower = query.toLowerCase();
      int searchedChapters = 0;

      // Search through all chapters
      for (final chapterInfo in _allChapters) {
        final chapterNumber = chapterInfo['number'] as int;
        final chapterTitle = chapterInfo['title'] ?? 'Chương $chapterNumber';

        searchedChapters++;
        print(
            '🔎 Searching chapter $chapterNumber ($searchedChapters/${_allChapters.length})');

        try {
          // Try to get from cache first, then from API
          Map<String, dynamic>? chapterData = await _cacheService
              .getCachedChapter(widget.story.slug, chapterNumber);

          if (chapterData == null) {
            print('📡 Loading chapter $chapterNumber from API...');
            chapterData = await OTruyenApi.getEpubChapterContent(
                widget.story.slug, chapterNumber);
            // Cache the loaded data
            await _cacheService.cacheChapter(
                widget.story.slug, chapterNumber, chapterData);
          } else {
            print('📋 Using cached chapter $chapterNumber');
          }

          final content = chapterData['chapter']?['content'] ?? '';
          if (content.isEmpty) {
            print('⚠️ Chapter $chapterNumber has empty content');
            continue;
          }

          final contentLower = content.toLowerCase();
          int matchCount = 0;

          // Find matches in this chapter
          int index = 0;
          while (index < contentLower.length) {
            final foundIndex = contentLower.indexOf(queryLower, index);
            if (foundIndex == -1) break;

            matchCount++;
            // Get surrounding context (100 chars before and after for global search)
            final start = (foundIndex - 100).clamp(0, content.length);
            final end =
                (foundIndex + query.length + 100).clamp(0, content.length);
            final context = content.substring(start, end);

            globalResults.add({
              'index': foundIndex,
              'context': context,
              'matchStart': foundIndex - start,
              'matchEnd': foundIndex - start + query.length,
              'chapterNumber': chapterNumber,
              'chapterTitle': chapterTitle,
              'matchCount': matchCount,
            });

            index = foundIndex + 1;
          }

          if (matchCount > 0) {
            print('✅ Found $matchCount matches in chapter $chapterNumber');
          }
        } catch (e) {
          print('❌ Error searching chapter $chapterNumber: $e');
          // Continue with other chapters even if one fails
        }
      }

      print(
          '🎯 Global search completed. Total results: ${globalResults.length}');

      // Update results
      if (mounted && _isSearching && _searchController.text == query) {
        setState(() {
          _searchResults = [];
          _globalSearchResults = globalResults;
          _currentSearchIndex = -1;
        });
        print('✅ State updated with ${globalResults.length} global results');
      } else {
        print('⚠️ Search was cancelled or component unmounted');
      }
    } catch (e) {
      print('❌ Global search error: $e');
      if (mounted && _isSearching) {
        setState(() {
          _searchResults = [];
          _globalSearchResults = [];
          _currentSearchIndex = -1;
        });
      }
    }
  }

  void _scrollToSearchResult(int index) {
    if (index < 0 || index >= _searchResults.length) return;

    final result = _searchResults[index];
    final textIndex = result['index'] as int;

    _scrollToPosition(textIndex);
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;

    final nextIndex = (_currentSearchIndex + 1) % _searchResults.length;
    setState(() {
      _currentSearchIndex = nextIndex;
    });
    _scrollToSearchResult(nextIndex);
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;

    final prevIndex = _currentSearchIndex > 0
        ? _currentSearchIndex - 1
        : _searchResults.length - 1;
    setState(() {
      _currentSearchIndex = prevIndex;
    });
    _scrollToSearchResult(prevIndex);
  }

  void _showSearchResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tìm thấy ${_searchResults.length} kết quả'),
        action: SnackBarAction(
          label: 'Đóng tìm kiếm',
          onPressed: _clearSearch,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSearchNoResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không tìm thấy kết quả nào'),
        duration: Duration(seconds: 2),
      ),
    );
    _clearSearch();
  }

  void _showGlobalSearchResults() {
    final chapterCount = _globalSearchResults
        .map((result) => result['chapterNumber'])
        .toSet()
        .length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả tìm kiếm: "$_searchQuery"',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_globalSearchResults.length} kết quả trong $chapterCount chương',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      _clearSearch();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _globalSearchResults.length,
                itemBuilder: (context, index) {
                  final result = _globalSearchResults[index];
                  final chapterNumber = result['chapterNumber'] as int;
                  final chapterTitle = result['chapterTitle'] as String;
                  final resultContext = result['context'] as String;
                  final matchStart = result['matchStart'] as int;
                  final matchEnd = result['matchEnd'] as int;

                  return ListTile(
                    title: Text(
                      chapterTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                            children: [
                              TextSpan(
                                  text: resultContext.substring(0, matchStart)),
                              TextSpan(
                                text: resultContext.substring(
                                    matchStart, matchEnd),
                                style: const TextStyle(
                                  backgroundColor: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(text: resultContext.substring(matchEnd)),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: chapterNumber == widget.chapterNumber
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      child: Text(
                        '$chapterNumber',
                        style: TextStyle(
                          color: chapterNumber == widget.chapterNumber
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (chapterNumber == widget.chapterNumber) {
                        // Same chapter - scroll to position
                        _scrollToPosition(result['index'] as int,
                            searchText: _searchQuery);
                      } else {
                        // Different chapter - navigate
                        _navigateToChapter(
                          chapterNumber,
                          initialScrollPosition: result['index'] as int,
                          searchText: _searchQuery,
                        );
                      }
                      _clearSearch();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      _globalSearchResults = [];
      _currentSearchIndex = -1;
      _isGlobalSearch = false;
    });
    _searchController.clear();

    // Only clear temp highlight if it's not from a bookmark
    if (_tempHighlightText != null && widget.bookmarkText == null) {
      _clearTempHighlight();
    }

    FocusScope.of(context).unfocus();
  }

  // Build search overlay widget
  Widget _buildSearchOverlay() {
    return Container(
      color: _backgroundColor.withOpacity(0.95),
      child: Column(
        children: [
          // Search input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search input row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: _textColor),
                      onPressed: _clearSearch,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: _textColor),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          hintStyle:
                              TextStyle(color: _textColor.withOpacity(0.6)),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });

                          if (value.isNotEmpty) {
                            if (_isGlobalSearch) {
                              // For global search, use longer debounce
                              Future.delayed(const Duration(milliseconds: 800),
                                  () {
                                if (_searchController.text == value &&
                                    _isSearching &&
                                    _isGlobalSearch) {
                                  _performSearch(value, true);
                                }
                              });
                            } else {
                              // For local search, use shorter debounce
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                if (_searchController.text == value &&
                                    _isSearching &&
                                    !_isGlobalSearch) {
                                  _performSearch(value, false);
                                }
                              });
                            }
                          } else {
                            setState(() {
                              _searchResults = [];
                              _globalSearchResults = [];
                              _currentSearchIndex = -1;
                            });
                          }
                        },
                      ),
                    ),
                    // Search scope toggle
                    PopupMenuButton<bool>(
                      icon: Icon(
                        _isGlobalSearch ? Icons.public : Icons.article,
                        color: _textColor,
                      ),
                      onSelected: (isGlobal) {
                        print(
                            '🔄 Changing search scope to: ${isGlobal ? "Global" : "Local"}');
                        setState(() {
                          _isGlobalSearch = isGlobal;
                          // Clear previous results when changing scope
                          _searchResults = [];
                          _globalSearchResults = [];
                          _currentSearchIndex = -1;
                        });
                        if (_searchController.text.isNotEmpty) {
                          print('🔄 Re-triggering search with new scope');
                          _performSearch(_searchController.text, isGlobal);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: false,
                          child: Row(
                            children: [
                              Icon(Icons.article,
                                  color: !_isGlobalSearch
                                      ? Theme.of(context).primaryColor
                                      : null),
                              const SizedBox(width: 8),
                              Text('Chương hiện tại'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: true,
                          child: Row(
                            children: [
                              Icon(Icons.public,
                                  color: _isGlobalSearch
                                      ? Theme.of(context).primaryColor
                                      : null),
                              const SizedBox(width: 8),
                              Text('Toàn bộ truyện'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Search results count
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isGlobalSearch
                          ? 'Đang tìm kiếm trong truyện này...'
                          : _searchResults.isNotEmpty
                              ? 'Tìm thấy ${_searchResults.length} kết quả trong chương'
                              : 'Không tìm thấy kết quả',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Search results
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Text(
                      'Nhập từ khóa để tìm kiếm',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  )
                : _isGlobalSearch
                    ? _buildGlobalSearchResults()
                    : _buildLocalSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy kết quả',
          style: TextStyle(
            color: _textColor.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final resultContext = result['context'] as String;
        final matchStart = result['matchStart'] as int;
        final matchEnd = result['matchEnd'] as int;

        return Card(
          color: _backgroundColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: RichText(
              text: TextSpan(
                style: TextStyle(color: _textColor, fontSize: 16),
                children: [
                  TextSpan(text: resultContext.substring(0, matchStart)),
                  TextSpan(
                    text: resultContext.substring(matchStart, matchEnd),
                    style: TextStyle(
                      backgroundColor: Colors.yellow.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(text: resultContext.substring(matchEnd)),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              _scrollToPosition(result['index'] as int,
                  searchText: _searchQuery);
              _clearSearch();
            },
          ),
        );
      },
    );
  }

  Widget _buildGlobalSearchResults() {
    print(
        '🖼️ Building global search results. Query: "$_searchQuery", Results: ${_globalSearchResults.length}');

    // Show loading state when query exists but no results yet (searching in progress)
    if (_searchQuery.isNotEmpty && _globalSearchResults.isEmpty) {
      print('⏳ Showing loading state for global search');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tìm kiếm trong truyện này...',
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Có thể mất vài phút để hoàn thành',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state when search completed but no results
    if (_searchQuery.isNotEmpty && _globalSearchResults.isEmpty) {
      print('❌ No global search results found');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: _textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    print('📋 Displaying ${_globalSearchResults.length} global search results');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _globalSearchResults.length,
      itemBuilder: (context, index) {
        final result = _globalSearchResults[index];
        final chapterNumber = result['chapterNumber'] as int;
        final chapterTitle = result['chapterTitle'] as String;
        final resultContext = result['context'] as String;
        final matchStart = result['matchStart'] as int;
        final matchEnd = result['matchEnd'] as int;

        return Card(
          color: _backgroundColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: chapterNumber == widget.chapterNumber
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              child: Text(
                '$chapterNumber',
                style: TextStyle(
                  color: chapterNumber == widget.chapterNumber
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              chapterTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textColor,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: _textColor.withOpacity(0.8), fontSize: 14),
                  children: [
                    TextSpan(text: resultContext.substring(0, matchStart)),
                    TextSpan(
                      text: resultContext.substring(matchStart, matchEnd),
                      style: TextStyle(
                        backgroundColor: Colors.yellow.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(text: resultContext.substring(matchEnd)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () {
              print(
                  '📍 Navigating to chapter $chapterNumber, position ${result['index']}');
              if (chapterNumber == widget.chapterNumber) {
                _scrollToPosition(result['index'] as int,
                    searchText: _searchQuery);
              } else {
                _navigateToChapter(
                  chapterNumber,
                  initialScrollPosition: result['index'] as int,
                  searchText: _searchQuery,
                );
              }
              _clearSearch();
            },
          ),
        );
      },
    );
  }

  // Check if there's already a highlight at the given position for horizontal reading
  bool _hasExistingHighlightAtPage(int pageIndex, int pageStart, int pageEnd) {
    if (!_isHorizontalReading || _highlights.isEmpty) {
      return false;
    }

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty || pageIndex >= _pages.length || pageIndex < 0) {
      return false;
    }

    // Find the starting position of this page in the full content
    int pageStartInFullContent = 0;
    for (int i = 0; i < pageIndex; i++) {
      if (i < _pages.length) {
        pageStartInFullContent += _pages[i].length;
        // Add space between pages (from split/join process)
        if (i < _pages.length - 1) pageStartInFullContent += 1;
      }
    }

    // Convert page-relative positions to full content positions
    final fullContentStart = pageStartInFullContent + pageStart;
    final fullContentEnd = pageStartInFullContent + pageEnd;

    // Check if any existing highlight overlaps with this position
    for (final highlight in _highlights) {
      if (highlight.startIndex < fullContentEnd &&
          highlight.endIndex > fullContentStart) {
        print(
            'Found existing highlight overlap in page $pageIndex: ${highlight.startIndex}-${highlight.endIndex} vs $fullContentStart-$fullContentEnd');
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if settings haven't been loaded yet
    if (!_settingsLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.story.title} - ${widget.chapterTitle}'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải cài đặt...'),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadChapterContent();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final chapter = _chapterData?['chapter'];
    final hasContent = chapter?['content'] != null &&
        chapter!['content'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _isFullScreen || _isSearching
          ? null
          : AppBar(
              backgroundColor: _backgroundColor,
              foregroundColor: _textColor,
              title: Text(
                '${widget.story.title} - ${chapter?['title'] ?? widget.chapterTitle}',
                style: TextStyle(color: _textColor),
              ),
              actions: [
                // Search button
                IconButton(
                  icon: Icon(Icons.search, color: _textColor),
                  onPressed: _showSearchDialog,
                ),
                IconButton(
                  icon: Icon(Icons.list, color: _textColor),
                  onPressed: _showChapterList,
                ),
                // New: Highlights/Bookmarks button
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.bookmark, color: _textColor),
                      if (_highlights.isNotEmpty || _bookmarks.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${_highlights.length + _bookmarks.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _openHighlightsBookmarks,
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: _textColor),
                  onPressed: _showSettings,
                ),
              ],
            ),
      body: Stack(
        children: [
          // Main content
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              // Use a more reliable way to detect taps
              if (!_isSearching) {
                Future.delayed(Duration.zero, () {
                  setState(() {
                    _isFullScreen = !_isFullScreen;
                    print('🔄 Toggled _isFullScreen to: $_isFullScreen');
                  });
                });
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!_isHorizontalReading) {
                  // Handle overscroll for chapter navigation
                  if (notification is OverscrollNotification) {
                    final overscroll = notification.overscroll;

                    // Overscroll at top (positive overscroll, pulling down) - previous chapter
                    if (overscroll > 20) {
                      final prevChapter = _getPreviousChapterNumber();
                      if (prevChapter != null) {
                        _navigateToChapter(prevChapter);
                        return true;
                      }
                    }
                    // Overscroll at bottom (negative overscroll, pulling up) - next chapter
                    else if (overscroll < -20) {
                      final nextChapter = _getNextChapterNumber();
                      if (nextChapter != null) {
                        _navigateToChapter(nextChapter);
                        return true;
                      }
                    }
                  }
                }
                return false;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  print(
                      '🖱️ Main tap down detected at: ${details.globalPosition}');
                  _handleTapAtPosition(details.globalPosition, 'main');
                },
                onPanStart: (_) => {
                  _clearTempHighlight(), // Clear highlights when scrolling starts
                  _lastTapTime = null, // Reset tap timing on pan start
                },
                child: hasContent
                    ? (_isHorizontalReading
                        ? _buildHorizontalContent()
                        : _buildVerticalContent())
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: _textColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có nội dung để hiển thị',
                              style: TextStyle(
                                fontSize: 18,
                                color: _textColor.withOpacity(0.7),
                                fontFamily: _fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // Search overlay
          if (_isSearching) _buildSearchOverlay(),
          // Fullscreen minimal info overlay
          if (_isFullScreen && hasContent)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _backgroundColor.withOpacity(0.3),
                      _backgroundColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chapter info
                      Text(
                        '${widget.chapterNumber}/${_allChapters.length}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: _backgroundColor.withOpacity(0.8),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Progress bar
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LinearProgressIndicator(
                            value: _readingProgress / 100,
                            backgroundColor: _textColor.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _textColor.withOpacity(0.8)),
                            minHeight: 2,
                          ),
                        ),
                      ),
                      // Page info and progress percentage
                      Row(
                        children: [
                          Text(
                            _isHorizontalReading
                                ? '${_currentPageIndex + 1}/${_pages.length}'
                                : '${_getCurrentEstimatedPage()}/${_getTotalEstimatedPages()}',
                            style: TextStyle(
                              color: _textColor.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: _backgroundColor.withOpacity(0.8),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_readingProgress.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _textColor.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: _backgroundColor.withOpacity(0.8),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_isFullScreen && hasContent
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _readingProgress / 100,
                          backgroundColor: _textColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_readingProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Chapter and page info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chương ${widget.chapterNumber}/${_allChapters.length}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _isHorizontalReading
                            ? 'Trang ${_currentPageIndex + 1}/${_pages.length}'
                            : 'Trang ${_getCurrentEstimatedPage()}/${_getTotalEstimatedPages()}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // Helper method to toggle fullscreen with debouncing
  void _toggleFullScreenWithDebounce(String source) {
    final now = DateTime.now();

    // Check if enough time has passed since last tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _tapDebounceTime) {
      print('🚫 Tap ignored - too soon after last tap (from $source)');
      return;
    }

    _lastTapTime = now;

    if (!_isSearching && mounted) {
      setState(() {
        _isFullScreen = !_isFullScreen;
        print('🔄 Toggled _isFullScreen to: $_isFullScreen (from $source)');
      });
    }
  }

  // Handle tap based on screen position
  void _handleTapAtPosition(Offset globalPosition, String source) {
    if (_isSearching) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = globalPosition.dx;

    // Divide screen into 3 zones
    final leftZone = screenWidth * 0.25; // 25% left
    final rightZone = screenWidth * 0.75; // 75% right (25% right zone)

    print(
        '🎯 Tap at x=$tapX, screenWidth=$screenWidth, zones: left<$leftZone, right>$rightZone');

    if (_isHorizontalReading) {
      // Horizontal reading mode: left/right for page navigation, center for fullscreen
      if (tapX < leftZone) {
        // Left zone - previous page
        _previousPage();
      } else if (tapX > rightZone) {
        // Right zone - next page
        _nextPage();
      } else {
        // Center zone - toggle fullscreen
        _clearTempHighlight();
        _toggleFullScreenWithDebounce('center-horizontal');
      }
    } else {
      // Vertical reading mode: only center zone toggles fullscreen
      if (tapX >= leftZone && tapX <= rightZone) {
        // Center zone - toggle fullscreen
        _clearTempHighlight();
        _toggleFullScreenWithDebounce('center-vertical');
      } else {
        print('🚫 Tap in side zone ignored for vertical reading');
      }
    }
  }

  // Navigate to previous page in horizontal mode
  void _previousPage() {
    if (!_isHorizontalReading) return;

    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('📖 Navigated to previous page: ${_currentPageIndex - 1}');
    } else {
      // At first page, try to go to previous chapter
      final prevChapter = _getPreviousChapterNumber();
      if (prevChapter != null) {
        print('📖 Going to previous chapter: $prevChapter');
        _navigateToChapter(prevChapter);
      } else {
        print('📖 Already at first page of first chapter');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ở trang đầu tiên'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // Navigate to next page in horizontal mode
  void _nextPage() {
    if (!_isHorizontalReading) return;

    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('📖 Navigated to next page: ${_currentPageIndex + 1}');
    } else {
      // At last page, try to go to next chapter
      final nextChapter = _getNextChapterNumber();
      if (nextChapter != null) {
        print('📖 Going to next chapter: $nextChapter');
        _navigateToChapter(nextChapter);
      } else {
        print('📖 Already at last page of last chapter');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ở trang cuối cùng'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
