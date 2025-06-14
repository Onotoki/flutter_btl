// Lớp mô hình dữ liệu đại diện cho một chương trong truyện
// Hỗ trợ cả truyện tranh (comic) và truyện chữ (novel)
class Chapter {
  // Các thuộc tính của chương
  final String id; // ID duy nhất của chương
  final String title; // Tiêu đề chương
  final String name; // Tên/số chương
  final String apiData; // Dữ liệu API để tải nội dung
  final String fileName; // Tên file chứa nội dung
  final String serverName; // Tên server chứa chương
  final String content; // Nội dung văn bản (dành cho truyện chữ)
  final int order; // Thứ tự chương
  final bool isTextContent; // Đánh dấu đây là chương chữ
  List<String>? images; // Danh sách hình ảnh (dành cho truyện tranh)

  // Constructor khởi tạo đối tượng Chapter
  Chapter({
    required this.id,
    required this.title,
    required this.name,
    required this.apiData,
    required this.fileName,
    this.serverName = '',
    this.content = '',
    this.order = 0,
    this.isTextContent = false,
    this.images,
  });

  // Factory method tạo Chapter từ dữ liệu JSON
  factory Chapter.fromJson(Map<String, dynamic> json,
      {String serverName = ''}) {
    // In ra cấu trúc JSON để gỡ lỗi
    print('Đang phân tích Chapter từ JSON: ${json.keys.toList()}');

    // Xử lý chapter_name để loại bỏ các ký tự không mong muốn
    String cleanChapterName(String name) {
      // Chỉ giữ lại số và dấu chấm, phù hợp cho định dạng số chương như "1.5"
      return name.trim();
    }

    return Chapter(
      id: json['id'] ?? json['server_chapter_id'] ?? '',
      title: json['chapter_title'] ?? '',
      name: cleanChapterName(json['chapter_name'] ?? ''),
      apiData: json['chapter_api_data'] ?? '',
      fileName: json['filename'] ?? '',
      serverName: serverName,
      content: '', // Chương comic thường không có content
      isTextContent: false, // Chương comic không phải text content
      order: 0, // Sẽ được đặt sau nếu cần
    );
  }

  // Tạo danh sách Chapter từ cấu trúc server_data
  static List<Chapter> fromServerData(Map<String, dynamic> serverInfo) {
    List<Chapter> chapters = [];
    String serverName = serverInfo['server_name'] ?? '';

    if (serverInfo.containsKey('server_data') &&
        serverInfo['server_data'] is List) {
      List<dynamic> serverData = serverInfo['server_data'];
      for (var chapterData in serverData) {
        if (chapterData is Map<String, dynamic>) {
          Chapter chapter =
              Chapter.fromJson(chapterData, serverName: serverName);
          chapters.add(chapter);
        }
      }
    }

    return chapters;
  }

  // Tạo danh sách Chapter từ cấu trúc chapters trong truyện tranh
  static List<Chapter> fromStoryChapters(List<dynamic> chaptersData) {
    List<Chapter> allChapters = [];

    for (var serverInfo in chaptersData) {
      if (serverInfo is Map<String, dynamic>) {
        allChapters.addAll(Chapter.fromServerData(serverInfo));
      }
    }

    return allChapters;
  }

  // Tạo danh sách Chapter từ nội dung truyện chữ (novel)
  static List<Chapter> fromNovelChapters(List<dynamic> chaptersData) {
    List<Chapter> textChapters = [];
    int order = 0;

    print('=== Đang xử lý ${chaptersData.length} chương truyện chữ ===');

    for (var serverInfo in chaptersData) {
      if (serverInfo is Map<String, dynamic>) {
        print('Thông tin server: ${serverInfo.keys.toList()}');

        if (serverInfo.containsKey('server_data') &&
            serverInfo['server_data'] is List) {
          List<dynamic> serverData = serverInfo['server_data'];
          print('Tìm thấy ${serverData.length} chương trong server_data');

          for (var chapterData in serverData) {
            if (chapterData is Map<String, dynamic>) {
              order++;

              // In ra cấu trúc dữ liệu để gỡ lỗi
              print('Cấu trúc chương $order: ${chapterData.keys.toList()}');
              print('  chapter_name: ${chapterData['chapter_name']}');
              print('  chapter_title: ${chapterData['chapter_title']}');
              print('  filename: ${chapterData['filename']}');

              // Lấy tiêu đề chương - các tên field có thể có
              String chapterTitle = '';
              for (var field in [
                'chapter_title',
                'chapter_name',
                'title',
                'name'
              ]) {
                if (chapterData.containsKey(field) &&
                    chapterData[field] != null &&
                    chapterData[field].toString().isNotEmpty) {
                  chapterTitle = chapterData[field].toString();
                  print('  Tìm thấy tiêu đề từ trường "$field": $chapterTitle');
                  break;
                }
              }
              if (chapterTitle.isEmpty) {
                chapterTitle = 'Chương $order';
                print('  Sử dụng tiêu đề mặc định: $chapterTitle');
              }

              // Lấy số thứ tự chương - các tên field có thể có
              String chapterName = order.toString();
              for (var field in [
                'chapter_name',
                'chapter_number',
                'order',
                'index',
                'chapter_index'
              ]) {
                if (chapterData.containsKey(field) &&
                    chapterData[field] != null) {
                  try {
                    chapterName = chapterData[field].toString();
                    print(
                        '  Tìm thấy tên chương từ trường "$field": $chapterName');
                    break;
                  } catch (e) {
                    print('  Lỗi khi lấy tên chương từ "$field": $e');
                  }
                }
              }

              // Lấy dữ liệu API
              String apiData = '';
              if (chapterData.containsKey('chapter_api_data')) {
                apiData = chapterData['chapter_api_data'].toString();
                print('  Dữ liệu API: $apiData');
              }

              final chapter = Chapter(
                id: 'novel_chapter_${order}',
                title: chapterTitle,
                name: chapterName,
                apiData: apiData,
                fileName: chapterData['filename']?.toString() ?? '',
                isTextContent: true,
              );

              textChapters.add(chapter);
              print('  Đã tạo chương: ${chapter.title} (tên: ${chapter.name})');
            }
          }
        }
      }
    }

    print('=== Tổng cộng đã tạo ${textChapters.length} chương ===');
    return textChapters;
  }

  // Hàm hỗ trợ để tính giá trị nhỏ nhất
  static int min(int a, int b) => a < b ? a : b;
}
