import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:btl/services/cache_service.dart';

// Các state chung cho tính năng cache
abstract class CacheableState<T> {}

// State khởi tạo - trạng thái ban đầu khi chưa có dữ liệu
class CacheableInitial<T> extends CacheableState<T> {}

// State đang tải - trạng thái khi đang fetch dữ liệu từ API
class CacheableLoading<T> extends CacheableState<T> {}

// State đã tải thành công - chứa dữ liệu và thời gian load
class CacheableLoaded<T> extends CacheableState<T> {
  final T data; // Dữ liệu được tải
  final DateTime loadedAt; // Thời gian load dữ liệu

  CacheableLoaded({
    required this.data,
    required this.loadedAt,
  });
}

// State lỗi - chứa thông báo lỗi khi có sự cố
class CacheableError<T> extends CacheableState<T> {
  final String message; // Thông báo lỗi
  CacheableError(this.message);
}

// Lớp Cubit trừu tượng cơ bản cho các tính năng có cache
abstract class CacheableCubit<T> extends Cubit<CacheableState<T>> {
  // Constructor khởi tạo với state ban đầu
  CacheableCubit() : super(CacheableInitial<T>());

  // Các phương thức trừu tượng cần được implement bởi lớp con
  String get cacheKey; // Key để lưu cache
  String get dataType; // Loại dữ liệu để hiển thị log
  Future<T> fetchFromApi(); // Phương thức fetch dữ liệu từ API
  T? parseFromCache(dynamic cachedData); // Phương thức parse dữ liệu từ cache

  // Phương thức chính để load dữ liệu (từ cache hoặc API)
  Future<void> loadData({bool forceRefresh = false}) async {
    try {
      // Kiểm tra cache trước khi gọi API
      if (!forceRefresh) {
        final cachedData = await CacheService.getData(cacheKey);

        if (cachedData != null) {
          print('Đang tải $dataType từ cache...');
          try {
            final data = parseFromCache(cachedData);

            if (data != null) {
              print('Dữ liệu cache hợp lệ cho $dataType');
              emit(CacheableLoaded<T>(
                data: data,
                loadedAt: DateTime.now(),
              ));
              return;
            }
          } catch (e) {
            print('Lỗi khi parse dữ liệu cache $dataType: $e');
            await CacheService.clearData(cacheKey);
          }
        }
      }

      print('Đang tải $dataType từ API...');
      emit(CacheableLoading<T>());

      // Tải dữ liệu từ API
      final data = await fetchFromApi();

      // Lưu dữ liệu vào cache
      await CacheService.saveData(cacheKey, data, dataType: dataType);

      emit(CacheableLoaded<T>(
        data: data,
        loadedAt: DateTime.now(),
      ));
    } catch (e) {
      print('Lỗi khi tải $dataType: $e');
      emit(CacheableError<T>('Không thể tải $dataType: $e'));
    }
  }

  // Phương thức refresh dữ liệu (bắt buộc tải từ API)
  void refresh() {
    loadData(forceRefresh: true);
  }

  // Phương thức xóa cache
  Future<void> clearCache() async {
    await CacheService.clearData(cacheKey);
  }
}
