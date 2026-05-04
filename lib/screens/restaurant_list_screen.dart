import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_runner/screens/menu_screen.dart';

class HomeCustomer extends StatelessWidget {
  const HomeCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurants"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("restaurants").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final restaurants = snapshot.data!.docs;

          return ListView(
            children: restaurants
                .map((r) => ListTile(
                      title: Text(r["name"]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuScreen(restaurantId: r.id, restaurantName: r["name"],),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
