import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:btl/api/otruyen_api.dart';
import 'package:btl/models/story.dart';
import 'package:btl/utils/content_filter.dart';
import 'package:btl/services/cache_service.dart';

// States
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, List<Story>> comicCategories;
  final Map<String, List<Story>> novelCategories;
  final DateTime loadedAt;

  HomeLoaded({
    required this.comicCategories,
    required this.novelCategories,
    required this.loadedAt,
  });

  // Kiểm tra xem data có cần refresh không (ví dụ: sau 15 phút)
  bool get needsRefresh {
    final now = DateTime.now();
    final difference = now.difference(loadedAt);
    return difference.inMinutes > 15; // Refresh sau 15 phút
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

// Cubit
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  // Cache keys
  static const String _comicCacheKey = 'home_comics';
  static const String _novelCacheKey = 'home_novels';

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    try {
      // Kiểm tra cache trước khi load từ API
      if (!forceRefresh) {
        final cachedComics =
            await CacheService.getData<Map<String, dynamic>>(_comicCacheKey);
        final cachedNovels =
            await CacheService.getData<Map<String, dynamic>>(_novelCacheKey);

        if (cachedComics != null && cachedNovels != null) {
          print('Loading data from cache...');
          try {
            // Convert cached data back to proper format
            final comicCategories = _convertCachedDataToStories(cachedComics);
            final novelCategories = _convertCachedDataToStories(cachedNovels);

            // Verify that data is valid before emitting
            bool hasValidData = false;
            for (final stories in comicCategories.values) {
              if (stories.isNotEmpty &&
                  stories.any((s) => s.title != 'Error Loading Story')) {
                hasValidData = true;
                break;
              }
            }
            for (final stories in novelCategories.values) {
              if (stories.isNotEmpty &&
                  stories.any((s) => s.title != 'Error Loading Story')) {
                hasValidData = true;
                break;
              }
            }

            if (hasValidData) {
              print('Cache data is valid, using cached data');
              emit(HomeLoaded(
                comicCategories: comicCategories,
                novelCategories: novelCategories,
                loadedAt: DateTime.now(),
              ));
              return;
            } else {
              print(
                  'Cache data is invalid, clearing cache and loading from API');
              await clearCache();
            }
          } catch (e) {
            print('Error converting cached data: $e');
            await clearCache();
          }
        }
      }

      print('Loading data from API...');
      emit(HomeLoading());

      final Map<String, List<Story>> comicCategories = {
        'Truyện mới cập nhật': [],
        'Đang phát hành': [],
        'Hoàn thành': [],
        'Sắp ra mắt': []
      };

      final Map<String, List<Story>> novelCategories = {
        'Ebook mới': [],
        'Truyện chữ hoàn thành': [],
        'Truyện chữ đang phát hành': [],
      };

      // Load dữ liệu từ API
      await _loadComicData(comicCategories);
      await _loadNovelData(novelCategories);

      // Cache dữ liệu vào SharedPreferences
      await _saveToCache(comicCategories, novelCategories);

      emit(HomeLoaded(
        comicCategories: comicCategories,
        novelCategories: novelCategories,
        loadedAt: DateTime.now(),
      ));
    } catch (e) {
      print('Error in loadHomeData: $e');
      emit(HomeError('Không thể tải dữ liệu: $e'));
    }
  }

  Future<void> _saveToCache(
    Map<String, List<Story>> comicCategories,
    Map<String, List<Story>> novelCategories,
  ) async {
    try {
      // Convert stories to JSON-serializable format
      final comicCacheData = <String, List<Map<String, dynamic>>>{};
      final novelCacheData = <String, List<Map<String, dynamic>>>{};

      for (final entry in comicCategories.entries) {
        final jsonList = <Map<String, dynamic>>[];
        for (final story in entry.value) {
          try {
            jsonList.add(story.toJson());
          } catch (e) {
            print('Error converting story to JSON: $e');
          }
        }
        comicCacheData[entry.key] = jsonList;
      }

      for (final entry in novelCategories.entries) {
        final jsonList = <Map<String, dynamic>>[];
        for (final story in entry.value) {
          try {
            jsonList.add(story.toJson());
          } catch (e) {
            print('Error converting story to JSON: $e');
          }
        }
        novelCacheData[entry.key] = jsonList;
      }

      await CacheService.saveData(_comicCacheKey, comicCacheData,
          dataType: 'home');
      await CacheService.saveData(_novelCacheKey, novelCacheData,
          dataType: 'home');

      print('Successfully saved data to cache');
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Map<String, List<Story>> _convertCachedDataToStories(
      Map<String, dynamic> cachedData) {
    final result = <String, List<Story>>{};

    print('Converting cached data to stories...');

    for (final entry in cachedData.entries) {
      final stories = <Story>[];
      final categoryName = entry.key;

      if (entry.value is List) {
        final items = entry.value as List;
        print('Processing category: $categoryName with ${items.length} items');

        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item is Map<String, dynamic>) {
            try {
              // Add some debugging
              if (!item.containsKey('id') || !item.containsKey('title')) {
                print('Item $i missing required fields: ${item.keys}');
                continue;
              }

              // Create story directly from cached JSON without complex parsing
              final story = Story(
                id: item['id']?.toString() ?? '',
                title: item['title']?.toString() ?? 'Unknown Title',
                description: item['description']?.toString() ?? '',
                thumbnail: item['thumbnail']?.toString() ?? '',
                categories: (item['categories'] as List?)?.cast<String>() ?? [],
                status: item['status']?.toString() ?? 'Unknown',
                views: item['views'] as int? ?? 0,
                chapters: item['chapters'] as int? ?? 0,
                updatedAt: item['updatedAt']?.toString() ?? '',
                slug: item['slug']?.toString() ?? '',
                authors: (item['authors'] as List?)?.cast<String>() ?? [],
                chaptersData: item['chaptersData'] as List? ?? [],
                itemType: item['itemType']?.toString() ?? 'comic',
              );

              if (story.title != 'Unknown Title' && story.id.isNotEmpty) {
                stories.add(story);
              } else {
                print('Story $i has invalid data: ${story.title}');
              }
            } catch (e) {
              print('Error converting cached story $i in $categoryName: $e');
              print('Story data: $item');
            }
          } else {
            print('Item $i is not a Map: ${item.runtimeType}');
          }
        }
      } else {
        print(
            'Category $categoryName value is not a List: ${entry.value.runtimeType}');
      }

      result[categoryName] = stories;
      print(
          'Category $categoryName: converted ${stories.length} valid stories');
    }

    return result;
  }

  Future<void> _loadComicData(Map<String, List<Story>> comicCategories) async {
    // 1. Truyện mới cập nhật
    final newUpdateResult = await OTruyenApi.getNewlyUpdatedComics();
    List<Story> newlyUpdatedComics = _parseStoriesData(newUpdateResult);
    newlyUpdatedComics = ContentFilter.filterStories(newlyUpdatedComics);
    newlyUpdatedComics =
        newlyUpdatedComics.where((story) => story.isComic).toList();
    comicCategories['Truyện mới cập nhật'] = newlyUpdatedComics;

    // 2. Đang phát hành
    final ongoingResult = await OTruyenApi.getOngoingComics();
    List<Story> ongoingComics = _parseStoriesData(ongoingResult);
    ongoingComics = ContentFilter.filterStories(ongoingComics);
    ongoingComics = ongoingComics.where((story) => story.isComic).toList();
    comicCategories['Đang phát hành'] = ongoingComics;

    // 3. Hoàn thành
    final completedResult = await OTruyenApi.getCompletedComics();
    List<Story> completedComics = _parseStoriesData(completedResult);
    completedComics = ContentFilter.filterStories(completedComics);
    completedComics = completedComics.where((story) => story.isComic).toList();
    comicCategories['Hoàn thành'] = completedComics;

    // 4. Sắp ra mắt
    final upcomingResult = await OTruyenApi.getUpcomingComics();
    List<Story> upcomingComics = _parseStoriesData(upcomingResult);
    upcomingComics = ContentFilter.filterStories(upcomingComics);
    upcomingComics = upcomingComics.where((story) => story.isComic).toList();
    comicCategories['Sắp ra mắt'] = upcomingComics;
  }

  Future<void> _loadNovelData(Map<String, List<Story>> novelCategories) async {
    try {
      // 1. Ebook mới
      final newEbooksResult = await OTruyenApi.getNewlyUpdatedEbooks();
      List<Story> newlyUpdatedEbooks = _parseStoriesData(newEbooksResult);
      newlyUpdatedEbooks = ContentFilter.filterStories(newlyUpdatedEbooks);
      novelCategories['Ebook mới'] = newlyUpdatedEbooks;
    } catch (e) {
      novelCategories['Ebook mới'] = _createSampleEbooks();
    }

    // 2. Truyện chữ từ mục ongoing và completed
    final ongoingResult = await OTruyenApi.getOngoingComics();
    List<Story> ongoingStories = _parseStoriesData(ongoingResult);
    ongoingStories = ContentFilter.filterStories(ongoingStories);
    List<Story> ongoingNovels =
        ongoingStories.where((story) => story.isNovel).toList();
    novelCategories['Truyện chữ đang phát hành'] = ongoingNovels;

    final completedResult = await OTruyenApi.getCompletedComics();
    List<Story> completedStories = _parseStoriesData(completedResult);
    completedStories = ContentFilter.filterStories(completedStories);
    List<Story> completedNovels =
        completedStories.where((story) => story.isNovel).toList();
    novelCategories['Truyện chữ hoàn thành'] = completedNovels;
  }

  List<Story> _parseStoriesData(dynamic data) {
    List<Story> stories = [];
    try {
      if (data is Map && data.containsKey('items')) {
        final items = data['items'];
        if (items is List) {
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              try {
                stories.add(Story.fromJson(item));
              } catch (e) {
                print('Lỗi parse story: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Lỗi parse stories data: $e');
    }
    return stories;
  }

  List<Story> _createSampleEbooks() {
    return [
      Story(
        id: "sample-ebook-1",
        title: "Sample Ebook 1",
        description: "Sample description",
        thumbnail: "",
        slug: "sample-ebook-1",
        categories: [],
        status: "Hoàn thành",
        views: 0,
        chapters: 1,
        updatedAt: DateTime.now().toIso8601String(),
        itemType: "ebook",
      ),
      Story(
        id: "sample-ebook-2",
        title: "Sample Ebook 2",
        description: "Sample description",
        thumbnail: "",
        slug: "sample-ebook-2",
        categories: [],
        status: "Hoàn thành",
        views: 0,
        chapters: 1,
        updatedAt: DateTime.now().toIso8601String(),
        itemType: "ebook",
      ),
    ];
  }

  void refresh() {
    loadHomeData(forceRefresh: true);
  }

  Future<void> clearCache() async {
    await CacheService.clearData(_comicCacheKey);
    await CacheService.clearData(_novelCacheKey);
  }
}
