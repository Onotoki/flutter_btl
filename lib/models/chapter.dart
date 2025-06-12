class Chapter {
  final String id;
  final String title;
  final String name;
  final String apiData;
  final String fileName;
  final String serverName;
  final String content;
  final int order;
  final bool isTextContent; // Đánh dấu đây là chapter chữ
  List<String>? images;

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

  factory Chapter.fromJson(Map<String, dynamic> json,
      {String serverName = ''}) {
    // In ra cấu trúc JSON để debug
    print('Parsing Chapter from JSON: ${json.keys.toList()}');

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

  // Tạo Chapter từ cấu trúc server_data
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

  // Tạo danh sách Chapter từ cấu trúc chapters trong truyện
  static List<Chapter> fromStoryChapters(List<dynamic> chaptersData) {
    List<Chapter> allChapters = [];

    for (var serverInfo in chaptersData) {
      if (serverInfo is Map<String, dynamic>) {
        allChapters.addAll(Chapter.fromServerData(serverInfo));
      }
    }

    return allChapters;
  }

  // Tạo danh sách Chapter từ nội dung truyện chữ
  static List<Chapter> fromNovelChapters(List<dynamic> chaptersData) {
    List<Chapter> textChapters = [];
    int order = 0;

    print('=== Processing ${chaptersData.length} novel chapters ===');

    for (var serverInfo in chaptersData) {
      if (serverInfo is Map<String, dynamic>) {
        print('Server info: ${serverInfo.keys.toList()}');

        if (serverInfo.containsKey('server_data') &&
            serverInfo['server_data'] is List) {
          List<dynamic> serverData = serverInfo['server_data'];
          print('Found ${serverData.length} chapters in server_data');

          for (var chapterData in serverData) {
            if (chapterData is Map<String, dynamic>) {
              order++;

              // In ra cấu trúc dữ liệu để debug
              print('Chapter $order structure: ${chapterData.keys.toList()}');
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
                  print('  Found title from field "$field": $chapterTitle');
                  break;
                }
              }
              if (chapterTitle.isEmpty) {
                chapterTitle = 'Chương $order';
                print('  Using default title: $chapterTitle');
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
                        '  Found chapter_name from field "$field": $chapterName');
                    break;
                  } catch (e) {
                    print('  Error getting chapter name from "$field": $e');
                  }
                }
              }

              // Lấy API data
              String apiData = '';
              if (chapterData.containsKey('chapter_api_data')) {
                apiData = chapterData['chapter_api_data'].toString();
                print('  API data: $apiData');
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
              print(
                  '  Created chapter: ${chapter.title} (name: ${chapter.name})');
            }
          }
        }
      }
    }

    print('=== Total ${textChapters.length} chapters created ===');
    return textChapters;
  }

  // Helper function để tính min
  static int min(int a, int b) => a < b ? a : b;
}
