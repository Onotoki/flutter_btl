import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

/**
 * 🔊 SERVICE TEXT-TO-SPEECH (TTS) - DỊCH VỤ CHUYỂN VĂN BẢN THÀNH GIỌNG NÓI
 * 
 * Dịch vụ này là trái tim của tính năng "Nghe truyện" trong ứng dụng,
 * chịu trách nhiệm xử lý tất cả các chức năng liên quan đến Text-to-Speech:
 * 
 * 🎯 CHỨC NĂNG CHÍNH:
 * ✅ Khởi tạo và cấu hình TTS engine
 * ✅ Quản lý việc đọc văn bản theo từng đoạn thông minh
 * ✅ Điều khiển phát/tạm dừng/dừng đọc với UX mượt mà
 * ✅ Xử lý lỗi TTS và tự động khôi phục
 * ✅ Hỗ trợ đa ngôn ngữ (ưu tiên tiếng Việt)
 * ✅ Làm sạch văn bản để tối ưu cho việc đọc
 * ✅ Tự động chia đoạn dài thành đoạn ngắn phù hợp
 * ✅ Callback system để đồng bộ với UI
 * 
 * 🔧 KIẾN TRÚC:
 * - Sử dụng Singleton pattern để đảm bảo consistency
 * - Tích hợp flutter_tts plugin cho cross-platform support
 * - Error handling robust để xử lý các trường hợp edge
 * - Memory management tối ưu
 */
class TTSService {
  // SINGLETON PATTERN - Đảm bảo chỉ có một instance duy nhất của TTSService
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  // ENGINE TTS CHÍNH - Sử dụng flutter_tts plugin
  final FlutterTts _tts = FlutterTts();

  // TRẠNG THÁI QUẢN LÝ TTS
  bool _isInitialized = false; // TTS đã được khởi tạo chưa
  bool _isPlaying = false; // Đang phát âm thanh
  bool _isPaused = false; // Đang tạm dừng

  // CÀI ĐẶT TTS - Có thể điều chỉnh bởi người dùng
  double _speechRate = 0.5; // Tốc độ đọc (0.0 - 1.0): 0.5 = tốc độ trung bình
  double _pitch = 1.0; // Cao độ giọng nói (0.5 - 2.0): 1.0 = bình thường
  double _volume = 0.8; // Âm lượng (0.0 - 1.0): 0.8 = khá to
  String _language = 'vi-VN'; // Ngôn ngữ mặc định: Tiếng Việt

  // QUẢN LÝ NỘI DUNG ĐỌC
  List<String> _paragraphs = []; // Danh sách các đoạn văn đã được chia nhỏ
  int _currentParagraphIndex =
      -1; // Chỉ số đoạn đang được đọc (-1 = chưa bắt đầu)

  // CALLBACK FUNCTIONS - Để thông báo trạng thái cho UI
  Function(int)? _onParagraphChanged; // Khi chuyển sang đoạn mới
  Function()? _onCompleted; // Khi đọc xong tất cả
  Function()? _onStarted; // Khi bắt đầu đọc
  Function()? _onPaused; // Khi tạm dừng
  Function()? _onContinued; // Khi tiếp tục đọc
  Function(String)? _onError; // Khi có lỗi xảy ra

  // GETTERS - Cho phép các class khác truy cập trạng thái
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get language => _language;
  List<String> get paragraphs => _paragraphs;
  int get currentParagraphIndex => _currentParagraphIndex;

