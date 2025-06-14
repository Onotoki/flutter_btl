import 'package:btl/models/story.dart';
import 'package:btl/models/category.dart';

/// Lọc Nội dung (ContentFilter)
///
/// Mô tả: Cung cấp các hàm tiện ích để lọc nội dung không phù hợp và phân loại truyện.
///
/// Chức năng:
/// - Lọc bỏ các truyện/thể loại có chứa từ khóa người lớn
/// - Phân biệt giữa truyện tranh và truyện chữ dựa trên thông tin truyện
/// - Hỗ trợ nhiều ngôn ngữ và định dạng từ khóa khác nhau
///
/// Phương thức chính:
/// - isAdultCategory(String categoryName): Kiểm tra tên thể loại có phải người lớn không
/// - isAdultStory(Story story): Kiểm tra truyện có nội dung người lớn không
/// - filterStories(List<Story> stories): Trả về danh sách truyện đã được lọc
/// - filterCategories(List<Category> categories): Lọc danh sách thể loại
class ContentFilter {
  // Danh sách các từ khóa liên quan đến nội dung người lớn cần lọc
  static final List<String> adultKeywords = [
    // Tiếng Anh
    'adult',
    'mature',
    '16+',
    '18+',
    '19+',
    'ecchi',
    'smut',
    'hentai',
    'porn',
    'sex',
    'xxx',
    'erotic',
    'nudity',

    // Các thể loại manga/anime người lớn
    'shounen-ai',
    'shoujo-ai',
    'yaoi',
    'yuri',
    'soft-yaoi',
    'soft-yuri',
    'josei',
    'seinen',
    'harem',
    'reverse-harem',
    'gender-bender',
    'doujinshi',

    // Tiếng Việt
    'người lớn',
    'nội dung nhạy cảm',
    'không phù hợp trẻ em',
    'dành cho người lớn',
    'cảnh nóng',
    'tình cảm',
    'đam mỹ',
    'dam-my',
    'gl',
    'bl',

    // Các từ khóa khác
    'manhua', // Một số manhua có nội dung người lớn
    'webtoon', // Một số webtoon có nội dung người lớn
  ];

  // Danh sách thể loại dành cho truyện chữ
  static final List<String> textNovelCategories = [
    'tiểu thuyết',
    'tiếu lâm',
    'cổ tích',
    'phiêu lưu, mạo hiểm',
    'trinh thám, hình sự',
    'kiếm hiệp',
    // 'novel',
    // 'văn học',
    // 'truyện chữ',
    // 'ebook',
    // 'light novel',
    // 'huyền huyễn',

    // 'truyện ngắn',
    // 'tâm lý',
    // 'lịch sử',
    // 'cổ đại',
    // 'xuân thu',
    // 'hiện đại',
  ];

  // Kiểm tra xem một thể loại có phải là thể loại người lớn không
  static bool isAdultCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    return adultKeywords.any((keyword) => lowerCaseName.contains(keyword));
  }

  // Kiểm tra xem một thể loại có phải là thể loại truyện chữ không
  static bool isNovelCategory(String categoryName) {
    final lowerCaseName = categoryName.toLowerCase();
    return textNovelCategories
        .any((keyword) => lowerCaseName.contains(keyword));
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

  // Kiểm tra xem một truyện có phải là truyện chữ không dựa trên thể loại và tên
  static bool detectNovelByCategory(Story story) {
    // Nếu đã có itemType là 'ebook' hoặc 'text_story' thì đó chính là truyện chữ
    if (story.isNovel) {
      return true;
    }

    // Kiểm tra theo thể loại
    if (story.categories.isNotEmpty) {
      for (String category in story.categories) {
        if (isNovelCategory(category)) {
          return true;
        }
      }
    }

    // Kiểm tra theo tiêu đề
    final lowerCaseTitle = story.title.toLowerCase();
    if (textNovelCategories
        .any((keyword) => lowerCaseTitle.contains(keyword))) {
      return true;
    }

    return false;
  }

  // Phân loại truyện thành truyện tranh hoặc truyện chữ nếu chưa được phân loại
  static void classifyStoryTypes(List<Story> stories) {
    for (var i = 0; i < stories.length; i++) {
      if (detectNovelByCategory(stories[i])) {
        // Nếu được phát hiện là truyện chữ nhưng chưa được đánh dấu
        if (!stories[i].isNovel) {
          // Tạo một bản sao của story với itemType = 'ebook'
          stories[i] = Story(
            id: stories[i].id,
            title: stories[i].title,
            description: stories[i].description,
            thumbnail: stories[i].thumbnail,
            categories: stories[i].categories,
            status: stories[i].status,
            views: stories[i].views,
            chapters: stories[i].chapters,
            updatedAt: stories[i].updatedAt,
            slug: stories[i].slug,
            authors: stories[i].authors,
            chaptersData: stories[i].chaptersData,
            itemType: 'ebook', // Đánh dấu là ebook
          );
        }
      }
    }
  }

  // Lọc danh sách truyện, loại bỏ nội dung người lớn
  static List<Story> filterStories(List<Story> stories) {
    // Trước tiên phân loại các story
    classifyStoryTypes(stories);
    // Sau đó lọc nội dung người lớn
    return stories.where((story) => !isAdultStory(story)).toList();
  }

  static List<Category> filterCategories(List<Category> categories) {
    return categories
        .where((category) => !isAdultCategory(category.name))
        .toList();
  }
}
