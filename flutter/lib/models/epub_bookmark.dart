// Lớp mô hình dữ liệu đại diện cho một bookmark trong sách EPUB
class EpubBookmark {
  // Các thuộc tính của bookmark
  final String id; // ID duy nhất của bookmark
  final String bookId; // ID của sách chứa bookmark
  final String content; // Nội dung văn bản tại vị trí bookmark
  final int pageNumber; // Số trang chứa bookmark
  final String pageId; // ID của trang chứa bookmark
  final String href; // Đường dẫn đến vị trí bookmark trong EPUB
  final String cfi; // Canonical Fragment Identifier để định vị chính xác
  final String note; // Ghi chú của người dùng cho bookmark
  final DateTime createdAt; // Thời gian tạo bookmark

  // Constructor khởi tạo đối tượng EpubBookmark
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

  // Chuyển đổi đối tượng EpubBookmark thành Map để lưu trữ hoặc truyền dữ liệu
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

  // Factory method tạo EpubBookmark từ dữ liệu JSON
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
