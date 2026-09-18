import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'screens/splash_screen.dart';

class WaseemMedicalApp extends StatefulWidget {
  const WaseemMedicalApp({super.key});

  @override
  State<WaseemMedicalApp> createState() => _WaseemMedicalAppState();
}

class _WaseemMedicalAppState extends State<WaseemMedicalApp> {
  bool dark = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await DatabaseService.instance.initialize();
    dark = await SettingsService.instance.isDarkMode();
    if (mounted) setState(() {});
  }

  void toggleTheme() async {
    await SettingsService.instance.setDarkMode(!dark);
    setState(() => dark = !dark);
  }

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF0B7891);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وسيم ميديكال',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD7E2EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD7E2EA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF0B7891), width: 1.5),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        fontFamily: 'Arial',
      ),
      home: SplashScreen(onThemeChanged: toggleTheme),
    );
  }
}
