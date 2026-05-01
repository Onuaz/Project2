import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/restaurant_service.dart';

class MenuUploadScreen extends StatefulWidget {
  final String restaurantId;

  const MenuUploadScreen({super.key, required this.restaurantId});

  @override
  State<MenuUploadScreen> createState() => _MenuUploadScreenState();
}

class _MenuUploadScreenState extends State<MenuUploadScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _service = RestaurantService();
  File? _image;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _upload() async {
    if (_image == null) return;
    final url = await _service.uploadImage(_image!);
    await _service.addMenuItem(
      widget.restaurantId,
      _name.text.trim(),
      double.parse(_price.text.trim()),
      url,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Menu Item')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Item Name')),
            const SizedBox(height: 12),
            TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _pick, child: const Text('Pick Image')),
            const SizedBox(height: 12),
            if (_image != null) Image.file(_image!, height: 120),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _upload, child: const Text('Upload')),
          ],
        ),
      ),
    );
  }
}
