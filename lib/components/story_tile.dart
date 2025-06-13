import 'package:flutter/material.dart';
import 'package:btl/models/story.dart';

class StoryTile extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StoryTile({
    super.key,
    required this.story,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Đảm bảo đối tượng story và các thuộc tính không null
    if (story == null) {
      return const SizedBox(width: 120, height: 200);
    }

    // Xử lý trường hợp thumbnail null hoặc rỗng
    final thumbnailUrl = story.thumbnail != null && story.thumbnail.isNotEmpty
        ? story.thumbnail
        : 'https://via.placeholder.com/150x200';

    // Đảm bảo title không null
    final title = story.title != null ? story.title : 'Truyện không tên';

    // Đảm bảo chapters không null
    final chaptersText = 'Chương: ${story.chapters}';

    return SizedBox(
      // Đảm bảo StoryTile luôn có chiều rộng cố định
      width: 100,
      child: GestureDetector(
        onTap: () {
          // Bọc onTap trong try-catch để tránh lỗi khi gọi hàm callback
          try {
            onTap();
          } catch (e) {
            print('Error in StoryTile onTap: $e');
          }
        },
        onLongPress: onLongPress != null
            ? () {
                try {
                  onLongPress!();
                } catch (e) {
                  print('Error in StoryTile onLongPress: $e');
                }
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail container with fixed width & height
            SizedBox(
              height: 160, // Fixed height for cover
              width: 120, // Fixed width for cover
              child: Stack(
                children: [
                  // Thumbnail image
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Biểu tượng góc phải trên cho loại truyện
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: story.isNovel
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.green.withOpacity(0.8),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Icon(
                        story.isNovel ? Icons.book : Icons.photo_library,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Tiêu đề
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Thông tin thêm
            // Text(
            //   chaptersText,
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey[600],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// 📐 Hàm tính kích thước ảnh responsive theo màn hình
  Size _getResponsiveSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = (screenWidth - 40) / 3; // trừ padding + khoảng cách
    final height = width * 4 / 3;
    return Size(width, height);
  }

  /// 🖼️ Hiển thị ảnh (thumbnail)
  Widget _buildThumbnail(BuildContext context, Size size) {
    if (story.thumbnail.isEmpty) {
      return _errorImage(size);
    }

    String imageUrl = story.thumbnail;

    if (story.thumbnail.startsWith('http')) {
      imageUrl = story.thumbnail;
    } else if (story.thumbnail.startsWith('/')) {
      imageUrl = 'https://otruyenapi.com${story.thumbnail}';
    } else if (story.thumbnail.startsWith('lib/') ||
        story.thumbnail.startsWith('assets/')) {
      try {
        return Image.asset(
          story.thumbnail,
          fit: BoxFit.cover,
          width: size.width,
          height: size.height,
          errorBuilder: (context, error, stackTrace) => _errorImage(size),
        );
      } catch (e) {
        return _errorImage(size);
      }
    } else {
      if (!story.thumbnail.startsWith('http')) {
        imageUrl = 'https://${story.thumbnail}';
      }
    }

    return _buildNetworkImage(imageUrl, size);
  }

  /// 🌐 Ảnh từ mạng (có xử lý lỗi và fallback domain)
  Widget _buildNetworkImage(String url, Size size) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
      errorBuilder: (context, error, stackTrace) {
        if (url.startsWith('https://otruyenapi.com/')) {
          final fallbackUrl =
              url.replaceFirst('https://otruyenapi.com', 'https://otruyen.cc');
          return Image.network(
            fallbackUrl,
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            errorBuilder: (_, __, ___) => _errorImage(size),
          );
        }
        return _errorImage(size);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: size.width,
          height: size.height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// ❌ Ảnh lỗi fallback
  Widget _errorImage(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported),
    );
  }
}
