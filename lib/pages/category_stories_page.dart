import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/models/category.dart';
import 'package:btl/components/story_tile.dart';
import 'package:btl/pages/story_detail_page.dart';
import 'package:btl/utils/content_filter.dart';

class CategoryStoriesPage extends StatefulWidget {
  final Category category;

  const CategoryStoriesPage({super.key, required this.category});

  @override
  State<CategoryStoriesPage> createState() => _CategoryStoriesPageState();
}

class _CategoryStoriesPageState extends State<CategoryStoriesPage> {
  List<Story> stories = []; //Danh sách truyện thuộc thể loại được tải từ API.
  bool isLoading = true; // Trạng thái tải dữ liệu
  String errorMessage = ''; // Lưu lỗi nếu có

  @override
  void initState() {
    super.initState();
    _loadStories(); //Hàm tải dữ liệu khi khởi động trang
  }

  Future<void> _loadStories() async {
    //Dùng lệnh gọi API để tải danh sách truyện theo thể loại được chọn
    try {
      //Kết quả sẽ lưu vào result và await giúp đợi phản hồi từ API trước khi tiếp tục xử lý
      final result = await OTruyenApi.getComicsByCategory(widget.category.slug);

      //Giúp chuyển đổi kiểu dữ liệu sang danh sách List và nếu API trả về null thì mặc định là danh sách rỗng
      final items = result['items'] as List<dynamic>? ?? [];

      setState(() {
        //Lọc bỏ truyện có nội dung không phù hợp.
        stories = ContentFilter.filterStories(
          //Chuyển từng truyện từ JSON sang Story và sau đó chuyển sang List để sử dụng
          items.map((data) => Story.fromJson(data)).toList(),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải danh sách truyện: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : stories.isEmpty
                  ? const Center(child: Text('Không có truyện nào'))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: stories.length,
                        itemBuilder: (context, index) => StoryTile(
                          story: stories[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StoryDetailPage(story: stories[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}
