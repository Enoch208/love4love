// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:love4love/route/app_pages.dart';
import 'package:shimmer/shimmer.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onToggle;

  const LoginPage({super.key, required this.onToggle});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      /// ✅ Use GetX to navigate to main app screen
      Get.offAllNamed(Routes.MAIN);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No se encontró ningún usuario con ese correo electrónico.';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta para ese usuario.';
          break;
        case 'invalid-email':
          message = 'El formato del correo electrónico es inválido.';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada.';
          break;
        default:
          message = 'Error al iniciar sesión: ${e.message}';
      }
      _showMessageBox(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessageBox(context, 'Ocurrió un error inesperado: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: SizedBox(
              width: 140,
              height: 140,
              child: FutureBuilder(
                future: precacheImage(
                  const AssetImage('assets/love4love.jpeg'),
                  context,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 800),
                      child: Image.asset(
                        'assets/love4love.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _fallbackLogo();
                        },
                      ),
                    );
                  } else {
                    return Shimmer.fromColors(
                      baseColor: Colors.pink[100]!,
                      highlightColor: Colors.pink[50]!,
                      child: Container(color: Colors.pink[200]),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: 36.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE5397C),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Inicia sesión para encontrar a tu pareja perfecta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32.0),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.pinkAccent),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Contraseña',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.pinkAccent),
            ),
          ),
          const SizedBox(height: 12.0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _showMessageBox(context, 'Funcionalidad de "Restablecer Contraseña"');
              },
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Iniciar Sesión'),
            ),
          ),
          const SizedBox(height: 24.0),
          GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    /// Optional: Replace toggle with GetX route to signup
                    widget.onToggle(); // or Get.toNamed(Routes.SIGNUP)
                  },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '¿No tienes una cuenta? ',
                style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                children: const [
                  TextSpan(
                    text: '¡Regístrate con nosotros!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.pink[200],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.favorite, size: 60, color: Colors.pink[600]),
    );
  }

  void _showMessageBox(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text('Información'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
