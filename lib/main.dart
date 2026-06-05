import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'screens/scan_screen.dart';
import 'screens/collection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness:
          Brightness.dark, // iOS usa Brightness (no IconBrightness)
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PokegameApp());
}

class PokegameApp extends StatelessWidget {
  const PokegameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokegame',
      debugShowCheckedModeBanner: false,
      // Scroll con física iOS
      scrollBehavior: const CupertinoScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFF4FC3F7),
        ),
        // Quita el splash de Material (se ve raro en iOS)
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const ScanScreen(),
        '/collection': (_) => const CollectionScreen(),
      },
    );
  }
}
