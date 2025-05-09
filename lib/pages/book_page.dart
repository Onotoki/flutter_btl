import 'package:flutter/material.dart';
import 'package:btl/components/book_tile.dart';
import 'package:btl/models/book.dart';
import 'package:btl/utils/back_to_intro_page.dart';
import 'package:btl/components/auto_image_slider.dart'; // Import widget slideshow
import 'details_page.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Book> books =
        List.generate(4, (index) => Book(imagePath: "lib/images/book.jpg"));

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(110),
        child: Container(
          color: Colors.grey[900],
          child: SafeArea(child: BackToIntroPage()),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thêm slideshow hình ảnh trước phần Happy Endings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: AutoImageSlider(), // Widget ảnh tự động chuyển đổi
            ),
            buildSectionTitle(context, "Happy Endings", books),
            buildHorizontalBookList(books),
            buildSectionTitle(context, "Top in Contemporary", books),
            buildHorizontalBookList(books),
            buildSectionTitle(context, "Enemies to Lovers", books),
            buildHorizontalBookList(books),
            buildSectionTitle(context, "Love Stories", books),
            buildHorizontalBookList(books),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(
      BuildContext context, String title, List<Book> books) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DetailsPage(categoryTitle: title, books: books)),
        );
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
