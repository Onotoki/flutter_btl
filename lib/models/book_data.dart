import 'package:btl/models/book.dart';

/// A utility class to manage and provide book data
class BookData {
  // Mock data for demonstration purposes
  static List<Book> _allBooks = [
    // Recommend For You category
    Book(imagePath: 'lib/assets/books/book1.jpg'),
    Book(imagePath: 'lib/assets/books/book2.jpg'),
    Book(imagePath: 'lib/assets/books/book3.jpg'),
    Book(imagePath: 'lib/assets/books/book4.jpg'),
    Book(imagePath: 'lib/assets/books/book5.jpg'),

    // Top in Contemporary
    Book(imagePath: 'lib/assets/books/book6.jpg'),
    Book(imagePath: 'lib/assets/books/book7.jpg'),
    Book(imagePath: 'lib/assets/books/book8.jpg'),
    Book(imagePath: 'lib/assets/books/book9.jpg'),
    Book(imagePath: 'lib/assets/books/book10.jpg'),

    // Enemies to Lovers
    Book(imagePath: 'lib/assets/books/book11.jpg'),
    Book(imagePath: 'lib/assets/books/book12.jpg'),
    Book(imagePath: 'lib/assets/books/book13.jpg'),
    Book(imagePath: 'lib/assets/books/book14.jpg'),
    Book(imagePath: 'lib/assets/books/book15.jpg'),

    // Love Stories
    Book(imagePath: 'lib/assets/books/book16.jpg'),
    Book(imagePath: 'lib/assets/books/book17.jpg'),
    Book(imagePath: 'lib/assets/books/book18.jpg'),
    Book(imagePath: 'lib/assets/books/book19.jpg'),
    Book(imagePath: 'lib/assets/books/book20.jpg'),
  ];

  // Map to associate categories with books
  static final Map<String, List<int>> _categoriesMap = {
    "Recommend For You": [0, 1, 2, 3, 4],
    "Top in Contemporary": [5, 6, 7, 8, 9],
    "Enemies to Lovers": [10, 11, 12, 13, 14],
    "Love Stories": [15, 16, 17, 18, 19]
  };

  /// Get all books
  static List<Book> getAllBooks() {
    return List.from(_allBooks);
  }

  /// Get books by category name
  static List<Book> getBooksByCategory(String category) {
    if (!_categoriesMap.containsKey(category)) {
      return [];
    }

    List<int> indexes = _categoriesMap[category]!;
    return indexes.map((index) => _allBooks[index]).toList();
  }
}
