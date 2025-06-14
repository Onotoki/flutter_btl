import 'package:btl/models/book.dart';

/// Lớp tiện ích để quản lý và cung cấp dữ liệu sách
class BookData {
  // Dữ liệu mẫu để demo ứng dụng
  // Danh sách tĩnh chứa tất cả các sách trong ứng dụng (20 cuốn sách)
  static List<Book> _allBooks = [
    Book(imagePath: 'lib/assets/books/book1.jpg'),
    Book(imagePath: 'lib/assets/books/book2.jpg'),
    Book(imagePath: 'lib/assets/books/book3.jpg'),
    Book(imagePath: 'lib/assets/books/book4.jpg'),
    Book(imagePath: 'lib/assets/books/book5.jpg'),
    Book(imagePath: 'lib/assets/books/book6.jpg'),
    Book(imagePath: 'lib/assets/books/book7.jpg'),
    Book(imagePath: 'lib/assets/books/book8.jpg'),
    Book(imagePath: 'lib/assets/books/book9.jpg'),
    Book(imagePath: 'lib/assets/books/book10.jpg'),
    Book(imagePath: 'lib/assets/books/book11.jpg'),
    Book(imagePath: 'lib/assets/books/book12.jpg'),
    Book(imagePath: 'lib/assets/books/book13.jpg'),
    Book(imagePath: 'lib/assets/books/book14.jpg'),
    Book(imagePath: 'lib/assets/books/book15.jpg'),
    Book(imagePath: 'lib/assets/books/book16.jpg'),
    Book(imagePath: 'lib/assets/books/book17.jpg'),
    Book(imagePath: 'lib/assets/books/book18.jpg'),
    Book(imagePath: 'lib/assets/books/book19.jpg'),
    Book(imagePath: 'lib/assets/books/book20.jpg'),
  ];

  // Bản đồ liên kết giữa các danh mục và các sách tương ứng
  // Mỗi danh mục chứa danh sách chỉ số tương ứng với vị trí sách trong _allBooks
  static final Map<String, List<int>> _categoriesMap = {
    "Recommend For You": [0, 1, 2, 3, 4],
    "Top in Contemporary": [5, 6, 7, 8, 9],
    "Enemies to Lovers": [10, 11, 12, 13, 14],
    "Love Stories": [15, 16, 17, 18, 19]
  };

  /// Lấy tất cả các sách
  /// Trả về một bản sao của danh sách để tránh việc thay đổi dữ liệu gốc
  static List<Book> getAllBooks() {
    return List.from(_allBooks);
  }

  /// Lấy danh sách sách theo tên danh mục
  /// Tham số [category]: Tên danh mục cần lấy sách
  /// Trả về: Danh sách các đối tượng Book thuộc danh mục đó, hoặc danh sách rỗng nếu không tìm thấy
  static List<Book> getBooksByCategory(String category) {
    // Kiểm tra xem danh mục có tồn tại trong bản đồ không
    if (!_categoriesMap.containsKey(category)) {
      return [];
    }

    // Lấy danh sách chỉ số của các sách thuộc danh mục
    List<int> indexes = _categoriesMap[category]!;
    // Chuyển đổi chỉ số thành đối tượng Book tương ứng
    return indexes.map((index) => _allBooks[index]).toList();
  }
}
