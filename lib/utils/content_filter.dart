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
    'smut',
    'manhua',
    'shounen-ai',
    'shoujo-ai',
    'soft-yaoi',
    'soft-yuri',
    'josei',
    'seinen',
    'gender-bender',
    'doujinshi',
    'dam-my'
  ];

  // Kiểm tra xem một thể loại có phải là thể loại người lớn không
  static bool isAdultCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    return adultKeywords.any((keyword) => lowerCaseName.contains(keyword));
  }

  // Kiểm tra xem một truyện có thuộc thể loại người lớn không
  static bool isAdultStory(Story story) {
    if (story.categories.any(isAdultCategory)) {
      return true;
    }
    final lowerCaseTitle = story.title.toLowerCase();
    return adultKeywords.any((keyword) => lowerCaseTitle.contains(keyword));
  }

  // Lọc danh sách truyện, loại bỏ nội dung người lớn
  static List<Story> filterStories(List<Story> stories) {
    return stories.where((story) => !isAdultStory(story)).toList();
  }
}
