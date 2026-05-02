import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications (this will request permissions internally)
  await NotificationService.initialize();

  // Initialize theme service
  await ThemeService.init();

  runApp(const TaskEaseApp());
}

class TaskEaseApp extends StatefulWidget {
  const TaskEaseApp({super.key});

  @override
  State<TaskEaseApp> createState() => _TaskEaseAppState();
}

class _TaskEaseAppState extends State<TaskEaseApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    ThemeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: ThemeService.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
