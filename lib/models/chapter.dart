class Chapter {
  final String id;
  final String title;
  final String name;
  final String apiData;
  final String fileName;
  final String serverName;
  List<String>? images;

  Chapter({
    required this.id,
    required this.title,
    required this.name,
    required this.apiData,
    required this.fileName,
    this.serverName = '',
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
      id: json['id'] ?? '',
      title: json['chapter_title'] ?? '',
      name: cleanChapterName(json['chapter_name'] ?? ''),
      apiData: json['chapter_api_data'] ?? '',
      fileName: json['filename'] ?? '',
      serverName: serverName,
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
}
