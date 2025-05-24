import 'package:btl/models/book_data.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../components/book_tile.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Book> favoriteBooks = [];
  List<Book> continueReadingBooks = []; // Thêm danh sách sách đang đọc dở

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      favoriteBooks = BookData.getBooksByCategory("Favorite Books");
      continueReadingBooks = BookData.getBooksByCategory(
          "Continue Reading"); // Giả định danh mục có sẵn
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Library",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 27),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildSectionTitle(
                  context, "Continue Reading", continueReadingBooks),
              buildHorizontalBookList(
                  continueReadingBooks), // Thêm phần continue reading

              buildSectionTitle(context, "Favorite Books", favoriteBooks),
              buildHorizontalBookList(favoriteBooks),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(
      BuildContext context, String title, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$title (${books.length}) >",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
    );
  }

  Widget buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 200,
      child: books.isEmpty
          ? const Center(child: Text("No books found", style: TextStyle()))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              itemBuilder: (context, index) {
                return BookTile(linkImage: books[index].imagePath);
              },
            ),
    );
  }
}
