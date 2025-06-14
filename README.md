# Ứng Dụng Đọc Truyện Flutter

Ứng dụng đọc truyện tranh và truyện chữ (ebook) được phát triển bằng Flutter với backend Python Flask, tích hợp Firebase Realtime Database.

## Tính Năng Chính

### Frontend (Flutter)
- Ứng dụng di động trên Android
- Đọc truyện tranh và ebook EPUB
- Tìm kiếm và phân loại theo thể loại
- Giao diện đọc thân thiện
- Hỗ trợ chế độ sáng/tối
- Lưu trữ lịch sử đọc

### Backend (Python Flask)
- API RESTful server
- Tích hợp Firebase Realtime Database
- Xử lý file EPUB (phục vụ cho việc đọc mục lục, nội dung chương)
- Phục vụ file media (ảnh bìa, file EPUB)
- API tìm kiếm
- Quản lý dữ liệu truyện tranh và ebook

## Cấu Trúc Dự Án

```
flutter_btl/
├── backend/                    # Backend Python Flask
│   ├── config.py              # Cấu hình Firebase và Media
│   ├── otruyen_api_server.py  # Main API server
│   └── requirements.txt       # Python dependencies
├── flutter/                   # Frontend Flutter
│   ├── lib/                  # Source code Flutter dự án
│   │   ├── api/             # API client
│   │   ├── components/      # Phụ thuộc
│   │   ├── models/         # Models
│   │   ├── pages/          # Màn hình/Pages
│   │   └── services/       # Dịch vụ hỗ trợ
│   ├── assets/             # Tài nguyên hệ thống (images, icons)
│   └── pubspec.yaml       # Flutter dependencies
└── README.md              # Readme file
```

## 🛠️ Yêu Cầu Hệ Thống

### Backend
- Python 3.8+
- Firebase Admin SDK
- Flask và các thư viện liên quan

### Frontend
- Flutter SDK 3.0+
- Dart SDK
- Android Studio / VS Code

## Cài Đặt

### 1. Clone Repository
```bash
git clone <repository-url>
cd flutter_btl
```

### 2. Cài Đặt Backend

#### a. Tạo Virtual Environment (khuyến nghị)
```bash
cd backend
python -m venv venv

# Windows
.\venv\Scripts\activate.bat # Active môi trường ảo
```

#### b. Cài đặt Dependencies
```bash
pip install -r requirements.txt
```

