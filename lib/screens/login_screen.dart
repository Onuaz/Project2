import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'role_select_screen.dart';
import 'home_customer.dart';
import 'home_restaurant.dart';
import 'home_driver.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  final _notify = NotificationService();

  Future<void> _login() async {
    final user = await _auth.signIn(_email.text.trim(), _password.text.trim());
    if (user == null) return;

    await _notify.saveToken(user.uid);

    final role = await _auth.getRole(user.uid);
    if (!mounted) return;
    if (role == 'customer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeCustomer()));
    } else if (role == 'restaurant') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeRestaurant()));
    } else if (role == 'driver') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDriver()));
    }
  }

  void _goRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
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
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(onPressed: _goRegister, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
