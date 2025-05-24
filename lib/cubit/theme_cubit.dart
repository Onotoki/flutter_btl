import 'package:bloc/bloc.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(LightTheme()) {
    loadTheme(); // Load theme ngay khi khởi tạo
  }

  void toggleTheme() async {
    if (state is LightTheme) {
      await darkThemeEvent();
    } else {
      await lightThemeEvent();
    }
  }

  Future<void> lightThemeEvent() async {
    emit(LightTheme());
    await saveTheme(LightTheme());
  }

  Future<void> darkThemeEvent() async {
    emit(DarkTheme());
    await saveTheme(DarkTheme());
  }

  Future<void> saveTheme(ThemeState mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode is LightTheme ? 'light' : 'dark');
  }

  Future<void> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String themeMode = prefs.getString('themeMode') ?? 'light'; // Mặc định là 'light' nếu không có giá trị
    if (themeMode == 'light') {
      emit(LightTheme());
    } else {
      emit(DarkTheme());
    }
  }
}