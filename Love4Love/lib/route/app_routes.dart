// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  static const SPLASH = '/splash'; // More explicit route name
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const MAIN = '/main';
  
  // Additional routes for future scalability
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const SETTINGS = '/settings';
  static const NOTIFICATIONS = '/notifications';
}