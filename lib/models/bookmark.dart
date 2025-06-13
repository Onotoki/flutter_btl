class Bookmark {
  final String id;
  final String text;
  final String chapterTitle;
  final int chapterNumber;
  final String storySlug;
  final int startIndex;
  final int endIndex;
  final String note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.text,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.storySlug,
    required this.startIndex,
    required this.endIndex,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'chapterTitle': chapterTitle,
      'chapterNumber': chapterNumber,
      'storySlug': storySlug,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      text: json['text'],
      chapterTitle: json['chapterTitle'],
      chapterNumber: json['chapterNumber'],
      storySlug: json['storySlug'],
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      note: json['note'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
