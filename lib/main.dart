import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:btl/cubit/home_cubit.dart';
import 'package:btl/cubit/categories_cubit.dart';
import 'package:btl/models/pages/Intropage/intro_page.dart';
import 'package:btl/models/pages/info_book.dart';
import 'package:btl/models/pages/search_page.dart';
import 'package:btl/models/pages/categories_page.dart';
import 'package:btl/theme/dark_theme.dart';
import 'package:btl/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()..loadTheme()),
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => CategoriesCubit()),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final mode = state is LightTheme ? ThemeMode.light : ThemeMode.dark;
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: IntroPage(),
          routes: {
            '/infopage': (context) => Info(),
            '/search': (context) => const SearchPage(),
            '/categories': (context) => const CategoriesPage(),
          },
        );
      },
    );
  }
}
