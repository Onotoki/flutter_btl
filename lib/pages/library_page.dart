import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/pages/libary_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:flutter/services.dart';
import 'package:btl/pages/categories_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<Map<String, dynamic>> listBooksReading = [];
  List<Map<String, dynamic>> listBooksFavorite = [];
  Widget? listReading;
  Widget? listFavorite;
  bool _isLoading = true;
  String? uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    uid = user.uid;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra đăng nhập
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem thư viện',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 10,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: Colors.white,
                  tabs: [
                    TabItem(title: 'Đang đọc'),
                    TabItem(title: 'Yêu thích'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TabBarView(children: [
            LibraryTab(category: 'books_reading', uid: uid!),
            LibraryTab(category: 'books_favorite', uid: uid!)
          ]),
        ),
      ),
    );
  }

  Widget TabItem({required String title}) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStoryList(List<Story> stories) {
    return SizedBox(
      height: 220,
      child: stories.isEmpty
          ? const Center(child: Text('Chưa có chuyện nào'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                return StoryTile(
                  story: stories[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StoryDetailPage(story: stories[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var category in _categories.entries) ...[
                          _buildSectionTitle(
                              context, category.key, category.value),
                          _buildHorizontalStoryList(category.value),
                        ],
                      ],
                    ),
                  ),
                ),
              );
  }
}
