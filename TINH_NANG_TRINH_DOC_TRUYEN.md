# 📚 TÍNH NĂNG TRÌNH ĐỌC TRUYỆN FLUTTER_BTL

## 🎯 TỔNG QUAN
Ứng dụng đọc truyện Flutter_BTL là một trình đọc sách điện tử đa tính năng, hỗ trợ cả truyện tranh và truyện chữ với nhiều tính năng nâng cao để tối ưu trải nghiệm đọc.

---

## 🔥 DANH SÁCH TÍNH NĂNG CHI TIẾT

### 📖 1. HIỂN THỊ NỘI DUNG TRUYỆN
- **Đọc đa định dạng**: Hỗ trợ cả truyện tranh (comic) và truyện chữ (novel/epub)
- **2 chế độ đọc**:
  - **Chế độ dọc**: Scroll liên tục (như đọc web)
  - **Chế độ ngang**: Lật trang từng trang (như sách thật)
- **Tự động chia trang thông minh**: Chia nội dung thành trang phù hợp với kích thước màn hình
- **Chế độ toàn màn hình**: Ẩn AppBar để tập trung đọc

### 🎨 2. TÙY CHỈNH GIAO DIỆN ĐỌC
- **Kích thước font**: 8-30px (mặc định 16px)
- **Chiều cao dòng**: 1.0-3.0 (mặc định 1.6 - tối ưu cho mắt)
- **10+ Font chữ**: Roboto, Arial, Times New Roman, Georgia, Courier New, Verdana, Tahoma, Comic Sans MS, Palatino, Garamond
- **Màu sắc**: Tùy chỉnh màu nền và màu chữ
- **Lưu cài đặt**: Tự động lưu vào SharedPreferences

### 🔊 3. TEXT-TO-SPEECH (TTS) THÔNG MINH
- **Đa ngôn ngữ**: Ưu tiên tiếng Việt, fallback sang tiếng Anh
- **Điều khiển đầy đủ**: Play/Pause/Stop/Điều chỉnh tốc độ
- **Highlight đồng bộ**: Highlight đoạn văn đang được đọc
- **Tự động cuộn**: Cuộn theo tiến độ TTS
- **Chia đoạn thông minh**: Tự động chia văn bản thành đoạn phù hợp
- **Xử lý lỗi robust**: Tự động khôi phục khi có lỗi TTS

### 🔍 4. TÌM KIẾM NÂNG CAO
- **Tìm kiếm trong chương**: Tìm trong chương hiện tại
- **Tìm kiếm toàn cục**: Tìm trong tất cả chương của truyện
- **Highlight kết quả**: Highlight kết quả tìm kiếm với màu sắc
- **Navigation**: Điều hướng nhanh giữa các kết quả
- **Highlight tạm thời**: Tự động xóa sau 5 giây

### ✨ 5. HIGHLIGHT VÀ BOOKMARK
- **Highlight văn bản**: Đánh dấu đoạn văn quan trọng
- **Bookmark vị trí**: Lưu vị trí đọc hiện tại
- **Quản lý danh sách**: Xem, xóa, chỉnh sửa highlight/bookmark
- **Điều hướng nhanh**: Click để đi đến vị trí đã đánh dấu
- **Lưu trữ persistent**: Dữ liệu không bị mất khi đóng ứng dụng

### ⏬ 6. TỰ ĐỘNG CUỘN THÔNG MINH
- **Tốc độ điều chỉnh**: 5-300 pixels/giây (mặc định 80)
- **Chỉ cho chế độ dọc**: Không hoạt động ở chế độ đọc ngang
- **Điều khiển linh hoạt**: Play/Pause/Resume dễ dàng
- **Auto fullscreen**: Tự động chuyển fullscreen khi bật

### 📊 7. THEO DÕI TIẾN ĐỘ ĐỌC
- **Firebase Firestore**: Lưu tiến độ đọc trên cloud
- **Đồng bộ đa thiết bị**: Tiến độ được sync qua các thiết bị
- **Hiển thị phần trăm**: Hiển thị % đã đọc trong chương
- **Tiếp tục đọc**: Tự động mở vị trí cũ khi quay lại
- **Tối ưu lưu trữ**: Chỉ lưu khi có thay đổi đáng kể

### 💬 8. HỆ THỐNG BÌNH LUẬN
- **Bình luận theo chương**: Mỗi chương có bình luận riêng
- **Nested comments**: Hỗ trợ trả lời bình luận
- **Like/Dislike**: Đánh giá bình luận
- **Hiển thị số lượng**: Badge hiển thị số comment trong AppBar
- **Firebase integration**: Lưu trữ và đồng bộ real-time

### 🗂️ 9. QUẢN LÝ CACHE VÀ HIỆU NĂNG
- **Cache offline**: Cache nội dung để đọc không cần internet
- **Lazy loading**: Chỉ load nội dung khi cần
- **Memory management**: Tối ưu sử dụng RAM
- **Background processing**: Không block UI thread

