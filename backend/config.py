# config.py (trong thư mục gốc của dự án)

# --- Cấu hình Firebase ---
# Đường dẫn đến file JSON chứa khóa tài khoản dịch vụ Firebase
# QUAN TRỌNG: Cập nhật đường dẫn này để đúng với thư mục gốc của dự án
# Ví dụ: "scripts/your-firebase-service-account-key.json"
FIREBASE_SERVICE_ACCOUNT_KEY_PATH = "scripts/truyen-flutter-firebase-adminsdk-fbsvc-924eee2bd9.json"  # CẬP NHẬT ĐƯỜNG DẪN NÀY

# URL của Firebase Realtime Database
# Ví dụ: "https://your-project-id-default-rtdb.firebaseio.com/"
FIREBASE_REALTIME_DATABASE_URL = "https://truyen-flutter-default-rtdb.firebaseio.com/"  # CẬP NHẬT URL NÀY

# Node gốc trong Firebase Realtime Database nơi lưu trữ các mục thư viện
# Điều này tương ứng với FIRESTORE_COLLECTION trong cấu hình các script
FIREBASE_DB_ROOT_NODE = "library_items"

# --- Cấu hình Media ---
# URL cơ sở để truy cập media ebook (ảnh bìa, file epub) được lưu trữ cục bộ hoặc trên server riêng.
# Điều này được sử dụng để xây dựng URL đầy đủ cho các tài nguyên ebook trong phản hồi API.
# Ví dụ: "http://localhost:8000" hoặc "https://your-media-server.com"  
# Nếu là None, API có thể trả về đường dẫn tương đối hoặc placeholder cho media ebook.
LOCAL_MEDIA_SERVER_BASE_URL = "http://192.168.1.190:5000" # <<< CẬP NHẬT HOẶC ĐẶT THÀNH None

# Đường dẫn phụ cho ebooks trên media server, được sử dụng nếu LOCAL_MEDIA_SERVER_BASE_URL được thiết lập.
# Ví dụ: nếu base là "http://localhost:8000" và subpath là "ebooks",
# thì ảnh bìa có thể nằm tại "http://localhost:8000/ebooks/ebook-slug/cover.jpg"
EBOOKS_URL_SUBPATH = "ebooks"

# --- Cấu hình OTruyen API (cho các mục được lấy từ OTruyen) ---
# Được sử dụng để xây dựng URL thumbnail đầy đủ cho các truyện tranh được lấy từ OTruyen
OTRUYEN_CDN_IMAGE_DOMAIN = "https://img.otruyenapi.com"

# Số mục mặc định trên mỗi trang cho phân trang
DEFAULT_ITEMS_PER_PAGE = 24 