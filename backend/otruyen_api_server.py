"""
OTruyen API Server với tích hợp Firebase
Tham khảo triển khai các API endpoints của OTruyen, lấy dữ liệu từ Firebase Realtime Database.
Máy chủ API cho ứng dụng đọc truyện tranh và ebook trực tuyến.
"""

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, db
import json
import os
from pathlib import Path
import re

# Import thư viện để xử lý EPUB
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup
import zipfile

# Thử import file cấu hình từ thư mục gốc
try:
    import config
except ImportError:
    print("LỖI NGHIÊM TRỌNG: Không tìm thấy config.py trong thư mục gốc của dự án.")
    print("Vui lòng tạo file config.py với cài đặt Firebase và Media.")
    exit(1)

app = Flask(__name__)
CORS(app)  # Kích hoạt CORS cho tất cả các domain

# Định nghĩa thư mục gốc cho các file media (ví dụ: project_root/media)
MEDIA_ROOT_DIR = Path(__file__).resolve().parent / "media"

# --- Khởi tạo Firebase ---
try:
    # Đảm bảo đường dẫn là tuyệt đối hoặc tương đối chính xác so với thư mục thực thi script.
    # Nếu run_server.py ở thư mục gốc, và config.py cũng ở thư mục gốc,
    # và FIREBASE_SERVICE_ACCOUNT_KEY_PATH là tương đối so với gốc (ví dụ: "scripts/key.json"),
    # thì điều này sẽ hoạt động.
    key_path = Path(config.FIREBASE_SERVICE_ACCOUNT_KEY_PATH)
    if not key_path.is_absolute():
        key_path = Path(__file__).resolve().parent / key_path # Làm cho nó tương đối với thư mục script này nếu không phải tuyệt đối
        # Đối với run_server.py, nếu nó ở gốc, key_path có thể cần là Path.cwd() / config.FIREBASE_SERVICE_ACCOUNT_KEY_PATH

    if not key_path.exists():
        print(f"LỖI NGHIÊM TRỌNG: Không tìm thấy Firebase service account key tại đường dẫn đã phân giải: {key_path}")
        print(f"Vui lòng kiểm tra FIREBASE_SERVICE_ACCOUNT_KEY_PATH trong config.py: {config.FIREBASE_SERVICE_ACCOUNT_KEY_PATH}")
        exit(1)

    cred = credentials.Certificate(str(key_path))
    firebase_admin.initialize_app(cred, {
        'databaseURL': config.FIREBASE_REALTIME_DATABASE_URL
    })
    print("Firebase Admin SDK đã được khởi tạo thành công.")
    FB_DB = db.reference(config.FIREBASE_DB_ROOT_NODE)
except Exception as e:
    print(f"LỖI NGHIÊM TRỌNG: Không thể khởi tạo Firebase Admin SDK: {e}")
    print("Kiểm tra thông tin xác thực Firebase và URL cơ sở dữ liệu trong config.py.")
    exit(1)
# --- Kết thúc khởi tạo Firebase ---

def construct_thumb_url(item_data):
    """Xây dựng URL thumbnail đầy đủ dựa trên loại item."""
    if not isinstance(item_data, dict):
        return ""

    item_type = item_data.get("itemType")
    slug = item_data.get("slug", "")

    if item_type == "ebook":
        cover_filename = item_data.get("localCoverFilename")
        # Nếu Flask server chính là media server
        if config.LOCAL_MEDIA_SERVER_BASE_URL and config.LOCAL_MEDIA_SERVER_BASE_URL.startswith(("http://localhost", "http://127.0.0.1")):
            # URL sẽ tương đối với server root, được xây dựng bởi route
            # Ví dụ: /ebooks/slug-name/cover.jpg
            if cover_filename and slug:
                 return f"/{config.LOCAL_MEDIA_SERVER_BASE_URL}/{slug}/{cover_filename}"
        # Đối với external media server
        elif config.LOCAL_MEDIA_SERVER_BASE_URL and cover_filename and slug:
            return f"{config.LOCAL_MEDIA_SERVER_BASE_URL}/{config.EBOOKS_URL_SUBPATH}/{slug}/{cover_filename}"
        elif cover_filename: # Trả về đường dẫn tương đối nếu không có base URL và không self-hosted
            return f"{config.EBOOKS_URL_SUBPATH}/{slug}/{cover_filename}"
        return "" # Placeholder hoặc rỗng nếu không có cover
    elif item_type == "comic": # Mặc định hoặc 'comic'
        thumb = item_data.get("thumb_url") # Đây phải là filename từ OTruyen
        if thumb:
            return f"{config.OTRUYEN_CDN_IMAGE_DOMAIN}/uploads/comics/{thumb}"
        return ""
    return "" # Mặc định cho các loại không xác định

def format_item_for_response(item_data_tuple):
    """Định dạng một item (key, data) từ Firebase cho API response, thêm thumb_url đầy đủ."""
    if not item_data_tuple or not isinstance(item_data_tuple, tuple) or len(item_data_tuple) != 2:
        return None
    
    key, data = item_data_tuple
    if not isinstance(data, dict):
        return None

    # Đảm bảo các trường cơ bản được có mặt, thêm 'id' nếu sử dụng Firebase key làm ID
    if '_id' not in data:
        data['_id'] = key # Sử dụng Firebase key nếu _id bị thiếu

    # Xây dựng thumb_url đầy đủ
    data['thumb_url_full'] = construct_thumb_url(data) # URL đầy đủ cho client
    
    # Để nhất quán với JSON gốc, đảm bảo 'thumb_url' chỉ là filename cho comics
    if data.get("itemType") == "comic" and data.get("thumb_url", "").startswith("http"):
        data["thumb_url"] = data["thumb_url"].split("/")[-1]
    elif data.get("itemType") == "ebook":
        # Đối với ebooks, thumb_url có thể là localCoverFilename hoặc đường dẫn tương đối được xây dựng
        data["thumb_url"] = data.get("localCoverFilename", "")


    # Đảm bảo 'category' và 'chaptersLatest' là lists, ngay cả khi rỗng, để khớp với cấu trúc OTruyen
    data['category'] = data.get('category', [])
    
    # Mô phỏng 'chaptersLatest': lấy chapter cuối cùng nếu 'chapters' tồn tại
    if 'chapters' in data and isinstance(data['chapters'], list) and data['chapters']:
        last_server_chapters = data['chapters'][-1].get('server_data', [])
        if last_server_chapters:
            data['chaptersLatest'] = [last_server_chapters[-1]]
        else:
            data['chaptersLatest'] = []
    else:
        data['chaptersLatest'] = []
        
    return data

