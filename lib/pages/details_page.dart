import 'package:flutter/material.dart';
import 'package:btl/components/book_tile.dart';
import 'package:btl/models/book.dart';

class DetailsPage extends StatelessWidget {
  final String categoryTitle;
  final List<Book> books;

  const DetailsPage(
      {super.key, required this.categoryTitle, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          categoryTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[900],
        // Cập nhật màu của nút quay lại
        iconTheme: const IconThemeData(
          color: Colors.white, // Màu trắng cho nút quay lại
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Hiển thị 2 cột
            crossAxisSpacing: 10.0, // Khoảng cách giữa các cột
            mainAxisSpacing: 10.0, // Khoảng cách giữa các hàng
            childAspectRatio: 3 / 4, // Tỷ lệ khung hình của mỗi ô (rộng/cao)
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
