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
  final _auth = AuthService.instance;
  String? _error;
  bool _loading = false;

  Future<void> _register() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = await _auth.register(email, password, _role);

    if (user == null) {
      setState(() {
        _error = 'Registration failed';
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field(_email, 'Email'),
            const SizedBox(height: 16),
            _field(_password, 'Password', obscure: true),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _role,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'customer',
                  child: Text('Customer', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'restaurant',
                  child: Text('Restaurant', style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: 'driver',
                  child: Text('Driver', style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
        ),
      ),
    );
  }
}
