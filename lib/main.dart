import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/health_repository.dart';
import 'viewmodels/health_view_model.dart';
import 'views/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => HealthViewModel(HealthRepository(), preferences)..load(),
      child: const HealthMateApp(),
    ),
  );
}

class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key});
  @override
  Widget build(BuildContext context) {
    final mode = context.watch<HealthViewModel>().themeMode;
    ThemeData theme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: brightness,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? const Color(0xFF102A43)
            : const Color(0xFFEAF3FF),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
    return MaterialApp(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
