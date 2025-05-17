import 'package:flutter/material.dart';
import 'package:btl/models/book.dart';
import 'package:btl/models/book_data.dart';
import 'package:btl/pages/category_books_page.dart';
import 'package:btl/components/book_tile.dart';
import 'package:btl/components/auto_image_slider.dart';
import 'package:btl/utils/back_to_intro_page.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  List<Book> recommendedBooks = [];
  List<Book> contemporaryBooks = [];
  List<Book> enemiesToLoversBooks = [];
  List<Book> loveStoriesBooks = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    setState(() {
      recommendedBooks = BookData.getBooksByCategory("Recommend For You");
      contemporaryBooks = BookData.getBooksByCategory("Top in Contemporary");
      enemiesToLoversBooks = BookData.getBooksByCategory("Enemies to Lovers");
      loveStoriesBooks = BookData.getBooksByCategory("Love Stories");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: SafeArea(child: BackToIntroPage()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "$title >",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: AutoImageSlider(),
            ),
            const SizedBox(height: 15),
            buildSectionTitle(context, "Recommend For You", recommendedBooks),
            buildHorizontalBookList(recommendedBooks),
            buildSectionTitle(
                context, "Top in Contemporary", contemporaryBooks),
            buildHorizontalBookList(contemporaryBooks),
            buildSectionTitle(
                context, "Enemies to Lovers", enemiesToLoversBooks),
            buildHorizontalBookList(enemiesToLoversBooks),
            buildSectionTitle(context, "Love Stories", loveStoriesBooks),
            buildHorizontalBookList(loveStoriesBooks),
            SizedBox(
              height: 15,
            )
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(
      BuildContext context, String title, List<Book> books) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CategoryBooksPage(category: title, books: books),
            ),
          );
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "$title >",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
    );
  }

  Widget buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 200,
      child: books.isEmpty
          ? const Center(
              child: Text("No books available",
                  style: TextStyle(color: Colors.white)))
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
