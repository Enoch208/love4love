// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import, strict_top_level_inference, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:love4love/main_app_screen.dart';
import 'package:love4love/profile_screen.dart';
import 'package:love4love/route/auth_guard.dart';
import 'package:love4love/services/notification_service.dart';
import 'package:love4love/splash_screen.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/auth_guard.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification services
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Love4Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Inter',
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.pages,
    );
  }
}

// Defining Routes properly
abstract class Routes {
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const MAIN = '/main';
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const SETTINGS = '/settings';
}

// Defining AppPages correctly
class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashScreen()),
    GetPage(name: Routes.LOGIN, page: () => const AuthScreen()),
    GetPage(name: Routes.SIGNUP, page: () => const AuthScreen()),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainAppScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(name: Routes.HOME, page: () => const HomeScreen()),
    GetPage(name: Routes.PROFILE, page: () => const ProfileScreen()),
    GetPage(name: Routes.SETTINGS, page: () => const SettingsScreen()),
  ];
}

// Corrected screen implementations
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Auth Screen')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Home Screen')));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Settings Screen')));
  }
}
