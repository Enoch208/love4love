import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:love4love/route/app_pages.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Get.offAllNamed(Routes.MAIN); // To Discover after login
      } else {
        Get.offAllNamed(Routes.LOGIN);
      }
    });

    return const Scaffold(
      body: Center(
        child: Text(
          'Love4Love ❤️',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
