import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_customer.dart';
import 'home_restaurant.dart';
import 'home_driver.dart';
import 'orders_screen.dart';
import 'account_manager.dart';
import 'cart_screen.dart';

class HomeShell extends StatefulWidget {
  final String role;
  final String displayName;
  const HomeShell({super.key, required this.role, required this.displayName});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.role == 'admin';
  }

  Widget _buildHomeForRole() {
    switch (widget.role) {
      case 'restaurant':
        return const HomeRestaurant();
      case 'driver':
        return const HomeDriver();
      case 'admin':
        return _AdminHome();
      default:
        return const HomeCustomer();
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    // Accounts tab only visible to admins
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
    ];
    if (_isAdmin) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Accounts'));
    }
    return items;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = _buildHomeForRole();
        break;
      case 1:
        body = const OrdersScreen();
        break;
      case 2:
        body = const AccountManager();
        break;
      default:
        body = _buildHomeForRole();
    }

    final titleName = widget.displayName.isEmpty ? widget.role[0].toUpperCase() + widget.role.substring(1) : widget.displayName;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: Text('Food Runner — $titleName'),
        actions: [
          // Cart icon available from any screen
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF071026),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white70,
        onTap: (i) {
          // If admin, index mapping is direct.
          // If not admin and user taps index 2 (which doesn't exist), ignore.
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

class _AdminHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.people, color: Colors.black),
              label: const Text('Manage Accounts', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManager())),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.list, color: Colors.black),
              label: const Text('View Orders', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            const SizedBox(height: 12),
            const Text('Admin accounts cannot place orders. Use the Accounts tab to manage users and restaurants.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