#### c. Cấu hình Firebase
1. Tạo project trên [Firebase Console](https://console.firebase.google.com/)
2. Tạo Realtime Database
3. Tải service account key JSON
4. Cập nhật đường dẫn vào file `config.py`:

```python
# Đường dẫn đến file service account key
FIREBASE_SERVICE_ACCOUNT_KEY_PATH = "path/to/your-firebase-key.json"

# URL Realtime Database
FIREBASE_REALTIME_DATABASE_URL = "https://your-project-default-rtdb.firebaseio.com/"

# URL cho media
LOCAL_MEDIA_SERVER_BASE_URL = "http://localhost:5000"
```

#### d. Tạo thư mục Media
```bash
media/ebooks
```

### 3. Cài Đặt Frontend

```bash
cd flutter
flutter pub get # Tải các thư viện
```

## Chạy Ứng Dụng

### 1. Khởi động Backend
```bash
cd backend
python otruyen_api_server.py
```
Server sẽ chạy tại: `http://localhost:5000`

### 2. Chạy Flutter App
```bash
cd flutter
flutter run
```

## API Endpoints

### Thông tin API (Dựa vào API OTruyen)
- **Base URL**: `http://localhost:5000`
- **Phiên bản**: `v1`

### Endpoints chính

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/` | Thông tin API server |
| GET | `/v1/api/home` | Danh sách truyện trang chủ |
| GET | `/v1/api/danh-sach/{type}` | Danh sách theo loại |
| GET | `/v1/api/the-loai` | Danh sách thể loại |
| GET | `/v1/api/the-loai/{slug}` | Truyện theo thể loại |
| GET | `/v1/api/truyen-tranh/{slug}` | Chi tiết truyện |
| GET | `/v1/api/truyen-chu/{slug}` | Nội dung truyện chữ |
| GET | `/v1/api/truyen-chu/{slug}/muc-luc` | Mục lục EPUB |
| GET | `/v1/api/truyen-chu/{slug}/chuong/{number}` | Đọc chương EPUB |
| GET | `/v1/api/tim-kiem` | Tìm kiếm |
| GET | `/ebooks/{slug}/{filename}` | Phục vụ file media |

### Ví dụ sử dụng API

#### Lấy danh sách trang chủ
```bash
curl "http://localhost:5000/v1/api/home?page=1"
```

#### Tìm kiếm truyện
```bash
curl "http://localhost:5000/v1/api/tim-kiem?keyword=naruto&page=1"
```

#### Đọc chương EPUB
```bash
curl "http://localhost:5000/v1/api/truyen-chu/ten-truyen/chuong/1"
```

## Cấu Hình Firebase

### 1. Cấu trúc Database
```json
{
  "library_items": {
    "comic_slug-name": {
      "itemType": "comic",
      "name": "Tên truyện",
      "slug": "slug-name",
      "thumb_url": "cover.jpg (ảnh bìa)",
      "category": [...],
      "chapters": [...],
      "status": "ongoing|completed (đang phát hành/hoàn thành)",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    },
    "ebook_slug-name": {
      "itemType": "ebook",
      "name": "Tên ebook",
      "slug": "slug-name",
      "localCoverFilename": "cover.jpg  (ảnh bìa)",
      "localEpubFilename": "book.epub (file epub)",
      "status": "completed (trạng thái truyện)",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

### 2. Security Rules (Cập nhật trong rule trên Firebase)
```json
{
  "rules": {
    "library_items": {
      ".read": true,
      ".write": false
    }
  }
}
```

### 3. Indexing Rules
```json
{
  "rules": {
    "library_items": {
      ".indexOn": ["itemType", "status", "createdAt", "updatedAt"]
    }
  }
}
```

## Quản Lý EPUB

### Cấu trúc thư mục EPUB
```
media/ebooks/
├── truyen-1/
│   ├── cover.jpg
│   └── truyen-1.epub
├── truyen-2/
│   ├── cover.png
│   └── truyen-2.epub
```

### Tính năng EPUB
- Đọc mục lục (TOC) tự động
- Trích xuất nội dung chương
- Chuyển đổi HTML thành text thuần túy để phục vụ cho flutter
- Hỗ trợ ảnh bìa

## Flutter Development

### Cấu trúc Flutter
- **API Layer**: Xử lý HTTP requests
- **Models**: Data models cho truyện, chương, ...
- **Services**: Dịch vụ
- **Components**: UI components tái sử dụng
- **Pages**: Các màn hình chính

### Dependencies chính
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.5
  cached_network_image: ^3.2.3
  provider: ^6.0.5
  shared_preferences: ^2.0.18
  ...
```

## Các lỗi thường gặp

### Backend
1. **Firebase connection error**
   - Kiểm tra service account key path
   - Kiểm tra Firebase project URL
   - Kiểm tra kết nối mạng

2. **EPUB reading error**
   - Kiểm tra định dạng file EPUB

3. **Media serving error**
   - Kiểm tra cấu hình config.py

### Flutter
1. **API connection error**
   - Kiểm tra backend hoạt động chưa
   - Kiểm tra cấu hình đường dẫn baseUrl
   - Kiểm tra kết nối mạng

2. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check SDK versions (phải > 23.)

## Build APK

### Android APK
```bash
cd flutter
flutter build apk --release
```

## Team

- **Nhóm 07** - Ứng dụng đọc truyện.
1.	Vũ Văn Tín	MSSV: 2221050564
2.	Đặng Trí Dũng	MSSV: 2221050407
3.	Phạm Quốc Cường	MSSV: 2221050012
4.	Phạm Hồng Đạt	MSSV: 2221050470

---

**Ghi chú**: Đây là dự án học tập. 