import 'package:flutter/material.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/category.dart';
import 'package:btl/pages/category_stories_page.dart';
import 'package:btl/utils/content_filter.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> categories = [];
  bool isLoading = true;
  String errorMessage = '';
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    String logs = '';
    try {
      logs += 'Starting to load categories...\n';
      final result = await OTruyenApi.getCategories();

      logs += 'Categories API Response keys: ${result.keys.toList()}\n';

      // Xử lý theo cấu trúc API OTruyen - đúng cấu trúc trả về là "items" không phải "categories"
      if (result.containsKey('items') && result['items'] is List) {
        logs += 'Found items list in response\n';
        List<dynamic> categoriesData = result['items'];
        logs += 'Categories count: ${categoriesData.length}\n';

        List<Category> loadedCategories = [];
        for (var categoryData in categoriesData) {
          if (categoryData is Map<String, dynamic>) {
            try {
              Category category = Category.fromJson(categoryData);

              // Kiểm tra xem có phải là thể loại người lớn không
              if (!ContentFilter.isAdultCategory(category.name)) {
                loadedCategories.add(category);
              } else {
                logs += 'Filtered out adult category: ${category.name}\n';
              }
            } catch (e) {
              logs += 'Error parsing category: $e\n';
            }
          }
        }

        setState(() {
          categories = loadedCategories;
          isLoading = false;
          debugInfo = logs;
        });

        logs +=
            'Successfully loaded ${categories.length} categories after filtering\n';
        print(logs);
      } else {
        logs +=
            'No items found in response structure. Available keys: ${result.keys.toList()}\n';
        throw Exception('Invalid API response structure');
      }
    } catch (e) {
      logs += 'Error loading categories: $e\n';
      print(logs);
      setState(() {
        errorMessage = 'Không thể tải danh sách thể loại: $e';
        isLoading = false;
        debugInfo = logs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thể loại truyện'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : categories.isEmpty
                  ? const Center(child: Text('Không có thể loại nào'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(categories[index]);
                      },
                    ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryStoriesPage(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${category.stories} truyện',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
