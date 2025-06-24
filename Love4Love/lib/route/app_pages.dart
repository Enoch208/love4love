// ignore: unused_import
// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';
import 'package:love4love/screens/login_page.dart'; // ✅ Corrected
import 'package:love4love/screens/registration_page.dart';
import 'package:love4love/main_app_screen.dart';
import 'package:love4love/notifications_screen.dart';
import 'package:love4love/route/auth_guard.dart';
import 'package:love4love/splash_screen.dart';

abstract class Routes {
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const MAIN = '/main';
  static const NOTIFICATIONS = '/notifications';
}

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final pages = [
    GetPage(name: Routes.SPLASH, page: () => const SplashScreen()),
    GetPage(name: Routes.LOGIN, page: () => LoginPage(onToggle: () {  },)), // ✅ FIXED
    GetPage(name: Routes.SIGNUP, page: () => RegistrationPage(onToggle: () {})),
    GetPage(
      name: Routes.MAIN,
      page: () => const MainAppScreen(),
      middlewares: [AuthGuard()],
    ),
    GetPage(name: Routes.NOTIFICATIONS, page: () => const NotificationsScreen()),
  ];
}
