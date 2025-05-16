import 'package:flutter/material.dart';
import 'package:btl/models/book.dart';
import 'package:btl/components/book_tile.dart';

class CategoryBooksPage extends StatelessWidget {
  final String category;
  final List<Book> books;

  const CategoryBooksPage(
      {super.key, required this.category, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.grey[900],
      body: books.isEmpty
          ? const Center(
              child: Text("No books available",
                  style: TextStyle(color: Colors.white)))
          : Padding(
              padding: const EdgeInsets.only(top: 10, right: 12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Hiển thị 2 cột mỗi hàng
                  crossAxisSpacing: 2, // Khoảng cách giữa các cột
                  mainAxisSpacing: 10, // Khoảng cách giữa các hàng
                  childAspectRatio: 2 / 3, // Giữ tỷ lệ ảnh tự nhiên
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return BookTile(linkImage: books[index].imagePath);
                },
              ),
            ),
    );
  }
}
