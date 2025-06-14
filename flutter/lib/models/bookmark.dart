// Lớp đại diện cho một đánh dấu trong truyện
class Bookmark {
  // Các thuộc tính của đánh dấu
  final String id;
  final String text; // Nội dung văn bản được đánh dấu
  final String chapterTitle; // Tiêu đề chương chứa đánh dấu
  final int chapterNumber; // Số thứ tự của chương
  final String storySlug; // Định danh của truyện
  final int startIndex; // Vị trí bắt đầu của đánh dấu
  final int endIndex; // Vị trí kết thúc của đánh dấu
  final String note; // Ghi chú người dùng
  final DateTime createdAt; // Thời điểm tạo đánh dấu

  // Hàm khởi tạo với các tham số bắt buộc
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

  // Chuyển đối tượng thành định dạng JSON để lưu trữ
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

  // Tạo đối tượng Bookmark từ dữ liệu JSON
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
