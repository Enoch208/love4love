// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:love4love/main_app_screen.dart';
import 'package:email_validator/email_validator.dart';

class RegistrationPage extends StatefulWidget {
  final VoidCallback onToggle;

  const RegistrationPage({super.key, required this.onToggle});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _register() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final dob = _dobController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || dob.isEmpty || _selectedGender == null) {
      _showMessageBox(context, 'Por favor completa todos los campos.');
      return;
    }

    if (!EmailValidator.validate(email)) {
      _showMessageBox(context, 'Por favor ingresa un correo electrónico válido.');
      return;
    }

    if (password != confirmPassword) {
      _showMessageBox(context, 'Las contraseñas no coinciden.');
      return;
    }

    if (password.length < 6) {
      _showMessageBox(context, 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainAppScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña es demasiado débil.';
          break;
        case 'email-already-in-use':
          message = 'Ya existe una cuenta con ese correo electrónico.';
          break;
        default:
          message = 'Error al registrarse: ${e.message}';
      }
      _showMessageBox(context, message);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessageBox(context, 'Ocurrió un error inesperado: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡Únete a Love4Love!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE5397C)),
            ),
            const SizedBox(height: 8),
            Text('Cuéntanos un poco sobre ti.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),

            _buildTextField(controller: _fullNameController, hint: 'Nombre completo', icon: Icons.person_outline),
            const SizedBox(height: 16),

            _buildTextField(controller: _emailController, hint: 'Correo electrónico', icon: Icons.email_outlined, inputType: TextInputType.emailAddress),
            const SizedBox(height: 16),

            _buildTextField(controller: _passwordController, hint: 'Contraseña', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),

            _buildTextField(controller: _confirmPasswordController, hint: 'Confirmar contraseña', icon: Icons.lock_reset_outlined, obscure: true),
            const SizedBox(height: 16),

            _buildDateField(context),
            const SizedBox(height: 16),

            _buildGenderDropdown(),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Registrar Ahora'),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _isLoading ? null : widget.onToggle,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '¿Ya tienes una cuenta? ',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  children: const [
                    TextSpan(
                      text: '¡Inicia Sesión!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextField(
      controller: _dobController,
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.pink),
              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.pink)),
            ),
            child: child!,
          ),
        );
        if (pickedDate != null) {
          _dobController.text = pickedDate.toLocal().toString().split(' ')[0];
        }
      },
      decoration: const InputDecoration(
        hintText: 'Fecha de nacimiento',
        prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.pinkAccent),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        hintText: 'Seleccionar género',
        prefixIcon: Icon(Icons.wc_outlined, color: Colors.pinkAccent),
      ),
      items: ['Femenino', 'Masculino', 'No binario', 'Prefiero no decir']
          .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
          .toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }

  void _showMessageBox(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Información'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
