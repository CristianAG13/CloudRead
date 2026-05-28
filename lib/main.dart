import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/books_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/nav_controller.dart';
import 'screens/home_shell.dart';
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
      ],
      child: MaterialApp(
        title: 'CloudRead',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeShell(),
      ),
    );
  }
}
