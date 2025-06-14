// Lớp mô hình dữ liệu đại diện cho một highlight (đánh dấu) trong truyện chữ
class Highlight {
  // Các thuộc tính của highlight
  final String id; // ID duy nhất của highlight
  final String text; // Văn bản được đánh dấu
  final String chapterTitle; // Tiêu đề chương chứa highlight
  final int chapterNumber; // Số thứ tự chương
  final String storySlug; // Slug của truyện chứa highlight
  final int startIndex; // Vị trí bắt đầu của highlight trong văn bản
  final int endIndex; // Vị trí kết thúc của highlight trong văn bản
  final String color; // Màu sắc của highlight
  final DateTime createdAt; // Thời gian tạo highlight

  // Constructor khởi tạo đối tượng Highlight
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

  // Chuyển đổi đối tượng Highlight thành Map để lưu trữ hoặc truyền dữ liệu
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

  // Factory method tạo Highlight từ dữ liệu JSON
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
