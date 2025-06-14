// Lớp đại diện cho thể loại truyện
class Category {
  // Các thuộc tính của thể loại
  final String id;
  final String name;
  final String description;
  final int stories; // Số lượng truyện trong thể loại
  final String slug; // Đường dẫn URL thân thiện

  // Hàm khởi tạo với các tham số bắt buộc
  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.stories,
    required this.slug,
  });

  // Phương thức tạo đối tượng Category từ dữ liệu JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    // In ra cấu trúc JSON để debug
    print('Đang phân tích Category từ JSON: ${json.keys.toList()}');

    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stories: _parseStories(json),
      slug: json['slug'] ?? '',
    );
  }

  // Hàm hỗ trợ để phân tích số lượng truyện từ các định dạng JSON khác nhau
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

  // Bắt buộc phải có toJson() để cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'stories': stories,
      'slug': slug,
    };
  }

  // Phương thức để phân tích danh sách thể loại từ API
  static List<Category> parseCategories(Map<String, dynamic> apiResponse) {
    List<Category> categories = [];

    // Kiểm tra và trích xuất dữ liệu từ response API
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
