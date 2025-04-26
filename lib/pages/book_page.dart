import 'package:flutter/material.dart';
import 'package:btl/components/book_tile.dart';
import 'package:btl/models/book.dart';
import 'package:btl/utils/back_to_intro_page.dart';
import 'package:btl/utils/phan_duoi_back_to_intro_page.dart';
import 'details_page.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  // Hàm tạo tiêu đề với điều hướng
  Widget buildSectionTitle(
      BuildContext context, String title, List<Book> books) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailsPage(categoryTitle: title, books: books),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "$title >",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo danh sách ngang cho sách
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

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu cho từng danh mục
    List<Book> happyEndingsBooks =
        List.generate(4, (index) => Book(imagePath: "lib/images/book.jpg"));
    List<Book> contemporaryBooks =
        List.generate(4, (index) => Book(imagePath: "lib/images/book.jpg"));
    List<Book> enemiesToLoversBooks =
        List.generate(4, (index) => Book(imagePath: "lib/images/book.jpg"));
    List<Book> loveStoriesBooks =
        List.generate(4, (index) => Book(imagePath: "lib/images/book.jpg"));

    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 50, right: 20, left: 20),
            child: BackToIntroPage(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 15, bottom: 20),
            child: PhanDuoiBackToIntroPage(),
          ),
          buildSectionTitle(context, "Happy Endings", happyEndingsBooks),
          buildHorizontalBookList(happyEndingsBooks),
          buildSectionTitle(context, "Top in Contemporary", contemporaryBooks),
          buildHorizontalBookList(contemporaryBooks),
          buildSectionTitle(context, "Enemies to Lovers", enemiesToLoversBooks),
          buildHorizontalBookList(enemiesToLoversBooks),
          buildSectionTitle(context, "Love Stories", loveStoriesBooks),
          buildHorizontalBookList(loveStoriesBooks),
        ],
      ),
    );
  }
}
