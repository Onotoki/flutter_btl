# Cập Nhật Điều Hướng Chương

## Thay Đổi Chính

### 1. Hướng Điều Hướng Mới
**Mong muốn:**
- Ở đầu chương + kéo xuống → chương trước
- Ở cuối chương + kéo lên → chương tiếp theo

**Cách hoạt động:**
- Khi bạn ở **đầu chương** (scroll = 0) và cố gắng **kéo xuống thêm** → chuyển về chương trước
- Khi bạn ở **cuối chương** (scroll = max) và cố gắng **kéo lên thêm** → chuyển sang chương tiếp theo

### 2. Giao Diện Bottom Navigation Mới

**Bây giờ:**
```
================== 75% ==================

  Chương 5/20          Trang 3/8
```

### 3. Tính Năng Mới
- **Thanh tiến độ**: Hiển thị % nội dung đã đọc trong chương hiện tại
- **Thông tin chi tiết**: 
  - Số chương hiện tại / tổng số chương
  - Số trang hiện tại / tổng số trang (ước tính cho chế độ dọc)
- **Giao diện gọn gàng**: Loại bỏ nút điều hướng để tiết kiệm không gian

## Cách Sử Dụng

### Điều Hướng Chương:
1. **Về chương trước**: 
   - Scroll lên đầu chương (scroll về 0)
   - Tiếp tục kéo xuống (overscroll)
   
2. **Đến chương tiếp**: 
   - Scroll xuống cuối chương (scroll đến max)
   - Tiếp tục kéo lên (overscroll)

**Lưu ý:** Cần kéo với lực đủ mạnh để tạo overscroll effect (> 20px)

### Xem Tiến Độ:
- Thanh tiến độ ở bottom navigation hiển thị % đã đọc
- Thông tin chương và trang hiển thị bên dưới

## Debugging

Nếu điều hướng không hoạt động:
1. Đảm bảo bạn đã scroll đến đầu/cuối chương
2. Kéo mạnh hơn để tạo overscroll
3. Kiểm tra có chương trước/sau không
4. Thử trong chế độ debug để xem console logs

## Technical Details

### Overscroll Detection
```dart
if (notification is OverscrollNotification) {
  final overscroll = notification.overscroll;
  
  // Pulling down at top (overscroll > 0) -> previous chapter
  if (overscroll > 20) {
    // Navigate to previous chapter
  }
  // Pulling up at bottom (overscroll < 0) -> next chapter  
  else if (overscroll < -20) {
    // Navigate to next chapter
  }
}
```

### Progress Tracking
```dart
void _updateReadingProgress() {
  final scrollOffset = _scrollController.offset;
  final maxScrollExtent = _scrollController.position.maxScrollExtent;
  
  if (maxScrollExtent > 0) {
    _readingProgress = (scrollOffset / maxScrollExtent * 100).clamp(0.0, 100.0);
  }
}
```

### Page Estimation (Vertical Mode)
```dart
int _getCurrentEstimatedPage() {
  final scrollOffset = _scrollController.offset;
  final maxScrollExtent = _scrollController.position.maxScrollExtent;
  final viewportHeight = _scrollController.position.viewportDimension;
  
  final totalContentHeight = maxScrollExtent + viewportHeight;
  final estimatedTotalPages = (totalContentHeight / viewportHeight).ceil();
  
  return ((scrollOffset / maxScrollExtent) * (estimatedTotalPages - 1)).floor() + 1;
}
```

## Files Được Cập Nhật

1. **`epub_chapter_page.dart`**
   - Thêm overscroll navigation
   - Thêm progress tracking
   - Thêm page estimation cho chế độ dọc
   - Thay đổi bottomNavigationBar
   - Xử lý tất cả các loại truyện chữ và ebook

## Lợi Ích

1. **Trực quan hơn**: Điều hướng theo logic tự nhiên
2. **Thông tin phong phú**: Biết được vị trí chính xác trong truyện
3. **Giao diện gọn**: Không còn nút chiếm không gian
4. **Trải nghiệm mượt**: Overscroll tự nhiên thay vì gesture phức tạp