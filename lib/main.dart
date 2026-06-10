import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/books_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/nav_controller.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CloudReadApp());
}

class CloudReadApp extends StatelessWidget {
  const CloudReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Concrete storage implementation chosen here, so the rest of the app
    // only ever sees the abstract `FavoritesStorage`. Swap this single line
    // to migrate to a different backend.
    final favoritesStorage = SharedPreferencesFavoritesStorage();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              FavoritesProvider(storage: favoritesStorage)..loadFavorites(),
        ),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) => MaterialApp(
          title: 'CloudRead',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.mode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
