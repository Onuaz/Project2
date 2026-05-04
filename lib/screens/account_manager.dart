import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'orders_screen.dart';
import 'restaurant_menu_editor.dart';

class AccountManager extends StatelessWidget {
  const AccountManager({super.key});

  Future<void> _showEditDialog(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final emailCtrl = TextEditingController(text: doc?.data()?['email'] ?? '');
    final nameCtrl = TextEditingController(text: doc?.data()?['name'] ?? '');
    final roleCtrl = TextEditingController(text: doc?.data()?['role'] ?? 'customer');
    final addressCtrl = TextEditingController(text: doc?.data()?['address'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071026),
        title: Text(doc == null ? 'Add Account' : 'Edit Account', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (customer/restaurant/driver/admin)', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              final data = {
                'email': emailCtrl.text.trim(),
                'name': nameCtrl.text.trim(),
                'role': roleCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              };
              if (doc == null) {
                await FirebaseFirestore.instance.collection('users').add(data);
              } else {
                await FirebaseFirestore.instance.collection('users').doc(doc.id).update(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snap.exists && (snap.data()?['role'] == 'admin');
  }

  Future<String?> _currentUid() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
          title: const Text('Account Manager'),
          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showEditDialog(context)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.restaurant), text: 'Restaurants'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Users tab
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No accounts', style: TextStyle(color: Colors.white)));
                return FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (context, adminSnap) {
                    final isAdmin = adminSnap.data ?? false;
                    return FutureBuilder<String?>(
                      future: _currentUid(),
                      builder: (context, meSnap) {
                        final me = meSnap.data;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final role = d.data()['role'] ?? '';
                            final canEdit = isAdmin; // only admins can edit/delete other accounts
                            return Card(
                              color: Colors.black.withOpacity(0.6),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: ListTile(
                                title: Text(d.data()['email'] ?? 'no-email', style: const TextStyle(color: Colors.white)),
                                subtitle: Text('${role} • ${d.data()['name'] ?? ''}\n${d.data()['address'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                                isThreeLine: true,
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (canEdit) IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent), onPressed: () => _showEditDialog(context, doc: d)),
                                  if (canEdit) IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () async {
                                    await FirebaseFirestore.instance.collection('users').doc(d.id).delete();
                                    if (role == 'restaurant') {
                                      await FirebaseFirestore.instance.collection('restaurants').doc(d.id).delete().catchError((_) {});
                                    }
                                  }),
                                  if (!canEdit) const Icon(Icons.visibility, color: Colors.white70),
                                ]),
                                onTap: () {
                                  // allow viewing profile details (read-only)
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF071026),
                                      title: Text(d.data()['email'] ?? 'Profile', style: const TextStyle(color: Colors.white)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Name: ${d.data()['name'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(height: 6),
                                          Text('Role: ${role}', style: const TextStyle(color: Colors.white70)),
                                          const SizedBox(height: 6),
                                          Text('Address: ${d.data()['address'] ?? ''}', style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white70))),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),

            // Restaurants tab (show all restaurants; tap to edit menu if admin or owner)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No restaurants', style: TextStyle(color: Colors.white)));
                return FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (context, adminSnap) {
                    final isAdmin = adminSnap.data ?? false;
                    return FutureBuilder<String?>(
                      future: _currentUid(),
                      builder: (context, meSnap) {
                        final me = meSnap.data;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final r = docs[i];
                            final name = r.data()['name'] ?? 'Unnamed';
                            final address = r.data()['address'] ?? '';
                            final ownerId = r.data()['ownerId'] ?? '';
                            final isOwner = me != null && me == ownerId;
                            final canEdit = isAdmin || isOwner;
                            return Card(
                              color: Colors.black.withOpacity(0.6),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: ListTile(
                                title: Text(name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(address, style: const TextStyle(color: Colors.white70)),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.cyanAccent),
                                    onPressed: () {
                                      // view restaurant details
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: const Color(0xFF071026),
                                          title: Text(name, style: const TextStyle(color: Colors.white)),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Address: $address', style: const TextStyle(color: Colors.white70)),
                                              const SizedBox(height: 8),
                                              Text('Owner: $ownerId', style: const TextStyle(color: Colors.white70)),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white70))),
                                            if (canEdit) TextButton(onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: r.id)));
                                            }, child: const Text('Edit Menu', style: TextStyle(color: Colors.white70))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  if (canEdit) IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: r.id))),
                                  ),
                                  if (isAdmin) IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('restaurants').doc(r.id).delete().catchError((_) {});
                                    },
                                  ),
                                ]),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: r.id)));
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
