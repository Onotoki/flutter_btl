import 'package:btl/models/book.dart';

class BookData {
  static List<Book> allBooks = [
    Book(
        id: 1,
        title: "Love in the Moonlight",
        author: "John Doe",
        category: "Love Stories",
        imagePath: "lib/images/book.jpg"),
    Book(
        id: 2,
        title: "Enemies to Lovers",
        author: "Jane Doe",
        category: "Enemies to Lovers",
        imagePath: "lib/images/book.jpg"),
    Book(
        id: 3,
        title: "Mystery of the Dark Forest",
        author: "Emily Smith",
        category: "Top in Contemporary",
        imagePath: "lib/images/book.jpg"),
    Book(
        id: 4,
        title: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        category: "Recommend For You",
        imagePath: "lib/images/book.jpg"),
    Book(
        id: 5,
        title: "Enemies to Lovers",
        author: "Jane Doe",
        category: "Recommend For You",
        imagePath: "lib/images/book.jpg"),
  ];

  static List<Book> getBooksByCategory(String category) {
    return allBooks.where((book) => book.category == category).toList();
  }

  // 🔥 Added method to fetch all books 🔥
  static List<Book> getAllBooks() {
    return allBooks;
  }
}
