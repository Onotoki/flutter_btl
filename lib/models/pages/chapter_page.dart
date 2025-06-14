import 'package:btl/api/otruyen_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Thêm import cho Timer
import '../../services/chapter_cache_service.dart';
import '../chapter.dart';
import '../../components/info_book_widgets.dart/comment_chapter.dart'; // Thêm import cho CommentChapter

class ChapterPage extends StatefulWidget {
  final String storySlug;
  final String chapterTitle;
  final int chapterNumber;
  final String chapterApiData; // API URL để tải nội dung chương
  final List<Chapter> allChapters; // Danh sách tất cả các chương
  final int currentChapterIndex; // Index của chương hiện tại
  final String? idBook; // Thêm tham số idBook để lưu tiến độ

  const ChapterPage({
    super.key,
    required this.storySlug,
    required this.chapterApiData,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.allChapters,
    required this.currentChapterIndex,
    this.idBook, // Tham số tùy chọn
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
  final ChapterCacheService _cacheService = ChapterCacheService();

  // UI state
  bool _isUIVisible = true;
  late ScrollController _scrollController;
  int _currentImageIndex = 0;
  double _scrollProgress = 0.0;

  // Auto-scroll functionality - Tối ưu hóa
  bool _isAutoScrolling = false;
  bool _isAutoScrollActive = false; // Track if auto-scroll is actually running
  bool _isAutoScrollControlsVisible = true;
  Timer? _autoScrollTimer;
  double _autoScrollSpeed =
      80.0; // Tăng từ 50 lên 80 pixels per second, đảm bảo >= 10.0
  bool _wasUIVisibleBeforeAutoScroll = false;

  // Image preloading - Tính năng mới
  final Map<String, ImageProvider> _imageCache = {};
  final Set<int> _preloadedImages = {};

  // Firebase reading progress variables
  String? uid;
  bool isFirebase = false;
  double _scrollPercentage = 0.0;
  double sum = 0.0;
  double _lastSavedProgress = 0.0;
  int _lastSaveTime = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollProgress);

    // Đảm bảo autoScrollSpeed luôn trong khoảng hợp lệ (5.0 - 300.0)
    _autoScrollSpeed = _autoScrollSpeed.clamp(5.0, 300.0);

    // Initialize Firebase auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      _loadReadingProgress();
    }

