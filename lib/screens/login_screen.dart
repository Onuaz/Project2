import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _role = TextEditingController(text: 'customer');
  final _address = TextEditingController();
  bool _loading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _email.text.trim();
    final password = _password.text;
    final role = _role.text.trim();
    final name = _name.text.trim();
    final address = _address.text.trim();

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        // authStateChanges will route to HomeShell
      } else {
        // Signup flow: require address for restaurant
        if (role == 'restaurant' && address.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant address is required')));
          setState(() => _loading = false);
          return;
        }

        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        final uid = cred.user!.uid;

        final userDoc = {
          'email': email,
          'role': role,
          'name': name,
          'address': address,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userDoc);

        if (role == 'restaurant') {
          await FirebaseFirestore.instance.collection('restaurants').doc(uid).set({
            'name': name.isEmpty ? 'Unnamed Restaurant' : name,
            'address': address,
            'ownerId': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Show confirmation and auto-login (createUser signs in automatically)
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF00E5FF)),
                      SizedBox(height: 12),
                      Text('Account Created', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('You are now signed in.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1200));
          if (context.mounted) Navigator.of(context).pop(); // close dialog
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Auth error';
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _role.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Runner'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin ? 'Sign up' : 'Sign in', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white70)),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Password min 6 chars' : null,
              ),
              const SizedBox(height: 8),
              if (!_isLogin) ...[
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _role,
                  decoration: const InputDecoration(labelText: 'Role (customer/restaurant/driver/admin)', labelStyle: TextStyle(color: Colors.white70)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter role' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address (required for restaurant)', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                child: _loading ? const CircularProgressIndicator() : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
