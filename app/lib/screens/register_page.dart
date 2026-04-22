import 'package:flutter/material.dart';
import 'package:stylee_app/auth/setup_profile_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({
    super.key,
    required this.onTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();
  bool _isLoading = false;

  void signUp() async {
    if (passwordTextController.text != confirmPasswordTextController.text) {
      _showError('Пароли не совпадают');
      return;
    }

    if (emailTextController.text.isEmpty || passwordTextController.text.isEmpty) {
      _showError('Заполните все поля');
      return;
    }

    if (passwordTextController.text.length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetupProfilePage(
            email: emailTextController.text.trim(),
            password: passwordTextController.text,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailTextController.dispose();
    passwordTextController.dispose();
    confirmPasswordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // logo
                Icon(
                  Icons.person_add_rounded,
                  size: 100,
                  color: Colors.pink.shade300,
                ),

                const SizedBox(height: 30),
                // title
                Text(
                  'Создать аккаунт',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Присоединяйтесь к Stylee',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),
                // email textfield
                TextField(
                  controller: emailTextController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.pink.shade300,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // password textfield
                TextField(
                  controller: passwordTextController,
                  obscureText: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.pink.shade300,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // confirm password textfield
                TextField(
                  controller: confirmPasswordTextController,
                  obscureText: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Подтвердите пароль',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.pink.shade300,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // sign up button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Продолжить',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                // login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Уже есть аккаунт?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _isLoading ? null : widget.onTap,
                      child: Text(
                        'Войти',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE91E63),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
