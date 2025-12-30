import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Admin / Kadiv')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Username'),
            const TextField(),
            const SizedBox(height: 16),
            const Text('Password'),
            const TextField(obscureText: true),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Masuk'),
            )
          ],
        ),
      ),
    );
  }
}
