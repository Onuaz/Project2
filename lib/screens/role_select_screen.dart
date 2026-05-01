import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'customer';
  final _auth = AuthService();

  Future<void> _register() async {
    await _auth.register(_email.text.trim(), _password.text.trim(), _role);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 24),
            DropdownButton<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                DropdownMenuItem(value: 'driver', child: Text('Driver')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
