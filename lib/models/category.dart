class Category {
  final String id;
  final String name;
  final String description;
  final int stories;
  final String slug;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.stories,
    required this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // In ra cấu trúc JSON để debug
    print('Parsing Category from JSON: ${json.keys.toList()}');

    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stories: _parseStories(json),
      slug: json['slug'] ?? '',
    );
  }

  static int _parseStories(Map<String, dynamic> json) {
    // Thử nhiều cách để lấy số truyện
    if (json.containsKey('stories') && json['stories'] != null) {
      return int.tryParse(json['stories'].toString()) ?? 0;
    } else if (json.containsKey('comics_count') &&
        json['comics_count'] != null) {
      return int.tryParse(json['comics_count'].toString()) ?? 0;
    } else if (json.containsKey('count') && json['count'] != null) {
      return int.tryParse(json['count'].toString()) ?? 0;
    }
    return 0;
  }

  // Phương thức để phân tích danh sách thể loại từ API
  static List<Category> parseCategories(Map<String, dynamic> apiResponse) {
    List<Category> categories = [];

    if (apiResponse.containsKey('items')) {
      List<dynamic> categoriesData = apiResponse['items'];
      for (var categoryData in categoriesData) {
        if (categoryData is Map<String, dynamic>) {
          categories.add(Category.fromJson(categoryData));
        }
      }
    }

    return categories;
  }
}
