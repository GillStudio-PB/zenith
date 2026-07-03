// This file defines the main entry point of the Dubai Worker application. It initializes the database, sets up the system UI, and runs the app with a custom theme and router configuration. The app uses Riverpod for state management and provides a visually appealing interface with a gradient background and image overlay.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db/database_service.dart';
import 'router.dart';

// Global Database Instance
late DatabaseService db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));

  db = DatabaseService();
  await db.init();

  runApp(const ProviderScope(child: DubaiWorkerApp()));
}

class DubaiWorkerApp extends StatelessWidget {
  const DubaiWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zenith',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0C29),
                    Color(0xFF302B63),
                    Color(0xFF0A0A0A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.7),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                // Return an empty container when image is not found, letting the gradient show behind
                return const SizedBox.shrink();
              },
            ),
            if (child != null) child,
          ],
        );
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor:
            Colors.transparent, // Let stack background show through
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Color(0xFF141414),
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Defaulting to a modern sans-serif concept
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
              letterSpacing: 1.2,
              color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.03),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    fontSize: 14))),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                textStyle: const TextStyle(letterSpacing: 1.2))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.02),
          labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.0),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.3))),
        ),
        dividerTheme: DividerThemeData(
            color: Colors.white.withValues(alpha: 0.05), thickness: 1),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