    _loadChapterContent();
  }

  @override
  void dispose() {
    // Lưu tiến độ đọc trước khi dispose
    if (uid != null && widget.idBook != null) {
      updateReadingProgress(_scrollPercentage);
    }

    _scrollController.dispose();
    _autoScrollTimer?.cancel(); // Cancel timer when disposing
    // Clear image cache
    _imageCache.clear();
    _preloadedImages.clear();
    super.dispose();
  }

  // Tải tiến độ đọc từ Firebase
  Future<void> _loadReadingProgress() async {
    if (uid == null || widget.idBook == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.idBook)
          .get();

      if (doc.exists) {
        setState(() {
          isFirebase = true;
        });

        final data = doc.data()!;
        if (data.containsKey('chapters_reading')) {
          final chaptersReading =
              data['chapters_reading'] as Map<String, dynamic>;

          // Tính tổng tiến độ các chương trước
          sum = 0.0;
          for (int i = 1; i <= widget.currentChapterIndex; i++) {
            final chapterKey = i.toString();
            if (chaptersReading.containsKey(chapterKey)) {
              sum += (chaptersReading[chapterKey] as num).toDouble();
            }
          }

          // Lấy tiến độ chương hiện tại
          // Sửa lỗi: sử dụng (currentChapterIndex + 1) để nhất quán
          final currentChapterKey = (widget.currentChapterIndex + 1).toString();
          if (chaptersReading.containsKey(currentChapterKey)) {
            final currentProgress =
                (chaptersReading[currentChapterKey] as num).toDouble();

            // Khôi phục vị trí scroll sau khi content được tải
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && currentProgress > 0) {
                _restoreScrollPosition(currentProgress);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Lỗi khi tải tiến độ đọc: $e');
    }
  }

  // Khôi phục vị trí scroll
  void _restoreScrollPosition(double percentage) async {
    print('Khôi phục vị trí scroll: $percentage%');

    // Giảm thời gian chờ xuống để tăng tốc độ khôi phục vị trí
    await Future.delayed(const Duration(seconds: 2));

    if (_scrollController.hasClients) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final targetOffset = (percentage / 100.0) * maxExtent;

      // Sử dụng animateTo để tạo hiệu ứng mượt mà khi cuộn
      // _scrollController.animateTo(
      //   targetOffset,
      //   duration: const Duration(milliseconds: 500),
      //   curve: Curves.easeOutQuad, // Sử dụng curve mượt hơn
      // );
      _scrollController.jumpTo(targetOffset);

      // Hiển thị thông báo đã khôi phục vị trí đọc
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã khôi phục vị trí đọc'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.1,
              left: 20,
              right: 20),
        ),
      );
    }
  }

  // Cập nhật tiến độ đọc lên Firebase
  Future<void> updateReadingProgress(double newProgress) async {
    if (uid == null || widget.idBook == null) return;

    try {
      final rawProgress = (sum + newProgress) / widget.allChapters.length;
      final totalProgress = double.parse(rawProgress.toStringAsFixed(2));

      final docRef = FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.idBook);

      if (!isFirebase) {
        // Tạo mới document
        print('Tạo mới tiến độ đọc');
        await docRef.set({
          // Sửa lỗi: sử dụng (currentChapterIndex + 1) để khớp với chapterNumber
          'chapters_reading': {
            (widget.currentChapterIndex + 1).toString(): newProgress
          },
          'process': totalProgress,
          'slug': widget.storySlug,
          'id_book': widget.idBook,
          'totals_chapter': widget.allChapters.length
        });
        isFirebase = true;
      } else {
        // Cập nhật document hiện có
        print('Cập nhật tiến độ đọc');
        await docRef.set({
          // Sửa lỗi: sử dụng (currentChapterIndex + 1) để khớp với chapterNumber
          'chapters_reading': {
            (widget.currentChapterIndex + 1).toString(): newProgress
          },
          'process': totalProgress,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Lỗi khi cập nhật tiến độ đọc: $e');
    }
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients && contentImages.isNotEmpty) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScroll > 0) {
        final newProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);

        setState(() {
          _scrollProgress = newProgress;

          // Cập nhật _scrollPercentage cho Firebase
          _scrollPercentage = newProgress * 100;

          // Tính toán ảnh hiện tại dựa trên vị trí scroll
          final newImageIndex =
              ((currentScroll / maxScroll) * contentImages.length)
                  .floor()
                  .clamp(0, contentImages.length - 1);

          if (newImageIndex != _currentImageIndex) {
            _currentImageIndex = newImageIndex;
            // Trigger preloading when image index changes
            _preloadNearbyImages(_currentImageIndex);

            // Thêm: Lưu tiến độ đọc mỗi khi chuyển ảnh
            if (uid != null && widget.idBook != null) {
              updateReadingProgress(_scrollPercentage);
            }
          }
        });

        // Thêm: Lưu tiến độ đọc theo khoảng thời gian
        // Khi cuộn một đoạn dài (tránh cập nhật quá nhiều)
        if (uid != null && widget.idBook != null) {
          // Tính toán thay đổi phần trăm so với lần lưu trước
          final progressChange = (_scrollPercentage - _lastSavedProgress).abs();

          // Nếu đã cuộn hơn 5% hoặc đã quá lâu kể từ lần lưu trước
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (progressChange > 5.0 || currentTime - _lastSaveTime > 10000) {
            updateReadingProgress(_scrollPercentage);
            _lastSavedProgress = _scrollPercentage;
            _lastSaveTime = currentTime;
          }
        }
      }
    }
  }

  void _preloadNearbyImages(int currentIndex) {
    // Preload 3 images before and after current position
    for (int i = -3; i <= 3; i++) {
      final targetIndex = currentIndex + i;
      if (targetIndex >= 0 && targetIndex < contentImages.length) {
        _preloadImage(targetIndex);
      }
    }
  }

  void _preloadImage(int index) {
    if (_preloadedImages.contains(index) ||
        index < 0 ||
        index >= contentImages.length) {
      return;
    }

    final imageUrl = contentImages[index];
    if (_imageCache.containsKey(imageUrl)) {
      return;
    }

    _preloadedImages.add(index);

    final imageProvider = NetworkImage(imageUrl);
    _imageCache[imageUrl] = imageProvider;

    // Preload into memory
    precacheImage(imageProvider, context).catchError((error) {
      // Remove from cache if failed
      _imageCache.remove(imageUrl);
      _preloadedImages.remove(index);

      // Retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _preloadImage(index);
        }
      });
    });
  }

  Future<void> _loadChapterContent() async {
    String logs = '';
    try {
      logs += 'Đang tải nội dung chương từ: ${widget.chapterApiData}\n';

      // Try to get from cache first
      final cachedData = await _cacheService.getCachedChapter(
          widget.storySlug, widget.chapterNumber);

      if (cachedData != null) {
        print('Using cached data for comic chapter ${widget.chapterNumber}');
        _processChapterData(cachedData, logs + 'Sử dụng dữ liệu từ cache\n');

        // Preload adjacent chapters in background
        _preloadAdjacentChapters();
        return;
      }

      if (widget.chapterApiData.startsWith('http')) {
        logs += 'URL hợp lệ, đang gọi API để tải nội dung...\n';

        // Sử dụng phương thức API mới để tải nội dung chương
        final chapterContent =
            await OTruyenApi.getChapterContent(widget.chapterApiData);
        logs += 'Đã nhận phản hồi từ API\n';
        logs += 'Dữ liệu nhận được: ${chapterContent.keys.toList()}\n';

        // Cache the loaded data
        await _cacheService.cacheChapter(
            widget.storySlug, widget.chapterNumber, chapterContent);

        _processChapterData(chapterContent, logs);

        // Preload adjacent chapters in background
        _preloadAdjacentChapters();
      } else {
        logs += 'URL không hợp lệ: ${widget.chapterApiData}\n';
        setState(() {
          isLoading = false;
          errorMessage = 'URL chương không hợp lệ';
          debugInfo = logs;
        });
      }
    } catch (e) {
      logs += 'Lỗi khi tải nội dung: $e\n';
      setState(() {
        isLoading = false;
        errorMessage = 'Không thể tải nội dung chương: $e';
        debugInfo = logs;
      });
    }
  }

  void _processChapterData(Map<String, dynamic> chapterContent, String logs) {
    // Hiển thị nội dung chương (ảnh hoặc văn bản)
    if (chapterContent.containsKey('images') &&
        chapterContent['images'] is List<String> &&
        (chapterContent['images'] as List<String>).isNotEmpty) {
      final images = chapterContent['images'] as List<String>;
      logs += 'Tìm thấy ${images.length} ảnh để hiển thị\n';
      logs += 'URL ảnh đầu tiên: ${images[0]}\n';

      setState(() {
        contentImages = images;
        textContent = '';
        isLoading = false;
        debugInfo = logs;
      });
    } else if (chapterContent.containsKey('content') &&
        chapterContent['content'] != null &&
        chapterContent['content'].toString().isNotEmpty) {
      final content = chapterContent['content'].toString();
      logs +=
          'Tìm thấy nội dung văn bản: ${content.substring(0, content.length > 100 ? 100 : content.length)}...\n';

      setState(() {
        textContent = content;
        contentImages = [];
        isLoading = false;
        debugInfo = logs;
      });
    } else {
      logs += 'Không tìm thấy nội dung hợp lệ\n';
      logs += 'Cấu trúc dữ liệu: ${chapterContent.toString()}\n';

      setState(() {
        isLoading = false;
        errorMessage = 'Không tìm thấy nội dung chương';
        debugInfo = logs;
      });
    }
  }

  // Preload adjacent chapters for smoother navigation
  void _preloadAdjacentChapters() {
    // This would need to be implemented with navigation data from parent
    // For now, we'll just cache the current chapter
    print('Comic chapter cached: ${widget.chapterNumber}');

    // Start preloading first few images
    if (contentImages.isNotEmpty) {
      _preloadNearbyImages(0);
    }
  }

  void _toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                  Text('${widget.allChapters.length} chương'),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.allChapters.length,
                itemBuilder: (context, index) {
                  final chapter = widget.allChapters[index];
                  final isCurrentChapter = index == widget.currentChapterIndex;

                  return ListTile(
                    title: Text(
                      chapter.title.isEmpty
                          ? 'Chương ${chapter.name}'
                          : chapter.title,
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
                        chapter.name,
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
                        _navigateToChapter(index);
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

  void _navigateToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < widget.allChapters.length) {
      final chapter = widget.allChapters[chapterIndex];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterPage(
            storySlug: widget.storySlug,
            chapterTitle: chapter.title,
            chapterNumber: int.tryParse(chapter.name) ?? chapterIndex + 1,
            chapterApiData: chapter.apiData,
            allChapters: widget.allChapters,
            currentChapterIndex: chapterIndex,
            idBook: widget.idBook,
          ),
        ),
      );
    }
  }

  // Handle overscroll for chapter navigation
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      final overscroll = notification.overscroll;

      // Overscroll at top (positive overscroll, pulling down) - next chapter
      if (overscroll > 30) {
        final nextChapterIndex = widget.currentChapterIndex + 1;
        if (nextChapterIndex < widget.allChapters.length) {
          _navigateToChapter(nextChapterIndex);
          return true;
        }
      }
      // Overscroll at bottom (negative overscroll, pulling up) - previous chapter
      else if (overscroll < -30) {
        final prevChapterIndex = widget.currentChapterIndex - 1;
        if (prevChapterIndex >= 0) {
          _navigateToChapter(prevChapterIndex);
          return true;
        }
      }
    }
    return false;
  }

  // Auto-scroll functionality methods - Tối ưu hóa
  void _startAutoScroll() {
    // Save current UI visibility state and hide UI for better reading experience
    _wasUIVisibleBeforeAutoScroll = _isUIVisible;

    setState(() {
      _isAutoScrolling = true;
      _isAutoScrollActive = true;
      _isUIVisible = false; // Hide UI for immersive reading
      _isAutoScrollControlsVisible = true;
    });

    // Start auto-scroll timer - Tối ưu: 16ms interval cho 60fps
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients || !_isAutoScrollActive || !mounted) {
        timer.cancel();
        return;
      }

      final currentOffset = _scrollController.offset;
      final maxOffset = _scrollController.position.maxScrollExtent;

      // Calculate scroll increment based on speed - Tối ưu: 60fps thay vì 20fps
      final scrollIncrement =
          (_autoScrollSpeed / 60); // 16ms intervals = 60 times per second

      if (currentOffset >= maxOffset) {
        // Reached the end - try to go to next chapter
        timer.cancel();
        _handleAutoScrollChapterEnd();
        return;
      }

      // Tối ưu: Dùng jumpTo thay vì animateTo để giảm lag
      _scrollController.jumpTo(
        (currentOffset + scrollIncrement).clamp(0.0, maxOffset),
      );
    });
  }

  void _pauseAutoScroll() {
    setState(() {
      _isAutoScrollActive = false;
    });
    _autoScrollTimer?.cancel();
    // Don't change _isAutoScrolling state - just pause the timer
    // This way the control panel stays visible and user can resume
  }

  void _resumeAutoScroll() {
    if (_isAutoScrolling) {
      setState(() {
        _isAutoScrollActive = true;
      });

      // Start auto-scroll timer again - Tối ưu: 16ms interval cho 60fps
      _autoScrollTimer =
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_scrollController.hasClients || !_isAutoScrollActive || !mounted) {
          timer.cancel();
          return;
        }

        final currentOffset = _scrollController.offset;
        final maxOffset = _scrollController.position.maxScrollExtent;

        // Calculate scroll increment based on speed - Tối ưu: 60fps thay vì 20fps
        final scrollIncrement =
            (_autoScrollSpeed / 60); // 16ms intervals = 60 times per second

        if (currentOffset >= maxOffset) {
          // Reached the end - try to go to next chapter
          timer.cancel();
          _handleAutoScrollChapterEnd();
          return;
        }

        // Tối ưu: Dùng jumpTo thay vì animateTo để giảm lag
        _scrollController.jumpTo(
          (currentOffset + scrollIncrement).clamp(0.0, maxOffset),
        );
      });
    }
  }

  void _stopAutoScroll() {
    setState(() {
      _isAutoScrolling = false;
      _isAutoScrollActive = false;
      _isAutoScrollControlsVisible = true;
      // Restore previous UI visibility state
      _isUIVisible = _wasUIVisibleBeforeAutoScroll;
    });
    _autoScrollTimer?.cancel();
  }

  void _handleAutoScrollChapterEnd() {
    final nextChapterIndex = widget.currentChapterIndex + 1;
    if (nextChapterIndex < widget.allChapters.length) {
      // Show notification and continue to next chapter
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chuyển sang chương ${nextChapterIndex + 1}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to next chapter and continue auto-scroll
      _navigateToChapter(nextChapterIndex);

      // Start auto-scroll in new chapter after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startAutoScroll();
        }
      });
    } else {
      // Reached the end of the story
      _stopAutoScroll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đọc hết truyện!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _adjustAutoScrollSpeed(double newSpeed) {
    setState(() {
      _autoScrollSpeed =
          newSpeed.clamp(5.0, 300.0); // Đảm bảo nhất quán với EPUB reader
    });
  }

  void _toggleAutoScrollControls() {
    if (_isAutoScrolling) {
      setState(() {
        _isAutoScrollControlsVisible = !_isAutoScrollControlsVisible;
      });
    }
  }

  // Hiển thị bình luận theo chương
  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: CommentChapter(
            idBook: widget.idBook ?? widget.storySlug,
            chapterIndex: widget.currentChapterIndex,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isUIVisible
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.7),
              foregroundColor: Colors.white,
              title: Text(
                  'Chương ${widget.chapterNumber}: ${widget.chapterTitle}'),
              actions: [
                // Thêm nút bình luận
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: _showComments,
                  tooltip: 'Bình luận',
                ),
                // Auto-scroll button
                IconButton(
                  icon: Icon(
                    _isAutoScrollActive
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: _isAutoScrolling ? Colors.green : Colors.white,
                  ),
                  onPressed: () {
                    if (_isAutoScrollActive) {
                      _pauseAutoScroll();
                    } else if (_isAutoScrolling) {
                      _resumeAutoScroll();
                    } else {
                      // If not currently auto-scrolling, start it
                      _startAutoScroll();
                    }
                  },
                  tooltip: _isAutoScrollActive
                      ? 'Tạm dừng tự động cuộn'
                      : (_isAutoScrolling
                          ? 'Tiếp tục tự động cuộn'
                          : 'Bắt đầu tự động cuộn'),
                ),
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: _showChapterList,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Main content with overscroll detection
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: GestureDetector(
              onTap: () {
                // If in auto-scroll mode, tap toggles control panel visibility
                if (_isAutoScrolling) {
                  _toggleAutoScrollControls();
                } else {
                  _toggleUIVisibility();
                }
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : contentImages.isNotEmpty
                          // Chuyển sang sử dụng SingleChildScrollView + Column để render tất cả ảnh một lúc
                          ? SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  // Spacing cho AppBar khi hiển thị
                                  if (_isUIVisible) const SizedBox(height: 100),

                                  // Render tất cả ảnh trong một Column
                                  ...contentImages.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final imageUrl = entry.value;
                                    return _buildImageWidget(imageUrl, index);
                                  }).toList(),

                                  // Spacing ở cuối
                                  const SizedBox(height: 100),
                                ],
                              ),
                            )
                          // Text content cho truyện chữ
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Spacing for AppBar when visible
                                  if (_isUIVisible) const SizedBox(height: 100),

                                  // Text content for novel chapters
                                  if (textContent.isNotEmpty)
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

                                  // Bottom spacing
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
            ),
          ),

          // Right slider with navigation buttons (only show when UI is visible)
          if (_isUIVisible && contentImages.isNotEmpty)
            Positioned(
              right: 8,
              top: 120,
              bottom: 120,
              child: Container(
                width: 32,
                child: Column(
                  children: [
                    // Up arrow button
                    GestureDetector(
                      onTap: _scrollToTop,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Thin slider
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 1, // Rotate to make it vertical
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6.0,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10.0),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20.0),
                            activeTrackColor: Colors.black.withOpacity(0.4),
                            inactiveTrackColor: Colors.black.withOpacity(0.4),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.2),
                            trackShape: const RoundedRectSliderTrackShape(),
                          ),
                          child: Slider(
                            value: _scrollProgress,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) {
                              if (!_scrollController.hasClients) return;

                              final targetScroll = value *
                                  _scrollController.position.maxScrollExtent;
                              _scrollController.jumpTo(targetScroll);
                            },
                            onChangeEnd: (value) {
                              // Optional: Add haptic feedback when slider interaction ends
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Down arrow button
                    GestureDetector(
                      onTap: _showChapterList,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.list,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Down arrow button
                    GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Auto-scroll control panel
          if (_isAutoScrolling && contentImages.isNotEmpty)
            _buildAutoScrollControlPanel(),
        ],
      ),

      // Bottom progress bar (always visible)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chương: ${widget.currentChapterIndex + 1}/${widget.allChapters.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              contentImages.isNotEmpty
                  ? '${(((_currentImageIndex + 1) / contentImages.length) * 100).round()}%'
                  : '%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              contentImages.isNotEmpty
                  ? 'Trang: ${_currentImageIndex + 1}/${contentImages.length}'
                  : 'Trang: 1/1',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoScrollControlPanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: _isAutoScrollControlsVisible ? 0 : -80,
      top: MediaQuery.of(context).size.height * 0.2,
      child: Container(
        width: 80,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(-2, 0),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            // Speed display (more compact)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    '${_autoScrollSpeed.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'px/s',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Speed slider (vertical, taking most space)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16.0),
                      activeTrackColor: Colors.green,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.green,
                      overlayColor: Colors.green.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _autoScrollSpeed,
                      min: 5.0,
                      max: 300.0,
                      onChanged: _adjustAutoScrollSpeed,
                    ),
                  ),
                ),
              ),
            ),

            // Control buttons (more compact)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause button
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(
                        _isAutoScrollActive ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        if (_isAutoScrollActive) {
                          _pauseAutoScroll();
                        } else {
                          _resumeAutoScroll();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Stop button
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _stopAutoScroll,
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

  Widget _buildImageWidget(String imageUrl, int index) {
    // Sử dụng cached image provider nếu có
    // final ImageProvider imageProvider =
    //     _imageCache[imageUrl] ?? NetworkImage(imageUrl);

    // return Image(
    //   image: imageProvider,
    //   fit: BoxFit.fitWidth,
    //   width: double.infinity,
    //   loadingBuilder: (context, child, loadingProgress) {
    //     if (loadingProgress == null) return child;
    //     return Container(
    //       width: double.infinity,
    //       height: 200,
    //       color: Colors.grey[200],
    //       child: Center(
    //         child: CircularProgressIndicator(
    //           value: loadingProgress.expectedTotalBytes != null
    //               ? loadingProgress.cumulativeBytesLoaded /
    //                   loadingProgress.expectedTotalBytes!
    //               : null,
    //         ),
    //       ),
    //     );
    //   },
    //   errorBuilder: (context, error, stackTrace) {
    //     // Auto retry khi ảnh lỗi
    //     Future.delayed(const Duration(seconds: 1), () {
    //       if (mounted) {
    //         _preloadImage(index);
    //       }
    //     });

    //     return Container(
    //       width: double.infinity,
    //       height: 200,
    //       color: Colors.grey[300],
    //       child: Center(
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             const Icon(Icons.image_not_supported),
    //             const SizedBox(height: 8),
    //             const Text('Không thể tải ảnh', style: TextStyle(fontSize: 14)),
    //             const SizedBox(height: 4),
    //             Text(
    //               imageUrl.length > 50
    //                   ? '${imageUrl.substring(0, 50)}...'
    //                   : imageUrl,
    //               style: const TextStyle(fontSize: 12),
    //             ),
    //             const SizedBox(height: 8),
    //             const Text('Đang thử lại...',
    //                 style: TextStyle(fontSize: 10, color: Colors.orange)),
    //           ],
    //         ),
    //       ),
    //     );
    //   },
    // );
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}