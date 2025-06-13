# 🚀 Hướng dẫn sử dụng hệ thống Cache trong Flutter App

## 📋 Tổng quan

Hệ thống cache của app được thiết kế để:
- **Giảm thời gian load** dữ liệu 
- **Tiết kiệm băng thông** Internet
- **Cải thiện trải nghiệm** người dùng
- **Hoạt động offline** cơ bản

## 🎯 Các loại cache đã implement:

### 1. **Trang chủ (Home)** ✅
- **Cache duration**: 10 phút
- **File**: `lib/cubit/home_cubit.dart`
- **Cách dùng**:
```dart
final homeCubit = context.read<HomeCubit>();
await homeCubit.loadData(); // Auto cache
homeCubit.refresh(); // Force refresh
```

### 2. **Search Results** ✅
- **Cache duration**: 5 phút
- **File**: `lib/cubit/search_cubit.dart`
- **Cách dùng**:
```dart
final searchCubit = context.read<SearchCubit>();
await searchCubit.searchStories("tên truyện");
searchCubit.searchWithRefresh("tên truyện"); // Force refresh
```

### 3. **Categories (Thể loại)** ✅
- **Cache duration**: 60 phút (1 giờ)
- **File**: `lib/cubit/categories_cubit.dart`
- **Cách dùng**:
```dart
final categoriesCubit = context.read<CategoriesCubit>();
await categoriesCubit.loadData(); // Auto cache
categoriesCubit.refresh(); // Force refresh
```

### 4. **Story Detail** ✅
- **Cache duration**: 30 phút
- **File**: `lib/cubit/story_detail_cubit.dart`
- **Cách dùng**:
```dart
final detailCubit = context.read<StoryDetailCubit>();
await detailCubit.loadStoryDetail("story-slug");
detailCubit.refreshStoryDetail("story-slug"); // Force refresh
```

## 🛠 Cách tạo cache cho chức năng mới:

### Bước 1: Extend CacheableCubit

```dart
import 'package:btl/cubit/cacheable_cubit.dart';

class YourFeatureCubit extends CacheableCubit<YourDataType> {
  @override
  String get cacheKey => 'your_feature_key';

  @override
  String get dataType => 'your_feature'; // Phải match với CacheService._cacheDurations

  @override
  Future<YourDataType> fetchFromApi() async {
    // API call logic here
    return await YourApi.getData();
  }

  @override
  YourDataType? parseFromCache(dynamic cachedData) {
    try {
      if (cachedData is Map<String, dynamic>) {
        return YourDataType.fromJson(cachedData);
      }
    } catch (e) {
      print('Error parsing cache: $e');
    }
    return null;
  }
}
```

### Bước 2: Thêm cache duration cho dataType mới

Mở `lib/services/cache_service.dart` và thêm vào `_cacheDurations`:

```dart
static const Map<String, int> _cacheDurations = {
  'home': 10,
  'categories': 60,  
  'story_detail': 30,
  'search': 5,
  'chapters': 120,
  'user_prefs': -1,
  'your_feature': 15, // ← Thêm dòng này
};
```

### Bước 3: Tạo Data Model với serialization

```dart
class YourDataType {
  final String id;
  final String name;
  // ... other fields

  YourDataType({required this.id, required this.name});

  // Bắt buộc phải có toJson() để cache
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Bắt buộc phải có fromJson() để restore từ cache
  factory YourDataType.fromJson(Map<String, dynamic> json) {
    return YourDataType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
```

### Bước 4: Thêm vào BlocProvider trong main.dart

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => HomeCubit()),
    BlocProvider(create: (context) => SearchCubit()),
    BlocProvider(create: (context) => StoryDetailCubit()),
    BlocProvider(create: (context) => YourFeatureCubit()), // ← Thêm dòng này
  ],
  child: MyApp(),
)
```

### Bước 5: Sử dụng trong Widget

```dart
class YourFeaturePage extends StatefulWidget {
  @override
  _YourFeaturePageState createState() => _YourFeaturePageState();
}

class _YourFeaturePageState extends State<YourFeaturePage> {
  @override
  void initState() {
    super.initState();
    // Load data khi trang mở
    context.read<YourFeatureCubit>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Feature')),
      body: BlocBuilder<YourFeatureCubit, CacheableState<YourDataType>>(
        builder: (context, state) {
          if (state is CacheableLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is CacheableLoaded<YourDataType>) {
            return _buildContent(state.data);
          } else if (state is CacheableError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          return Center(child: Text('Chưa có dữ liệu'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh data
          context.read<YourFeatureCubit>().refresh();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent(YourDataType data) {
    return ListView(
      children: [
        Text('ID: ${data.id}'),
        Text('Name: ${data.name}'),
        // ... other content
      ],
    );
  }
}
```

## 🎛 Cache Management Commands:

### Clear cache theo loại:
```dart
await CacheService.clearDataByType('search'); // Xóa tất cả search cache
await CacheService.clearDataByType('story_detail'); // Xóa tất cả story detail cache
```

### Clear tất cả cache:
```dart
await CacheService.clearAllCache();
```

### Check cache info:
```dart
final info = await CacheService.getCacheInfo('home_comics');
print('Cache age: ${info?['ageMinutes']} minutes');
print('Is expired: ${info?['isExpired']}');
```

## ⚙️ Các thiết lập cache hiện tại:

| Data Type | Duration | Mô tả |
|-----------|----------|-------|
| `home` | 10 phút | Trang chủ truyện tranh/tiểu thuyết |
| `categories` | 60 phút | Danh sách thể loại |
| `story_detail` | 30 phút | Chi tiết truyện |
| `search` | 5 phút | Kết quả tìm kiếm |
| `chapters` | 120 phút | Danh sách chương |
| `user_prefs` | Không hết hạn | Tùy chọn người dùng |

## 🎉 Ưu điểm của hệ thống:

1. **Generic Pattern**: Tái sử dụng cho mọi feature
2. **Type Safe**: Sử dụng Generic types
3. **Auto Expire**: Tự động xóa cache cũ
4. **Offline Support**: Hoạt động khi mất mạng
5. **Smart Loading**: Load từ cache trước, API sau
6. **Easy Debug**: Log chi tiết cho dev

## 🚨 Lưu ý quan trọng:

1. **Luôn implement toJson() và fromJson()** cho data models
2. **Thêm dataType vào _cacheDurations** trước khi dùng  
3. **Handle errors** trong parseFromCache()
4. **Test offline mode** để đảm bảo cache hoạt động
5. **Không cache data nhạy cảm** (passwords, tokens)

## 📱 Test Cache:

1. **Load data lần đầu** → Thấy API call trong log
2. **Load data lần 2** → Thấy "Cache hit" trong log
3. **Tắt mạng và mở app** → Data vẫn hiển thị từ cache
4. **Đợi hết cache duration** → API call lại

---

**🎯 Kết quả**: App sẽ load nhanh hơn, tiết kiệm data và hoạt động tốt ngay cả khi mạng yếu! 