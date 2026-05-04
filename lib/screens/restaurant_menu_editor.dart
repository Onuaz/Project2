import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantMenuEditor extends StatelessWidget {
  final String restaurantId;
  const RestaurantMenuEditor({super.key, required this.restaurantId});

  Future<void> _showEditItemDialog(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final nameCtrl = TextEditingController(text: doc?.data()?['name'] ?? '');
    final priceCtrl = TextEditingController(text: doc?.data()?['price']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071026),
        title: Text(doc == null ? 'Add Menu Item' : 'Edit Menu Item', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: Colors.white70)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              if (name.isEmpty) return;
              final col = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('menu');
              if (doc == null) {
                await col.add({'name': name, 'price': price, 'createdAt': FieldValue.serverTimestamp()});
              } else {
                await col.doc(doc.id).update({'name': name, 'price': price});
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Future<void> _editRestaurantDetails(BuildContext context) async {
    final docRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
    final snap = await docRef.get();
    final data = snap.data() ?? {};
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final addressCtrl = TextEditingController(text: data['address'] ?? '');
    final latCtrl = TextEditingController(text: data['lat']?.toString() ?? '');
    final lngCtrl = TextEditingController(text: data['lng']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071026),
        title: const Text('Edit Restaurant Details', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.white70))),
              const SizedBox(height: 8),
              const Text('Optional coordinates (for distance calculations)', style: TextStyle(color: Colors.white70)),
              TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude', labelStyle: TextStyle(color: Colors.white70)), keyboardType: TextInputType.number),
              TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitude', labelStyle: TextStyle(color: Colors.white70)), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final address = addressCtrl.text.trim();
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              final update = <String, dynamic>{'name': name, 'address': address};
              if (lat != null && lng != null) {
                update['lat'] = lat;
                update['lng'] = lng;
              }
              await docRef.set(update, SetOptions(merge: true));
              Navigator.pop(context);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant updated')));
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('menu').orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('Menu Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editRestaurantDetails(context), tooltip: 'Edit restaurant details'),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showEditItemDialog(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: menuRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No menu items', style: TextStyle(color: Colors.white)));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final name = d.data()['name'] ?? 'Unnamed';
              final price = d.data()['price'] ?? 0;
              return Card(
                color: Colors.black.withOpacity(0.6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('\$${price.toString()}', style: const TextStyle(color: Colors.white70)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.cyanAccent), onPressed: () => _showEditItemDialog(context, doc: d)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('menu').doc(d.id).delete()),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
