import 'package:flutter/material.dart';
import 'package:btl/components/book_tile.dart';
import 'package:btl/models/book.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Book> favoriteBooks = List.generate(
        4, (index) => Book(imagePath: "lib/images/book.jpg")); // Danh mục mới

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Library",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
        ),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildSectionTitle(
                context, "Favorite Books", favoriteBooks), // Mục mới
            buildHorizontalBookList(favoriteBooks), // Danh sách sách
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(
      BuildContext context, String title, List<Book> books) {
    return GestureDetector(
      onTap: () {
        // Điều hướng nếu cần
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "$title >",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          return BookTile(linkImage: books[index].imagePath);
        },
      ),
    );
  }
}
