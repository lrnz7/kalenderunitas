import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  final String _adminPassword = "unitas2025";
  bool _isLoading = false;

  void _login() async {
    final password = _passwordController.text.trim();
    
    if (password == _adminPassword) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      Navigator.pushReplacementNamed(
        context, 
        '/main',
        arguments: true, // Admin mode
      );
    } else if (password.isEmpty) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      
      Navigator.pushReplacementNamed(
        context, 
        '/main',
        arguments: false, // User mode
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password salah!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066CC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            width: 400,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Image.asset(
                    'assets/images/logo_unitas.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.calendar_month,
                        size: 60,
                        color: Color(0xFF0066CC),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 25),

                // Title
                const Text(
                  'KALENDER UNITAS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066CC),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Sistem Informasi 2025-2026',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 30),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Admin',
                    labelStyle: const TextStyle(color: Color(0xFF0066CC)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF0066CC)),
                    hintText: 'Kosongkan untuk user biasa',
                    hintStyle: const TextStyle(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 15),

                // Info Text
                const Text(
                  'Kosongkan password untuk masuk sebagai user biasa\n(is password "unitas2025" untuk admin)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Buttons
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0066CC))
                    : Column(
                        children: [
                          // User Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                _passwordController.clear();
                                Navigator.pushReplacementNamed(
                                  context, 
                                  '/main',
                                  arguments: false, // User mode
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                elevation: 2,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'MASUK SEBAGAI USER',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Admin Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066CC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'LOGIN SEBAGAI ADMIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}