import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/books_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LecturaApp());
}

class LecturaApp extends StatelessWidget {
  const LecturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );
    final displayTheme = GoogleFonts.playfairDisplayTextTheme(
      Theme.of(context).textTheme,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Lectura',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD4A853),
            brightness: Brightness.dark,
          ),
          textTheme: textTheme.copyWith(
            headlineSmall: displayTheme.headlineSmall,
            titleLarge: displayTheme.titleLarge,
            titleMedium: displayTheme.titleMedium,
            titleSmall: displayTheme.titleSmall,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            elevation: 4,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