### 🌍 10. DỊCH THUẬT
- **Popup translate**: Dịch văn bản được chọn
- **Đa ngôn ngữ**: Hỗ trợ dịch sang nhiều ngôn ngữ
- **Integration**: Tích hợp với dịch vụ dịch thuật

---

## 🔧 KIẾN TRÚC KỸ THUẬT

### 📁 Cấu trúc thư mục
```
lib/
├── pages/               # Các màn hình chính
│   ├── epub_chapter_page.dart    # Trang đọc truyện chính (5966 dòng)
│   ├── story_detail_page.dart    # Trang chi tiết truyện
│   ├── highlights_bookmarks_page.dart  # Quản lý highlight/bookmark
│   └── ...
├── services/            # Các service xử lý logic
│   ├── tts_service.dart          # Service TTS (944 dòng)
│   ├── reading_settings_service.dart  # Quản lý cài đặt
│   ├── reading_service.dart      # Quản lý tiến độ đọc
│   ├── chapter_cache_service.dart     # Cache chương
│   └── ...
├── components/          # Các widget tái sử dụng
│   ├── selectable_text_widget.dart    # Widget text có thể select
│   ├── translate_popup.dart      # Popup dịch thuật
│   └── info_book_widgets.dart/   # Widgets thông tin sách
├── models/              # Các model dữ liệu
│   ├── story.dart       # Model truyện
│   ├── highlight.dart   # Model highlight
│   ├── bookmark.dart    # Model bookmark
│   └── ...
└── api/                 # API calls
    └── otruyen_api.dart # API truyện
```

### 🏗️ Design Patterns
- **Singleton Pattern**: TTSService, ReadingSettingsService
- **StatefulWidget**: Quản lý state phức tạp
- **Service Layer**: Tách biệt logic nghiệp vụ
- **Observer Pattern**: Callback functions cho TTS
- **Factory Pattern**: Model creation

### 🔄 State Management
- **Local State**: StatefulWidget với setState
- **Persistent Storage**: SharedPreferences cho cài đặt
- **Cloud Storage**: Firebase Firestore cho tiến độ và comments
- **Memory Cache**: In-memory cache cho performance

### 🎯 Performance Optimizations
- **Lazy Loading**: Chỉ load khi cần
- **Text Chunking**: Chia text thành chunks nhỏ cho TTS
- **Image Caching**: Cache hình ảnh
- **Memory Management**: Proper dispose của controllers
- **Background Processing**: Non-blocking operations

---

## 📱 TRẢI NGHIỆM NGƯỜI DÙNG

### 🎨 UI/UX Features
- **Material Design**: Tuân thủ Material Design guidelines
- **Responsive**: Thích ứng với nhiều kích thước màn hình
- **Accessibility**: Hỗ trợ TTS cho người khiếm thị
- **Dark/Light Theme**: Tùy chỉnh màu sắc theo sở thích
- **Gesture Support**: Hỗ trợ các gesture cơ bản

### 🚀 Performance
- **Fast Loading**: Cache và lazy loading
- **Smooth Scrolling**: Tối ưu scroll performance
- **Memory Efficient**: Quản lý memory tốt
- **Battery Optimized**: Không drain pin không cần thiết

### 🔒 Reliability
- **Error Handling**: Xử lý lỗi gracefully
- **Offline Support**: Hoạt động offline với cache
- **Data Persistence**: Không mất dữ liệu khi app crash
- **Auto Recovery**: Tự động khôi phục TTS khi có lỗi

---

## 🎯 TARGET USERS

### 👥 Đối tượng sử dụng
- **Độc giả truyện chữ**: Người yêu thích đọc novel, light novel
- **Người khiếm thị**: Sử dụng TTS để "nghe" truyện
- **Học sinh, sinh viên**: Đọc tài liệu học tập
- **Người bận rộn**: Sử dụng TTS để nghe truyện khi di chuyển

### 💡 Use Cases
- **Đọc giải trí**: Đọc truyện tranh, tiểu thuyết
- **Học tập**: Đọc tài liệu, sách giáo khoa
- **Accessibility**: Hỗ trợ người khiếm thị
- **Multitasking**: Nghe truyện while doing other tasks

---

## 🚀 FUTURE ENHANCEMENTS

### 🔮 Tính năng có thể phát triển thêm
- **AI Reading Recommendations**: Gợi ý sách dựa trên sở thích
- **Social Features**: Chia sẻ quotes, đánh giá sách
- **Advanced Analytics**: Thống kê thời gian đọc, tốc độ đọc
- **Voice Control**: Điều khiển bằng giọng nói
- **Reading Groups**: Tạo nhóm đọc, thảo luận
- **Annotation System**: Ghi chú chi tiết hơn
- **Export Features**: Xuất highlights, notes
- **Integration với Learning Apps**: Kết nối với ứng dụng học tập

---

*📝 Tài liệu này được tạo để giúp các lập trình viên hiểu rõ về kiến trúc và tính năng của ứng dụng đọc truyện Flutter_BTL.* 