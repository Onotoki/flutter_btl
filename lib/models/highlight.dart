class Highlight {
  final String id;
  final String text;
  final String chapterTitle;
  final int chapterNumber;
  final String storySlug;
  final int startIndex;
  final int endIndex;
  final String color;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.text,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.storySlug,
    required this.startIndex,
    required this.endIndex,
    required this.color,
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
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'],
      text: json['text'],
      chapterTitle: json['chapterTitle'],
      chapterNumber: json['chapterNumber'],
      storySlug: json['storySlug'],
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      color: json['color'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