  /**
   * KHỞI TẠO TTS ENGINE
   * 
   * Đây là bước quan trọng nhất, cần thực hiện trước khi sử dụng bất kỳ chức năng TTS nào.
   * Quá trình khởi tạo bao gồm:
   * 1. Kiểm tra các ngôn ngữ có sẵn trên thiết bị
   * 2. Thiết lập ngôn ngữ phù hợp (ưu tiên tiếng Việt)
   * 3. Cấu hình các thông số TTS (tốc độ, cao độ, âm lượng)
   * 4. Đăng ký các callback handlers để xử lý sự kiện
   */
  Future<void> initialize() async {
    if (_isInitialized) {
      print('TTS already initialized');
      return;
    }

    try {
      print('Initializing TTS Service...');

      // BƯỚC 1: KIỂM TRA CÁC NGÔN NGỮ CÓ SẴN TRÊN THIẾT BỊ
      // Lấy danh sách ngôn ngữ được hỗ trợ từ TTS engine của hệ điều hành
      var availableLanguages = await _tts.getLanguages;
      print('Available languages: $availableLanguages');

      // BƯỚC 2: CHỌN NGÔN NGỮ PHÙ HỢP
      // Ưu tiên sử dụng tiếng Việt, nếu không có thì dùng tiếng Anh
      String languageToUse = _language;
      if (availableLanguages != null && availableLanguages.isNotEmpty) {
        if (!availableLanguages.contains(_language)) {
          print('Language $_language not available, checking alternatives...');
          // Fallback theo thứ tự ưu tiên: en-US -> en-GB -> ngôn ngữ đầu tiên có sẵn
          if (availableLanguages.contains('en-US')) {
            languageToUse = 'en-US';
            print('Falling back to English (US)');
          } else if (availableLanguages.contains('en-GB')) {
            languageToUse = 'en-GB';
            print('Falling back to English (UK)');
          } else {
            languageToUse = availableLanguages[0];
            print('Using first available language: $languageToUse');
          }
        }
      }

      // BƯỚC 3: CẤU HÌNH TTS ENGINE
      // Thiết lập ngôn ngữ cho TTS engine
      var result = await _tts.setLanguage(languageToUse);
      print('Set language result: $result');

      // BƯỚC 4: KIỂM TRA NGÔN NGỮ ĐÃ ĐƯỢC CÀI ĐẶT (CHỈ CHO ANDROID)
      // Đảm bảo ngôn ngữ được cài đặt đầy đủ trên thiết bị
      try {
        var isInstalled = await _tts.isLanguageInstalled(languageToUse);
        print('Language $languageToUse installed: $isInstalled');
        if (isInstalled == false) {
          print(
              'Warning: Language $languageToUse may not be properly installed');
        }
      } catch (e) {
        print('Could not check language installation: $e');
      }

      // BƯỚC 5: THIẾT LẬP CÁC THÔNG SỐ TTS
      // Cấu hình tốc độ đọc (speechRate)
      result = await _tts.setSpeechRate(_speechRate);
      print('Set speech rate result: $result');

      // Cấu hình cao độ giọng nói (pitch)
      result = await _tts.setPitch(_pitch);
      print('Set pitch result: $result');

      // Cấu hình âm lượng (volume)
      result = await _tts.setVolume(_volume);
      print('Set volume result: $result');

      // BƯỚC 6: ĐĂNG KÝ CÁC CALLBACK HANDLERS
      // Handler khi TTS hoàn thành đọc một đoạn
      _tts.setCompletionHandler(() {
        print('TTS Completion handler called');
        _onParagraphCompleted(); // Tự động chuyển sang đoạn tiếp theo
      });

      // Handler khi TTS bắt đầu đọc
      _tts.setStartHandler(() {
        print('TTS Start handler called');
        _isPlaying = true;
        _isPaused = false;
        _onStarted?.call(); // Thông báo cho UI
      });

      // Handler khi TTS bị tạm dừng
      _tts.setPauseHandler(() {
        print('TTS Pause handler called');
        _isPaused = true;
        _onPaused?.call(); // Thông báo cho UI
      });

      // Handler khi TTS tiếp tục đọc sau khi tạm dừng
      _tts.setContinueHandler(() {
        print('TTS Continue handler called');
        _isPaused = false;
        _onContinued?.call(); // Thông báo cho UI
      });

      // Handler xử lý lỗi TTS - Rất quan trọng để xử lý các lỗi synthesis
      _tts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _handleTTSError(msg); // Xử lý lỗi và cố gắng khôi phục
      });