def get_all_items_from_firebase(limit=None, order_by_child=None, start_at_key=None, item_type_filter=None):
    """Lấy tất cả items từ Firebase, với filtering tùy chọn và hỗ trợ phân trang cơ bản."""
    try:
        query = FB_DB
        if order_by_child:
            query = query.order_by_child(order_by_child)
        else:
            query = query.order_by_key() # Sắp xếp mặc định theo key

        if start_at_key:
            query = query.start_at(start_at_key)
        
        if limit:
            # Firebase limit_to_first/last lấy N items.
            # Nếu start_at được sử dụng, chúng ta có thể cần lấy limit + 1 để biết có trang tiếp theo không,
            # nhưng để đơn giản, chỉ lấy 'limit'.
            query = query.limit_to_first(limit)
            
        results = query.get()

        if not results:
            return []

        items = []
        # Firebase trả về dict khi được sắp xếp theo key/child, hoặc list nếu không có order_by (ít phổ biến cho collections)
        if isinstance(results, dict):
            for key, value in results.items():
                if isinstance(value, dict): # Đảm bảo value là một dict
                    if item_type_filter and value.get("itemType") != item_type_filter:
                        continue
                    items.append(format_item_for_response((key, value)))
        return [item for item in items if item is not None]
    except Exception as e:
        print(f"Lỗi khi lấy dữ liệu từ Firebase: {e}")
        return []

@app.route('/')
def index():
    """Endpoint thông tin API"""
    return jsonify({
        "name": "OTruyen API Server (Firebase Edition)",
        "version": "1.2.0",
        "description": "Máy chủ API cho dữ liệu manga/comic, được hỗ trợ bởi Firebase Realtime Database.",
        "endpoints": {
            "/v1/api/home": "Danh sách truyện trang chủ (truyện tranh & ebook mới nhất)",
            "/v1/api/danh-sach/{type}": "Danh sách item theo trạng thái/loại (ví dụ: truyen-moi, ebook-moi)",
            "/v1/api/the-loai": "Danh sách thể loại (được lấy từ items)",
            "/v1/api/the-loai/{slug}": "Items theo slug thể loại",
            "/v1/api/truyen-tranh/{slug_or_id}": "Chi tiết item theo slug hoặc ID",
            "/v1/api/truyen-chu/{slug_or_id}": "Nội dung truyện chữ theo slug hoặc ID",
            "/v1/api/truyen-chu/{slug_or_id}/muc-luc": "Lấy mục lục EPUB",
            "/v1/api/truyen-chu/{slug_or_id}/chuong/{chapter_number}": "Đọc nội dung chương EPUB cụ thể",
            "/v1/api/tim-kiem": "Tìm kiếm items theo từ khóa",
            "/health": "Endpoint kiểm tra tình trạng",
            "/ebooks/{slug}/{filename}": "Phục vụ file media ebook"
        },
        "epub_features": {
            "description": "Khả năng đọc EPUB",
            "supported_operations": [
                "Trích xuất mục lục từ file EPUB",
                "Đọc nội dung từng chương",
                "Phân tích nội dung HTML thành văn bản thuần túy",
                "Điều hướng giữa các chương",
                "Phục vụ ảnh bìa và file EPUB"
            ]
        }
    })

