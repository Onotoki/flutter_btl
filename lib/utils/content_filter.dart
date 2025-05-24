import 'package:btl/models/story.dart';

class ContentFilter {
  // Danh sách các từ khóa liên quan đến nội dung người lớn cần lọc
  static final List<String> adultKeywords = [
    'adult',
    'người lớn',
    'mature',
    '16+',
    '18+',
    'ecchi',
    'mature',
    'smut',
    'manhua',
    'shounen-ai',
    'shoujo-ai',
    'soft-yaoi',
    'soft-yuri',
    'josei',
    'seinen',
    'harem',
    'gender-bender,'
        'doujinshi',
    'dam-my',
  ];

  // Kiểm tra xem một thể loại có phải là thể loại người lớn không
  static bool isAdultCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    return adultKeywords.any((keyword) => lowerCaseName.contains(keyword));
  }

  // Kiểm tra xem một truyện có thuộc thể loại người lớn không
  static bool isAdultStory(Story story) {
    // Kiểm tra xem truyện có thể loại người lớn không
    if (story.categories.isNotEmpty) {
      for (String category in story.categories) {
        if (isAdultCategory(category)) {
          return true;
        }
      }
    }

    // Kiểm tra xem tiêu đề truyện có chứa từ khóa người lớn không
    final lowerCaseTitle = story.title.toLowerCase();
    if (adultKeywords.any((keyword) => lowerCaseTitle.contains(keyword))) {
      return true;
    }

    return false;
  }

  // Lọc danh sách truyện, loại bỏ nội dung người lớn
  static List<Story> filterStories(List<Story> stories) {
    return stories.where((story) => !isAdultStory(story)).toList();
  }
}
