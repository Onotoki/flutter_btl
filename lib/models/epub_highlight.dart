class EpubHighlight {
  final String id;
  final String bookId;
  final String content;
  final int pageNumber;
  final String pageId;
  final String rangy;
  final String note;
  final String color;
  final DateTime createdAt;

  EpubHighlight({
    required this.id,
    required this.bookId,
    required this.content,
    required this.pageNumber,
    required this.pageId,
    required this.rangy,
    this.note = '',
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'content': content,
      'pageNumber': pageNumber,
      'pageId': pageId,
      'rangy': rangy,
      'note': note,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory EpubHighlight.fromJson(Map<String, dynamic> json) {
    return EpubHighlight(
      id: json['id'],
      bookId: json['bookId'],
      content: json['content'],
      pageNumber: json['pageNumber'],
      pageId: json['pageId'],
      rangy: json['rangy'],
      note: json['note'] ?? '',
      color: json['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