@app.route('/v1/api/home')
def get_home():
    """
    Lấy items trang chủ.
    Đối với Firebase RTDB, 'home' thường có nghĩa là các items mới nhất.
    Chúng ta sẽ lấy comics và ebooks mới nhất theo 'updatedAt' hoặc 'createdAt' nếu có,
    ngược lại theo key (thứ tự chèn).
    """
    page = request.args.get('page', 1, type=int)
    per_page = config.DEFAULT_ITEMS_PER_PAGE

    # Lấy items mới nhất - RTDB sắp xếp theo 'updatedAt' cần indexing để có hiệu suất.
    # Hiện tại, chúng ta sắp xếp theo 'createdAt' nếu nó tồn tại, giả định nó là timestamp hoặc ISO string.
    # Ngược lại, theo key (thường theo thứ tự thời gian cho auto-IDs).
    all_items_raw = FB_DB.order_by_child("createdAt").limit_to_last(100).get() # Lấy một tập lớn hơn và sắp xếp/phân trang trong app
    
    all_items = []
    if isinstance(all_items_raw, dict):
        # Items từ limit_to_last thường theo thứ tự tăng dần, nên đảo ngược để giảm dần (mới nhất trước)
        for key, value in reversed(list(all_items_raw.items())):
            if isinstance(value, dict):
                 formatted = format_item_for_response((key,value))
                 if formatted:
                    all_items.append(formatted)

    start_index = (page - 1) * per_page
    end_index = start_index + per_page
    paginated_items = all_items[start_index:end_index]

    return jsonify({
        "status": "success",
        "message": "",
        "data": {
            "seoOnPage": {"titleHead": "Trang chủ - Truyện mới cập nhật"}, # Placeholder SEO
            "items": paginated_items,
            "params": {
                "pagination": {
                    "totalItems": len(all_items),
                    "totalItemsPerPage": per_page,
                    "currentPage": page,
                    "pageRanges": 5, # Placeholder
                    "totalPages": (len(all_items) + per_page - 1) // per_page
                }
            },
            "APP_DOMAIN_FRONTEND": "http://localhost:3000", # Ví dụ
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/danh-sach/<string:type_slug>')
def get_comic_list(type_slug):
    """
    Get item list by type/status.
    'truyen-moi' -> latest comics (itemType: comic)
    'hoan-thanh' -> completed comics/ebooks
    'ebook-moi' -> latest ebooks (itemType: ebook)
    'dang-phat-hanh' -> ongoing comics/ebooks
    """
    page = request.args.get('page', 1, type=int)
    per_page = config.DEFAULT_ITEMS_PER_PAGE

    query = FB_DB.order_by_child("updatedAt") # Requires .indexOn in Firebase rules for "updatedAt"

    all_items_raw = query.get()
    all_items = []

    if isinstance(all_items_raw, dict):
        # Sort by updatedAt timestamp in descending order (newest first)
        # Firebase returns dict, convert to list of tuples and sort
        sorted_items_tuples = sorted(all_items_raw.items(), key=lambda item: item[1].get("updatedAt", ""), reverse=True)

        for key, value in sorted_items_tuples:
            if not isinstance(value, dict):
                continue

            formatted_item = format_item_for_response((key, value))
            if not formatted_item:
                continue

            match = False
            if type_slug == "truyen-moi" and formatted_item.get("itemType") == "comic":
                match = True # Assuming "truyen-moi" are latest comics
            elif type_slug == "ebook-moi" and formatted_item.get("itemType") == "ebook":
                match = True
            elif type_slug == "hoan-thanh" and formatted_item.get("status") == "completed":
                match = True
            elif type_slug == "dang-phat-hanh" and formatted_item.get("status") == "ongoing":
                match = True
            elif type_slug == "sap-ra-mat": # 'coming_soon' status
                 if formatted_item.get("status") == "coming_soon":
                    match = True
            
            if match:
                all_items.append(formatted_item)

    start_index = (page - 1) * per_page
    end_index = start_index + per_page
    paginated_items = all_items[start_index:end_index]
    
    title_page = type_slug.replace("-", " ").title()

    return jsonify({
        "status": "success",
        "data": {
            "titlePage": title_page,
            "items": paginated_items,
            "params": {
                "type_slug": type_slug,
                "pagination": {
                    "totalItems": len(all_items),
                    "totalItemsPerPage": per_page,
                    "currentPage": page,
                    "pageRanges": 5,
                     "totalPages": (len(all_items) + per_page - 1) // per_page
                }
            },
            "APP_DOMAIN_FRONTEND": "http://localhost:3000",
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/the-loai')
def get_categories():
    """
    Get list of unique comic categories from all items in Firebase.
    This can be slow on large datasets without pre-aggregation.
    """
    all_items_raw = FB_DB.order_by_key().get() # Get all items
    
    categories = {} # Use a dict to store unique categories by slug
    if isinstance(all_items_raw, dict):
        for key, value in all_items_raw.items():
            if isinstance(value, dict) and "category" in value and isinstance(value["category"], list):
                for cat_info in value["category"]:
                    if isinstance(cat_info, dict) and "slug" in cat_info and "name" in cat_info:
                        categories[cat_info["slug"]] = {
                            "_id": cat_info.get("id", cat_info["slug"]), # Use 'id' if present, else slug
                            "slug": cat_info["slug"],
                            "name": cat_info["name"]
                        }
    
    return jsonify({
        "status": "success",
        "message": "",
        "data": {"items": list(categories.values())}
    })

@app.route('/v1/api/the-loai/<string:slug>')
def get_category_comics(slug):
    """Get items by category slug."""
    page = request.args.get('page', 1, type=int)
    per_page = config.DEFAULT_ITEMS_PER_PAGE

    # Firebase RTDB doesn't directly support querying array_contains for categories.
    # We need to fetch all items and filter in the application.
    # This is NOT performant for large datasets.
    # For better performance, you'd typically denormalize data or use a search service.
    
    all_items_raw = FB_DB.order_by_key().get() # Get all items
    filtered_items = []

    category_name = slug.replace("-", " ").title() # For display

    if isinstance(all_items_raw, dict):
        for key, value in all_items_raw.items():
            if isinstance(value, dict) and "category" in value and isinstance(value["category"], list):
                for cat_info in value["category"]:
                    if isinstance(cat_info, dict) and cat_info.get("slug") == slug:
                        formatted = format_item_for_response((key, value))
                        if formatted:
                            filtered_items.append(formatted)
                        break # Found in this item's categories
    
    # Sort results (e.g., by updatedAt, default by key implicitly)
    filtered_items.sort(key=lambda x: x.get("updatedAt", ""), reverse=True)


    start_index = (page - 1) * per_page
    end_index = start_index + per_page
    paginated_items = filtered_items[start_index:end_index]

    return jsonify({
        "status": "success",
        "data": {
            "titlePage": category_name,
            "items": paginated_items,
            "params": {
                "type_slug": "the-loai",
                "slug": slug,
                "pagination": {
                    "totalItems": len(filtered_items),
                    "totalItemsPerPage": per_page,
                    "currentPage": page,
                    "pageRanges": 5,
                    "totalPages": (len(filtered_items) + per_page - 1) // per_page
                }
            },
            "APP_DOMAIN_FRONTEND": "http://localhost:3000",
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/truyen-tranh/<string:slug_or_id>')
def get_comic_details(slug_or_id):
    """
    Get item details by its slug or Firebase key (_id).
    Firebase keys for comics are like "comic_{slug}" and for ebooks "ebook_{slug}".
    """
    # Try fetching by direct key first (if _id is passed)
    item_data = FB_DB.child(slug_or_id).get()

    if not item_data or not isinstance(item_data, dict):
        # If not found by direct key, try to find by slug.
        # This requires iterating or specific indexing if not using prefixed keys.
        # Assuming keys are "comic_SLUG" or "ebook_SLUG"
        possible_keys = [f"comic_{slug_or_id}", f"ebook_{slug_or_id}"]
        for p_key in possible_keys:
            item_data = FB_DB.child(p_key).get()
            if item_data and isinstance(item_data, dict):
                break # Found
    
    if not item_data or not isinstance(item_data, dict):
        return jsonify({"status": "error", "message": "Truyện không tìm thấy"}), 404

    # Use the key it was found with if _id is not in the data
    # This part is a bit tricky as we don't know which key was successful if iterating
    # Best if slug_or_id is the actual Firebase key.
    # For simplicity, we assume item_data now holds the correct data.
    
    # If item_data's key isn't slug_or_id, it means we found it via a prefixed key.
    # We need the original key for format_item_for_response if _id isn't in item_data.
    # This logic is simplified; a robust solution would pass the actual Firebase key.
    
    # For now, if _id is missing in item_data, we can't reliably determine the key here
    # unless slug_or_id *was* the key.
    # This assumes format_item_for_response can handle item_data without a key tuple.
    # Let's try to reconstruct a semblence of the key for format_item_for_response
    # This is a placeholder for a more robust key retrieval if slug_or_id is not the key.
    
    effective_key = slug_or_id # Assume slug_or_id might be the key.
    if '_id' not in item_data: # If the item itself doesn't have an _id field
         # Try to determine key if found by slug
        prefix = "comic_" if item_data.get("itemType") == "comic" else "ebook_"
        if slug_or_id == item_data.get("slug"): # if slug_or_id was indeed a slug
             effective_key = prefix + slug_or_id

    formatted_item = format_item_for_response((effective_key, item_data))

    if not formatted_item:
         return jsonify({"status": "error", "message": "Lỗi xử lý dữ liệu truyện"}), 500

    return jsonify({
        "status": "success",
        "message": "",
        "data": {
            "item": formatted_item,
            "APP_DOMAIN_FRONTEND": "http://localhost:3000",
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/tim-kiem')
def search_comics():
    """
    Search items by keyword in name or origin_name.
    This is a basic client-side-like search by fetching all and filtering.
    NOT performant for large Firebase RTDB datasets.
    Requires indexing on Firebase or a dedicated search solution for performance.
    """
    keyword = request.args.get('keyword', '').lower()
    page = request.args.get('page', 1, type=int)
    per_page = config.DEFAULT_ITEMS_PER_PAGE

    if not keyword:
        return jsonify({"status": "error", "message": "Keyword parameter is required"}), 400

    all_items_raw = FB_DB.order_by_key().get()
    search_results = []

    if isinstance(all_items_raw, dict):
        for key, value in all_items_raw.items():
            if isinstance(value, dict):
                name = value.get("name", "").lower()
                origin_name_list = value.get("origin_name", [])
                if isinstance(origin_name_list, list):
                    origin_names = " ".join(origin_name_list).lower()
                else:
                    origin_names = ""
                
                # Simple search
                if keyword in name or keyword in origin_names:
                    formatted = format_item_for_response((key,value))
                    if formatted:
                        search_results.append(formatted)
    
    # Sort results (e.g., by relevance if implemented, or name)
    search_results.sort(key=lambda x: x.get("name", ""))


    start_index = (page - 1) * per_page
    end_index = start_index + per_page
    paginated_items = search_results[start_index:end_index]
    
    return jsonify({
        "status": "success",
        "data": {
            "titlePage": f"Tìm kiếm: {keyword}",
            "items": paginated_items,
            "params": {
                "keyword": keyword,
                "pagination": {
                    "totalItems": len(search_results),
                    "totalItemsPerPage": per_page,
                    "currentPage": page,
                    "pageRanges": 5,
                    "totalPages": (len(search_results) + per_page - 1) // per_page
                }
            },
            "APP_DOMAIN_FRONTEND": "http://localhost:3000",
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/truyen-chu/<string:slug_or_id>')
def get_text_story_content(slug_or_id):
    """
    Get text story content by its slug or Firebase key (_id).
    Returns both metadata and content chapters.
    """
    # Try fetching by direct key first (if _id is passed)
    item_data = FB_DB.child(slug_or_id).get()

    if not item_data or not isinstance(item_data, dict):
        # If not found by direct key, try to find by slug.
        possible_keys = [f"ebook_{slug_or_id}", f"text_story_{slug_or_id}"]
        for p_key in possible_keys:
            item_data = FB_DB.child(p_key).get()
            if item_data and isinstance(item_data, dict):
                slug_or_id = p_key  # Update to use the found key
                break # Found
    
    if not item_data or not isinstance(item_data, dict):
        return jsonify({"status": "error", "message": "Truyện chữ không tìm thấy"}), 404

    # Check if this is actually a text-based story
    if item_data.get("itemType") not in ["ebook", "text_story"]:
        return jsonify({"status": "error", "message": "Đây không phải là truyện chữ"}), 400

    formatted_item = format_item_for_response((slug_or_id, item_data))

    if not formatted_item:
        return jsonify({"status": "error", "message": "Lỗi xử lý dữ liệu truyện chữ"}), 500

    # Đối với ebook EPUB, đọc TOC từ file thực tế
    content_data = {
        "chapters": [],
        "content": "",
        "totalChapters": 0,
        "hasContent": False,
        "isEpub": False
    }
    
    if item_data.get("itemType") == "ebook" and item_data.get("localEpubFilename"):
        # Đây là EPUB, đọc TOC từ file
        book_slug = item_data.get("slug", slug_or_id.replace("ebook_", ""))
        epub_filename = item_data.get("localEpubFilename")
        epub_file_path = MEDIA_ROOT_DIR / config.EBOOKS_URL_SUBPATH / book_slug / epub_filename
        
        if epub_file_path.exists():
            try:
                print(f"\n=== Xử lý EPUB cho {book_slug} ===")
                # Đọc TOC từ EPUB
                epub_chapters = get_epub_table_of_contents(str(epub_file_path))
                print(f"Đã nhận {len(epub_chapters)} chapters từ TOC")
                
                # Chuyển đổi sang format tương thích với client
                chapters_data = []
                chapter_counter = 1  # Đếm chapters thực sự
                
                for i, chapter in enumerate(epub_chapters):
                    print(f"  Converting chapter {i+1}: {chapter}")
                    
                    # Lọc bỏ các chapters không phải nội dung chính
                    title_lower = chapter['title'].lower()
                    href_lower = chapter['href'].lower()
                    
                    # Bỏ qua các chapters không phải nội dung chính
                    if any(skip_word in title_lower for skip_word in ['mục lục', 'toc', 'chào mừng', 'welcome', 'giới thiệu', 'introduction']):
                        print(f"    Skipping non-content chapter: {chapter['title']}")
                        continue
                    if any(skip_word in href_lower for skip_word in ['toc.html', 'welcome.html', 'intro.html']):
                        print(f"    Skipping non-content href: {chapter['href']}")
                        continue
                    
                    # Tạo chapter data với số thứ tự thực tế
                    chapter_data = {
                        "filename": f"Chapter {chapter_counter}",
                        "chapter_name": str(chapter_counter),  # Sử dụng counter thay vì order
                        "chapter_title": chapter['title'],
                        "chapter_api_data": f"/v1/api/truyen-chu/{book_slug}/chuong/{chapter['order']}"  # Vẫn sử dụng order gốc cho API
                    }
                    chapters_data.append(chapter_data)
                    print(f"    Result: {chapter_data}")
                    chapter_counter += 1
                
                print(f"Tạo được {len(chapters_data)} chapter data entries")
                
                content_data = {
                    "chapters": [{
                        "server_name": "EPUB Reader",
                        "server_data": chapters_data
                    }],
                    "content": f"Ebook EPUB với {len(epub_chapters)} chương. Sử dụng API endpoint để đọc từng chương.",
                    "totalChapters": len(epub_chapters),
                    "hasContent": len(epub_chapters) > 0,
                    "isEpub": True,
                    "epubInfo": {
                        "tocEndpoint": f"/v1/api/truyen-chu/{book_slug}/muc-luc",
                        "chapterEndpoint": f"/v1/api/truyen-chu/{book_slug}/chuong/{{chapter_number}}"
                    }
                }
                
                print(f"Final content_data structure:")
                print(f"  - totalChapters: {content_data['totalChapters']}")
                print(f"  - chapters[0]['server_data'] length: {len(content_data['chapters'][0]['server_data'])}")
                print(f"=== Kết thúc xử lý EPUB ===\n")
            except Exception as e:
                print(f"Lỗi đọc EPUB TOC: {e}")
                # Fallback về dữ liệu cũ nếu có lỗi
                content_data = {
                    "chapters": formatted_item.get("chapters", []),
                    "content": formatted_item.get("content", ""),
                    "totalChapters": len(formatted_item.get("chapters", [])),
                    "hasContent": bool(formatted_item.get("content") or formatted_item.get("chapters")),
                    "isEpub": True,
                    "error": f"Không thể đọc EPUB: {str(e)}"
                }
        else:
            # File EPUB không tồn tại
            content_data = {
                "chapters": formatted_item.get("chapters", []),
                "content": "File EPUB không tồn tại trên server",
                "totalChapters": 0,
                "hasContent": False,
                "isEpub": True,
                "error": "File EPUB không tồn tại"
            }
    else:
        # Không phải EPUB hoặc không có file, sử dụng dữ liệu cũ
        content_data = {
            "chapters": formatted_item.get("chapters", []),
            "content": formatted_item.get("content", ""),
            "totalChapters": len(formatted_item.get("chapters", [])),
            "hasContent": bool(formatted_item.get("content") or formatted_item.get("chapters")),
            "isEpub": False
        }

    return jsonify({
        "status": "success",
        "message": "",
        "data": {
            "item": formatted_item,
            "content": content_data,
            "APP_DOMAIN_FRONTEND": "http://localhost:3000",
            "APP_DOMAIN_CDN_IMAGE": config.OTRUYEN_CDN_IMAGE_DOMAIN
        }
    })

@app.route('/v1/api/truyen-chu/<string:slug_or_id>/chuong/<int:chapter_number>')
def get_epub_chapter_content(slug_or_id, chapter_number):
    """
    Đọc nội dung chương cụ thể từ file EPUB.
    
    Args:
        slug_or_id: Slug hoặc ID của truyện
        chapter_number: Số thứ tự chương (bắt đầu từ 1)
    
    Returns:
        JSON với nội dung chương
    """
    # Tìm thông tin truyện từ Firebase
    item_data = FB_DB.child(slug_or_id).get()

    if not item_data or not isinstance(item_data, dict):
        # Thử tìm bằng prefix key
        possible_keys = [f"ebook_{slug_or_id}", f"text_story_{slug_or_id}"]
        for p_key in possible_keys:
            item_data = FB_DB.child(p_key).get()
            if item_data and isinstance(item_data, dict):
                slug_or_id = p_key
                break
    
    if not item_data or not isinstance(item_data, dict):
        return jsonify({"status": "error", "message": "Truyện không tìm thấy"}), 404

    # Kiểm tra đây có phải ebook không
    if item_data.get("itemType") != "ebook":
        return jsonify({"status": "error", "message": "Đây không phải là ebook EPUB"}), 400

    # Lấy đường dẫn file EPUB
    epub_filename = item_data.get("localEpubFilename")
    if not epub_filename:
        return jsonify({"status": "error", "message": "Không tìm thấy file EPUB"}), 404
    
    book_slug = item_data.get("slug", slug_or_id.replace("ebook_", ""))
    epub_file_path = MEDIA_ROOT_DIR / config.EBOOKS_URL_SUBPATH / book_slug / epub_filename
    
    if not epub_file_path.exists():
        return jsonify({"status": "error", "message": "File EPUB không tồn tại trên server"}), 404

    try:
        # Lấy TOC để tìm chapter theo số thứ tự
        all_chapters = get_epub_table_of_contents(str(epub_file_path))
        
        if not all_chapters:
            return jsonify({"status": "error", "message": "Không thể đọc mục lục EPUB"}), 500
        
        # Lọc ra các chapters thực sự là nội dung chính (giống logic ở endpoint khác)
        content_chapters = []
        for chapter in all_chapters:
            title_lower = chapter['title'].lower()
            href_lower = chapter['href'].lower()
            
            # Bỏ qua các chapters không phải nội dung chính
            if any(skip_word in title_lower for skip_word in ['mục lục', 'toc', 'chào mừng', 'welcome', 'giới thiệu', 'introduction']):
                continue
            if any(skip_word in href_lower for skip_word in ['toc.html', 'welcome.html', 'intro.html']):
                continue
            
            content_chapters.append(chapter)
        
        if chapter_number < 1 or chapter_number > len(content_chapters):
            return jsonify({
                "status": "error", 
                "message": f"Số chương không hợp lệ. Ebook này có {len(content_chapters)} chương nội dung"
            }), 400
        
        # Lấy chapter theo index (chapter_number - 1)
        target_chapter = content_chapters[chapter_number - 1]
        chapter_href = target_chapter['href']
        
        # Đọc nội dung chương
        chapter_content = read_epub_chapter_content(str(epub_file_path), chapter_href)
        
        if not chapter_content:
            return jsonify({"status": "error", "message": "Không thể đọc nội dung chương"}), 500
        
        return jsonify({
            "status": "success",
            "data": {
                "chapter": {
                    "number": chapter_number,
                    "title": chapter_content['title'] or target_chapter['title'],
                    "content": chapter_content['content'],
                    "html_content": chapter_content.get('html_content', ''),
                    "href": chapter_href
                },
                "story": {
                    "title": item_data.get("name", ""),
                    "slug": book_slug,
                    "totalChapters": len(content_chapters)
                },
                "navigation": {
                    "previousChapter": chapter_number - 1 if chapter_number > 1 else None,
                    "nextChapter": chapter_number + 1 if chapter_number < len(content_chapters) else None
                }
            }
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": f"Lỗi đọc EPUB: {str(e)}"}), 500

@app.route('/v1/api/truyen-chu/<string:slug_or_id>/muc-luc')
def get_epub_table_of_contents_api(slug_or_id):
    """
    Lấy mục lục (Table of Contents) của ebook EPUB.
    
    Args:
        slug_or_id: Slug hoặc ID của truyện
    
    Returns:
        JSON với danh sách chương
    """
    # Tìm thông tin truyện từ Firebase
    item_data = FB_DB.child(slug_or_id).get()

    if not item_data or not isinstance(item_data, dict):
        # Thử tìm bằng prefix key
        possible_keys = [f"ebook_{slug_or_id}", f"text_story_{slug_or_id}"]
        for p_key in possible_keys:
            item_data = FB_DB.child(p_key).get()
            if item_data and isinstance(item_data, dict):
                slug_or_id = p_key
                break
    
    if not item_data or not isinstance(item_data, dict):
        return jsonify({"status": "error", "message": "Truyện không tìm thấy"}), 404

    # Kiểm tra đây có phải ebook không
    if item_data.get("itemType") != "ebook":
        return jsonify({"status": "error", "message": "Đây không phải là ebook EPUB"}), 400

    # Lấy đường dẫn file EPUB
    epub_filename = item_data.get("localEpubFilename")
    if not epub_filename:
        return jsonify({"status": "error", "message": "Không tìm thấy file EPUB"}), 404
    
    book_slug = item_data.get("slug", slug_or_id.replace("ebook_", ""))
    epub_file_path = MEDIA_ROOT_DIR / config.EBOOKS_URL_SUBPATH / book_slug / epub_filename
    
    if not epub_file_path.exists():
        return jsonify({"status": "error", "message": "File EPUB không tồn tại trên server"}), 404

    try:
        # Lấy TOC từ file EPUB
        all_chapters = get_epub_table_of_contents(str(epub_file_path))
        
        if not all_chapters:
            return jsonify({"status": "error", "message": "Không thể đọc mục lục EPUB"}), 500
        
        # Lọc ra các chapters thực sự là nội dung chính
        content_chapters = []
        chapter_counter = 1
        
        for chapter in all_chapters:
            title_lower = chapter['title'].lower()
            href_lower = chapter['href'].lower()
            
            # Bỏ qua các chapters không phải nội dung chính
            if any(skip_word in title_lower for skip_word in ['mục lục', 'toc', 'chào mừng', 'welcome', 'giới thiệu', 'introduction']):
                continue
            if any(skip_word in href_lower for skip_word in ['toc.html', 'welcome.html', 'intro.html']):
                continue
            
            content_chapters.append({
                "number": chapter_counter,
                "title": chapter['title'],
                "href": chapter['href'],
                "original_order": chapter['order']  # Giữ lại order gốc để debug
            })
            chapter_counter += 1
        
        return jsonify({
            "status": "success",
            "data": {
                "story": {
                    "title": item_data.get("name", ""),
                    "slug": book_slug,
                    "totalChapters": len(content_chapters)
                },
                "chapters": content_chapters
            }
        })
        
    except Exception as e:
        return jsonify({"status": "error", "message": f"Lỗi đọc EPUB: {str(e)}"}), 500

@app.route('/health')
def health_check():
    """Endpoint kiểm tra tình trạng hệ thống"""
    return jsonify({"status": "healthy", "message": "OTruyen API Server (Firebase Edition) đang hoạt động"})

@app.errorhandler(404)
def not_found(error):
    """Xử lý lỗi 404"""
    return jsonify({"status": "error", "message": "Không tìm thấy endpoint"}), 404

@app.errorhandler(500)
def internal_error(error):
    app.logger.error(f"Lỗi Server: {error}", exc_info=True)
    return jsonify({"status": "error", "message": f"Lỗi server nội bộ: {error}"}), 500

# Route để phục vụ file media ebook
@app.route(f'/{config.EBOOKS_URL_SUBPATH}/<path:item_slug>/<path:filename>')
def serve_ebook_media(item_slug, filename):
    """
    Phục vụ các file liên quan đến ebook (như cover hoặc epubs) từ thư mục media.
    URL ví dụ: /ebooks/your-ebook-slug/cover.jpg
    Nó sẽ phục vụ: MEDIA_ROOT_DIR / EBOOKS_URL_SUBPATH / your-ebook-slug / filename
    """
    # Xây dựng đường dẫn đầy đủ đến thư mục cho ebook slug cụ thể
    # MEDIA_ROOT_DIR là "project_root/media"
    # config.EBOOKS_URL_SUBPATH là "ebooks"
    # Vậy, specific_ebook_dir là "project_root/media/ebooks/your-ebook-slug"
    specific_ebook_dir = MEDIA_ROOT_DIR / config.EBOOKS_URL_SUBPATH / item_slug
    # print(f"Đang cố gắng phục vụ: {filename} từ {specific_ebook_dir}") # Để debug
    if not specific_ebook_dir.exists() or not specific_ebook_dir.is_dir():
        # print(f"Không tìm thấy thư mục: {specific_ebook_dir}") # Để debug
        return jsonify({"status": "error", "message": "Không tìm thấy thư mục media ebook"}), 404
    
    try:
        return send_from_directory(directory=str(specific_ebook_dir.resolve()), path=filename)
    except FileNotFoundError:
        # print(f"Không tìm thấy file trong thư mục: {filename} trong {specific_ebook_dir}") # Để debug
        return jsonify({"status": "error", "message": "Không tìm thấy file media ebook"}), 404
    except Exception as e:
        # print(f"Lỗi phục vụ file: {e}") # Để debug
        app.logger.error(f"Lỗi phục vụ ebook media: {e}")
        return jsonify({"status": "error", "message": "Không thể phục vụ file media ebook"}), 500

def html_to_clean_text(html_content):
    """
    Chuyển đổi HTML thành text thuần túy với format đẹp.

    Args:
        html_content (str): Nội dung HTML

    Returns:
        str: Text thuần túy đã được format
    """
    from bs4 import BeautifulSoup
    import re

    soup = BeautifulSoup(html_content, 'html.parser')

    # Loại bỏ các thẻ không cần thiết
    for unwanted in soup(["script", "style", "nav", "header", "footer", "aside"]):
        unwanted.decompose()

    # Loại bỏ các link navigation
    for link in soup.find_all("a"):
        if link.get('href', '').startswith('#') or 'nav' in link.get('class', []):
            link.decompose()

    # Xử lý các thẻ heading - thêm line breaks và format
    for heading in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
        heading.insert_before('\n\n')
        heading.insert_after('\n')

    # Xử lý paragraphs
    for p in soup.find_all('p'):
        p.insert_after('\n\n')

    # Xử lý divs (chỉ nếu chứa text trực tiếp)
    for div in soup.find_all('div'):
        if div.get_text(strip=True) and not div.find(['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
            div.insert_after('\n')

    # Xử lý line breaks
    for br in soup.find_all('br'):
        br.replace_with('\n')

    # Xử lý lists
    for ul in soup.find_all(['ul', 'ol']):
        ul.insert_before('\n')
        ul.insert_after('\n')

    for li in soup.find_all('li'):
        li.insert_before('• ')
        li.insert_after('\n')

    # Xử lý blockquotes
    for blockquote in soup.find_all('blockquote'):
        blockquote.insert_before('\n"')
        blockquote.insert_after('"\n')

    # Lấy text
    text = soup.get_text()

    # Dọn dẹp text
    # Loại bỏ multiple spaces
    text = re.sub(r'[ \t]+', ' ', text)
    # Loại bỏ spaces ở đầu/cuối dòng
    text = re.sub(r'^ +| +$', '', text, flags=re.MULTILINE)
    # Giới hạn line breaks liên tiếp
    text = re.sub(r'\n{4,}', '\n\n\n', text)
    # Loại bỏ line breaks ở đầu và cuối
    text = text.strip()

    return text

def read_epub_chapter_content(epub_file_path, chapter_href):
    """
    Đọc nội dung chương từ file EPUB bằng href.
    
    Args:
        epub_file_path (str): Đường dẫn đến file EPUB
        chapter_href (str): Href của chương cần đọc (từ TOC)
    
    Returns:
        dict: {'content': str, 'title': str} hoặc None nếu lỗi
    """
    try:
        book = epub.read_epub(epub_file_path)
        
        # Tìm item dựa trên href
        target_item = None
        for item in book.get_items():
            if hasattr(item, 'get_name') and item.get_name() == chapter_href:
                target_item = item
                break
            # Thử cả file_name attribute
            if hasattr(item, 'file_name') and item.file_name == chapter_href:
                target_item = item
                break
        
        if not target_item:
            # Nếu không tìm thấy exact match, thử tìm partial match
            for item in book.get_items():
                item_name = getattr(item, 'file_name', '') or getattr(item, 'get_name', lambda: '')()
                if chapter_href in item_name or item_name in chapter_href:
                    target_item = item
                    break
        
        if not target_item:
            return None
            
        # Lấy nội dung và parse HTML
        content_bytes = target_item.get_content()
        content_html = content_bytes.decode('utf-8', errors='ignore')
        
        # Dùng BeautifulSoup để parse và lấy text
        soup = BeautifulSoup(content_html, 'html.parser')
        
        # Lấy title từ tag h1, h2, hoặc title
        title = ""
        for tag in ['h1', 'h2', 'h3', 'title']:
            title_elem = soup.find(tag)
            if title_elem:
                title = title_elem.get_text(strip=True)
                break
        
        # Sử dụng hàm helper để chuyển đổi HTML thành text thuần túy
        content_text = html_to_clean_text(content_html)
        
        return {
            'title': title,
            'content': content_text,
            'html_content': content_html  # Trả về cả HTML cho tùy chọn render
        }
        
    except Exception as e:
        print(f"Lỗi đọc chương EPUB {chapter_href} từ {epub_file_path}: {e}")
        return None

def get_epub_table_of_contents(epub_file_path):
    """
    Lấy mục lục (TOC) từ file EPUB.
    
    Returns:
        list: Danh sách chapters với format {'title': str, 'href': str, 'order': int}
    """
    try:
        print(f"\n=== Đang đọc TOC từ: {epub_file_path} ===")
        book = epub.read_epub(epub_file_path)
        chapters = []
        
        # Debug thông tin EPUB
        print(f"EPUB metadata:")
        print(f"  - Title: {book.get_metadata('DC', 'title')}")
        print(f"  - TOC structure type: {type(book.toc)}")
        print(f"  - TOC length: {len(book.toc) if hasattr(book.toc, '__len__') else 'Unknown'}")
        
        # Lấy TOC từ EPUB
        for i, item in enumerate(book.toc):
            print(f"  TOC item {i}: {type(item)} - {item}")
            if hasattr(item, 'title') and hasattr(item, 'href'):
                chapter_info = {
                    'title': item.title,
                    'href': item.href,
                    'order': i + 1
                }
                chapters.append(chapter_info)
                print(f"    Added chapter: {chapter_info}")
            else:
                print(f"    Skipped item (no title/href): {item}")
        
        print(f"Found {len(chapters)} chapters from TOC")
        
        # Nếu không có TOC, thử lấy từ spine (thứ tự đọc)
        if not chapters:
            print("No TOC found, trying spine...")
            print(f"Spine length: {len(book.spine)}")
            
            for i, item_id in enumerate(book.spine):
                print(f"  Spine item {i}: {item_id}")
                item = book.get_item_with_id(item_id[0])  # spine items are tuples
                if item and hasattr(item, 'get_name'):
                    item_name = item.get_name()
                    # Tạo title từ filename
                    title = os.path.splitext(os.path.basename(item_name))[0].replace('_', ' ').title()
                    chapter_info = {
                        'title': title,
                        'href': item_name,
                        'order': i + 1
                    }
                    chapters.append(chapter_info)
                    print(f"    Added spine chapter: {chapter_info}")
                else:
                    print(f"    Skipped spine item: {item}")
        
        print(f"=== Total chapters found: {len(chapters)} ===\n")
        return chapters
    except Exception as e:
        print(f"Lỗi lấy TOC từ {epub_file_path}: {e}")
        import traceback
        traceback.print_exc()
        return []

def test_html_to_text_conversion():
    """Hàm test để kiểm tra logic chuyển đổi HTML thành text"""
    test_html = """
    <html>
    <body>
        <h1>Chương 1: Khởi đầu</h1>
        <p>Đây là đoạn văn đầu tiên của chương. Nó chứa nhiều thông tin quan trọng.</p>
        <p>Đây là đoạn văn thứ hai. <br>Có line break ở giữa.</p>

        <h2>Phần 1.1</h2>
        <div>Nội dung trong div không có thẻ p.</div>

        <ul>
            <li>Mục thứ nhất</li>
            <li>Mục thứ hai</li>
        </ul>

        <blockquote>Đây là một trích dẫn quan trọng.</blockquote>

        <script>alert('test');</script>
        <style>.test { color: red; }</style>
    </body>
    </html>
    """

    result = html_to_clean_text(test_html)
    print("=== KIỂM TRA CHUYỂN ĐỔI HTML THÀNH TEXT ===")
    print("HTML đầu vào:")
    print(test_html)
    print("\nText đầu ra:")
    print(repr(result))
    print("\nOutput được format:")
    print(result)
    print("=== KẾT THÚC KIỂM TRA ===")

if __name__ == '__main__':
    # Kiểm tra chuyển đổi HTML thành text
    # test_html_to_text_conversion()

    # Đảm bảo thư mục media cho ebooks tồn tại (tùy chọn, script nên tạo nếu cần)
    ebook_media_path = MEDIA_ROOT_DIR / config.EBOOKS_URL_SUBPATH
    if not ebook_media_path.exists():
        print(f"Thông tin: Thư mục media ebook '{ebook_media_path}' không tồn tại. Nó có thể được tạo bởi script import EPUB của bạn.")
        # Bạn có thể tạo nó ở đây một cách tùy chọn:
        # ebook_media_path.mkdir(parents=True, exist_ok=True)
        # print(f"Thông tin: Đã tạo thư mục '{ebook_media_path}'.")

    print("Đang khởi động OTruyen API Server (Firebase Edition)...")
    print(f"Firebase Root Node: {config.FIREBASE_DB_ROOT_NODE}")
    print(f"API Docs (mô phỏng): http://localhost:5000/") # Root hiển thị thông tin cơ bản
    app.run(host='0.0.0.0', port=5000, debug=True)