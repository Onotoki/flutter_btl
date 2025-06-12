import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:btl/cubit/home_cubit.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/models/story.dart';
import 'package:btl/utils/back_to_intro_page.dart';
import 'package:btl/utils/phan_duoi_back_to_intro_page.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/pages/categories_page.dart';
import 'package:btl/pages/search_page.dart';
import 'package:btl/pages/section_stories_page.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true; // Giữ state khi switch tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data when page is first initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().loadHomeData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          );
        }

        if (state is HomeError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<HomeCubit>().loadHomeData(forceRefresh: true);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (state is HomeLoaded) {
          return SafeArea(
            child: Column(
              children: [
                // Header với back button và search (layout gốc)
                const Padding(
                  padding: EdgeInsets.only(top: 10, right: 20, left: 20),
                  child: BackToIntroPage(),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 10),
                  child: PhanDuoiBackToIntroPage(),
                ),

                // Cache status indicator (tính năng mới)
                if (state.needsRefresh)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Dữ liệu có thể đã cũ. Kéo xuống để làm mới.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<HomeCubit>().refresh();
                          },
                          child: const Text('Làm mới',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                // TabBar (layout gốc với icons)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor:
                        Colors.green, // Thanh bên dưới màu xanh lá cây
                    labelColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white // Màu text cho dark mode
                        : Colors.grey[500], // Màu text cho light mode
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, // Làm đậm text khi được chọn
                      fontSize: 16,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(
                        //icon: Icon(Icons.photo_library),
                        text: 'Truyện tranh',
                      ),
                      Tab(
                        //icon: Icon(Icons.book),
                        text: 'Truyện chữ',
                      ),
                    ],
                  ),
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Truyện tranh
                      _buildTabContent(state.comicCategories, 'comic'),
                      // Tab Truyện chữ
                      _buildTabContent(state.novelCategories, 'novel'),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Initial state
        return const Center(
          child: Text('Chưa có dữ liệu'),
        );
      },
    );
  }

  // Widget để build TabBar content
  Widget _buildTabContent(Map<String, List<Story>> categories, String tabType) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HomeCubit>().refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Hiển thị các danh mục
            for (var category in categories.entries)
              _buildCategorySection(category.key, category.value),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, List<Story> stories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GestureDetector(
        onTap: () {
          // Navigate to section stories page để hiển thị tất cả truyện trong section
          try {
            // Map tiêu đề section với section type để gọi API tương ứng
            String? sectionType = _getSectionType(title);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectionStoriesPage(
                  sectionTitle: title,
                  stories: stories,
                  sectionType: sectionType,
                ),
              ),
            );
          } catch (e) {
            print('Error navigating to section stories: $e');
            // Hiển thị thông báo lỗi cho người dùng
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể mở danh sách truyện: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Hàm tạo danh sách ngang cho truyện (style gốc)
  Widget _buildHorizontalStoryList(List<Story> stories) {
    // Đảm bảo danh sách không null và không có phần tử null
    final validStories = stories.where((story) => story != null).toList();

    return Container(
      height: 220,
      constraints: const BoxConstraints(minHeight: 220),
      child: validStories.isEmpty
          ? const Center(child: Text('Không có dữ liệu'))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: validStories.length,
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                if (index >= 0 && index < validStories.length) {
                  final story = validStories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StoryTile(
                      story: story,
                      onTap: () {
                        // Thêm kiểm tra null và thiết lập onTap an toàn
                        try {
                          if (story != null && story.id.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoryDetailPage(
                                  story: story,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error navigating to story detail: $e');
                          // Hiển thị thông báo lỗi cho người dùng
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể mở chi tiết truyện: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  );
                } else {
                  return const SizedBox(width: 120, height: 200);
                }
              },
            ),
    );
  }

  // Phương thức để map tiêu đề section với API type
  String? _getSectionType(String title) {
    switch (title) {
      case 'Truyện mới cập nhật':
        return 'truyen-moi';
      case 'Đang phát hành':
        return 'dang-phat-hanh';
      case 'Hoàn thành':
        return 'hoan-thanh';
      case 'Sắp ra mắt':
        return 'sap-ra-mat';
      case 'Ebook mới':
        return 'ebook-moi';
      case 'Truyện chữ đang phát hành':
        return 'dang-phat-hanh'; // Sử dụng chung với truyện tranh
      case 'Truyện chữ hoàn thành':
        return 'hoan-thanh'; // Sử dụng chung với truyện tranh
      default:
        return null; // Không có API tương ứng
    }
  }

  // Phương thức mới để xây dựng một phần danh mục an toàn (style gốc)
  Widget _buildCategorySection(String title, List<Story>? stories) {
    // Nếu danh sách null hoặc rỗng, bỏ qua
    if (stories == null || stories.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, title, stories),
          _buildHorizontalStoryList(stories),
        ],
      );
    } catch (e) {
      print('Error building category section $title: $e');
      return const SizedBox.shrink();
    }
  }
}
