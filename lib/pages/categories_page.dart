import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/category.dart';
import 'package:btl/pages/category_stories_page.dart';
import 'package:btl/utils/content_filter.dart';

//Khai báo trang thể loại
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> categories = []; // Danh sách thể loại
  bool isLoading = true; // Trạng thái tải dữ liệu
  String errorMessage = ''; // Lưu lỗi nếu có

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Hàm tải dữ liệu khi khởi động trang
  }

  Future<void> _loadCategories() async {
    List<String> filteredOutCategories = []; // Danh sách thể loại bị loại bỏ

    //Dùng lệnh gọi API để tải danh sách các thể loại
    try {
      final result = await OTruyenApi
          .getCategories(); //Kết quả sẽ lưu vào result và await giúp đợi phản hồi từ API trước khi tiếp tục xử lý

      //Giúp chuyển đổi kiểu dữ liệu sang danh sách List và nếu API trả về null thì mặc định là danh sách rỗng
      final items = result['items'] as List<dynamic>? ?? [];

      categories = items
          //Lọc ra các phần tử có kiểu Map<String, dynamic>, đảm bảo chỉ xử lý dữ liệu JSON hợp lệ.
          .whereType<Map<String, dynamic>>()
          //Chuyển đổi từng phần tử JSON thành một đối tượng Category bằng phương thức Category.fromJson().
          .map((data) =>
              Category.fromJson(data)) // Chuyển đổi thành đối tượng Category
          // Trước khi chuyển đổi:
          // {
          //   "items": [
          //     {"name": "Hành động", "slug": "hanh-dong"},
          //     {"name": "Ecchi", "slug": "ecchi"},
          //     {"name": "Phiêu lưu", "slug": "phieu-luu"}
          //   ]
          // }
          // Sau khi chuyển đổi:
          // [
          //   Category(name: "Hành động", slug: "hanh-dong"),
          //   Category(name: "Ecchi", slug: "ecchi"),
          //   Category(name: "Phiêu lưu", slug: "phieu-luu")
          // ]
          .where((category) {
        final isAdult = ContentFilter.isAdultCategory(category.name);
        if (isAdult) {
          filteredOutCategories.add(category.name); // Ghi lại thể loại bị lọc
        }
        return !isAdult; // Chỉ giữ lại thể loại không phải người lớn
      }).toList(); //Chuyển where về lại thành danh sách List

      print('Danh sách thể loại người lớn đã bị lọc: $filteredOutCategories');

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải danh sách thể loại: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Thể loại truyện',
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) //Hiển thị vòng quay khi tải
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage)) // Hiển thị lỗi nếu có
              : categories.isEmpty
                  ? const Center(child: Text('Không có thể loại nào'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, //Mỗi hàng có hai cột
                        childAspectRatio:
                            1.5, //Tỉ lệ chiều rộng, chiều cao (giúp các ô không quá vuông)
                        crossAxisSpacing: 10, //Khoảng cách ngang
                        mainAxisSpacing: 10, //Khoảng cách dọc
                      ),
                      itemCount:
                          categories.length, //Đếm số phần tử trong danh sách

                      //Hàm để hiển thị mỗi thể loại
                      itemBuilder: (context, index) =>
                          _buildCategoryCard(categories[index]),
                    ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 10, //Tạo hiệu ứng nổi lên một chút
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CategoryStoriesPage(category: category)),
        ),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center, // Căn giữa nội dung trong ô
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
