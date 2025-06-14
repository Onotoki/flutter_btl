// Lớp mô hình dữ liệu đại diện cho một highlight (đánh dấu) trong sách EPUB
class EpubHighlight {
  // Các thuộc tính của highlight
  final String id; // ID duy nhất của highlight
  final String bookId; // ID của sách chứa highlight
  final String content; // Nội dung văn bản được đánh dấu
  final int pageNumber; // Số trang chứa highlight
  final String pageId; // ID của trang chứa highlight
  final String rangy; // Thông tin vị trí highlight (sử dụng thư viện Rangy)
  final String note; // Ghi chú của người dùng cho highlight
  final String color; // Màu sắc của highlight
  final DateTime createdAt; // Thời gian tạo highlight

  // Constructor khởi tạo đối tượng EpubHighlight
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

  // Chuyển đổi đối tượng EpubHighlight thành Map để lưu trữ hoặc truyền dữ liệu
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

  // Factory method tạo EpubHighlight từ dữ liệu JSON
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
