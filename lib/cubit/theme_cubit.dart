import 'package:bloc/bloc.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(InitialTheme());

  void lightThemeEvent() async {
    emit(LightTheme());
    saveTheme(LightTheme());
  }

  void darkThemeEvent() async {
    emit(DarkTheme());
    saveTheme(DarkTheme());
  }

  Future<void> saveTheme(ThemeState mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode is LightTheme ? 'light' : 'dark');
  }

  Future<void> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('themeMode') == 'light') {
      emit(LightTheme());
    } else if (prefs.getString('themeMode') == 'dark') {
      emit(DarkTheme());
    }
  }
}
