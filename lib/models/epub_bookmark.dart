class EpubBookmark {
  final String id;
  final String bookId;
  final String content;
  final int pageNumber;
  final String pageId;
  final String href;
  final String cfi;
  final String note;
  final DateTime createdAt;

  EpubBookmark({
    required this.id,
    required this.bookId,
    required this.content,
    required this.pageNumber,
    required this.pageId,
    required this.href,
    required this.cfi,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'content': content,
      'pageNumber': pageNumber,
      'pageId': pageId,
      'href': href,
      'cfi': cfi,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory EpubBookmark.fromJson(Map<String, dynamic> json) {
    return EpubBookmark(
      id: json['id'],
      bookId: json['bookId'],
      content: json['content'],
      pageNumber: json['pageNumber'],
      pageId: json['pageId'],
      href: json['href'],
      cfi: json['cfi'],
      note: json['note'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
