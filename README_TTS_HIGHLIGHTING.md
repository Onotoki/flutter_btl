# TTS Highlighting & Auto-Scroll Feature

## Tính năng mới: Làm nổi bật văn bản và tự động cuộn khi đọc TTS

### Mô tả
Khi sử dụng tính năng Text-to-Speech (TTS), ứng dụng sẽ:
1. **Tự động làm nổi bật** đoạn văn bản đang được đọc
2. **Tự động cuộn** để đảm bảo văn bản đang đọc luôn hiển thị trong khung nhìn

### Cách hoạt động

1. **Bật TTS**: Nhấn vào icon 🔊 trên thanh công cụ
2. **Bắt đầu đọc**: Nhấn nút play ▶️ trong panel điều khiển TTS
3. **Theo dõi**: 
   - Đoạn văn bản đang được đọc sẽ được highlight với màu xanh dương nhạt + gạch chân
   - Màn hình sẽ tự động cuộn để giữ văn bản đang đọc ở giữa khung nhìn

### Tính năng highlighting

- **Màu nền**: Xanh dương nhạt (opacity 0.3)
- **Gạch chân**: Màu xanh dương, độ dày 2.0px
- **Ưu tiên**: TTS highlight có độ ưu tiên cao nhất khi có nhiều highlight cùng lúc

### Tính năng auto-scroll

#### Chế độ đọc dọc (Vertical Reading)
- Tự động cuộn để đưa văn bản đang đọc về vị trí 30% từ trên xuống màn hình
- Animation mượt mà với thời gian 800ms
- Sử dụng curve `Curves.easeInOutCubic` để tạo hiệu ứng tự nhiên

#### Chế độ đọc ngang (Horizontal Reading) 
- Tự động chuyển đến trang chứa đoạn văn đang được đọc
- Animation chuyển trang với thời gian 500ms
- Chỉ chuyển trang khi cần thiết (không ở trang hiện tại)

### Cài đặt TTS

Trong menu **Cài đặt TTS** (nhấn biểu tượng ⚙️), bạn có thể điều chỉnh:

1. **Ngôn ngữ**: Chọn ngôn ngữ đọc (tiếng Việt, tiếng Anh, v.v.)
2. **Tốc độ**: Điều chỉnh tốc độ đọc (0.0 - 1.0)
3. **Độ cao**: Điều chỉnh độ cao giọng nói (0.5 - 2.0)
4. **Tự động cuộn**: Bật/tắt tính năng tự động cuộn ✨ **MỚI**
5. **Nghe thử**: Test các cài đặt hiện tại

### Cải tiến kỹ thuật

#### SelectableTextWidget
- Thêm parameters `ttsHighlightStart` và `ttsHighlightEnd`
- Hỗ trợ nhiều loại highlight đồng thời với hệ thống type-based
- System ưu tiên: TTS highlight > Temp highlight > User highlight

#### EpubChapterPage
- `_updateTTSHighlighting()`: Tính toán vị trí highlight + trigger auto-scroll
- `_autoScrollToTTSPosition()`: Điều phối auto-scroll cho cả 2 chế độ đọc
- `_scrollToTTSPositionInVerticalMode()`: Auto-scroll thông minh cho chế độ dọc
- `_navigateToTTSPositionInHorizontalMode()`: Auto-navigate cho chế độ ngang
- `_getPageRelativeTTSHighlight()`: Chuyển đổi vị trí highlight cho từng trang

#### Settings Integration
- Biến `_ttsAutoScrollEnabled`: Điều khiển bật/tắt auto-scroll
- Lưu vào TTS Settings modal với toggle switch
- Default: enabled (bật sẵn)

### Trải nghiệm người dùng

#### ✅ **Tối ưu hóa**
1. **Perfect Sync**: Highlight và auto-scroll hoàn toàn đồng bộ với âm thanh
2. **Smooth Animation**: Cuộn mượt mà không gây choáng váng
3. **Smart Positioning**: Đưa text về vị trí tối ưu trên màn hình
4. **User Control**: Có thể tắt auto-scroll nếu không muốn
5. **Mode-Aware**: Hoạt động khác nhau tùy theo chế độ đọc

#### 🎯 **Positioning Logic**
- **Vertical**: Text đang đọc xuất hiện ở 30% từ trên xuống
- **Horizontal**: Tự động chuyển đến trang chứa text đang đọc
- **Fallback**: Nếu không tìm thấy vị trí chính xác, sử dụng fuzzy matching

### Test Scenarios

1. **Basic Highlighting**: ✅ Highlight xuất hiện/biến mất đúng cách
2. **Paragraph Navigation**: ✅ Highlight + scroll di chuyển theo paragraph
3. **Vertical Auto-scroll**: ✅ Cuộn mượt mà đến vị trí đúng
4. **Horizontal Auto-navigation**: ✅ Chuyển trang tự động khi cần
5. **Settings Toggle**: ✅ Bật/tắt auto-scroll hoạt động
6. **Error Handling**: ✅ Clear highlight khi có lỗi TTS
7. **Performance**: ✅ Không lag khi cuộn/highlight nhiều

### Debug & Monitoring

Tất cả actions đều có detailed logging với prefix `🔊`:
```
🔊 _updateTTSHighlighting called with index: 2
🔊 Looking for paragraph: "Đây là đoạn văn đầu tiên..."
🔊 TTS highlight set: 245-389
🔊 _autoScrollToTTSPosition called: 245-389
🔊 TTS Auto-scroll: ratio=0.15, target=120.5, max=800.0
```

### Performance Notes

- Sử dụng `clamp()` để đảm bảo indices luôn trong phạm vi hợp lệ
- Debounced highlighting để tránh update quá nhiều
- Lazy calculation - chỉ tính toán khi cần thiết
- Memory-efficient: clear highlight khi không sử dụng 