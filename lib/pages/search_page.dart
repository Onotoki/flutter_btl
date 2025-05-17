import 'package:flutter/material.dart';
import 'package:btl/models/book.dart';
import 'package:btl/models/book_data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
    searchController.addListener(_filterBooks);
  }

  void _loadBooks() {
    setState(() {
      allBooks = BookData.getAllBooks();
      filteredBooks =
          []; // Không hiển thị sách ban đầu, chỉ xuất hiện khi nhập từ khóa
    });
  }

  void _filterBooks() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredBooks = query.isNotEmpty
          ? allBooks
              .where((book) => book.title.toLowerCase().contains(query))
              .toList()
          : []; // Chỉ hiển thị sách khi nhập từ khóa
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: "Nhập từ khóa để tìm kiếm...",
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),
        ),
      ),
      body: filteredBooks.isEmpty
          ? const Center(
              child: Text("Không có sách nào được tìm thấy",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          : ListView.builder(
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      // Hình ảnh sách bên trái
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          filteredBooks[index].imagePath,
                          width: 80, // Kích thước hình ảnh
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(
                          width: 12), // Khoảng cách giữa ảnh và tiêu đề

                      // Phần tiêu đề bên phải
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filteredBooks[index].title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              filteredBooks[index].author,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
