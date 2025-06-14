/**
 * TRANG ĐỌC TRUYỆN CHỮ (EPUB CHAPTER PAGE)
 * 
 * Đây là component chính của ứng dụng đọc truyện, chịu trách nhiệm hiển thị và quản lý
 * tất cả các tính năng liên quan đến việc đọc truyện chữ.
 * 
 * CHỨC NĂNG CHÍNH:
 * 
 * 1. HIỂN THỊ NỘI DUNG TRUYỆN
 *    - Hiển thị nội dung chương theo 2 chế độ: dọc (scroll) và ngang (page)
 *    - Tự động chia trang thông minh cho chế độ đọc ngang
 *    - Hỗ trợ chế độ toàn màn hình để tập trung đọc
 * 
 * 2. TÙY CHỈNH GIAO DIỆN ĐỌC
 *    - Điều chỉnh kích thước font chữ (16px mặc định, có thể thay đổi)
 *    - Thay đổi chiều cao dòng (1.6 mặc định) để tối ưu trải nghiệm đọc
 *    - Chọn từ 10+ font chữ khác nhau (Roboto, Arial, Times New Roman, v.v.)
 *    - Tùy chỉnh màu nền và màu chữ (mặc định: trắng/đen)
 *    - Lưu tất cả cài đặt vào SharedPreferences để duy trì qua các phiên đọc
 * 
 * 3. TEXT-TO-SPEECH (TTS) THÔNG MINH
 *    - Chuyển văn bản thành giọng nói với hỗ trợ đa ngôn ngữ
 *    - Ưu tiên tiếng Việt, fallback sang tiếng Anh nếu cần
 *    - Điều khiển đầy đủ: play/pause/stop/điều chỉnh tốc độ
 *    - Highlight đoạn văn đang được đọc bằng màu sắc
 *    - Tự động cuộn theo tiến độ đọc TTS
 *    - Chia nhỏ văn bản thành các đoạn phù hợp cho TTS
 * 
 * 4. TÌM KIẾM NÂNG CAO
 *    - Tìm kiếm trong chương hiện tại với highlight kết quả
 *    - Tìm kiếm toàn cục trong tất cả chương của truyện
 *    - Điều hướng nhanh giữa các kết quả tìm kiếm
 *    - Highlight tạm thời (5 giây) cho kết quả được chọn
 * 
 * 5. HIGHLIGHT VÀ BOOKMARK
 *    - Đánh dấu đoạn văn quan trọng với màu highlight
 *    - Tạo bookmark tại vị trí đọc hiện tại
 *    - Quản lý danh sách highlight/bookmark với khả năng xóa/chỉnh sửa
 *    - Điều hướng nhanh đến các vị trí đã đánh dấu
 * 
 * 6. TỰ ĐỘNG CUỘN THÔNG MINH
 *    - Tự động cuộn với tốc độ có thể điều chỉnh (5-300 pixels/giây)
 *    - Chỉ hoạt động ở chế độ đọc dọc (vertical mode)
 *    - Điều khiển play/pause/resume dễ dàng
 *    - Tự động chuyển fullscreen khi bật auto-scroll
 * 
 * 7. THEO DÕI TIẾN ĐỘ ĐỌC
 *    - Lưu vị trí đọc hiện tại vào Firebase Firestore
 *    - Đồng bộ tiến độ đọc qua nhiều thiết bị
 *    - Hiển thị phần trăm đã đọc trong chương
 *    - Tự động tiếp tục từ vị trí cũ khi mở lại
 * 
 * 8. HỆ THỐNG BÌNH LUẬN
 *    - Bình luận theo từng chương cụ thể
 *    - Hỗ trợ trả lời bình luận (nested comments)
 *    - Hiển thị số lượng bình luận trong icon
 *    - Tích hợp với Firebase để lưu trữ và đồng bộ
 * 
 * 9. QUẢN LÝ CACHE VÀ HIỆU NĂNG
 *    - Cache nội dung chương để đọc offline
 *    - Lazy loading để tối ưu hiệu năng
 *    - Quản lý bộ nhớ thông minh
 * 
 * 10. DỊCH THUẬT
 *    - Popup dịch văn bản được chọn
 *    - Hỗ trợ dịch sang nhiều ngôn ngữ khác nhau
 * 
 * KIẾN TRÚC KỸ THUẬT:
 * - Sử dụng StatefulWidget để quản lý state phức tạp
 * - Tích hợp với multiple services: ReadingService, TTSService, SettingsService
 * - Sử dụng Firebase cho authentication và data storage
 * - Tối ưu hiệu năng với proper dispose và memory management
 */

import 'package:flutter/material.dart';
import '../../api/otruyen_api.dart';
import '../story.dart';
import '../highlight.dart';
import '../bookmark.dart';
import '../../services/reading_service.dart';
import '../../services/reading_settings_service.dart';
import '../../services/chapter_cache_service.dart';
import '../../services/tts_service.dart';
import '../../components/selectable_text_widget.dart';
import '../../components/info_book_widgets.dart/comment_chapter.dart'; // Thêm import CommentChapter
import 'highlights_bookmarks_page.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import cho Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Thêm import cho Firebase Auth

/**
 * EPUB CHAPTER PAGE - WIDGET CHÍNH
 * 
 * Widget này nhận các tham số đầu vào để hiển thị chương truyện cụ thể:
 * - story: Thông tin truyện từ API
 * - chapterNumber: Số chương (bắt đầu từ 1)
 * - chapterTitle: Tiêu đề chương
 * - initialScrollPosition: Vị trí cuộn ban đầu (optional)
 * - searchText: Văn bản cần highlight khi search (optional)
 * - bookmarkText: Văn bản bookmark để highlight (optional)
 * - autoStartTTS: Tự động bật TTS khi load (mặc định false)
 */
class EpubChapterPage extends StatefulWidget {
  final Story story; // Thông tin truyện từ API
  final int chapterNumber; // Số chương (bắt đầu từ 1)
  final String chapterTitle; // Tiêu đề chương
  final int? initialScrollPosition; // Vị trí cuộn ban đầu (optional)
  final String? searchText; // Text để highlight khi search (optional)
  final String? bookmarkText; // Text bookmark để highlight (optional)
  final bool autoStartTTS; // Tự động bật TTS khi load (mặc định false)

  const EpubChapterPage({
    Key? key,
    required this.story,
    required this.chapterNumber,
    required this.chapterTitle,
    this.initialScrollPosition,
    this.searchText,
    this.bookmarkText, // For bookmark highlighting
    this.autoStartTTS = false, // Default to false
  }) : super(key: key);

  @override
  State<EpubChapterPage> createState() => _EpubChapterPageState();
}

/**
 * STATE CLASS CHO EPUB CHAPTER PAGE
 * 
 * Class này quản lý tất cả state và logic của trang đọc truyện chữ.
 * Được tổ chức thành các nhóm biến theo chức năng để dễ bảo trì.
 */
class _EpubChapterPageState extends State<EpubChapterPage> {
  // QUẢN LÝ TRẠNG THÁI LOADING VÀ DỮ LIỆU CHƯƠNG
  bool _isLoading = true; // Trạng thái đang tải nội dung chương
  String? _error; // Thông báo lỗi nếu có
  Map<String, dynamic>? _chapterData; // Dữ liệu chương từ API
  List<Map<String, dynamic>> _allChapters =
      []; // Danh sách tất cả chương trong truyện
  bool _settingsLoaded = false; // Đã load xong cài đặt đọc chưa

  // ===============
  // CÁC SERVICE - TẦNG XỬ LÝ LOGIC NGHIỆP VỤ
  // ==========================
  final ReadingSettingsService _settingsService =
      ReadingSettingsService(); // Quản lý cài đặt đọc (font, màu sắc, v.v.)
  final ChapterCacheService _cacheService =
      ChapterCacheService(); // Cache nội dung chương để đọc offline
  final ReadingService _readingService =
      ReadingService(); // Quản lý tiến độ đọc, highlight, bookmark
  final TTSService _ttsService = TTSService(); // Text-to-Speech service

  // =============
  // CÀI ĐẶT GIAO DIỆN ĐỌC - ĐƯỢC LOAD TỪ SHAREDPREFERENCES
  // ================================
  double _fontSize = 16.0; // Kích thước font chữ (có thể điều chỉnh 8-30px)
  double _lineHeight = 1.6; // Chiều cao dòng (1.0-3.0) - 1.6 là tối ưu cho mắt
  String _fontFamily = 'Roboto'; // Font chữ hiện tại (có 10+ font khả dụng)
  Color _backgroundColor = Colors.white; // Màu nền trang đọc
  Color _textColor = Colors.black; // Màu chữ
  bool _isFullScreen = false; // Chế độ toàn màn hình (ẩn AppBar)
  bool _isHorizontalReading = false; // Chế độ đọc ngang (page) vs dọc (scroll)
  List<String> _pages = []; // Danh sách trang khi đọc ngang
  int _currentPageIndex = 0; // Trang hiện tại (chỉ dùng cho đọc ngang)
  late ScrollController _scrollController; // Controller cho scroll dọc
  late PageController _pageController; // Controller cho page ngang

  // =============
  // TỰ ĐỘNG CUỘN THÔNG MINH (CHỈ CHO CHỂ ĐỘ ĐỌC DỌC)
  // ====================
  bool _isAutoScrolling = false; // Đã bật chế độ auto-scroll chưa
  bool _isAutoScrollActive = false; // Auto-scroll có đang chạy thực sự không
  bool _isAutoScrollControlsVisible = true; // Hiển thị controls auto-scroll
  Timer? _autoScrollTimer; // Timer điều khiển auto-scroll
  double _autoScrollSpeed =
      80.0; // Tốc độ cuộn (5-300 pixels/giây) - 80 là tối ưu
  bool _wasFullScreenBeforeAutoScroll =
      false; // Trạng thái fullscreen trước khi auto-scroll

  // ==========
  // THEO DÕI TIẾN ĐỘ ĐỌC VÀ ĐỒNG BỘ FIREBASE
  // ========================
  double _readingProgress =
      0.0; // Phần trăm đã đọc trong chương hiện tại (0.0-1.0)

  // Firebase reading progress tracking - Đồng bộ tiến độ qua thiết bị
  String? uid; // User ID từ Firebase Auth
  bool isFirebase = false; // Kiểm tra xem có dữ liệu trên Firebase không
  double sum = 0.0; // Tổng tiến độ các chương trước đó
  double _scrollPercentage = 0.0; // Phần trăm scroll hiện tại (0.0-1.0)
  double _lastSavedProgress =
      0.0; // Tiến độ đã lưu lần cuối (để tránh lưu liên tục)
  int _lastSaveTime = 0; // Thời gian lưu lần cuối (milliseconds)

  // =========
  // HIGHLIGHT VÀ BOOKMARK - ĐÁNH DẤU VÀ LƯU VỊ TRÍ QUAN TRỌNG
  // ====================
  List<Highlight> _highlights = []; // Danh sách các đoạn văn được highlight
  List<Bookmark> _bookmarks = []; // Danh sách các bookmark (vị trí đánh dấu)

  // =====================================
  // TÌM KIẾM NÂNG CAO - TRONG CHƯƠNG VÀ TOÀN CỤC
  // =================
  bool _isSearching = false; // Đang ở chế độ tìm kiếm
  String _searchQuery = ''; // Từ khóa tìm kiếm hiện tại
  List<Map<String, dynamic>> _searchResults =
      []; // Kết quả tìm kiếm trong chương
  int _currentSearchIndex = -1; // Vị trí kết quả hiện tại (-1 = chưa chọn)
  final TextEditingController _searchController =
      TextEditingController(); // Controller input search
  bool _isGlobalSearch =
      false; // true: tìm tất cả chương, false: chỉ chương hiện tại
  List<Map<String, dynamic>> _globalSearchResults =
      []; // Kết quả tìm kiếm toàn cục

  // Temporary highlight cho kết quả tìm kiếm (tự động xóa sau 5 giây)
  int? _tempHighlightStart; // Vị trí bắt đầu highlight tạm thời
  int? _tempHighlightEnd; // Vị trí kết thúc highlight tạm thời
  String? _tempHighlightText; // Text được highlight tạm thời

  // =========================================
  // THEO DÕI LỰA CHỌN VĂN BẢN (CHO HIGHLIGHT/BOOKMARK)
  // ===========
  bool _isTextSelectionActive = false; // Đang có text được select không
  Timer? _tapTimer; // Timer để phân biệt single tap vs long press

  // ==========================
  // TEXT-TO-SPEECH (TTS) - CHUYỂN VĂN BẢN THÀNH GIỌNG NÓI
  // ===================
  bool _isTTSEnabled = false; // Đã bật chế độ TTS chưa
  bool _isTTSControlsVisible = false; // Hiển thị controls TTS
  bool _isTTSPlaying = false; // TTS có đang phát không
  bool _isTTSPaused = false; // TTS có đang tạm dừng không
  int _currentTTSParagraph =
      -1; // Đoạn văn hiện tại đang được đọc (-1 = chưa bắt đầu)
  List<String> _ttsParagraphs =
      []; // Danh sách các đoạn văn đã chia nhỏ cho TTS

  // TTS Language selection - Chọn ngôn ngữ đọc
  String? _selectedLanguage = 'vi-VN'; // Ngôn ngữ mặc định (Tiếng Việt)
  List<dynamic> _availableLanguages =
      []; // Danh sách ngôn ngữ có sẵn trên thiết bị
  bool _isCurrentLanguageInstalled = false; // Ngôn ngữ hiện tại đã cài đặt chưa

  // TTS highlighting variables - Highlight đoạn đang được đọc
  int? _ttsHighlightStart; // Vị trí bắt đầu highlight TTS
  int? _ttsHighlightEnd; // Vị trí kết thúc highlight TTS
  bool _ttsAutoScrollEnabled = true; // Tự động cuộn theo TTS (mặc định bật)
  bool _wasFullScreenBeforeTTS =
      false; // Trạng thái fullscreen trước khi bật TTS

  // TTS paragraph mapping - Lưu vị trí gốc của các đoạn
  List<Map<String, dynamic>> _ttsParagraphPositions =
      []; // Map đoạn TTS với vị trí trong text gốc

  // ==============================
  // HỆ THỐNG BÌNH LUẬN THEO CHƯƠNG
  // ===============

