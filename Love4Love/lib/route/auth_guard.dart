import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_pages.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}
