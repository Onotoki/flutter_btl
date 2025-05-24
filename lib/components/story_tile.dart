import 'package:flutter/material.dart';
import 'package:btl/models/story.dart';

class StoryTile extends StatelessWidget {
  final Story story;
  final Function()? onTap;

  const StoryTile({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = _getResponsiveSize(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size.width,
          decoration: BoxDecoration(
            // color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildThumbnail(context, size),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
                child: Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