      // HOÀN THÀNH KHỞI TẠO
      _isInitialized = true;
      _language = languageToUse; // Cập nhật ngôn ngữ hiện tại
      print(
          'TTS Service initialized successfully with language: $languageToUse');
    } catch (e) {
      print('Error initializing TTS: $e');
      _isInitialized = false;
      throw e; // Re-throw để caller có thể xử lý
    }
  }

  /**
   * THIẾT LẬP NỘI DUNG CẦN ĐỌC
   * 
   * Phương thức này nhận văn bản đầu vào và xử lý để chuẩn bị cho TTS:
   * 1. Chia văn bản thành các đoạn nhỏ phù hợp
   * 2. Làm sạch văn bản để tránh lỗi synthesis
   * 3. Tối ưu hóa cho việc đọc lên
   * 
   * @param content - Văn bản gốc cần được đọc lên
   */
  void setContent(String content) {
    print('Setting TTS content...');

    // BƯỚC 1: CHIA VĂN BẢN THÀNH CÁC ĐOẠN
    // Đầu tiên thử chia theo dấu xuống dòng (đoạn văn tự nhiên)
    List<String> initialSplit = content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    print('Initial split: ${initialSplit.length} paragraphs');

    // BƯỚC 2: QUYẾT ĐỊNH PHƯƠNG PHÁP CHIA VĂN BẢN
    if (initialSplit.length > 1) {
      // Nếu có nhiều đoạn tự nhiên, sử dụng phương pháp chia theo đoạn
      _paragraphs = initialSplit
          .map((p) => _cleanTextForTTS(p)) // Làm sạch từng đoạn
          .where((p) => p.isNotEmpty) // Bỏ đoạn rỗng
          .toList();
    } else {
      // Nếu văn bản không có phân đoạn rõ ràng, chia thành các chunk nhỏ
      print('Content not well-separated, splitting into smaller chunks...');
      _paragraphs = _splitIntoReadableChunks(content);
    }

    // BƯỚC 3: RESET TRẠNG THÁI VÀ CHUẨN BỊ ĐỌC
    _currentParagraphIndex = -1; // Chưa bắt đầu đọc đoạn nào
    print('TTS content set: ${_paragraphs.length} paragraphs');

    // BƯỚC 4: DEBUG - IN RA VÀI ĐOẠN ĐẦU ĐỂ KIỂM TRA
    for (int i = 0; i < _paragraphs.length && i < 3; i++) {
      final displayText = _paragraphs[i].length > 50
          ? _paragraphs[i].substring(0, 50) + "..."
          : _paragraphs[i];
      print('Paragraph $i: "$displayText"');
    }
  }

  /**
   * CHIA VĂN BẢN THÀNH CÁC ĐOẠN ĐỌC ĐƯỢC
   * 
   * Khi văn bản không có phân đoạn tự nhiên, phương thức này sẽ chia thành các chunk
   * có kích thước phù hợp để TTS có thể đọc mượt mà và người dùng dễ theo dõi.
   * 
   * Chiến lược chia:
   * - Kích thước mục tiêu: 500 ký tự/chunk
   * - Kích thước tối đa: 800 ký tự/chunk
   * - Ưu tiên cắt ở cuối câu (. ! ?)
   * - Thứ hai là dấu phẩy, hai chấm
   * - Cuối cùng là khoảng trắng
   * 
   * @param content - Văn bản gốc cần chia
   * @return List<String> - Danh sách các đoạn đã chia
   */
  List<String> _splitIntoReadableChunks(String content) {
    List<String> chunks = [];

    // KÍCH THƯỚC CHUNK MONG MUỐN
    const int targetChunkSize = 500; // Kích thước lý tưởng cho mỗi chunk
    const int maxChunkSize = 800; // Kích thước tối đa cho phép

    String remainingContent = content.trim();

    // VÒNG LẶP CHIA VĂN BẢN
    while (remainingContent.isNotEmpty) {
      if (remainingContent.length <= targetChunkSize) {
        // Phần còn lại đủ nhỏ, thêm vào danh sách và kết thúc
        chunks.add(_cleanTextForTTS(remainingContent));
        break;
      }

      // TÌM ĐIỂM CẮT TỐI ƯU
      int breakPoint =
          _findBreakPoint(remainingContent, targetChunkSize, maxChunkSize);

      String chunk = remainingContent.substring(0, breakPoint).trim();
      if (chunk.isNotEmpty) {
        chunks.add(_cleanTextForTTS(chunk));
      }

      // CẬP NHẬT VĂN BẢN CÒN LẠI
      remainingContent = remainingContent.substring(breakPoint).trim();
    }

    return chunks.where((chunk) => chunk.isNotEmpty).toList();
  }

  /**
   * TÌM ĐIỂM CẮT TỐI ƯU CHO VIỆC CHIA VĂN BẢN
   * 
   * Thuật toán tìm điểm cắt theo thứ tự ưu tiên:
   * 1. Cuối câu (. ! ?) - Tự nhiên nhất cho việc đọc
   * 2. Dấu phẩy, hai chấm (: ; ,) - Tạm dừng tự nhiên
   * 3. Khoảng trắng giữa các từ - Không cắt giữa từ
   * 4. Cắt cứng nếu không tìm được điểm phù hợp
   * 
   * @param text - Văn bản cần tìm điểm cắt
   * @param targetSize - Kích thước mục tiêu
   * @param maxSize - Kích thước tối đa cho phép
   * @return int - Vị trí cắt tối ưu
   */
  int _findBreakPoint(String text, int targetSize, int maxSize) {
    if (text.length <= targetSize) return text.length;

    // ƯU TIÊN 1: TÌM CUỐI CÂU GẦN VỊ TRÍ MỤC TIÊU
    // Các ký tự kết thúc câu tự nhiên cho việc đọc
    List<String> sentenceEnders = ['. ', '! ', '? ', '.\n', '!\n', '?\n'];

    for (String ender in sentenceEnders) {
      int pos = text.lastIndexOf(ender, targetSize);
      if (pos > targetSize * 0.7) {
        // Phải ít nhất 70% kích thước mục tiêu để tránh chunk quá nhỏ
        return pos + ender.length;
      }
    }

    // ƯU TIÊN 2: TÌM CÁC DẤU CHẤM CÂU KHÁC
    // Các điểm tạm dừng tự nhiên trong câu
    List<String> otherBreaks = ['; ', ': ', ', ', '.\t', '!\t', '?\t'];

    for (String breaker in otherBreaks) {
      int pos = text.lastIndexOf(breaker, targetSize);
      if (pos > targetSize * 0.8) {
        // Yêu cầu 80% kích thước mục tiêu vì ít tự nhiên hơn cuối câu
        return pos + breaker.length;
      }
    }

    // ƯU TIÊN 3: TÌM KHOẢNG TRẮNG (RANH GIỚI TỪ)
    // Tránh cắt giữa từ
    int pos = text.lastIndexOf(' ', targetSize);
    if (pos > targetSize * 0.8) {
      return pos + 1;
    }

    // PHƯƠNG ÁN CUỐI CÙNG: CẮT CỨNG
    // Nếu không tìm được điểm phù hợp, sử dụng kích thước tối đa hoặc cắt cứng
    return text.length < maxSize ? text.length : targetSize;
  }

  /**
   * LÀM SẠCH VĂN BẢN CHO TTS
   * 
   * Đây là bước rất quan trọng để tránh lỗi synthesis trong TTS.
   * Các vấn đề thường gặp:
   * - Ký tự đặc biệt gây lỗi TTS engine
   * - Khoảng trắng dư thừa
   * - Dấu chấm câu bị lặp lại
   * - Văn bản quá dài
   * 
   * LƯU Ý: Giữ nguyên ký tự tiếng Việt (á, à, ả, ã, ạ, ă, ắ, ằ, ẳ, ẵ, ặ, â, ấ, ầ, ẩ, ẫ, ậ, ...)
   * 
   * @param text - Văn bản gốc cần làm sạch
   * @return String - Văn bản đã được làm sạch và tối ưu cho TTS
   */
  String _cleanTextForTTS(String text) {
    if (text.isEmpty) return text;

    // DEBUG: In ra một phần văn bản gốc để kiểm tra
    final originalPreview =
        text.length > 100 ? text.substring(0, 100) + "..." : text;
    print('🔊 Original text preview: "$originalPreview"');

    // BƯỚC 1: LÀM SẠCH CÁC KÝ TỰ VÀ KHOẢNG TRẮNG
    String cleaned = text
        // Loại bỏ khoảng trắng dư thừa (nhiều space, tab, newline thành 1 space)
        .replaceAll(RegExp(r'\s+'), ' ')
        // Chỉ loại bỏ ký tự thực sự có vấn đề, KHÔNG loại bỏ ký tự tiếng Việt
        // Giữ lại: chữ cái (bao gồm tiếng Việt), số, khoảng trắng, dấu chấm câu cơ bản
        .replaceAll(
            RegExp(r'[^\p{L}\p{N}\s\.,!?;:\-\(\)\[\]""' '""…]', unicode: true),
            '')
        // BƯỚC 2: CHUẨN HÓA DẤU CHẤM CÂU LẶP LẠI
        // Thay thế nhiều dấu chấm liên tiếp bằng dấu ba chấm
        .replaceAll(RegExp(r'[.]{2,}'), '...')
        // Thay thế nhiều dấu chấm than bằng một dấu
        .replaceAll(RegExp(r'[!]{2,}'), '!')
        // Thay thế nhiều dấu chấm hỏi bằng một dấu
        .replaceAll(RegExp(r'[?]{2,}'), '?')
        .trim();

    // BƯỚC 3: SỬA KHOẢNG CÁCH XUNG QUANH DẤU CHẤM CÂU
    // Đảm bảo có khoảng trắng sau dấu chấm câu để TTS tạm dừng phù hợp
    cleaned = cleaned.replaceAllMapped(
      RegExp(
          r'([.!?])([A-ZÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬĐÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴ])'),
      (match) {
        return '${match.group(1)} ${match.group(2)}';
      },
    );

    // BƯỚC 4: GIỚI HẠN ĐỘ DÀI VĂN BẢN (NẾU CẦN)
    // TTS có thể gặp vấn đề với văn bản quá dài
    if (cleaned.length > 1500) {
      // Tìm điểm cắt tốt gần vị trí 1200 ký tự
      int breakPoint = cleaned.lastIndexOf('.', 1200);
      if (breakPoint == -1) breakPoint = cleaned.lastIndexOf(' ', 1200);
      if (breakPoint == -1) breakPoint = 1200;
      cleaned = cleaned.substring(0, breakPoint);
    }

    // DEBUG: In ra văn bản đã làm sạch để so sánh
    final cleanedPreview =
        cleaned.length > 100 ? cleaned.substring(0, 100) + "..." : cleaned;
    print('🔊 Cleaned text preview: "$cleanedPreview"');

    // KIỂM TRA XEM VĂN BẢN CÓ BỊ THAY ĐỔI NHIỀU KHÔNG
    if (cleaned != text) {
      print('🔊 Text was modified during cleaning');
    }

    return cleaned;
  }

  /**
   * THIẾT LẬP CÁC CALLBACK FUNCTIONS
   * 
   * Đăng ký các hàm callback để UI có thể nhận thông báo về trạng thái TTS.
   * Điều này cho phép UI cập nhật giao diện theo thời gian thực.
   * 
   * @param onParagraphChanged - Được gọi khi chuyển sang đoạn mới (nhận index đoạn)
   * @param onCompleted - Được gọi khi đọc xong tất cả nội dung
   * @param onStarted - Được gọi khi bắt đầu đọc
   * @param onPaused - Được gọi khi tạm dừng đọc
   * @param onContinued - Được gọi khi tiếp tục đọc sau khi tạm dừng
   * @param onError - Được gọi khi có lỗi TTS (nhận thông báo lỗi)
   */
  void setCallbacks({
    Function(int)? onParagraphChanged,
    Function()? onCompleted,
    Function()? onStarted,
    Function()? onPaused,
    Function()? onContinued,
    Function(String)? onError,
  }) {
    print('Setting TTS callbacks');
    _onParagraphChanged = onParagraphChanged;
    _onCompleted = onCompleted;
    _onStarted = onStarted;
    _onPaused = onPaused;
    _onContinued = onContinued;
    _onError = onError;
  }

  /**
   * ĐỌC MỘT ĐOẠN CỤ THỂ
   * 
   * Phương thức chính để đọc một đoạn văn bất kỳ trong danh sách.
   * Bao gồm cơ chế retry để xử lý lỗi synthesis.
   * 
   * @param index - Chỉ số đoạn cần đọc (0-based)
   */
  Future<void> speakParagraph(int index) async {
    print('speakParagraph called with index: $index');

    if (!_isInitialized) {
      print('TTS not initialized, initializing now...');
      await initialize();
    }

    if (index < 0 || index >= _paragraphs.length) {
      print('Invalid paragraph index: $index (total: ${_paragraphs.length})');
      return;
    }

    try {
      print('Stopping current TTS...');
      await _tts.stop();

      _currentParagraphIndex = index;
      final displayText = _paragraphs[index].length > 50
          ? _paragraphs[index].substring(0, 50) + "..."
          : _paragraphs[index];
      print('Speaking paragraph $index: "$displayText"');

      // Try speaking with retry mechanism
      bool success = await _retrySpeaking(_paragraphs[index]);
      if (success) {
        _onParagraphChanged?.call(index);
      } else {
        print('Failed to speak paragraph after retries');
        // Try with cleaned text as fallback
        String cleanedText = _cleanTextForTTS(_paragraphs[index]);
        if (cleanedText != _paragraphs[index]) {
          print('Trying with further cleaned text...');
          success = await _retrySpeaking(cleanedText);
          if (success) {
            _onParagraphChanged?.call(index);
          }
        }
      }
    } catch (e) {
      print('Error speaking paragraph: $e');
    }
  }

  // Speak text directly
  Future<void> speakText(String text) async {
    final displayText = text.length > 50 ? text.substring(0, 50) + "..." : text;
    print('speakText called with: "$displayText"');

    if (!_isInitialized) {
      print('TTS not initialized, initializing now...');
      await initialize();
    }

    if (text.trim().isEmpty) {
      print('Text is empty, cannot speak');
      return;
    }

    try {
      print('Stopping current TTS...');
      await _tts.stop();

      print('Speaking text...');
      var result = await _tts.speak(text);
      print('TTS speak result: $result');
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  // Start reading from beginning or current position
  Future<void> play() async {
    print('play() called');

    // KIỂM TRA NỘI DUNG
    if (_paragraphs.isEmpty) {
      print('No paragraphs to read');
      return; // Không có nội dung để đọc
    }

    // XỬ LÝ CÁC TRƯỜNG HỢP KHÁC NHAU
    if (_currentParagraphIndex < 0) {
      // TRƯỜNG HỢP 1: BẮT ĐẦU TỪ ĐẦU
      print('Starting from paragraph 0');
      await speakParagraph(0);
    } else {
      if (_isPaused) {
        // TRƯỜNG HỢP 2: TIẾP TỤC SAU KHI PAUSE
        print('Resuming TTS...');
        await _tts.awaitSpeakCompletion(true);
      } else {
        // TRƯỜNG HỢP 3: TIẾP TỤC TỪ ĐOẠN HIỆN TẠI
        print('Continuing from paragraph $_currentParagraphIndex');
        await speakParagraph(_currentParagraphIndex);
      }
    }
  }

  /**
   * TẠM DỪNG TTS
   * 
   * Tạm dừng việc đọc hiện tại. Có thể tiếp tục bằng play() hoặc resume().
   */
  Future<void> pause() async {
    print('pause() called');
    try {
      var result = await _tts.pause();
      print('TTS pause result: $result');
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  /**
   * DỪNG HOÀN TOÀN TTS
   * 
   * Dừng việc đọc và reset tất cả trạng thái. 
   * Muốn đọc lại phải bắt đầu từ đầu.
   */
  Future<void> stop() async {
    print('stop() called');
    try {
      var result = await _tts.stop();
      print('TTS stop result: $result');

      // RESET TẤT CẢ TRẠNG THÁI
      _isPlaying = false;
      _isPaused = false;
      _currentParagraphIndex = -1; // Quay về trạng thái chưa bắt đầu
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  /**
   * CHUYỂN VỀ ĐOẠN TRƯỚC
   * 
   * Di chuyển về đoạn trước đó và bắt đầu đọc.
   */
  Future<void> previousParagraph() async {
    print('previousParagraph() called');
    if (_currentParagraphIndex > 0) {
      await speakParagraph(_currentParagraphIndex - 1);
    } else {
      print('Already at first paragraph'); // Đã ở đoạn đầu tiên
    }
  }

  /**
   * CHUYỂN ĐẾN ĐOẠN TIẾP THEO
   * 
   * Di chuyển đến đoạn tiếp theo và bắt đầu đọc.
   */
  Future<void> nextParagraph() async {
    print('nextParagraph() called');
    if (_currentParagraphIndex < _paragraphs.length - 1) {
      await speakParagraph(_currentParagraphIndex + 1);
    } else {
      print('Already at last paragraph'); // Đã ở đoạn cuối cùng
    }
  }

  /**
   * CẬP NHẬT TỐC ĐỘ ĐỌC
   * 
   * @param rate - Tốc độ đọc (0.0 - 1.0): 0.0 = rất chậm, 1.0 = rất nhanh
   */
  Future<void> setSpeechRate(double rate) async {
    print('setSpeechRate: $rate');
    _speechRate = rate;
    try {
      var result = await _tts.setSpeechRate(rate);
      print('Set speech rate result: $result');
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  /**
   * CẬP NHẬT CAO ĐỘ GIỌNG NÓI
   * 
   * @param pitch - Cao độ (0.5 - 2.0): 0.5 = thấp, 1.0 = bình thường, 2.0 = cao
   */
  Future<void> setPitch(double pitch) async {
    print('setPitch: $pitch');
    _pitch = pitch;
    try {
      var result = await _tts.setPitch(pitch);
      print('Set pitch result: $result');
    } catch (e) {
      print('Error setting pitch: $e');
    }
  }

  /**
   * CẬP NHẬT ÂM LƯỢNG
   * 
   * @param volume - Âm lượng (0.0 - 1.0): 0.0 = tắt tiếng, 1.0 = âm lượng tối đa
   */
  Future<void> setVolume(double volume) async {
    print('setVolume: $volume');
    _volume = volume;
    try {
      var result = await _tts.setVolume(volume);
      print('Set volume result: $result');
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /**
   * THAY ĐỔI NGÔN NGỮ TTS
   * 
   * @param language - Mã ngôn ngữ (ví dụ: 'vi-VN', 'en-US', 'ja-JP')
   */
  Future<void> setLanguage(String language) async {
    print('setLanguage: $language');
    _language = language;
    try {
      var result = await _tts.setLanguage(language);
      print('Set language result: $result');
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      print('🔊 Getting available languages from TTS engine...');
      var languages = await _tts.getLanguages;
      print('🔊 Raw languages from TTS engine: $languages');

      // ĐẢM BẢO DANH SÁCH NGÔN NGỮ HỢP LỆ
      if (languages == null || languages.isEmpty) {
        print(
            '🔊 TTS engine returned null/empty languages, using fallback list');
        // DANH SÁCH NGÔN NGỮ DỰ PHÒNG khi TTS engine không trả về đúng
        return [
          'vi-VN', // Tiếng Việt
          'en-US', // Tiếng Anh (Mỹ)
          'en-GB', // Tiếng Anh (Anh)
          'zh-CN', // Tiếng Trung (Giản thể)
          'zh-TW', // Tiếng Trung (Phồn thể)
          'ja-JP', // Tiếng Nhật
          'ko-KR', // Tiếng Hàn
          'fr-FR', // Tiếng Pháp
          'de-DE', // Tiếng Đức
          'es-ES', // Tiếng Tây Ban Nha
          'it-IT', // Tiếng Ý
          'pt-BR', // Tiếng Bồ Đào Nha (Brazil)
          'ru-RU', // Tiếng Nga
          'th-TH', // Tiếng Thái
          'id-ID', // Tiếng Indonesia
          'ms-MY' // Tiếng Malaysia
        ];
      }

      // CHUYỂN ĐỔI SANG List<String> NẾU CẦN
      List<String> languageList =
          languages.map((lang) => lang.toString()).toList();
      print('🔊 Processed language list: $languageList');
      return languageList;
    } catch (e) {
      print('🔊 Error getting languages: $e');
      print('🔊 Returning fallback language list');
      // TRẢ VỀ DANH SÁCH DỰ PHÒNG KHI CÓ LỖI
      return [
        'vi-VN',
        'en-US',
        'en-GB',
        'zh-CN',
        'zh-TW',
        'ja-JP',
        'ko-KR',
        'fr-FR',
        'de-DE',
        'es-ES',
        'it-IT',
        'pt-BR',
        'ru-RU',
        'th-TH',
        'id-ID',
        'ms-MY'
      ];
    }
  }

  /**
   * KIỂM TRA NGÔN NGỮ ĐÃ CÀI ĐẶT (CHỈ CHO ANDROID)
   * 
   * Kiểm tra xem một ngôn ngữ cụ thể đã được cài đặt đầy đủ trên thiết bị chưa.
   * Chỉ hoạt động trên Android, iOS sẽ trả về false.
   * 
   * @param language - Mã ngôn ngữ cần kiểm tra
   * @return bool - true nếu đã cài đặt, false nếu chưa hoặc có lỗi
   */
  Future<bool> isLanguageInstalled(String language) async {
    try {
      var result = await _tts.isLanguageInstalled(language);
      print('Language $language installed: $result');
      return result ?? false;
    } catch (e) {
      print('Error checking language installation: $e');
      return false; // Giả sử chưa cài đặt nếu có lỗi
    }
  }

  /**
   * XỬ LÝ KHI HOÀN THÀNH MỘT ĐOẠN
   * 
   * Callback nội bộ được gọi khi TTS hoàn thành đọc một đoạn.
   * Tự động chuyển sang đoạn tiếp theo hoặc kết thúc nếu đã đọc hết.
   */
  void _onParagraphCompleted() {
    print('_onParagraphCompleted called');
    if (_currentParagraphIndex < _paragraphs.length - 1) {
      // CÒN ĐOẠN TIẾP THEO - TIẾP TỤC ĐỌC
      print('Moving to next paragraph: ${_currentParagraphIndex + 1}');
      speakParagraph(_currentParagraphIndex + 1);
    } else {
      // ĐÃ ĐỌC HẾT TẤT CẢ ĐOẠN
      print('All paragraphs completed');
      _isPlaying = false;
      _isPaused = false;
      _currentParagraphIndex = -1;
      _onCompleted?.call(); // Thông báo cho UI
    }
  }

  /**
   * XỬ LÝ LỖI TTS
   * 
   * Phân tích và xử lý các loại lỗi TTS khác nhau.
   * Cố gắng khôi phục hoặc đưa ra giải pháp thay thế.
   * 
   * @param errorMessage - Thông báo lỗi từ TTS engine
   */
  void _handleTTSError(String errorMessage) {
    print('Handling TTS Error: $errorMessage');

    // PHÂN TÍCH MÃ LỖI VÀ XỬ LÝ TƯƠNG ỨNG
    if (errorMessage.contains('-8')) {
      print('TTS Error -8: Synthesis error detected');
      _handleSynthesisError(); // Lỗi tổng hợp âm thanh
    } else if (errorMessage.contains('-5')) {
      print('TTS Error -5: Language not supported');
      _handleLanguageError(); // Lỗi ngôn ngữ không hỗ trợ
    } else if (errorMessage.contains('-4')) {
      print('TTS Error -4: Invalid parameter');
      _handleInvalidParameterError(); // Lỗi tham số không hợp lệ
    } else {
      print('Unknown TTS error: $errorMessage');
    }

    // THÔNG BÁO LỖI CHO UI (NẾU CÓ CALLBACK)
    _onError?.call(errorMessage);
  }

  /**
   * XỬ LÝ LỖI SYNTHESIS (-8)
   * 
   * Lỗi tổng hợp âm thanh thường do văn bản có vấn đề hoặc TTS engine bị lỗi.
   * Thử khôi phục bằng cách chuyển ngôn ngữ hoặc reset engine.
   */
  void _handleSynthesisError() async {
    print('Attempting to recover from synthesis error...');

    try {
      // DỪNG TTS HIỆN TẠI
      await _tts.stop();

      // THỬ CHUYỂN SANG NGÔN NGỮ KHÁC NẾU ĐANG DÙNG TIẾNG VIỆT
      if (_language == 'vi-VN') {
        print('Switching from Vietnamese to English due to synthesis error');
        await setLanguage('en-US');
      }

      // RESET TRẠNG THÁI
      _isPlaying = false;
      _isPaused = false;
    } catch (e) {
      print('Failed to recover from synthesis error: $e');
    }
  }

  /**
   * XỬ LÝ LỖI NGÔN NGỮ (-5)
   * 
   * Ngôn ngữ không được hỗ trợ trên thiết bị.
   * Thử chuyển sang tiếng Anh làm ngôn ngữ dự phòng.
   */
  void _handleLanguageError() async {
    print('Language not supported, trying fallback...');

    try {
      // CHUYỂN SANG TIẾNG ANH LÀM DỰ PHÒNG
      await setLanguage('en-US');
    } catch (e) {
      print('Failed to set fallback language: $e');
    }
  }

  /**
   * XỬ LÝ LỖI THAM SỐ KHÔNG HỢP LỆ (-4)
   * 
   * Các tham số TTS (tốc độ, cao độ, âm lượng) không hợp lệ.
   * Reset về giá trị mặc định.
   */
  void _handleInvalidParameterError() async {
    print('Invalid parameter detected, resetting to defaults...');

    try {
      // RESET VỀ GIÁ TRỊ MẶC ĐỊNH
      await setSpeechRate(0.5); // Tốc độ trung bình
      await setPitch(1.0); // Cao độ bình thường
      await setVolume(0.8); // Âm lượng cao
    } catch (e) {
      print('Failed to reset parameters: $e');
    }
  }

  /**
   * THỬ ĐỌC VỚI CƠ CHẾ RETRY
   * 
   * Thử đọc văn bản với số lần thử lại giới hạn.
   * Hữu ích khi TTS engine tạm thời bị lỗi.
   * 
   * @param text - Văn bản cần đọc
   * @param maxRetries - Số lần thử tối đa (mặc định: 3)
   * @return bool - true nếu thành công, false nếu thất bại
   */
  Future<bool> _retrySpeaking(String text, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Attempt $attempt to speak text...');
        await _tts.stop();
        await Future.delayed(Duration(milliseconds: 500)); // Tạm dừng ngắn

        var result = await _tts.speak(text);
        print('Retry speak result: $result');
        return true; // Thành công
      } catch (e) {
        print('Retry attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          print('All retry attempts failed');
          return false; // Thất bại hoàn toàn
        }
        await Future.delayed(Duration(seconds: 1)); // Đợi trước khi thử lại
      }
    }
    return false;
  }

  /**
   * TIẾP TỤC ĐỌC SAU KHI TẠM DỪNG
   * 
   * Khôi phục việc đọc từ trạng thái tạm dừng.
   * Khác với play() ở chỗ này chỉ xử lý resume, không bắt đầu mới.
   */
  Future<void> resume() async {
    print('resume() called');
    try {
      if (_isPaused &&
          _currentParagraphIndex >= 0 &&
          _currentParagraphIndex < _paragraphs.length) {
        print(
            'Resuming by restarting current paragraph: $_currentParagraphIndex');
        _isPaused = false;
        await speakParagraph(_currentParagraphIndex); // Đọc lại đoạn hiện tại
      } else {
        print('Cannot resume - invalid state or paragraph index');
        _isPaused = false;
        _isPlaying = false;
      }
    } catch (e) {
      print('Error resuming TTS: $e');
      _isPaused = false;
      _isPlaying = false;
    }
  }

  /**
   * GIẢI PHÓNG TÀI NGUYÊN
   * 
   * Dọn dẹp và giải phóng tất cả tài nguyên khi không sử dụng TTS nữa.
   * Cần gọi khi dispose widget hoặc thoát ứng dụng.
   */
  void dispose() {
    print('Disposing TTS Service');
    _tts.stop(); // Dừng TTS
    _isInitialized = false; // Đánh dấu chưa khởi tạo
    _isPlaying = false; // Reset trạng thái
    _isPaused = false;
    _currentParagraphIndex = -1; // Reset vị trí
    _paragraphs.clear(); // Xóa nội dung
  }
}