  /**
   * Hiển thị modal bottom sheet chứa danh sách bình luận của chương hiện tại
   * Modal này chiếm 90% chiều cao màn hình và tự động cập nhật số lượng comment khi đóng
   */
  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép điều khiển chiều cao modal
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9, // Modal chiếm 90% chiều cao màn hình
          child: CommentChapter(
            idBook:
                widget.story.id ?? widget.story.slug, // ID sách để lưu comment
            chapterIndex: widget.chapterNumber, // Số chương để group comment
          ),
        );
      },
    ).then((_) =>
        _getCommentCount()); // Cập nhật lại số lượng comment sau khi đóng modal
  }

  /**
   * Lấy số lượng bình luận của chương hiện tại từ Firebase Firestore
   * 
   * Cấu trúc dữ liệu Firebase:
   * books/{bookId}/chapter_comment/{chapterIndex}/comments/{commentId}
   * 
   * Function này được gọi khi:
   * - Trang được khởi tạo (initState)
   * - Sau khi đóng modal comment để cập nhật số lượng mới
   */
  Future<void> _getCommentCount() async {
    try {
      final idBook = widget.story.id ?? widget.story.slug; // ID sách duy nhất
      final chapterIndex = widget.chapterNumber; // Số chương

      print(
          'Đang lấy số lượng bình luận cho sách $idBook, chương $chapterIndex');

      // Truy vấn tất cả bình luận của chương này theo cấu trúc lưu trữ của CommentChapter
      // Chỉ đếm số lượng document, không load nội dung để tối ưu performance
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .doc(idBook)
          .collection('chapter_comment')
          .doc('$chapterIndex')
          .collection('comments')
          .get();

      if (mounted) {
        // Kiểm tra widget còn tồn tại không
        setState(() {
          _commentCount = snapshot.docs.length; // Cập nhật số lượng comment
          print('Số lượng bình luận: $_commentCount');
        });
      }
    } catch (e) {
      print('Lỗi khi lấy số lượng bình luận: $e');
    }
  }

  // =====================================
  // DANH SÁCH FONT CHỮ CÓ SẴN VÀ CÁC BIẾN TRẠNG THÁI KHÁC
  // =====================================

  // Danh sách 10 font chữ phổ biến để người dùng lựa chọn
  final List<String> _availableFonts = [
    'Roboto', // Font mặc định của Android
    'Arial', // Font phổ biến trên Windows
    'Times New Roman', // Font serif cổ điển
    'Georgia',
    'Courier New',
    'Verdana',
    'Tahoma',
    'Comic Sans MS'
  ];

  // Biến trạng thái để theo dõi overlay đánh dấu (highlight/bookmark)
  bool _isHighlightBookmarkOverlayVisible =
      false; // Có đang hiển thị overlay highlight/bookmark không

  // Biến lưu số lượng bình luận hiện tại (hiển thị trong badge)
  int _commentCount = 0; // Số lượng comment của chương hiện tại

  // =====================================
  // KHỞI TẠO WIDGET - THIẾT LẬP TẤT CẢ CONTROLLER VÀ SERVICE
  // ================================================

  @override
  void initState() {
    super.initState();

    // =====================================
    //KHỞI TẠO CÁC CONTROLLER CHO SCROLL VÀ PAGE
    // ===============================================
    _scrollController =
        ScrollController(); // Controller cho chế độ đọc dọc (scroll)
    _pageController =
        PageController(); // Controller cho chế độ đọc ngang (page)

    // Thêm listener để theo dõi tiến độ đọc khi user scroll
    _scrollController.addListener(_updateReadingProgress);

    // ===================================
    // KHỞI TẠO FIREBASE AUTH VÀ ĐỒNG BỘ TIẾN ĐỘ ĐỌC
    // ==============================
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid; // Lưu User ID để đồng bộ dữ liệu
      _loadReadingProgress(); // Load tiến độ đọc từ Firebase
    }

    // Khởi tạo thời gian lưu trạng thái ban đầu (để tránh lưu quá thường xuyên)
    _lastSaveTime = DateTime.now().millisecondsSinceEpoch;

    // ==============================
    // LOAD CÀI ĐẶT VÀ DỮ LIỆU BAN ĐẦU
    // ===============================
    _loadSettings(); // Load cài đặt đọc từ SharedPreferences

    // Lấy số lượng bình luận để hiển thị badge
    _getCommentCount();

    // ========================================================================
    // TỰ ĐỘNG BẬT TTS NẾU ĐƯỢC YÊU CẦU (CHO CHỨC NĂNG "NGHE TRUYỆN")
    // ========================================================================
    if (widget.autoStartTTS) {
      print('Tự động bắt đầu TTS theo yêu cầu');
      // Delay để đảm bảo trang đã được load hoàn toàn
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          // Kiểm tra widget còn tồn tại
          // Lưu trạng thái fullscreen hiện tại và chuyển sang fullscreen cho TTS
          _wasFullScreenBeforeTTS = _isFullScreen;

          setState(() {
            _isTTSEnabled = true; // Bật TTS
            _isTTSControlsVisible = true; // Hiển thị controls
            _isFullScreen = true; // Chuyển fullscreen để focus vào TTS
          });

          _saveSettings(); // Lưu cài đặt fullscreen
          _clearTempHighlight(); // Xóa highlight tạm thời
          _clearSearch(); // Xóa search

          // Delay thêm để đảm bảo TTS content đã được thiết lập
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _playTTS(); // Bắt đầu phát TTS
            }
          });
        }
      });
    }
  }

  /**
   * CẬP NHẬT TIẾN ĐỘ ĐỌC DỰA TRÊN VỊ TRÍ CUỘN
   *
   * Phương thức này được gọi mỗi khi người dùng cuộn trang để cập nhật
   * phần trăm đã đọc và đồng bộ lên Firebase nếu cần thiết.
   */
  /// Cập nhật tiến độ đọc dựa trên vị trí cuộn
  /// Phương thức này sẽ tính toán phần trăm đã đọc và lưu lên Firebase nếu cần thiết
  void _updateReadingProgress() {
    // Kiểm tra xem ScrollController có client không
    if (!_scrollController.hasClients) return;

    // Lấy vị trí cuộn hiện tại (offset) và chiều dài tối đa có thể cuộn
    final scrollOffset =
        _scrollController.offset; // offset là vị trí cuộn hiện tại
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Nếu chiều dài tối đa lớn hơn 0, tính toán tiến độ
    if (maxScrollExtent > 0) {
      final newProgress =
          (scrollOffset / maxScrollExtent * 100).clamp(0.0, 100.0);
      setState(() {
        _readingProgress = newProgress; // Cập nhật tiến độ đọc
      });

      // Lưu tiến độ lên Firebase nếu có thay đổi đáng kể
      _saveProgressToFirebaseIfNeeded(newProgress);
    }
  }

  /**
   * LƯU TIẾN ĐỘ LÊN FIREBASE NẾU CẦN THIẾT
   *
   * Tránh spam requests bằng cách chỉ lưu khi:
   * - Thay đổi >= 5% hoặc
   * - Đã qua 10 giây kể từ lần lưu cuối
   */
  void _saveProgressToFirebaseIfNeeded(double newProgress) {
    if (uid == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final progressDiff = (newProgress - _lastSavedProgress).abs();
    final timeDiff = now - _lastSaveTime;

    // Lưu nếu:
    // 1. Thay đổi >= 5% hoặc
    // 2. Đã qua 10 giây kể từ lần lưu cuối
    if (progressDiff >= 5.0 || timeDiff >= 10000) {
      _lastSavedProgress = newProgress;
      _lastSaveTime = now;
      updateReadingProgress(newProgress);
    }
  }

  /**
   * CẬP NHẬT TIẾN ĐỘ ĐỌC CHO CHẾ ĐỘ ĐỌC NGANG
   *
   * Tính toán phần trăm dựa trên trang hiện tại và tổng số trang.
   */
  void _updateHorizontalReadingProgress() {
    if (_pages.isEmpty) return;

    final newProgress =
        ((_currentPageIndex + 1) / _pages.length * 100).clamp(0.0, 100.0);
    setState(() {
      _readingProgress = newProgress;
    });

    // Lưu tiến độ lên Firebase nếu có thay đổi đáng kể
    _saveProgressToFirebaseIfNeeded(newProgress);
  }

  /**
   * TÍNH TOÁN TRANG ƯỚC TÍNH CHO CHẾ ĐỘ ĐỌC DỌC
   *
   * Ước tính trang hiện tại dựa trên vị trí cuộn và chiều cao viewport.
   */
  int _getCurrentEstimatedPage() {
    if (!_scrollController.hasClients) return 1;

    final scrollOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (maxScrollExtent <= 0) return 1;

    // Ước tính tổng số trang dựa trên chiều cao nội dung
    final totalContentHeight = maxScrollExtent + viewportHeight;
    final estimatedTotalPages = (totalContentHeight / viewportHeight).ceil();

    // Tính toán trang hiện tại
    final currentPage =
        ((scrollOffset / maxScrollExtent) * (estimatedTotalPages - 1)).floor() +
            1;

    return currentPage.clamp(1, estimatedTotalPages);
  }

  /**
   * TÍNH TỔNG SỐ TRANG ƯỚC TÍNH
   *
   * Tính toán tổng số trang dựa trên chiều cao nội dung và viewport.
   */
  int _getTotalEstimatedPages() {
    if (!_scrollController.hasClients) return 1;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (maxScrollExtent <= 0) return 1;

    final totalContentHeight = maxScrollExtent + viewportHeight;
    return (totalContentHeight / viewportHeight).ceil();
  }

  /**
   * TẢI CÀI ĐẶT TỪ SHAREDPREFERENCES
   *
   * Load tất cả cài đặt đọc truyện đã lưu trước đó như font chữ,
   * màu sắc, chế độ đọc, tốc độ auto-scroll, v.v.
   */
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
        // Đảm bảo autoScrollSpeed luôn nằm trong khoảng hợp lệ (5.0 - 300.0)
        final rawSpeed = settings['autoScrollSpeed']?.toDouble() ?? 80.0;
        _autoScrollSpeed = rawSpeed.clamp(5.0, 300.0);
        _settingsLoaded = true;
      });

      print('Cài đặt EPUB đã được tải thành công');
    } catch (e) {
      print('Lỗi khi tải cài đặt EPUB: $e');
      setState(() {
        _settingsLoaded = true;
      });
    }

    _loadChapterContent();
    _loadTableOfContents();
    _loadHighlightsAndBookmarks();

    // Khởi tạo tiến độ đọc dựa trên chế độ đọc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isHorizontalReading && _pages.isNotEmpty) {
        _updateHorizontalReadingProgress();
      }
    });
  }

  /**
   * LƯU CÀI ĐẶT KHI CÓ THAY ĐỔI
   *
   * Lưu tất cả cài đặt hiện tại vào SharedPreferences và
   * tính toán lại trang nếu cần thiết.
   */
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
        'autoScrollSpeed': _autoScrollSpeed,
      });

      // Nếu đang ở chế độ đọc ngang, tính toán lại trang khi font thay đổi
      if (_isHorizontalReading && _chapterData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePagesBasedOnScreenSize();
        });
      }

      print('Cài đặt EPUB đã được lưu thành công');
    } catch (e) {
      print('Lỗi khi lưu cài đặt EPUB: $e');
    }
  }

  /**
   * HÀM TIỆN ÍCH ĐỂ TÍNH TOÁN LẠI TRANG
   *
   * Được gọi khi có thay đổi font hoặc kích thước ảnh hưởng đến layout.
   */
  void _recalculatePages() {
    if (_isHorizontalReading && _chapterData != null) {
      _calculatePagesBasedOnScreenSize();
    }
  }

  /**
   * GIẢI PHÓNG TÀI NGUYÊN KHI WIDGET BỊ HỦY
   *
   * Lưu tiến độ đọc cuối cùng và giải phóng tất cả controller,
   * timer và service để tránh memory leak.
   */
  @override
  void dispose() {
    // Lưu tiến độ đọc trước khi dispose
    if (uid != null && widget.story.slug.isNotEmpty) {
      updateReadingProgress(_readingProgress);
    }

    _scrollController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _autoScrollTimer?.cancel();
    _tapTimer?.cancel();
    // Dọn dẹp TTS
    _ttsService.dispose();
    // Xóa cache khi dispose
    _chapterContentCache.clear();
    super.dispose();
  }

  /**
   * TẢI TIẾN ĐỘ ĐỌC TỪ FIREBASE
   *
   * Lấy tiến độ đọc đã lưu từ Firebase Firestore và khôi phục
   * vị trí đọc cuối cùng của người dùng.
   */
  Future<void> _loadReadingProgress() async {
    if (uid == null || widget.story.slug.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.story.slug)
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
          for (int i = 1; i < widget.chapterNumber; i++) {
            final chapterKey = i.toString();
            if (chaptersReading.containsKey(chapterKey)) {
              sum += (chaptersReading[chapterKey] as num).toDouble();
            }
          }

          // Lấy tiến độ chương hiện tại
          final currentChapterKey = widget.chapterNumber.toString();
          if (chaptersReading.containsKey(currentChapterKey)) {
            final currentProgress =
                (chaptersReading[currentChapterKey] as num).toDouble();

            // Khôi phục vị trí scroll sau khi content được tải
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (currentProgress > 0) {
                _restoreScrollPosition(currentProgress);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Lỗi khi tải tiến độ đọc EPUB: $e');
    }
  }

  /**
   * KHÔI PHỤC VỊ TRÍ SCROLL
   *
   * Khôi phục vị trí đọc cuối cùng dựa trên phần trăm tiến độ đã lưu.
   * Hỗ trợ cả chế độ đọc dọc (scroll) và ngang (page).
   */
  void _restoreScrollPosition(double percentage) async {
    print('Khôi phục vị trí scroll EPUB: $percentage%');

    if (_isHorizontalReading) {
      // Cho chế độ đọc ngang, tính toán trang dựa trên phần trăm
      if (_pages.isNotEmpty) {
        final targetPageIndex = ((percentage / 100.0) * _pages.length).floor();
        final validPageIndex = targetPageIndex.clamp(0, _pages.length - 1);

        setState(() {
          _currentPageIndex = validPageIndex;
        });

        // Cập nhật PageController nếu cần
        if (_pageController.hasClients) {
          _pageController.jumpToPage(validPageIndex);
        }

        _updateHorizontalReadingProgress();
      }
    } else {
      // Cho chế độ đọc dọc, khôi phục vị trí scroll
      await Future.delayed(const Duration(milliseconds: 500));

      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final targetOffset = (percentage / 100.0) * maxExtent;

        _scrollController.jumpTo(targetOffset.clamp(0.0, maxExtent));
      }
    }
  }

  /**
   * CẬP NHẬT TIẾN ĐỘ ĐỌC LÊN FIREBASE
   *
   * Lưu tiến độ đọc hiện tại lên Firebase Firestore để đồng bộ
   * qua nhiều thiết bị và tính toán tổng tiến độ của cả cuốn sách.
   */
  Future<void> updateReadingProgress(double newProgress) async {
    if (uid == null || widget.story.slug.isEmpty) return;

    try {
      // Tính tổng số chương từ _allChapters
      final totalChapters = _allChapters.isNotEmpty ? _allChapters.length : 1;
      final rawProgress = (sum + newProgress) / totalChapters;
      final totalProgress = double.parse(rawProgress.toStringAsFixed(2));

      final docRef = FirebaseFirestore.instance
          .collection('user_reading')
          .doc(uid)
          .collection('books_reading')
          .doc(widget.story.slug);

      if (!isFirebase) {
        // Tạo mới document
        print('Tạo mới tiến độ đọc EPUB');
        await docRef.set({
          'chapters_reading': {widget.chapterNumber.toString(): newProgress},
          'process': totalProgress,
          'slug': widget.story.slug,
          'id_book': widget.story.slug,
          'totals_chapter': totalChapters
        });
        isFirebase = true;
      } else {
        // Cập nhật document hiện có
        print('Cập nhật tiến độ đọc EPUB');
        await docRef.set({
          'chapters_reading': {widget.chapterNumber.toString(): newProgress},
          'process': totalProgress,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Lỗi khi cập nhật tiến độ đọc EPUB: $e');
    }
  }

  /**
   * TẢI NỘI DUNG CHƯƠNG
   *
   * Tải nội dung chương từ cache hoặc API, sau đó chia thành trang
   * và xử lý các tính năng như auto-scroll, preload chương kế tiếp.
   */
  Future<void> _loadChapterContent() async {
    try {
      // Thử lấy từ cache trước
      final cachedData = await _cacheService.getCachedChapter(
          widget.story.slug, widget.chapterNumber);

      if (cachedData != null) {
        print('Sử dụng dữ liệu cache cho chương ${widget.chapterNumber}');
        setState(() {
          _chapterData = cachedData;
          _isLoading = false;
          _error = null;
        });

        // Chia nội dung thành trang sau khi tải xong
        _splitContentIntoPages();

        // Tự động cuộn đến vị trí bookmark nếu có
        _handleAutoScroll();

        // Preload các chương kế tiếp trong background
        _preloadAdjacentChapters();
        return;
      }

      // Nếu không có trong cache, tải từ API
      print('Đang tải chương ${widget.chapterNumber} từ API...');
      final result = await OTruyenApi.getEpubChapterContent(
          widget.story.slug, widget.chapterNumber);

      setState(() {
        _chapterData = result;
        _isLoading = false;
        _error = null;
      });

      // Cache dữ liệu đã tải
      await _cacheService.cacheChapter(
          widget.story.slug, widget.chapterNumber, result);

      // Chia nội dung thành trang sau khi tải xong
      _splitContentIntoPages();

      // Tự động cuộn đến vị trí bookmark nếu có
      _handleAutoScroll();

      // Preload các chương kế tiếp trong background
      _preloadAdjacentChapters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /**
   * TẢI MỤC LỤC TRUYỆN
   *
   * Lấy danh sách tất cả chương trong truyện để tính toán
   * tổng tiến độ đọc và điều hướng giữa các chương.
   */
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

  /**
   * TẢI HIGHLIGHTS VÀ BOOKMARKS
   *
   * Lấy danh sách các đoạn văn được highlight và bookmark
   * của chương hiện tại để hiển thị trong UI.
   */
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

  /**
   * CHIA NỘI DUNG THÀNH CÁC TRANG CHO CHẾ ĐỘ ĐỌC NGANG
   *
   * Phân tích nội dung chương và chia thành các trang phù hợp
   * cho chế độ đọc ngang, đồng thời thiết lập TTS content.
   */
  void _splitContentIntoPages() {
    final content = _chapterData?['chapter']?['content'] ?? '';

    // DEBUG: Ghi log cấu trúc dữ liệu chương và nội dung
    print('DEBUG _splitContentIntoPages:');
    print('Khóa _chapterData: ${_chapterData?.keys.toList()}');
    if (_chapterData?.containsKey('chapter') == true) {
      print('Khóa chapter: ${_chapterData!['chapter']?.keys.toList()}');
    }
    print('Độ dài nội dung thô: ${content.length}');
    if (content.isNotEmpty) {
      final contentPreview =
          content.length > 300 ? content.substring(0, 300) : content;
      print('Xem trước nội dung thô: "$contentPreview"');
    }

    if (content.isEmpty) {
      _pages = ['Không có nội dung'];
      return;
    }

    // Thiết lập nội dung TTS
    _setupTTSContent(content);

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

    // Cập nhật tiến độ cho chế độ đọc ngang
    if (_isHorizontalReading) {
      _updateHorizontalReadingProgress();
    }
  }

  /**
   * THIẾT LẬP NỘI DUNG VÀ CALLBACKS CHO TTS
   *
   * Chuẩn bị nội dung cho Text-to-Speech service và đăng ký
   * các callback để xử lý events từ TTS.
   */
  void _setupTTSContent(String content) {
    print('_setupTTSContent được gọi với độ dài nội dung: ${content.length}');

    // DEBUG: In ra 200 ký tự đầu của nội dung để kiểm tra
    if (content.isNotEmpty) {
      final preview =
          content.length > 200 ? content.substring(0, 200) : content;
      print('Xem trước nội dung: "$preview"');
    } else {
      print('CẢNH BÁO: Nội dung trống!');
    }

    // BƯỚC 1: TẠO MAPPING VỊ TRÍ ĐOẠN VĂN
    // Tạo bản đồ vị trí các đoạn văn TRƯỚC khi thiết lập TTS content
    // Điều này cần thiết để highlight chính xác đoạn đang đọc trong UI
    _createTTSParagraphMapping(content);

    // BƯỚC 2: THIẾT LẬP NỘI DUNG CHO TTS SERVICE
    _ttsService.setContent(content);
    _ttsParagraphs = _ttsService.paragraphs; // Lấy danh sách đoạn đã chia

    print('Số đoạn TTS sau khi thiết lập: ${_ttsParagraphs.length}');
    print('Số vị trí đoạn TTS: ${_ttsParagraphPositions.length}');

    // DEBUG: In ra đoạn đầu tiên sẽ được đọc
    if (_ttsParagraphs.isNotEmpty) {
      final firstParagraph = _ttsParagraphs[0];
      final paragraphPreview = firstParagraph.length > 100
          ? firstParagraph.substring(0, 100)
          : firstParagraph;
      print('Xem trước đoạn đầu tiên: "$paragraphPreview"');

      if (_ttsParagraphPositions.isNotEmpty) {
        print('Vị trí đoạn đầu tiên: ${_ttsParagraphPositions[0]}');
      }
    }

    // BƯỚC 3: ĐĂNG KÝ CÁC CALLBACK EVENTS
    // Thiết lập các callback để UI có thể phản ứng với các sự kiện TTS
    _ttsService.setCallbacks(
      // Khi chuyển sang đoạn mới - cập nhật highlighting
      onParagraphChanged: (index) {
        print('Đoạn văn đã chuyển sang: $index');
        _updateTTSHighlighting(index); // Highlight đoạn đang đọc
        setState(() {
          _currentTTSParagraph = index;
        });
      },
      // Khi bắt đầu đọc - cập nhật UI controls
      onStarted: () {
        print('TTS đã bắt đầu');
        setState(() {
          _isTTSPlaying = true;
        });
      },
      // Khi tạm dừng - cập nhật UI
      onPaused: () {
        print('TTS đã tạm dừng');
        setState(() {
          _isTTSPlaying = false;
          _isTTSPaused = true;
        });
      },
      // Khi tiếp tục đọc - cập nhật UI
      onContinued: () {
        print('TTS đã tiếp tục');
        setState(() {
          _isTTSPlaying = true;
          _isTTSPaused = false;
        });
      },
      // Khi đọc xong tất cả - reset UI
      onCompleted: () {
        print('TTS đã hoàn thành');
        setState(() {
          _isTTSPlaying = false;
          _isTTSPaused = false;
          _currentTTSParagraph = -1;
          _ttsHighlightStart = null; // Xóa highlighting
          _ttsHighlightEnd = null;
        });
      },
      // Khi có lỗi TTS - hiển thị dialog lỗi
      onError: (errorMessage) {
        print('Lỗi TTS: $errorMessage');
        setState(() {
          _isTTSPlaying = false;
          _isTTSPaused = false;
          _ttsHighlightStart = null;
          _ttsHighlightEnd = null;
        });
        _showTTSErrorDialog(errorMessage); // Hiển thị dialog lỗi cho user
      },
    );

    // BƯỚC 4: KHỞI TẠO CÀI ĐẶT NGÔN NGỮ
    _initializeTTSLanguage();

    print('Thiết lập TTS đã hoàn thành');
  }

  /**
   * TẠO BẢN ĐỒ VỊ TRÍ CÁC ĐOẠN VĂN CHO TTS
   * 
   * Phương thức này tạo ra một mapping giữa các đoạn văn mà TTS sẽ đọc
   * và vị trí thực tế của chúng trong văn bản gốc.
   * 
   * Mục đích:
   * - Để có thể highlight chính xác đoạn đang được đọc trong UI
   * - Đồng bộ việc cuộn màn hình với đoạn đang đọc
   * - Theo dõi tiến độ đọc TTS
   * 
   * @param content - Văn bản gốc cần tạo mapping
   */
  void _createTTSParagraphMapping(String content) {
    _ttsParagraphPositions.clear(); // Xóa mapping cũ

    // CHIA VĂN BẢN THEO CÙNG LOGIC VỚI TTSService
    // Đảm bảo mapping chính xác với cách TTS chia đoạn
    List<String> initialSplit = content
        .split('\n') // Chia theo dấu xuống dòng
        .map((p) => p.trim()) // Bỏ khoảng trắng đầu/cuối
        .where((p) => p.isNotEmpty) // Bỏ dòng trống
        .toList();

    if (initialSplit.length > 1) {
      // PHƯƠNG PHÁP 1: CHIA THEO ĐOẠN VĂN TỰ NHIÊN
      int currentPosition = 0;

      for (String paragraph in initialSplit) {
        // Tìm vị trí thực tế của đoạn này trong văn bản gốc
        int startPos = content.indexOf(paragraph, currentPosition);
        if (startPos != -1) {
          // Làm sạch đoạn văn giống như TTSService
          String cleanedParagraph = _cleanTextForTTSMapping(paragraph);
          if (cleanedParagraph.isNotEmpty) {
            _ttsParagraphPositions.add({
              'start': startPos, // Vị trí bắt đầu
              'end': startPos + paragraph.length, // Vị trí kết thúc
              'originalText': paragraph, // Văn bản gốc
              'cleanedText': cleanedParagraph, // Văn bản đã làm sạch
            });
          }
          currentPosition = startPos + paragraph.length;
        }
      }
    } else {
      // PHƯƠNG PHÁP 2: CHIA THEO CHUNKS (giống TTSService)
      _createChunkBasedMapping(content);
    }

    print(
        '🔊 Created ${_ttsParagraphPositions.length} paragraph position mappings');
  }

  /**
   * TẠO MAPPING DỰA TRÊN CHUNKS
   * 
   * Sử dụng khi văn bản không có phân đoạn tự nhiên.
   * Chia thành các chunk có kích thước phù hợp giống TTSService.
   * 
   * @param content - Văn bản gốc cần chia
   */
  void _createChunkBasedMapping(String content) {
    // KÍCH THƯỚC CHUNK GIỐNG TRONG TTSService
    const int targetChunkSize = 500; // Kích thước mục tiêu
    const int maxChunkSize = 800; // Kích thước tối đa

    String remainingContent = content.trim();
    int currentPosition = 0;

    while (remainingContent.isNotEmpty) {
      if (remainingContent.length <= targetChunkSize) {
        // Phần còn lại đủ nhỏ
        String cleanedChunk = _cleanTextForTTSMapping(remainingContent);
        if (cleanedChunk.isNotEmpty) {
          _ttsParagraphPositions.add({
            'start': currentPosition,
            'end': currentPosition + remainingContent.length,
            'originalText': remainingContent,
            'cleanedText': cleanedChunk,
          });
        }
        break;
      }

      // TÌM ĐIỂM CẮT TỐI ƯU
      int breakPoint = _findBreakPointForMapping(
          remainingContent, targetChunkSize, maxChunkSize);

      String chunk = remainingContent.substring(0, breakPoint).trim();
      if (chunk.isNotEmpty) {
        String cleanedChunk = _cleanTextForTTSMapping(chunk);
        if (cleanedChunk.isNotEmpty) {
          _ttsParagraphPositions.add({
            'start': currentPosition,
            'end': currentPosition + breakPoint,
            'originalText': chunk,
            'cleanedText': cleanedChunk,
          });
        }
      }

      // CẬP NHẬT VỊ TRÍ VÀ VĂN BẢN CÒN LẠI
      currentPosition += breakPoint;
      remainingContent = remainingContent.substring(breakPoint).trim();

      // Bỏ qua khoảng trắng
      while (currentPosition < content.length &&
          RegExp(r'\s').hasMatch(content[currentPosition])) {
        currentPosition++;
      }
    }
  }

  /**
   * TÌM ĐIỂM CẮT CHO MAPPING
   * 
   * Sử dụng cùng logic với TTSService để đảm bảo mapping chính xác.
   * Tìm điểm cắt tối ưu để chia văn bản thành chunks.
   * 
   * @param text - Văn bản cần tìm điểm cắt
   * @param targetSize - Kích thước mục tiêu
   * @param maxSize - Kích thước tối đa
   * @return int - Vị trí cắt tối ưu
   */
  int _findBreakPointForMapping(String text, int targetSize, int maxSize) {
    if (text.length <= targetSize) return text.length;

    // Look for sentence endings near target size
    List<String> sentenceEnders = ['. ', '! ', '? ', '.\n', '!\n', '?\n'];

    for (String ender in sentenceEnders) {
      int pos = text.lastIndexOf(ender, targetSize);
      if (pos > targetSize * 0.7) {
        return pos + ender.length;
      }
    }

    // Look for other punctuation
    List<String> otherBreaks = ['; ', ': ', ', ', '.\t', '!\t', '?\t'];

    for (String breaker in otherBreaks) {
      int pos = text.lastIndexOf(breaker, targetSize);
      if (pos > targetSize * 0.8) {
        return pos + breaker.length;
      }
    }

    // Look for word boundaries
    int pos = text.lastIndexOf(' ', targetSize);
    if (pos > targetSize * 0.8) {
      return pos + 1;
    }

    // If all else fails, use max size or hard break
    return text.length < maxSize ? text.length : targetSize;
  }

  // Clean text for TTS mapping (same logic as TTSService)
  String _cleanTextForTTSMapping(String text) {
    if (text.isEmpty) return text;

    String cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
            RegExp(r'[^\p{L}\p{N}\s\.,!?;:\-\(\)\[\]""' '""…]', unicode: true),
            '')
        .replaceAll(RegExp(r'[.]{2,}'), '...')
        .replaceAll(RegExp(r'[!]{2,}'), '!')
        .replaceAll(RegExp(r'[?]{2,}'), '?')
        .replaceAll(RegExp(r'([.!?])\s*([A-Z])'), r'$1 $2')
        .trim();

    if (cleaned.length > 1500) {
      int breakPoint = cleaned.lastIndexOf('.', 1200);
      if (breakPoint == -1) breakPoint = cleaned.lastIndexOf(' ', 1200);
      if (breakPoint == -1) breakPoint = 1200;
      cleaned = cleaned.substring(0, breakPoint);
    }

    return cleaned;
  }

  /**
   * KHỞI TẠO NGÔN NGỮ TTS
   *
   * Lấy danh sách ngôn ngữ có sẵn từ TTS service và thiết lập
   * ngôn ngữ mặc định cho việc đọc truyện.
   */
  void _initializeTTSLanguage() async {
    try {
      print('Đang khởi tạo ngôn ngữ TTS...');
      final languages = await _ttsService.getLanguages();
      print('Ngôn ngữ có sẵn từ dịch vụ TTS: $languages');

      setState(() {
        _availableLanguages = languages;
      });

      // Nếu không có ngôn ngữ nào, sử dụng danh sách dự phòng
      if (_availableLanguages.isEmpty) {
        print('Không có ngôn ngữ từ dịch vụ TTS, sử dụng danh sách dự phòng');
        setState(() {
          _availableLanguages = [
            'vi-VN',
            'en-US',
            'en-GB',
            'zh-CN',
            'ja-JP',
            'ko-KR'
          ];
        });
      }

      // Thiết lập ngôn ngữ mặc định
      if (_selectedLanguage != null) {
        await _ttsService.setLanguage(_selectedLanguage!);
        _checkLanguageInstallation();
      }

      print(
          'Khởi tạo ngôn ngữ TTS đã hoàn thành. Số ngôn ngữ có sẵn: ${_availableLanguages.length}');
    } catch (e) {
      print('Lỗi khởi tạo ngôn ngữ TTS: $e');
      // Cung cấp ngôn ngữ dự phòng ngay cả khi có lỗi
      setState(() {
        _availableLanguages = [
          'vi-VN',
          'en-US',
          'en-GB',
          'zh-CN',
          'ja-JP',
          'ko-KR'
        ];
      });
    }
  }

  /**
   * KIỂM TRA NGÔN NGỮ ĐÃ CÀI ĐẶT (CHỈ ANDROID)
   *
   * Kiểm tra xem ngôn ngữ hiện tại đã được cài đặt trên thiết bị chưa
   * để hiển thị thông báo phù hợp cho người dùng.
   */
  void _checkLanguageInstallation() async {
    if (_selectedLanguage != null) {
      try {
        final isInstalled =
            await _ttsService.isLanguageInstalled(_selectedLanguage!);
        setState(() {
          _isCurrentLanguageInstalled = isInstalled;
        });
      } catch (e) {
        print('Lỗi kiểm tra cài đặt ngôn ngữ: $e');
        setState(() {
          _isCurrentLanguageInstalled =
              true; // Giả định đã cài nếu không kiểm tra được
        });
      }
    }
  }

  /**
   * LẤY DANH SÁCH DROPDOWN CHO NGÔN NGỮ
   *
   * Tạo danh sách dropdown items với tên ngôn ngữ thân thiện
   * thay vì mã ngôn ngữ khó hiểu.
   */
  List<DropdownMenuItem<String>> _getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];

    // Bản đồ mã ngôn ngữ sang tên thân thiện
    final Map<String, String> languageNames = {
      'vi-VN': 'Tiếng Việt (Việt Nam)',
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'zh-CN': '中文 (简体)',
      'zh-TW': '中文 (繁體)',
      'ja-JP': '日本語',
      'ko-KR': '한국어',
      'fr-FR': 'Français',
      'de-DE': 'Deutsch',
      'es-ES': 'Español',
      'it-IT': 'Italiano',
      'pt-BR': 'Português (Brasil)',
      'ru-RU': 'Русский',
      'th-TH': 'ไทย',
      'id-ID': 'Bahasa Indonesia',
      'ms-MY': 'Bahasa Melayu',
    };

    for (dynamic language in languages) {
      final languageCode = language as String;
      final displayName = languageNames[languageCode] ?? languageCode;

      items.add(DropdownMenuItem(
        value: languageCode,
        child: Text(
          displayName,
          style: TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return items;
  }

  /**
   * XỬ LÝ THAY ĐỔI LỰA CHỌN NGÔN NGỮ
   *
   * Cập nhật ngôn ngữ TTS khi người dùng chọn ngôn ngữ mới
   * từ dropdown menu.
   */
  void _changeLanguage(String? selectedLanguage) async {
    if (selectedLanguage != null) {
      setState(() {
        _selectedLanguage = selectedLanguage;
      });

      try {
        await _ttsService.setLanguage(selectedLanguage);
        _checkLanguageInstallation();
      } catch (e) {
        print('Lỗi thiết lập ngôn ngữ: $e');
      }
    }
  }

  /**
   * CÁC PHƯƠNG THỨC ĐIỀU KHIỂN TTS
   */

  /**
   * BẬT/TẮT CHẾ ĐỘ TTS
   *
   * Khi lần đầu bật TTS: chuyển sang fullscreen và hiển thị controls
   * Khi đã bật TTS: chỉ toggle hiển thị controls
   */
  void _toggleTTS() {
    print('_toggleTTS được gọi: $_isTTSEnabled');

    if (!_isTTSEnabled) {
      // Lần đầu bật TTS - lưu trạng thái fullscreen hiện tại và chuyển sang fullscreen
      print('Lần đầu bật TTS - chuyển sang fullscreen và hiển thị controls');
      _wasFullScreenBeforeTTS = _isFullScreen;

      setState(() {
        _isTTSEnabled = true;
        _isTTSControlsVisible = true;
        _isFullScreen = true;
      });

      _saveSettings(); // Lưu trạng thái fullscreen
      _clearTempHighlight();
      _clearSearch();
    } else {
      // TTS đã được bật - chỉ toggle hiển thị controls
      print('TTS đã được bật - toggle hiển thị controls');
      setState(() {
        _isTTSControlsVisible = !_isTTSControlsVisible;
      });
    }
  }

  /**
   * PHÁT TTS
   *
   * Bắt đầu hoặc tiếp tục phát TTS. Xử lý các trường hợp:
   * - Resume từ pause
   * - Khởi tạo TTS service nếu cần
   * - Kiểm tra dữ liệu chương có sẵn
   */
  void _playTTS() async {
    print('_playTTS được gọi');
    print('TTS đang phát: $_isTTSPlaying, TTS tạm dừng: $_isTTSPaused');
    print('Số đoạn văn: ${_ttsParagraphs.length}');
    print('TTS service đã khởi tạo: ${_ttsService.isInitialized}');
    print('Dữ liệu chương có sẵn: ${_chapterData != null}');

    // Nếu TTS đang tạm dừng, tiếp tục thay vì bắt đầu mới
    if (_isTTSPaused && !_isTTSPlaying) {
      print('Tiếp tục TTS từ tạm dừng...');
      try {
        await _ttsService.resume();
        setState(() {
          _isTTSPaused = false;
          _isTTSPlaying = true;
        });
        return;
      } catch (e) {
        print('Lỗi tiếp tục TTS: $e');
        // Nếu resume thất bại, khởi động lại TTS
        setState(() {
          _isTTSPaused = false;
        });
      }
    }

    // Kiểm tra dữ liệu chương trước
    if (_chapterData == null) {
      print('Không có dữ liệu chương, không thể thiết lập TTS');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang tải nội dung, vui lòng đợi...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Nếu không có đoạn văn, thử thiết lập lại nội dung TTS
    if (_ttsParagraphs.isEmpty) {
      print('Không có đoạn văn, đang thử thiết lập lại nội dung TTS...');
      final content = _chapterData?['chapter']?['content'] ?? '';
      if (content.isNotEmpty) {
        _setupTTSContent(content);
        // Đợi một chút để thiết lập hoàn thành
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Kiểm tra lại sau khi thử thiết lập
    if (_ttsParagraphs.isEmpty) {
      print('Vẫn không có đoạn văn để phát sau khi thử thiết lập');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có nội dung để đọc'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Khởi tạo TTS service nếu chưa được khởi tạo
    if (!_ttsService.isInitialized) {
      print('TTS service chưa được khởi tạo, đang khởi tạo...');
      try {
        await _ttsService.initialize();
        print('TTS service đã được khởi tạo thành công');
      } catch (e) {
        print('Thất bại khi khởi tạo TTS service: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khởi tạo TTS: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    try {
      print('Bắt đầu phát TTS...');
      await _ttsService.play();
      setState(() {
        _isTTSPaused = false;
      });
      print('Lệnh phát TTS đã được gửi thành công');
    } catch (e) {
      print('Lỗi trong _playTTS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi TTS: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /**
   * TẠM DỪNG TTS
   *
   * Tạm dừng việc phát TTS hiện tại, có thể tiếp tục sau.
   */
  void _pauseTTS() async {
    print('_pauseTTS được gọi');
    try {
      await _ttsService.pause();
      print('Lệnh tạm dừng TTS đã được gửi thành công');
    } catch (e) {
      print('Lỗi trong _pauseTTS: $e');
    }
  }

  /**
   * DỪNG HOÀN TOÀN TTS
   *
   * Dừng TTS và tắt hoàn toàn chế độ TTS, khôi phục trạng thái
   * fullscreen trước đó.
   */
  void _stopTTS() async {
    print('_stopTTS được gọi - tắt hoàn toàn TTS');
    try {
      await _ttsService.stop();
      print('Lệnh dừng TTS đã được gửi thành công');

      // Tắt hoàn toàn TTS và ẩn controls, khôi phục trạng thái fullscreen trước đó
      setState(() {
        _isTTSEnabled = false;
        _isTTSControlsVisible = false;
        _isTTSPlaying = false;
        _isTTSPaused = false;
        _currentTTSParagraph = -1;
        _ttsHighlightStart = null;
        _ttsHighlightEnd = null;
        // Khôi phục trạng thái fullscreen trước đó
        _isFullScreen = _wasFullScreenBeforeTTS;
      });

      _saveSettings(); // Lưu trạng thái fullscreen đã khôi phục
    } catch (e) {
      print('Lỗi trong _stopTTS: $e');
    }
  }

  /**
   * CHUYỂN VỀ ĐOẠN VĂN TTS TRƯỚC ĐÓ
   *
   * Điều hướng TTS về đoạn văn trước đó trong danh sách.
   */
  void _previousTTSParagraph() async {
    print('_previousTTSParagraph được gọi');
    print('Đoạn văn hiện tại: ${_ttsService.currentParagraphIndex}');
    try {
      await _ttsService.previousParagraph();
      print('Lệnh đoạn văn trước đã được gửi thành công');
    } catch (e) {
      print('Lỗi trong _previousTTSParagraph: $e');
    }
  }

  /**
   * CHUYỂN ĐẾN ĐOẠN VĂN TTS TIẾP THEO
   *
   * Điều hướng TTS đến đoạn văn tiếp theo trong danh sách.
   */
  void _nextTTSParagraph() async {
    print('_nextTTSParagraph được gọi');
    print('Đoạn văn hiện tại: ${_ttsService.currentParagraphIndex}');
    print('Tổng số đoạn văn: ${_ttsService.paragraphs.length}');
    try {
      await _ttsService.nextParagraph();
      print('Lệnh đoạn văn tiếp theo đã được gửi thành công');
    } catch (e) {
      print('Lỗi trong _nextTTSParagraph: $e');
    }
  }

  /**
   * HIỂN THỊ CÀI ĐẶT TTS
   *
   * Mở modal bottom sheet chứa các tùy chọn cài đặt TTS
   * như ngôn ngữ, tốc độ đọc, v.v.
   */
  void _showTTSSettings() {
    print('_showTTSSettings được gọi');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) =>
            _buildTTSSettingsModal(setModalState),
      ),
    );
  }

  void _showTTSErrorDialog(String errorMessage) {
    if (!mounted) return;

    String userFriendlyMessage;
    String solution;

    if (errorMessage.contains('-8')) {
      userFriendlyMessage = 'Lỗi tổng hợp giọng nói';
      solution =
          'Có thể do ngôn ngữ tiếng Việt chưa được cài đặt trên thiết bị. Hãy thử:\n'
          '• Cài đặt gói ngôn ngữ tiếng Việt trong Cài đặt > Ngôn ngữ\n'
          '• Hoặc chuyển sang tiếng Anh trong cài đặt TTS';
    } else if (errorMessage.contains('-5')) {
      userFriendlyMessage = 'Ngôn ngữ không được hỗ trợ';
      solution =
          'Ngôn ngữ hiện tại không khả dụng. Ứng dụng sẽ tự động chuyển sang tiếng Anh.';
    } else if (errorMessage.contains('-4')) {
      userFriendlyMessage = 'Lỗi cài đặt TTS';
      solution =
          'Các thông số TTS không hợp lệ. Ứng dụng sẽ tự động đặt lại về mặc định.';
    } else {
      userFriendlyMessage = 'Lỗi TTS không xác định';
      solution =
          'Hãy thử khởi động lại ứng dụng hoặc kiểm tra cài đặt TTS của thiết bị.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _backgroundColor,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Lỗi Text-to-Speech',
                style: TextStyle(color: _textColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userFriendlyMessage,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Giải pháp:',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                solution,
                style: TextStyle(color: _textColor),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Chi tiết lỗi: $errorMessage',
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTTSSettings();
              },
              child: Text(
                'Cài đặt TTS',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Đóng',
                style: TextStyle(color: _textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  /**
   * TÍNH TOÁN SỐ TRANG DỰA TRÊN KÍCH THƯỚC MÀN HÌNH THỰC TẾ
   *
   * Phương thức này tính toán chính xác số trang cần thiết dựa trên:
   * - Kích thước màn hình thiết bị
   * - Font size và line height hiện tại
   * - Trạng thái fullscreen
   * - Chế độ đọc (dọc/ngang)
   */
  void _calculatePagesBasedOnScreenSize() {
    final content = _chapterData?['chapter']?['content'] ?? '';
    if (content.isEmpty || !mounted) return;

    // Lấy kích thước màn hình
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Tính toán chiều cao có sẵn cho nội dung
    final appBarHeight = _isFullScreen ? 0.0 : kToolbarHeight;
    // Trong fullscreen, SafeArea xử lý status bar, không cần trừ thêm
    final statusBarHeight = 0.0;
    // Cho chế độ đọc ngang, đã bỏ hiển thị số trang, không cần khoảng trống bottom
    final bottomBarHeight = _isHorizontalReading
        ? 0.0
        : (_isFullScreen
            ? 60.0
            : 80.0); // Bottom navigation bar (chỉ cho chế độ dọc)
    final contentPadding = 32.0; // Padding trên + dưới
    final titleHeight = _isFullScreen
        ? 0.0
        : (_fontSize + 4) * 1.2 + 24; // Tiêu đề + khoảng cách

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

    print(
        'Tính toán màn hình (fullscreen: $_isFullScreen, ngang: $_isHorizontalReading):');
    print('Chiều cao có sẵn: $availableHeight');
    print('Chiều cao status bar: $statusBarHeight');
    print('Chiều cao bottom bar: $bottomBarHeight');
    print('Số dòng tối đa: $maxLines');
    print('Ký tự mỗi dòng: $charsPerLine');
    print('Ký tự mỗi trang: $charsPerPage');

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
      print(
          'Trang đã được tính lại: ${_pages.length} trang (fullscreen: $_isFullScreen, ngang: $_isHorizontalReading)');
      print('Hoàn thành tính toán trang cho chế độ đọc ngang');

      // Cập nhật tiến độ cho chế độ đọc ngang
      if (_isHorizontalReading) {
        _updateHorizontalReadingProgress();
      }
    }
  }

  /**
   * ĐIỀU HƯỚNG ĐẾN CHƯƠNG KHÁC
   *
   * Chuyển đến chương được chỉ định với các tùy chọn:
   * - initialScrollPosition: Vị trí cuộn ban đầu
   * - searchText: Text để highlight khi search
   * - bookmarkText: Text bookmark để highlight
   */
  void _navigateToChapter(int chapterNumber,
      {int? initialScrollPosition, String? searchText, String? bookmarkText}) {
    print('_navigateToChapter được gọi với: $chapterNumber');
    print('Chương hiện tại: ${widget.chapterNumber}');
    print('Số chương có sẵn: ${_allChapters.length}');

    if (chapterNumber == widget.chapterNumber) {
      print('Cùng chương - bỏ qua điều hướng');
      return;
    }

    // Kiểm tra chương có tồn tại trong danh sách không
    bool chapterExists = false;
    for (var chapter in _allChapters) {
      if (chapter['number'] == chapterNumber) {
        chapterExists = true;
        break;
      }
    }

    if (!chapterExists) {
      print('Chương $chapterNumber không tồn tại trong danh sách chương');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chương $chapterNumber không tồn tại'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Đang điều hướng đến chương $chapterNumber');

    try {
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
    } catch (e) {
      print('Lỗi điều hướng đến chương $chapterNumber: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chuyển chương: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /**
   * LẤY TIÊU ĐỀ CHƯƠNG
   *
   * Tìm và trả về tiêu đề của chương được chỉ định từ danh sách
   * tất cả chương. Nếu không tìm thấy, sử dụng tiêu đề mặc định.
   */
  String _getChapterTitle(int chapterNumber) {
    print('Đang lấy tiêu đề chương cho chương: $chapterNumber');
    print('Số chương có sẵn: ${_allChapters.length}');

    for (var chapter in _allChapters) {
      if (chapter['number'] == chapterNumber) {
        final title = chapter['title'] ?? 'Chương $chapterNumber';
        print('Tìm thấy tiêu đề: $title');
        return title;
      }
    }

    final fallbackTitle = 'Chương $chapterNumber';
    print('Sử dụng tiêu đề dự phòng: $fallbackTitle');
    return fallbackTitle;
  }

  /**
   * CHUYỂN ĐỔI HƯỚNG ĐỌC
   *
   * Toggle giữa chế độ đọc dọc (scroll) và ngang (page).
   * Khi chuyển sang đọc ngang, tự động tính toán lại trang.
   */
  void _toggleReadingDirection() {
    setState(() {
      _isHorizontalReading = !_isHorizontalReading;
      if (_isHorizontalReading) {
        // Khi chuyển sang đọc ngang, tính toán trang dựa trên kích thước màn hình hiện tại
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculatePagesBasedOnScreenSize();
        });
        // Khởi tạo tiến độ cho chế độ ngang
        _updateHorizontalReadingProgress();
      }
    });
    _saveSettings(); // Lưu thay đổi cài đặt ngay lập tức
  }

  /**
   * LẤY SỐ CHƯƠNG TIẾP THEO
   *
   * Trả về số chương tiếp theo từ dữ liệu navigation,
   * null nếu đây là chương cuối.
   */
  int? _getNextChapterNumber() {
    final navigation = _chapterData?['navigation'];
    final nextChapter = navigation?['nextChapter'];
    print('Lấy số chương tiếp theo: $nextChapter');
    print('Dữ liệu navigation: $navigation');
    return nextChapter;
  }

  /**
   * LẤY SỐ CHƯƠNG TRƯỚC ĐÓ
   *
   * Trả về số chương trước đó từ dữ liệu navigation,
   * null nếu đây là chương đầu.
   */
  int? _getPreviousChapterNumber() {
    final navigation = _chapterData?['navigation'];
    final prevChapter = navigation?['previousChapter'];
    print('_getPreviousChapterNumber: $prevChapter');
    print('Dữ liệu navigation: $navigation');
    return prevChapter;
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildThemeOption(
                      'Sáng', Colors.white, Colors.black, setModalState),
                  _buildThemeOption(
                      'Tối', Colors.black, Colors.white, setModalState),
                  _buildThemeOption('Sepia', const Color(0xFFF5F1E4),
                      Colors.brown.shade800, setModalState),
                ],
              ),

              const SizedBox(height: 20),
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
    _toggleHighlightBookmarkOverlay();
  }

  void _toggleHighlightBookmarkOverlay() {
    setState(() {
      _isHighlightBookmarkOverlayVisible = !_isHighlightBookmarkOverlayVisible;
    });

    if (_isHighlightBookmarkOverlayVisible) {
      // Load lại highlights và bookmarks khi mở overlay
      _loadHighlightsAndBookmarks();
    }
  }

  /**
   * ĐIỀU HƯỚNG ĐẾN BOOKMARK
   *
   * Chuyển đến vị trí bookmark được chỉ định. Nếu bookmark ở chương hiện tại
   * thì cuộn đến vị trí, nếu ở chương khác thì chuyển chương.
   */
  void _navigateToBookmark(Bookmark bookmark) {
    print('=== Điều hướng đến bookmark ===');
    print('Văn bản bookmark: "${bookmark.text}"');
    print('Chương bookmark: ${bookmark.chapterNumber}');
    print('Chương hiện tại: ${widget.chapterNumber}');
    print('Vị trí bắt đầu bookmark: ${bookmark.startIndex}');
    print('Vị trí kết thúc bookmark: ${bookmark.endIndex}');

    // Nếu là chương hiện tại, cuộn đến vị trí bookmark
    if (bookmark.chapterNumber == widget.chapterNumber) {
      print('Cùng chương - cuộn đến vị trí');
      _scrollToPosition(bookmark.startIndex, bookmarkText: bookmark.text);
    } else {
      print('Chương khác - điều hướng đến chương ${bookmark.chapterNumber}');
      print('Truyền vị trí cuộn ban đầu: ${bookmark.startIndex}');
      print('Truyền văn bản bookmark: "${bookmark.text}"');

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

  /**
   * ĐIỀU HƯỚNG ĐẾN HIGHLIGHT
   *
   * Chuyển đến vị trí highlight được chỉ định. Nếu highlight ở chương hiện tại
   * thì cuộn đến vị trí, nếu ở chương khác thì chuyển chương.
   */
  void _navigateToHighlight(Highlight highlight) {
    print('=== Điều hướng đến highlight ===');
    print('Văn bản highlight: "${highlight.text}"');
    print('Chương highlight: ${highlight.chapterNumber}');
    print('Chương hiện tại: ${widget.chapterNumber}');
    print('Vị trí bắt đầu highlight: ${highlight.startIndex}');
    print('Vị trí kết thúc highlight: ${highlight.endIndex}');

    // Nếu là chương hiện tại, cuộn đến vị trí highlight
    if (highlight.chapterNumber == widget.chapterNumber) {
      print('Cùng chương - cuộn đến vị trí');
      _scrollToPosition(highlight.startIndex, searchText: highlight.text);
    } else {
      print('Chương khác - điều hướng đến chương ${highlight.chapterNumber}');
      print('Truyền vị trí cuộn ban đầu: ${highlight.startIndex}');
      print('Truyền văn bản tìm kiếm: "${highlight.text}"');

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

  /**
   * CUỘN ĐẾN VỊ TRÍ CHỈ ĐỊNH
   *
   * Cuộn đến vị trí text index được chỉ định và thiết lập highlight tạm thời.
   * Hỗ trợ cả chế độ đọc dọc và ngang.
   */
  void _scrollToPosition(int textIndex,
      {String? searchText, String? bookmarkText}) {
    print('=== Cuộn đến vị trí ===');
    print('Chỉ số đích: $textIndex');
    print('Văn bản tìm kiếm: $searchText');
    print('Văn bản bookmark: $bookmarkText');
    print('Chế độ đọc: ${_isHorizontalReading ? "ngang" : "dọc"}');
    print('ScrollController có clients: ${_scrollController.hasClients}');

    final chapter = _chapterData?['chapter'];
    final content = chapter?['content'] ?? '';

    // Thiết lập highlight tạm thời - ưu tiên bookmark text hơn search text
    final highlightText = bookmarkText ?? searchText;
    print('=== Quyết định văn bản highlight ===');
    print('Văn bản bookmark: "$bookmarkText"');
    print('Văn bản tìm kiếm: "$searchText"');
    print('Văn bản highlight được chọn: "$highlightText"');

    // Improved highlight setting logic
    if (highlightText != null &&
        highlightText.isNotEmpty &&
        content.isNotEmpty &&
        textIndex >= 0 &&
        textIndex < content.length) {
      // Verify the text at the given position matches the highlight text
      final actualTextAtPosition = content.substring(textIndex,
          (textIndex + highlightText.length).clamp(0, content.length));

      print('Văn bản highlight mong đợi: "$highlightText"');
      print('Văn bản thực tế tại vị trí: "$actualTextAtPosition"');

      // Sử dụng fuzzy matching để có độ chính xác tốt hơn
      final isTextMatch = actualTextAtPosition.toLowerCase().trim() ==
              highlightText.toLowerCase().trim() ||
          actualTextAtPosition.contains(highlightText.trim()) ||
          highlightText.contains(actualTextAtPosition.trim());

      if (isTextMatch) {
        final tempStart = textIndex;
        final tempEnd = textIndex + highlightText.length;

        // Kiểm tra xem đã có highlight tại vị trí này chưa
        if (_hasExistingHighlightAt(tempStart, tempEnd)) {
          print('Bỏ qua temp highlight - đã được highlight tại vị trí này');
          print('Highlight hiện có tìm thấy tại phạm vi: $tempStart-$tempEnd');
        } else {
          print('Thiết lập highlight tạm thời');
          print('Bắt đầu: $tempStart, Kết thúc: $tempEnd');
          setState(() {
            _tempHighlightStart = tempStart;
            _tempHighlightEnd = tempEnd;
            _tempHighlightText = highlightText;
          });

          // Xóa highlight sau 8 giây (tăng từ 5)
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) {
              _clearTempHighlight();
            }
          });
        }
      } else {
        print('Văn bản không khớp - không thiết lập highlight');
        print('Mong đợi: "$highlightText"');
        print('Tìm thấy: "$actualTextAtPosition"');
      }
    } else {
      print('Không thiết lập highlight - điều kiện không đáp ứng');
      print(
          'highlightText null hoặc rỗng: ${highlightText == null || highlightText.isEmpty}');
      print('nội dung rỗng: ${content.isEmpty}');
      print(
          'textIndex ngoài phạm vi: $textIndex (độ dài nội dung: ${content.length})');
    }

    // Logic cuộn cải tiến cho đọc dọc
    if (!_isHorizontalReading && _scrollController.hasClients) {
      print('Độ dài nội dung: ${content.length}');
      print('MaxScrollExtent: ${_scrollController.position.maxScrollExtent}');

      if (content.isNotEmpty && textIndex >= 0 && textIndex < content.length) {
        // Tính toán chính xác hơn cho vị trí bookmark/search
        final scrollRatio = textIndex / content.length;
        final maxScrollExtent = _scrollController.position.maxScrollExtent;

        // Tính toán target offset cải tiến
        var targetOffset = scrollRatio * maxScrollExtent;

        // Áp dụng các chiến lược khác nhau dựa trên loại nội dung và vị trí
        if (bookmarkText != null) {
          print('=== Tính toán cuộn Bookmark ===');
          print('targetOffset gốc: $targetOffset');
          print('Tỷ lệ cuộn: $scrollRatio');
          print('Vị trí nội dung: ${textIndex}/${content.length}');

          // More precise bookmark positioning
          if (scrollRatio <= 0.05) {
            // Very beginning - scroll to top with small offset
            targetOffset = maxScrollExtent * 0.02;
          } else if (scrollRatio >= 0.95) {
            // Very end - scroll close to bottom
            targetOffset = maxScrollExtent * 0.92;
          } else {
            // Middle content - use adjusted ratio to account for UI elements
            // Reduce the target slightly to ensure content is visible above fold
            targetOffset = (scrollRatio * 0.85 + 0.08) * maxScrollExtent;
          }

          print('targetOffset bookmark đã điều chỉnh: $targetOffset');
        } else {
          print('=== Tính toán cuộn Search ===');
          print('targetOffset gốc: $targetOffset');

          // Đối với kết quả tìm kiếm, thận trọng hơn
          if (scrollRatio <= 0.05) {
            targetOffset = maxScrollExtent * 0.03;
          } else if (scrollRatio >= 0.95) {
            targetOffset = maxScrollExtent * 0.90;
          } else {
            targetOffset = (scrollRatio * 0.80 + 0.10) * maxScrollExtent;
          }

          print('targetOffset search đã điều chỉnh: $targetOffset');
        }

        // Đảm bảo target nằm trong giới hạn
        targetOffset = targetOffset.clamp(0.0, maxScrollExtent);

        print('Target offset cuối cùng: $targetOffset');
        print('MaxScrollExtent: $maxScrollExtent');

        // Use a longer duration for smoother animation
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );

        // Show feedback with more precise positioning info
        final positionPercent = (scrollRatio * 100).toStringAsFixed(1);
        final verticalFeedbackText = bookmarkText != null
            ? 'Đã nhảy đến bookmark (vị trí $positionPercent%)'
            : 'Đã nhảy đến kết quả tìm kiếm (vị trí $positionPercent%)';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verticalFeedbackText),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('textIndex không hợp lệ hoặc nội dung rỗng');
        print('textIndex: $textIndex, content.length: ${content.length}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể nhảy đến vị trí - dữ liệu không hợp lệ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (_isHorizontalReading) {
      // Điều hướng đọc ngang cải tiến
      _navigateToPositionInHorizontalMode(textIndex, bookmarkText, searchText);
    } else {
      print('ScrollController không có clients - đang thử lại...');

      // Thử lại sau một khoảng thời gian ngắn nếu ScrollController chưa sẵn sàng
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          print('Thử lại cuộn sau khi delay...');
          _scrollToPosition(textIndex,
              searchText: searchText, bookmarkText: bookmarkText);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể cuộn đến vị trí - thử lại sau'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  /**
   * PHƯƠNG THỨC RIÊNG CHO ĐIỀU HƯỚNG ĐỌC NGANG
   *
   * Xử lý điều hướng đến vị trí cụ thể trong chế độ đọc ngang (page view).
   */
  void _navigateToPositionInHorizontalMode(
      int textIndex, String? bookmarkText, String? searchText) {
    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    print('=== Điều hướng ngang ===');
    print('Số trang: ${_pages.length}');
    print('Độ dài nội dung đầy đủ: ${fullContent.length}');
    print('Chỉ số đích: $textIndex');

    if (_pages.isEmpty || fullContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có dữ liệu trang để điều hướng'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Thuật toán tìm trang chính xác hơn
    int targetPage = -1;
    int cumulativeIndex = 0;

    for (int i = 0; i < _pages.length; i++) {
      final pageContent = _pages[i];
      final pageStartIndex = cumulativeIndex;
      final pageEndIndex = cumulativeIndex + pageContent.length;

      print(
          'Trang $i: phạm vi $pageStartIndex-$pageEndIndex (độ dài: ${pageContent.length})');

      // Kiểm tra xem chỉ số đích có nằm trong trang này không
      if (textIndex >= pageStartIndex && textIndex < pageEndIndex) {
        targetPage = i;
        print('Tìm thấy đích ở trang $i');
        break;
      }

      // Cập nhật chỉ số tích lũy cho trang tiếp theo
      cumulativeIndex = pageEndIndex;
      // Tính đến khoảng trắng giữa các trang
      if (i < _pages.length - 1) {
        cumulativeIndex += 1;
      }
    }

    if (targetPage >= 0) {
      print('Điều hướng đến trang $targetPage');

      // Update current page index immediately for UI consistency
      setState(() {
        _currentPageIndex = targetPage;
      });

      // Animate to the target page
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      // Show feedback
      final feedbackText = bookmarkText != null
          ? 'Đã nhảy đến bookmark ở trang ${targetPage + 1}/${_pages.length}'
          : 'Đã nhảy đến kết quả ở trang ${targetPage + 1}/${_pages.length}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackText),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      print('Không thể tìm thấy trang đích cho chỉ số $textIndex');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy trang chứa nội dung'),
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

  /**
   * CALLBACK KHI THÊM HIGHLIGHT
   *
   * Được gọi khi người dùng tạo highlight mới.
   */
  void _onHighlightAdded(Highlight highlight) {
    setState(() {
      _highlights.add(highlight);
    });
    // Buộc rebuild để hiển thị highlight mới
    print('Đã thêm highlight, tổng số highlights: ${_highlights.length}');
  }

  /**
   * CALLBACK KHI THÊM BOOKMARK
   *
   * Được gọi khi người dùng tạo bookmark mới.
   */
  void _onBookmarkAdded(Bookmark bookmark) {
    setState(() {
      _bookmarks.add(bookmark);
    });
    print('Đã thêm bookmark, tổng số bookmarks: ${_bookmarks.length}');
  }

  /**
   * CALLBACK KHI THAY ĐỔI LỰA CHỌN VĂN BẢN
   *
   * Được gọi khi người dùng bắt đầu/kết thúc việc chọn văn bản.
   */
  void _onTextSelectionChanged(bool isActive) {
    setState(() {
      _isTextSelectionActive = isActive;
    });
    print('Lựa chọn văn bản đang hoạt động: $isActive');
  }

  // Get highlights for specific page in horizontal reading mode - IMPROVED VERSION
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

    // Use the helper method to calculate page start position
    int pageStartInFullContent = _calculatePageStartInFullContent(pageIndex);
    int pageEndInFullContent = pageStartInFullContent + pageContent.length;
    pageEndInFullContent =
        pageEndInFullContent.clamp(0, fullContent.length).toInt();

    // Debug logging
    print('=== Debug mapping highlight trang ===');
    print(
        'Trang $pageIndex: Bắt đầu=$pageStartInFullContent, Kết thúc=$pageEndInFullContent');
    print('Độ dài nội dung trang: ${pageContent.length}');
    print('Độ dài nội dung đầy đủ: ${fullContent.length}');

    // Verify our calculation by checking the actual content
    if (pageStartInFullContent + pageContent.length <= fullContent.length) {
      final extractedContent = fullContent.substring(
          pageStartInFullContent, pageStartInFullContent + pageContent.length);
      final contentMatches = extractedContent == pageContent;
      print('Xác minh nội dung: ${contentMatches ? "KHỚP" : "KHÔNG KHỚP"}');
      if (!contentMatches) {
        final maxLength = pageContent.length < 50 ? pageContent.length : 50;
        final maxExtractedLength =
            extractedContent.length < 50 ? extractedContent.length : 50;
        print('Mong đợi: "${pageContent.substring(0, maxLength)}..."');
        print(
            'Trích xuất: "${extractedContent.substring(0, maxExtractedLength)}..."');
      }
    }

    // Filter highlights that fall within this page and adjust indices
    List<Highlight> pageHighlights = [];

    for (final highlight in _highlights) {
      print(
          'Kiểm tra highlight "${highlight.text}": ${highlight.startIndex}-${highlight.endIndex}');

      // Kiểm tra xem highlight có chồng lấp với trang này không
      if (highlight.startIndex < pageEndInFullContent &&
          highlight.endIndex > pageStartInFullContent) {
        // Tính toán chỉ số điều chỉnh tương đối với nội dung trang
        final adjustedStart = (highlight.startIndex - pageStartInFullContent)
            .clamp(0, pageContent.length)
            .toInt();
        final adjustedEnd = (highlight.endIndex - pageStartInFullContent)
            .clamp(0, pageContent.length)
            .toInt();

        print(
            'Điều chỉnh thô: Bắt đầu=${highlight.startIndex - pageStartInFullContent}, Kết thúc=${highlight.endIndex - pageStartInFullContent}');
        print(
            'Điều chỉnh clamped: Bắt đầu=$adjustedStart, Kết thúc=$adjustedEnd');

        // Only add if we have a valid range
        if (adjustedStart >= 0 &&
            adjustedEnd > adjustedStart &&
            adjustedEnd <= pageContent.length) {
          // Verify the highlight text matches
          final highlightTextInPage =
              pageContent.substring(adjustedStart, adjustedEnd);
          final originalHighlightText = highlight.text;

          // Allow for some text differences due to formatting
          if (highlightTextInPage.trim() == originalHighlightText.trim() ||
              highlightTextInPage.contains(originalHighlightText.trim()) ||
              originalHighlightText.contains(highlightTextInPage.trim())) {
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
            print('Đã thêm highlight hợp lệ: $adjustedStart-$adjustedEnd');
          } else {
            print(
                'Văn bản không khớp - Mong đợi: "${originalHighlightText}", Nhận được: "${highlightTextInPage}"');
          }
        } else {
          print('Phạm vi không hợp lệ: $adjustedStart-$adjustedEnd');
        }
      } else {
        print('Không chồng lấp với trang');
      }
    }

    print('Trả về ${pageHighlights.length} highlights cho trang $pageIndex');
    print('=== Kết thúc Debug ===');
    return pageHighlights;
  }

  /**
   * WIDGET NỘI DUNG CHO CHẾ ĐỘ ĐỌC DỌC
   *
   * Tạo widget hiển thị nội dung trong chế độ cuộn dọc với
   * SelectableTextWidget để hỗ trợ highlight và bookmark.
   */
  Widget _buildVerticalContent() {
    final chapter = _chapterData?['chapter'];
    final content = chapter?['content'] ?? 'Không có nội dung';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        print('Phát hiện tap down nội dung dọc tại: ${details.globalPosition}');
        // Để main gesture detector xử lý logic tap
        // Đây chỉ là để phối hợp với SelectableTextWidget
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
              ttsHighlightStart: _ttsHighlightStart,
              ttsHighlightEnd: _ttsHighlightEnd,
              onHighlightAdded: _onHighlightAdded,
              onBookmarkAdded: _onBookmarkAdded,
              onTextSelectionChanged: _onTextSelectionChanged,
            ),
          ],
        ),
      ),
    );
  }

  /**
   * WIDGET NỘI DUNG CHO CHẾ ĐỘ ĐỌC NGANG
   *
   * Tạo widget PageView cho chế độ đọc ngang với hỗ trợ
   * overscroll để chuyển chương và SelectableTextWidget.
   */
  Widget _buildHorizontalContent() {
    final chapter = _chapterData?['chapter'];
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Xử lý overscroll để điều hướng chương trong chế độ ngang
        if (notification is OverscrollNotification) {
          final overscroll = notification.overscroll;

          // Overscroll sang trái (positive overscroll) khi ở trang đầu - chương trước
          if (overscroll > 20 && _currentPageIndex == 0) {
            final prevChapter = _getPreviousChapterNumber();
            if (prevChapter != null) {
              _navigateToChapter(prevChapter);
              return true;
            }
          }
          // Overscroll sang phải (negative overscroll) khi ở trang cuối - chương tiếp theo
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
              'Phát hiện tap down nội dung ngang tại: ${details.globalPosition}');
          // Để main gesture detector xử lý logic tap
          // Đây chỉ là để phối hợp với SelectableTextWidget
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
            // Update reading progress for horizontal mode
            _updateHorizontalReadingProgress();
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
                      ttsHighlightStart:
                          _getPageRelativeTTSHighlight(index)?['start'],
                      ttsHighlightEnd:
                          _getPageRelativeTTSHighlight(index)?['end'],
                      onHighlightAdded: _onHighlightAdded,
                      onBookmarkAdded: _onBookmarkAdded,
                      onTextSelectionChanged: _onTextSelectionChanged,
                      // New parameters for horizontal reading mode
                      isHorizontalReading: _isHorizontalReading,
                      pageIndex: index,
                      pageStartInFullContent:
                          _calculatePageStartInFullContent(index),
                    ),
                  ),
                  // Remove the page number display in horizontal reading mode
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Get temporary highlight relative to page for horizontal reading - IMPROVED VERSION
  Map<String, int>? _getPageRelativeTempHighlight(int pageIndex) {
    if (_tempHighlightStart == null || _tempHighlightEnd == null) {
      return null;
    }

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty || pageIndex >= _pages.length || pageIndex < 0) {
      return null;
    }

    // Calculate the absolute position of this page in the full content more accurately
    int pageStartInFullContent = 0;

    if (pageIndex > 0) {
      String searchContent = '';
      for (int i = 0; i < pageIndex; i++) {
        searchContent += _pages[i];
        if (i < pageIndex - 1) {
          searchContent += ' '; // Add space between pages as they were split
        }
      }
      pageStartInFullContent = searchContent.length;

      // Add space before current page if not first page
      if (pageIndex > 0 && pageStartInFullContent < fullContent.length) {
        pageStartInFullContent += 1; // Account for space between pages
      }
    }

    int pageEndInFullContent =
        pageStartInFullContent + _pages[pageIndex].length;
    pageEndInFullContent =
        pageEndInFullContent.clamp(0, fullContent.length).toInt();

    print('=== Temp Highlight Page Mapping Debug ===');
    print(
        'Page $pageIndex: Start=$pageStartInFullContent, End=$pageEndInFullContent');
    print('Temp highlight: ${_tempHighlightStart}-${_tempHighlightEnd}');

    // Verify our calculation by checking the actual content
    if (pageStartInFullContent + _pages[pageIndex].length <=
        fullContent.length) {
      final extractedContent = fullContent.substring(pageStartInFullContent,
          pageStartInFullContent + _pages[pageIndex].length);
      final contentMatches = extractedContent == _pages[pageIndex];
      print('Xác minh nội dung: ${contentMatches ? "KHỚP" : "KHÔNG KHỚP"}');
      if (!contentMatches) {
        // Try to find the correct position
        final correctStart = fullContent.indexOf(_pages[pageIndex]);
        if (correctStart != -1) {
          pageStartInFullContent = correctStart;
          pageEndInFullContent = correctStart + _pages[pageIndex].length;
          print(
              'Corrected positions: Start=$pageStartInFullContent, End=$pageEndInFullContent');
        }
      }
    }

    // Check if temp highlight overlaps with this page
    if (_tempHighlightStart! < pageEndInFullContent &&
        _tempHighlightEnd! > pageStartInFullContent) {
      // Calculate adjusted indices
      final adjustedStart = (_tempHighlightStart! - pageStartInFullContent)
          .clamp(0, _pages[pageIndex].length)
          .toInt();
      final adjustedEnd = (_tempHighlightEnd! - pageStartInFullContent)
          .clamp(0, _pages[pageIndex].length)
          .toInt();

      print('Adjusted temp highlight: Start=$adjustedStart, End=$adjustedEnd');

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

        // Verify the temp highlight text matches
        if (_tempHighlightText != null && _tempHighlightText!.isNotEmpty) {
          final tempTextInPage =
              _pages[pageIndex].substring(adjustedStart, adjustedEnd);
          if (tempTextInPage.trim() == _tempHighlightText!.trim() ||
              tempTextInPage.contains(_tempHighlightText!.trim()) ||
              _tempHighlightText!.contains(tempTextInPage.trim())) {
            print('Văn bản temp highlight đã được xác minh');
            return {
              'start': adjustedStart,
              'end': adjustedEnd,
            };
          } else {
            print(
                '❌ Temp highlight text mismatch - Expected: "${_tempHighlightText}", Got: "$tempTextInPage"');
          }
        } else {
          return {
            'start': adjustedStart,
            'end': adjustedEnd,
          };
        }
      }
    }

    print('Temp highlight không áp dụng cho trang này');
    return null;
  }

  // Get TTS highlight relative to page for horizontal reading
  Map<String, int>? _getPageRelativeTTSHighlight(int pageIndex) {
    if (_ttsHighlightStart == null || _ttsHighlightEnd == null) {
      return null;
    }

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty || pageIndex >= _pages.length || pageIndex < 0) {
      return null;
    }

    // Calculate the absolute position of this page in the full content more accurately
    int pageStartInFullContent = _calculatePageStartInFullContent(pageIndex);
    int pageEndInFullContent =
        pageStartInFullContent + _pages[pageIndex].length;

    // Ensure we don't exceed content bounds
    pageEndInFullContent =
        pageEndInFullContent.clamp(0, fullContent.length).toInt();

    print('=== TTS Highlight Page Mapping Debug ===');
    print(
        'Page $pageIndex: Start=$pageStartInFullContent, End=$pageEndInFullContent');
    print('TTS highlight: ${_ttsHighlightStart}-${_ttsHighlightEnd}');
    print('Độ dài nội dung trang: ${_pages[pageIndex].length}');
    print('Độ dài nội dung đầy đủ: ${fullContent.length}');

    // Check if TTS highlight overlaps with this page
    if (_ttsHighlightStart! < pageEndInFullContent &&
        _ttsHighlightEnd! > pageStartInFullContent) {
      // Calculate adjusted indices with better bounds checking
      int adjustedStart =
          (_ttsHighlightStart! - pageStartInFullContent).toInt();
      int adjustedEnd = (_ttsHighlightEnd! - pageStartInFullContent).toInt();

      // Clamp to page boundaries
      adjustedStart = adjustedStart.clamp(0, _pages[pageIndex].length);
      adjustedEnd = adjustedEnd.clamp(0, _pages[pageIndex].length);

      // Ensure we have a valid range
      if (adjustedEnd <= adjustedStart) {
        adjustedEnd = (adjustedStart + 1).clamp(0, _pages[pageIndex].length);
      }

      print('Adjusted TTS highlight: Start=$adjustedStart, End=$adjustedEnd');

      // Validate the highlight range
      if (adjustedStart >= 0 &&
          adjustedEnd > adjustedStart &&
          adjustedStart < _pages[pageIndex].length &&
          adjustedEnd <= _pages[pageIndex].length) {
        // Additional validation: check if the highlighted text makes sense
        final highlightedText =
            _pages[pageIndex].substring(adjustedStart, adjustedEnd);
        if (highlightedText.trim().isNotEmpty) {
          print(
              '✅ TTS highlight applied to page $pageIndex: "${highlightedText.length > 50 ? highlightedText.substring(0, 50) + "..." : highlightedText}"');
          return {
            'start': adjustedStart,
            'end': adjustedEnd,
          };
        } else {
          print('Văn bản TTS highlight rỗng hoặc chỉ có khoảng trắng');
        }
      } else {
        print(
            '❌ TTS highlight range is invalid: start=$adjustedStart, end=$adjustedEnd, pageLength=${_pages[pageIndex].length}');
      }
    } else {
      print('TTS highlight không chồng lấp với trang này');
    }

    return null;
  }

  // Handle auto-scroll to initial position
  void _handleAutoScroll() {
    if (widget.initialScrollPosition != null) {
      print('=== Thiết lập Auto-scroll ===');
      print('Vị trí cuộn ban đầu: ${widget.initialScrollPosition}');
      print('Văn bản tìm kiếm: ${widget.searchText}');
      print('Bookmark text: ${widget.bookmarkText}');

      // Use multiple frame callbacks to ensure UI is fully ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Callback frame đầu tiên đã được thực thi');

        // Wait longer for content to be fully rendered
        Future.delayed(const Duration(milliseconds: 800), () {
          print('Đang thực thi auto-scroll với delay...');
          print('ScrollController có clients: ${_scrollController.hasClients}');

          if (_scrollController.hasClients) {
            print(
                'ScrollController maxScrollExtent: ${_scrollController.position.maxScrollExtent}');

            // Ensure we have content before scrolling
            final chapter = _chapterData?['chapter'];
            final content = chapter?['content'] ?? '';

            if (content.isNotEmpty &&
                widget.initialScrollPosition! < content.length) {
              _scrollToPosition(
                widget.initialScrollPosition!,
                searchText: widget.searchText,
                bookmarkText: widget.bookmarkText,
              );
            } else {
              print('Vị trí cuộn không hợp lệ hoặc nội dung rỗng');
              print('Độ dài nội dung: ${content.length}');
              print('Vị trí được yêu cầu: ${widget.initialScrollPosition}');

              // Show error feedback
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể nhảy đến vị trí được yêu cầu'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            print('ScrollController chưa sẵn sàng, đang thử lại...');

            // Retry one more time after additional delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _scrollController.hasClients) {
                print('Thử lại thành công - đang thực thi cuộn');
                _scrollToPosition(
                  widget.initialScrollPosition!,
                  searchText: widget.searchText,
                  bookmarkText: widget.bookmarkText,
                );
              } else {
                print('❌ Final retry failed');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Không thể cuộn đến vị trí - UI chưa sẵn sàng'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            });
          }
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

  // Cache for chapter content to avoid reloading
  final Map<int, Map<String, dynamic>> _chapterContentCache = {};

  // Progress tracking for global search
  int _searchProgress = 0;
  int _totalChaptersToSearch = 0;

  // Maximum cache size to prevent memory issues
  static const int _maxCacheSize = 20;

  // Clear cache if it gets too large
  void _manageCacheSize() {
    if (_chapterContentCache.length > _maxCacheSize) {
      // Remove oldest entries (simple FIFO approach)
      final keysToRemove = _chapterContentCache.keys
          .take(_chapterContentCache.length - _maxCacheSize)
          .toList();
      for (final key in keysToRemove) {
        _chapterContentCache.remove(key);
      }
      print(
          '🧹 Cache cleaned. Removed ${keysToRemove.length} entries. Current size: ${_chapterContentCache.length}');
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    print('Bắt đầu tìm kiếm toàn cục tối ưu cho: "$query"');
    print('Tổng số chương cần tìm kiếm: ${_allChapters.length}');

    // Clear previous results immediately and show loading
    setState(() {
      _searchResults = [];
      _globalSearchResults = [];
      _currentSearchIndex = -1;
      _searchProgress = 0;
      _totalChaptersToSearch = _allChapters.length;
    });

    try {
      final List<Map<String, dynamic>> globalResults = [];
      final queryLower = query.toLowerCase();

      // Process chapters in batches for better performance
      const batchSize = 5; // Process 5 chapters at a time
      final batches = <List<Map<String, dynamic>>>[];

      for (int i = 0; i < _allChapters.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, _allChapters.length);
        batches.add(_allChapters.sublist(i, end));
      }

      print(
          '📦 Processing ${batches.length} batches of $batchSize chapters each');

      // Process batches sequentially but chapters within batch in parallel
      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        print('Đang xử lý batch ${batchIndex + 1}/${batches.length}');

        // Process chapters in this batch in parallel
        final batchFutures = batch
            .map((chapterInfo) =>
                _searchInChapter(chapterInfo, query, queryLower))
            .toList();

        final batchResults = await Future.wait(batchFutures);

        // Collect results from this batch
        for (final chapterResults in batchResults) {
          if (chapterResults.isNotEmpty) {
            globalResults.addAll(chapterResults);

            // Update UI with progressive results
            if (mounted && _isSearching && _searchController.text == query) {
              setState(() {
                _globalSearchResults = List.from(globalResults);
                _searchProgress = (batchIndex + 1) * batchSize;
              });
            }
          }
        }

        // Small delay between batches to prevent overwhelming the system
        if (batchIndex < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Check if search was cancelled
        if (!mounted || !_isSearching || _searchController.text != query) {
          print('⚠️ Search was cancelled');
          return;
        }
      }

      print(
          '🎯 Global search completed. Total results: ${globalResults.length}');

      // Final update
      if (mounted && _isSearching && _searchController.text == query) {
        setState(() {
          _searchResults = [];
          _globalSearchResults = globalResults;
          _currentSearchIndex = -1;
          _searchProgress = _totalChaptersToSearch;
        });
        print(
            'State đã được cập nhật với ${globalResults.length} kết quả toàn cục');
      }
    } catch (e) {
      print('Lỗi tìm kiếm toàn cục: $e');
      if (mounted && _isSearching) {
        setState(() {
          _searchResults = [];
          _globalSearchResults = [];
          _currentSearchIndex = -1;
          _searchProgress = 0;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchInChapter(
      Map<String, dynamic> chapterInfo, String query, String queryLower) async {
    final chapterNumber = chapterInfo['number'] as int;
    final chapterTitle = chapterInfo['title'] ?? 'Chương $chapterNumber';
    final results = <Map<String, dynamic>>[];

    try {
      // Check cache first
      Map<String, dynamic>? chapterData = _chapterContentCache[chapterNumber];

      if (chapterData == null) {
        // Try service cache
        chapterData = await _cacheService.getCachedChapter(
            widget.story.slug, chapterNumber);

        if (chapterData == null) {
          print('Đang tải chương $chapterNumber từ API...');
          chapterData = await OTruyenApi.getEpubChapterContent(
              widget.story.slug, chapterNumber);
          // Cache in service
          await _cacheService.cacheChapter(
              widget.story.slug, chapterNumber, chapterData);
        } else {
          print('Sử dụng chương $chapterNumber đã cache từ service');
        }

        // Cache in memory for this session
        _chapterContentCache[chapterNumber] = chapterData;
        _manageCacheSize();
      } else {
        print('Sử dụng chương $chapterNumber đã cache trong memory');
      }

      final content = chapterData['chapter']?['content'] ?? '';
      if (content.isEmpty) {
        print('Cảnh báo: Chương $chapterNumber có nội dung rỗng');
        return results;
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
        final end = (foundIndex + query.length + 100).clamp(0, content.length);
        final context = content.substring(start, end);

        results.add({
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
        print('Tìm thấy $matchCount kết quả khớp trong chương $chapterNumber');
      }
    } catch (e) {
      print('Lỗi tìm kiếm chương $chapterNumber: $e');
    }

    return results;
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

  /**
   * XÂY DỰNG WIDGET OVERLAY TÌM KIẾM
   *
   * Tạo giao diện tìm kiếm với thanh input, danh sách kết quả
   * và các nút điều hướng.
   */
  Widget _buildSearchOverlay() {
    return Container(
      color: _backgroundColor.withOpacity(0.95),
      child: Column(
        children: [
          // Thanh nhập liệu tìm kiếm
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
    if (_searchQuery.isNotEmpty &&
        _globalSearchResults.isEmpty &&
        _searchProgress < _totalChaptersToSearch) {
      print('⏳ Showing loading state for global search');
      final progressPercent = _totalChaptersToSearch > 0
          ? (_searchProgress / _totalChaptersToSearch * 100).round()
          : 0;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_textColor),
              value: _totalChaptersToSearch > 0
                  ? _searchProgress / _totalChaptersToSearch
                  : null,
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
              'Tiến trình: $_searchProgress/$_totalChaptersToSearch chương ($progressPercent%)',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            if (_globalSearchResults.isNotEmpty)
              Text(
                'Đã tìm thấy ${_globalSearchResults.length} kết quả',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      );
    }

    // Show empty state when search completed but no results
    if (_searchQuery.isNotEmpty && _globalSearchResults.isEmpty) {
      print('Không tìm thấy kết quả tìm kiếm toàn cục');
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

  // Xây dựng overlay cho bookmarks và highlights
  Widget _buildHighlightBookmarkOverlay() {
    return Container(
      color: _backgroundColor.withOpacity(0.95),
      child: Column(
        children: [
          // Thanh tiêu đề
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
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: _textColor),
                  onPressed: _toggleHighlightBookmarkOverlay,
                ),
                Expanded(
                  child: Text(
                    'Đánh dấu & Highlight',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab cho bookmarks và highlights
          DefaultTabController(
            length: 2,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        icon: Icon(Icons.highlight, color: _textColor),
                        text: 'Highlight',
                      ),
                      Tab(
                        icon: Icon(Icons.bookmark, color: _textColor),
                        text: 'Bookmark',
                      ),
                    ],
                    labelColor: _textColor,
                    indicatorColor: Theme.of(context).primaryColor,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab Highlights
                        _buildHighlightsTab(),

                        // Tab Bookmarks
                        _buildBookmarksTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Xây dựng tab Bookmarks
  Widget _buildBookmarksTab() {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: _textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đánh dấu nào',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn văn bản và nhấn vào biểu tượng đánh dấu để tạo',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lọc bookmarks của chương hiện tại
    final currentChapterBookmarks = _bookmarks
        .where((bookmark) => bookmark.chapterNumber == widget.chapterNumber)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentChapterBookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = currentChapterBookmarks[index];
        return Card(
          color: _backgroundColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              bookmark.chapterTitle,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              bookmark.text.length > 100
                  ? '${bookmark.text.substring(0, 100)}...'
                  : bookmark.text,
              style: TextStyle(
                color: _textColor.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: const Icon(
              Icons.bookmark,
              color: Colors.blue,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: _textColor.withOpacity(0.6)),
              onPressed: () async {
                // Xóa bookmark và cập nhật lại danh sách
                await _readingService.removeBookmark(bookmark.id);
                _loadHighlightsAndBookmarks();
              },
            ),
            onTap: () {
              _navigateToBookmark(bookmark);
              _toggleHighlightBookmarkOverlay();
            },
          ),
        );
      },
    );
  }

  // Xây dựng tab Highlights
  Widget _buildHighlightsTab() {
    if (_highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.highlight_alt,
              size: 64,
              color: _textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có highlight nào',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn văn bản và nhấn vào biểu tượng highlight để tạo',
              style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lọc highlights của chương hiện tại
    final currentChapterHighlights = _highlights
        .where((highlight) => highlight.chapterNumber == widget.chapterNumber)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentChapterHighlights.length,
      itemBuilder: (context, index) {
        final highlight = currentChapterHighlights[index];
        return Card(
          color: _backgroundColor,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              highlight.chapterTitle,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              highlight.text.length > 100
                  ? '${highlight.text.substring(0, 100)}...'
                  : highlight.text,
              style: TextStyle(
                color: _textColor.withOpacity(0.8),
                fontSize: 13,
                backgroundColor:
                    Color(int.parse(highlight.color)).withOpacity(0.3),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: Icon(
              Icons.format_paint,
              color: Color(int.parse(highlight.color)),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: _textColor.withOpacity(0.6)),
              onPressed: () async {
                // Xóa highlight và cập nhật lại danh sách
                await _readingService.removeHighlight(highlight.id);
                _loadHighlightsAndBookmarks();
              },
            ),
            onTap: () {
              _navigateToHighlight(highlight);
              _toggleHighlightBookmarkOverlay();
            },
          ),
        );
      },
    );
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
      appBar:
          _isFullScreen || _isSearching || _isHighlightBookmarkOverlayVisible
              ? null
              : AppBar(
                  backgroundColor: _backgroundColor,
                  foregroundColor: _textColor,
                  title: Text(
                    '${widget.story.title} - ${chapter?['title'] ?? widget.chapterTitle}',
                    style: TextStyle(color: _textColor),
                  ),
                  actions: [
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(Icons.bookmark),
                          if (_highlights.isNotEmpty || _bookmarks.isNotEmpty)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_highlights.length + _bookmarks.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: _openHighlightsBookmarks,
                      tooltip: 'Highlights & Bookmarks',
                    ),
                    // Auto-scroll button (only for vertical reading mode)
                    if (!_isHorizontalReading)
                      IconButton(
                        icon: Icon(
                          _isAutoScrollActive
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: _isAutoScrolling ? Colors.green : _textColor,
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
                    // Search button
                    IconButton(
                      icon: Icon(Icons.search, color: _textColor),
                      onPressed: _showSearchDialog,
                      tooltip: 'Tìm kiếm',
                    ),
                  ],
                ),
      body: Stack(
        children: [
          // Main content
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!_isHorizontalReading) {
                // Handle overscroll for chapter navigation
                if (notification is OverscrollNotification) {
                  final overscroll = notification.overscroll;

                  // Overscroll at top (positive overscroll, pulling down) - next chapter (đọc tiếp)
                  if (overscroll > 20) {
                    final nextChapter = _getNextChapterNumber();
                    if (nextChapter != null) {
                      _navigateToChapter(nextChapter);
                      return true;
                    }
                  }
                  // Overscroll at bottom (negative overscroll, pulling up) - previous chapter (quay lại)
                  else if (overscroll < -20) {
                    final prevChapter = _getPreviousChapterNumber();
                    if (prevChapter != null) {
                      _navigateToChapter(prevChapter);
                      return true;
                    }
                  }
                }
              }
              return false;
            },
            child: SafeArea(
              // Only apply SafeArea when in fullscreen mode
              top: _isFullScreen,
              bottom: false, // Let the content go to the bottom edge
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  print('Phát hiện pointer down tại: ${event.position}');
                  // Không can thiệp nếu text selection đang hoạt động
                  if (_isTextSelectionActive) {
                    print(
                        'Text selection đang hoạt động - bỏ qua pointer down');
                    return;
                  }

                  // Start timer to detect if this is a long press (for text selection)
                  _tapTimer?.cancel();
                  _tapTimer = Timer(const Duration(milliseconds: 300), () {
                    // If timer completes, it's likely a long press for text selection
                    // Không xử lý như tap
                    print('Phát hiện long press - bỏ qua tap');
                    setState(() {
                      _isTextSelectionActive = true;
                    });
                  });
                },
                onPointerMove: (event) {
                  // If pointer is moving and text selection is active, don't interfere
                  if (_isTextSelectionActive) {
                    print(
                        'Text selection đang hoạt động - cho phép pointer move');
                    return;
                  }
                },
                onPointerUp: (event) {
                  print('Phát hiện pointer up tại: ${event.position}');

                  // Nếu text selection đang hoạt động, không xử lý như tap
                  if (_isTextSelectionActive) {
                    print('Text selection đang hoạt động - bỏ qua pointer up');
                    // Reset text selection tracking after a longer delay to allow for context menu
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) {
                        setState(() {
                          _isTextSelectionActive = false;
                        });
                      }
                    });
                    return;
                  }

                  // Cancel timer and handle as tap if it was quick
                  if (_tapTimer?.isActive == true) {
                    _tapTimer?.cancel();
                    // Quick tap - handle fullscreen toggle
                    if (!_isSearching) {
                      print(
                          '⚡ Quick tap detected - handling fullscreen toggle');
                      _handleTapAtPosition(event.position, 'pointer');
                    }
                  }

                  // Reset text selection tracking after a delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        _isTextSelectionActive = false;
                      });
                    }
                  });
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    // Don't clear highlights if text selection is active
                    if (!_isTextSelectionActive) {
                      _clearTempHighlight(); // Clear highlights when scrolling starts
                    }
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
          ),
          // Search overlay
          if (_isSearching) _buildSearchOverlay(),
          // Highlight & Bookmark overlay
          if (_isHighlightBookmarkOverlayVisible)
            _buildHighlightBookmarkOverlay(),
          // Auto-scroll control panel
          if (_isAutoScrolling && !_isHorizontalReading)
            _buildAutoScrollControlPanel(),
          // TTS controls
          if (_isTTSEnabled) _buildTTSControls(),
          // Fullscreen minimal info overlay
          if (_isFullScreen && hasContent)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                decoration: BoxDecoration(
                  // More subtle background - no gradient, just semi-transparent
                  color: _backgroundColor.withOpacity(0.9),
                  // Optional: Add a subtle top border
                  border: Border(
                    top: BorderSide(
                      color: _textColor.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false, // Don't add top padding here
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chapter info
                      Text(
                        '${widget.chapterNumber}/${_allChapters.length}',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                          // Only show page info for vertical reading mode
                          Text(
                            _isHorizontalReading
                                ? '${_currentPageIndex + 1}/${_pages.length}'
                                : '${_getCurrentEstimatedPage()}/${_getTotalEstimatedPages()}',
                            style: TextStyle(
                              color: _textColor.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),

                          Text(
                            '${_readingProgress.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _textColor.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 8),
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
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Chapter list button
                      _buildBottomActionButton(
                        icon: Icons.list,
                        label: 'Chương',
                        onPressed: _showChapterList,
                        tooltip: 'Danh sách chương',
                      ),
                      // Comment button
                      _buildBottomActionButton(
                        icon: Icons.comment,
                        label: 'Bình luận',
                        onPressed: _showComments,
                        tooltip: 'Bình luận chương',
                        badge: _commentCount > 0 ? '$_commentCount' : null,
                      ),
                      // TTS button
                      _buildBottomActionButton(
                        icon: _isTTSEnabled
                            ? Icons.volume_up
                            : Icons.headphones_rounded,
                        label: 'Nghe',
                        onPressed: _toggleTTS,
                        isActive: _isTTSEnabled,
                        tooltip: _isTTSEnabled
                            ? (_isTTSControlsVisible
                                ? 'Ẩn điều khiển TTS'
                                : 'Hiện điều khiển TTS')
                            : 'Bật TTS',
                      ),
                      // Settings button
                      _buildBottomActionButton(
                        icon: Icons.settings,
                        label: 'Cài đặt',
                        onPressed: _showSettings,
                        tooltip: 'Cài đặt đọc sách',
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // Immediate fullscreen toggle without debouncing for direct calls
  void _toggleFullScreenImmediate(String source) {
    if (!_isSearching && mounted) {
      setState(() {
        _isFullScreen = !_isFullScreen;
        print(
            '🔄 Toggled _isFullScreen to: $_isFullScreen (from $source - immediate)');
      });

      // Recalculate pages when toggling fullscreen in horizontal reading mode
      if (_isHorizontalReading && _chapterData != null) {
        print(
            '📱 Recalculating pages for fullscreen change in horizontal mode');
        // Use addPostFrameCallback with additional delay to ensure UI is fully updated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _calculatePagesBasedOnScreenSize();
            }
          });
        });
      }

      // Save the fullscreen setting
      _saveSettings();
    }
  }

  // Handle tap based on screen position
  // Screen is divided into 3 zones: 30% left, 40% center, 30% right
  // - Vertical reading mode: Only center zone toggles fullscreen, side zones are ignored
  // - Horizontal reading mode: Left zone = previous page, Right zone = next page, Center zone = toggle fullscreen
  void _handleTapAtPosition(Offset globalPosition, String source) {
    if (_isSearching) return;

    // If in auto-scroll mode, tap toggles control panel visibility
    if (_isAutoScrolling) {
      _toggleAutoScrollControls();
      return;
    }

    // If TTS is enabled, tap toggles TTS controls visibility
    if (_isTTSEnabled) {
      _toggleTTSControls();
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = globalPosition.dx;

    // Divide screen into 3 zones: 30% left, 40% center, 30% right
    final leftZone = screenWidth * 0.3; // 30% left zone
    final rightZone = screenWidth * 0.7; // 70% (30% right zone)

    print(
        '🎯 Tap at x=$tapX, screenWidth=$screenWidth, zones: left<$leftZone, center=$leftZone-$rightZone, right>$rightZone');

    if (_isHorizontalReading) {
      // Horizontal reading mode: left/right for page navigation, center for fullscreen
      if (tapX < leftZone) {
        // Vùng trái - trang trước (phản hồi ngay lập tức)
        print('Tap vùng trái - trang trước');
        _previousPage();
      } else if (tapX > rightZone) {
        // Vùng phải - trang tiếp theo (phản hồi ngay lập tức)
        print('Tap vùng phải - trang tiếp theo');
        _nextPage();
      } else {
        // Vùng giữa - toggle fullscreen (phản hồi ngay lập tức)
        print('Tap vùng giữa - toggle fullscreen');
        _clearTempHighlight();
        _toggleFullScreenImmediate('center-horizontal');
      }
    } else {
      // Vertical reading mode: only center zone toggles fullscreen
      if (tapX >= leftZone && tapX <= rightZone) {
        // Vùng giữa - toggle fullscreen (phản hồi ngay lập tức)
        print('Tap vùng giữa - toggle fullscreen (dọc)');
        _clearTempHighlight();
        _toggleFullScreenImmediate('center-vertical');
      } else {
        print('Tap trong vùng bên bị bỏ qua cho chế độ đọc dọc');
        // In vertical mode, side zones do nothing to avoid accidental fullscreen toggle
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
      print('Đã điều hướng đến trang trước: ${_currentPageIndex - 1}');
    } else {
      // At first page, try to go to previous chapter
      final prevChapter = _getPreviousChapterNumber();
      if (prevChapter != null) {
        print('Đang chuyển đến chương trước: $prevChapter');
        _navigateToChapter(prevChapter);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chuyển sang chương $prevChapter'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        print('Đã ở trang đầu của chương đầu tiên');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ở chương đầu tiên'),
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
      print('Đã điều hướng đến trang tiếp theo: ${_currentPageIndex + 1}');
    } else {
      // At last page, try to go to next chapter
      final nextChapter = _getNextChapterNumber();
      if (nextChapter != null) {
        print('Đang chuyển đến chương tiếp theo: $nextChapter');
        _navigateToChapter(nextChapter);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chuyển sang chương $nextChapter'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        print('Đã ở trang cuối của chương cuối cùng');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ở chương cuối cùng'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // Helper method to calculate where a page starts in the full content
  int _calculatePageStartInFullContent(int pageIndex) {
    if (pageIndex <= 0) return 0;

    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    if (fullContent.isEmpty || pageIndex >= _pages.length) {
      return 0;
    }

    // More accurate calculation: find the actual position of each page in the full content
    int currentPosition = 0;

    for (int i = 0; i < pageIndex; i++) {
      final pageContent = _pages[i];

      // Find where this page actually starts in the full content
      int pageStart = fullContent.indexOf(pageContent, currentPosition);

      if (pageStart == -1) {
        // If exact match not found, try with cleaned content
        String cleanedFullContent = fullContent
            .substring(currentPosition)
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        String cleanedPageContent =
            pageContent.replaceAll(RegExp(r'\s+'), ' ').trim();

        int cleanedStart = cleanedFullContent.indexOf(cleanedPageContent);
        if (cleanedStart != -1) {
          // Map back to original position
          pageStart = currentPosition +
              _mapCleanedPositionToOriginal(
                  fullContent.substring(currentPosition),
                  cleanedFullContent,
                  cleanedStart);
        } else {
          // Fallback: estimate based on previous calculations
          pageStart = currentPosition;
        }
      }

      // Update current position to end of this page
      currentPosition = pageStart + pageContent.length;

      // Skip any whitespace between pages
      while (currentPosition < fullContent.length &&
          RegExp(r'\s').hasMatch(fullContent[currentPosition])) {
        currentPosition++;
      }
    }

    // Ensure we don't exceed content bounds
    return currentPosition.clamp(0, fullContent.length).toInt();
  }

  // Auto-scroll functionality methods
  void _startAutoScroll() {
    // Only works in vertical reading mode
    if (_isHorizontalReading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tự động cuộn chỉ hoạt động ở chế độ đọc dọc'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Save current fullscreen state and switch to fullscreen
    _wasFullScreenBeforeAutoScroll = _isFullScreen;

    setState(() {
      _isAutoScrolling = true;
      _isAutoScrollActive = true;
      _isFullScreen = true;
      _isAutoScrollControlsVisible = true;
    });

    _saveSettings(); // Save fullscreen state
    _clearTempHighlight();
    _clearSearch();

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
    if (!_isHorizontalReading && _isAutoScrolling) {
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
      // Restore previous fullscreen state
      _isFullScreen = _wasFullScreenBeforeAutoScroll;
    });
    _autoScrollTimer?.cancel();
    _saveSettings(); // Save restored fullscreen state
  }

  void _handleAutoScrollChapterEnd() {
    final nextChapter = _getNextChapterNumber();
    if (nextChapter != null) {
      // Show notification and continue to next chapter
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chuyển sang chương $nextChapter'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to next chapter and continue auto-scroll
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EpubChapterPage(
            story: widget.story,
            chapterNumber: nextChapter,
            chapterTitle: _getChapterTitle(nextChapter),
            autoStartTTS: _isTTSEnabled, // Continue TTS if it was enabled
          ),
        ),
      ).then((_) {
        // Start auto-scroll in new chapter after a short delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _startAutoScroll();
          }
        });
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
      _autoScrollSpeed = newSpeed.clamp(5.0, 300.0);
    });
    _saveSettings(); // Save speed change immediately
  }

  void _toggleAutoScrollControls() {
    if (_isAutoScrolling) {
      setState(() {
        _isAutoScrollControlsVisible = !_isAutoScrollControlsVisible;
      });
    }
  }

  void _toggleTTSControls() {
    if (_isTTSEnabled) {
      setState(() {
        _isTTSControlsVisible = !_isTTSControlsVisible;
      });
    }
  }

  // Build auto-scroll control panel widget
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
          color: _backgroundColor.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(-2, 0),
            ),
          ],
          border: Border.all(
            color: _textColor.withOpacity(0.15),
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
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'px/s',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
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
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: _textColor.withOpacity(0.2),
                      thumbColor: Theme.of(context).primaryColor,
                      overlayColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
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
                        color: _textColor,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _textColor.withOpacity(0.1),
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
                      icon: Icon(
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

  // Build TTS Settings Modal
  Widget _buildTTSSettingsModal(StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor,
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
          Text(
            'Cài đặt Text-to-Speech',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 20),

          // Language Selection - Always show, even if languages list is empty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngôn ngữ:',
                style: TextStyle(color: _textColor, fontSize: 16),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _availableLanguages.isNotEmpty
                      ? DropdownButton<String>(
                          value: _selectedLanguage,
                          items: _getLanguageDropDownMenuItems(
                              _availableLanguages),
                          onChanged: (value) {
                            _changeLanguage(value);
                            setModalState(() {});
                          },
                          dropdownColor: _backgroundColor,
                          style: TextStyle(color: _textColor, fontSize: 14),
                          underline: Container(
                            height: 1,
                            color: _textColor.withOpacity(0.3),
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: _textColor),
                          isExpanded: false,
                          menuMaxHeight: 300,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _textColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _textColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đang tải...',
                                    style: TextStyle(
                                        color: _textColor, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.refresh, color: _textColor),
                              onPressed: () {
                                print('🔊 Refreshing TTS languages...');
                                _initializeTTSLanguage();
                                setModalState(() {});
                              },
                              tooltip: 'Làm mới danh sách ngôn ngữ',
                              iconSize: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          if (!_isCurrentLanguageInstalled && _selectedLanguage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ngôn ngữ này có thể chưa được cài đặt trên thiết bị',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Speech Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tốc độ:', style: TextStyle(color: _textColor)),
              Text('${_ttsService.speechRate.toStringAsFixed(1)}',
                  style: TextStyle(color: _textColor)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: _textColor.withOpacity(0.3),
              thumbColor: Theme.of(context).primaryColor,
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: _ttsService.speechRate,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) async {
                await _ttsService.setSpeechRate(value);
                setModalState(() {});
              },
            ),
          ),

          // Pitch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Độ cao:', style: TextStyle(color: _textColor)),
              Text('${_ttsService.pitch.toStringAsFixed(1)}',
                  style: TextStyle(color: _textColor)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: _textColor.withOpacity(0.3),
              thumbColor: Theme.of(context).primaryColor,
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            ),
            child: Slider(
              value: _ttsService.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) async {
                await _ttsService.setPitch(value);
                setModalState(() {});
              },
            ),
          ),

          const SizedBox(height: 20),

          // Test and Close buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await _ttsService
                          .speakText('Đây là thử nghiệm Text-to-Speech');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi TTS: $e')),
                      );
                    }
                  },
                  child: const Text('Nghe thử'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _textColor.withOpacity(0.1),
                    foregroundColor: _textColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Auto-scroll toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tự động cuộn:',
                style: TextStyle(color: _textColor, fontSize: 16),
              ),
              Switch(
                value: _ttsAutoScrollEnabled,
                onChanged: (value) {
                  setModalState(() {
                    _ttsAutoScrollEnabled = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /**
   * XÂY DỰNG ĐIỀU KHIỂN TTS
   *
   * Tạo giao diện điều khiển Text-to-Speech với các nút
   * play/pause, previous/next, settings và thông tin tiến độ.
   */
  Widget _buildTTSControls() {
    if (!_isTTSControlsVisible) return const SizedBox.shrink();

    final currentParagraph = _ttsService.currentParagraphIndex >= 0
        ? _ttsService.currentParagraphIndex + 1
        : 0;
    final totalParagraphs = _ttsService.paragraphs.length;

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator for TTS
            if (totalParagraphs > 1) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currentParagraph / $totalParagraphs',
                    style: TextStyle(
                      color: _textColor.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: totalParagraphs > 0
                    ? currentParagraph / totalParagraphs
                    : 0.0,
                backgroundColor: _textColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
                minHeight: 2,
              ),
              const SizedBox(height: 8),
            ],
            // Main control buttons - first row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous chapter
                _buildTTSButton(
                  icon: Icons.skip_previous,
                  onPressed: () {
                    print('Nút chương trước đã được nhấn');
                    _navigateToPreviousChapterWithTTS();
                  },
                  enabled: _getPreviousChapterNumber() != null,
                  tooltip: 'Chương trước',
                ),

                // Previous paragraph
                _buildTTSButton(
                  icon: Icons.fast_rewind,
                  onPressed: () {
                    print('Nút đoạn văn trước đã được nhấn');
                    _previousTTSParagraph();
                  },
                  enabled: _ttsService.currentParagraphIndex > 0,
                  tooltip: 'Đoạn trước',
                ),

                // Play/Pause
                _buildTTSButton(
                  icon: _isTTSPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: () {
                    print(
                        '🔊 Play/Pause button pressed. Current state: $_isTTSPlaying');
                    if (_isTTSPlaying) {
                      _pauseTTS();
                    } else {
                      _playTTS();
                    }
                  },
                  size: 35,
                  enabled: true,
                  tooltip: _isTTSPlaying ? 'Tạm dừng' : 'Phát',
                ),

                // Next paragraph
                _buildTTSButton(
                  icon: Icons.fast_forward,
                  onPressed: () {
                    print('Nút đoạn văn tiếp theo đã được nhấn');
                    _nextTTSParagraph();
                  },
                  enabled:
                      _ttsService.currentParagraphIndex < totalParagraphs - 1,
                  tooltip: 'Đoạn sau',
                ),

                // Next chapter
                _buildTTSButton(
                  icon: Icons.skip_next,
                  onPressed: () {
                    print('Nút chương tiếp theo đã được nhấn');
                    _navigateToNextChapterWithTTS();
                  },
                  enabled: _getNextChapterNumber() != null,
                  tooltip: 'Chương sau',
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Secondary control buttons - second row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTTSIconButton(
                  icon: Icons.list,
                  onPressed: () {
                    print('Nút chương đã được nhấn');
                    _showChapterList();
                  },
                  enabled: true,
                  tooltip: 'Danh sách chương',
                ),

                // Stop/Off button
                _buildTTSIconButton(
                  icon: Icons.power_settings_new,
                  onPressed: () {
                    print('Nút dừng đã được nhấn');
                    _stopTTS();
                  },
                  enabled: true,
                  tooltip: 'Tắt TTS',
                ),

                // Settings
                _buildTTSIconButton(
                  icon: Icons.settings,
                  onPressed: () {
                    print('Nút cài đặt đã được nhấn');
                    _showTTSSettings();
                  },
                  enabled: true,
                  tooltip: 'Cài đặt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 25,
    bool enabled = true,
    String? tooltip,
  }) {
    Widget button = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled
            ? _textColor.withOpacity(0.1)
            : _textColor.withOpacity(0.05),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(20),
        child: Icon(
          icon,
          size: size,
          color: enabled ? _textColor : _textColor.withOpacity(0.3),
        ),
      ),
    );

    if (tooltip != null && enabled) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  Widget _buildTTSIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 25,
    bool enabled = true,
    String? tooltip,
  }) {
    Widget button = InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: size,
          color: enabled ? _textColor : _textColor.withOpacity(0.3),
        ),
      ),
    );

    if (tooltip != null && enabled) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }

  // Navigate to previous chapter and continue TTS
  void _navigateToPreviousChapterWithTTS() async {
    final prevChapter = _getPreviousChapterNumber();
    if (prevChapter == null) {
      print('Không có chương trước');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ở chương đầu tiên'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('🔊 Navigating to previous chapter: $prevChapter with TTS');

    // Stop current TTS
    await _ttsService.stop();

    // Navigate to previous chapter with auto-start TTS
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EpubChapterPage(
          story: widget.story,
          chapterNumber: prevChapter,
          chapterTitle: _getChapterTitle(prevChapter),
          autoStartTTS: true, // Auto-start TTS in new chapter
        ),
      ),
    );

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển sang chương $prevChapter'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Navigate to next chapter and continue TTS
  void _navigateToNextChapterWithTTS() async {
    final nextChapter = _getNextChapterNumber();
    if (nextChapter == null) {
      print('Không có chương tiếp theo');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ở chương cuối cùng'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('🔊 Navigating to next chapter: $nextChapter with TTS');

    // Stop current TTS
    await _ttsService.stop();

    // Navigate to next chapter with auto-start TTS
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EpubChapterPage(
          story: widget.story,
          chapterNumber: nextChapter,
          chapterTitle: _getChapterTitle(nextChapter),
          autoStartTTS: true, // Auto-start TTS in new chapter
        ),
      ),
    );

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chuyển sang chương $nextChapter'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Update TTS highlighting position
  void _updateTTSHighlighting(int paragraphIndex) {
    print('🔊 _updateTTSHighlighting called with index: $paragraphIndex');

    if (paragraphIndex < 0 || paragraphIndex >= _ttsParagraphs.length) {
      print('Chỉ số đoạn văn không hợp lệ: $paragraphIndex');
      setState(() {
        _ttsHighlightStart = null;
        _ttsHighlightEnd = null;
      });
      return;
    }

    // Check if we have position mapping for this paragraph
    if (paragraphIndex >= _ttsParagraphPositions.length) {
      print('Không có mapping vị trí cho chỉ số đoạn văn: $paragraphIndex');
      setState(() {
        _ttsHighlightStart = null;
        _ttsHighlightEnd = null;
      });
      return;
    }

    // Use the pre-calculated position mapping
    final positionMapping = _ttsParagraphPositions[paragraphIndex];
    final startIndex = positionMapping['start'] as int;
    final endIndex = positionMapping['end'] as int;
    final originalText = positionMapping['originalText'] as String;

    print('Sử dụng mapping vị trí: $startIndex-$endIndex');
    print(
        '🔊 Original text preview: "${originalText.length > 50 ? originalText.substring(0, 50) + "..." : originalText}"');

    // Validate the indices
    final content = _chapterData?['chapter']?['content'] ?? '';
    if (content.isEmpty) {
      print('Nội dung rỗng');
      setState(() {
        _ttsHighlightStart = null;
        _ttsHighlightEnd = null;
      });
      return;
    }

    // Ensure indices are within bounds
    final validStartIndex = startIndex.clamp(0, content.length).toInt();
    final validEndIndex =
        endIndex.clamp(validStartIndex, content.length).toInt();

    print('🔊 TTS highlight set: $validStartIndex-$validEndIndex');
    setState(() {
      _ttsHighlightStart = validStartIndex;
      _ttsHighlightEnd = validEndIndex;
    });

    // Auto-scroll to the highlighted position
    _autoScrollToTTSPosition(validStartIndex, validEndIndex);
  }

  // Helper method to map position from cleaned content back to original content
  int _mapCleanedPositionToOriginal(
      String originalContent, String cleanedContent, int cleanedPosition) {
    if (cleanedPosition <= 0) return 0;
    if (cleanedPosition >= cleanedContent.length) return originalContent.length;

    // Count characters in original content up to the equivalent position
    int originalPos = 0;
    int cleanedPos = 0;

    while (
        originalPos < originalContent.length && cleanedPos < cleanedPosition) {
      String originalChar = originalContent[originalPos];

      // If it's whitespace, it might be compressed in cleaned version
      if (RegExp(r'\s').hasMatch(originalChar)) {
        // Skip consecutive whitespace in original
        while (originalPos < originalContent.length &&
            RegExp(r'\s').hasMatch(originalContent[originalPos])) {
          originalPos++;
        }
        // This corresponds to one space in cleaned version
        if (cleanedPos < cleanedContent.length &&
            cleanedContent[cleanedPos] == ' ') {
          cleanedPos++;
        }
      } else {
        // Regular character - should match
        originalPos++;
        cleanedPos++;
      }
    }

    return originalPos.clamp(0, originalContent.length);
  }

  // Helper method to find reasonable end position for paragraph
  int _findParagraphEndPosition(
      String content, int startIndex, String targetParagraph) {
    // Try to find a reasonable end position based on content structure
    int estimatedLength = targetParagraph.length;
    int searchEnd =
        (startIndex + estimatedLength * 1.5).clamp(0, content.length).toInt();

    // Look for natural break points (sentence endings, line breaks)
    List<String> breakPoints = ['. ', '.\n', '! ', '!\n', '? ', '?\n', '\n\n'];

    int bestEndPos = startIndex + estimatedLength;

    for (String breakPoint in breakPoints) {
      int breakPos = content.indexOf(
          breakPoint, startIndex + (estimatedLength * 0.7).toInt());
      if (breakPos != -1 && breakPos <= searchEnd) {
        bestEndPos = breakPos + breakPoint.length;
        break;
      }
    }

    return bestEndPos.clamp(startIndex + 1, content.length);
  }

  // Auto-scroll to TTS position
  void _autoScrollToTTSPosition(int startIndex, int endIndex) {
    if (!_ttsAutoScrollEnabled) {
      print('🔊 TTS Auto-scroll disabled');
      return;
    }

    print('🔊 _autoScrollToTTSPosition called: $startIndex-$endIndex');

    if (_isHorizontalReading) {
      // For horizontal reading, navigate to the correct page
      _navigateToTTSPositionInHorizontalMode(startIndex, endIndex);
    } else {
      // For vertical reading, scroll to position
      _scrollToTTSPositionInVerticalMode(startIndex, endIndex);
    }
  }

  // Navigate to TTS position in horizontal mode
  void _navigateToTTSPositionInHorizontalMode(int startIndex, int endIndex) {
    final chapter = _chapterData?['chapter'];
    final fullContent = chapter?['content'] ?? '';

    print('Điều hướng TTS ngang: $startIndex-$endIndex');
    print('Số trang: ${_pages.length}');

    if (_pages.isEmpty || fullContent.isEmpty) {
      return;
    }

    // Find which page contains the TTS position
    int targetPage = -1;
    int cumulativeIndex = 0;

    for (int i = 0; i < _pages.length; i++) {
      final pageContent = _pages[i];
      final pageStartIndex = cumulativeIndex;
      final pageEndIndex = cumulativeIndex + pageContent.length;

      print('Trang $i: phạm vi $pageStartIndex-$pageEndIndex');

      // Check if TTS position falls within this page
      if (startIndex >= pageStartIndex && startIndex < pageEndIndex) {
        targetPage = i;
        print('🔊 TTS found on page $i');
        break;
      }

      cumulativeIndex = pageEndIndex;
      if (i < _pages.length - 1) {
        cumulativeIndex += 1; // Account for spaces between pages
      }
    }

    if (targetPage >= 0 && targetPage != _currentPageIndex) {
      print('🔊 Auto-navigating to page $targetPage for TTS');

      // Update current page index
      setState(() {
        _currentPageIndex = targetPage;
      });

      // Animate to the target page
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Scroll to TTS position in vertical mode
  void _scrollToTTSPositionInVerticalMode(int startIndex, int endIndex) {
    if (!_scrollController.hasClients) {
      print('🔊 ScrollController not ready for TTS scroll');
      return;
    }

    final content = _chapterData?['chapter']?['content'] ?? '';
    if (content.isEmpty) {
      return;
    }

    // Calculate scroll position
    final scrollRatio = startIndex / content.length;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // Calculate target offset - aim to put TTS content at the top of screen
    var targetOffset = scrollRatio * maxScrollExtent;

    // Adjust to put the content at the top of screen
    final viewportHeight = _scrollController.position.viewportDimension;
    // Add offset to scroll more and bring content to the top (30% of viewport height)
    targetOffset =
        (targetOffset + viewportHeight * 0.3).clamp(0.0, maxScrollExtent);

    print(
        '🔊 TTS Auto-scroll (TOP): ratio=$scrollRatio, target=$targetOffset, max=$maxScrollExtent, viewport=$viewportHeight');

    // Smooth scroll to position
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  // Build bottom action button widget
  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    String? badge,
    String? tooltip,
  }) {
    Widget buttonWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.green : _textColor,
              size: 24,
            ),
            // Badge for notifications (like bookmark count)
            if (badge != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green : _textColor.withOpacity(0.7),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: buttonWidget,
      ),
    );

    // Add tooltip if provided
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}
