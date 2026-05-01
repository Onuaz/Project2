import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/order.dart';

class AddOrderScreen extends StatefulWidget {
  final Order? existingOrder;

  const AddOrderScreen({super.key, this.existingOrder});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _itemController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'Pending';

  final _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    if (widget.existingOrder != null) {
      _restaurantController.text = widget.existingOrder!.restaurant;
      _itemController.text = widget.existingOrder!.item;
      _notesController.text = widget.existingOrder!.notes ?? '';
      _status = widget.existingOrder!.status;
    }
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _itemController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().toIso8601String();

    if (widget.existingOrder == null) {
      final newOrder = Order(
        restaurant: _restaurantController.text.trim(),
        item: _itemController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _status,
        timestamp: now,
      );
      await _dbHelper.insertOrder(newOrder);
    } else {
      final updatedOrder = Order(
        id: widget.existingOrder!.id,
        restaurant: _restaurantController.text.trim(),
        item: _itemController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _status,
        timestamp: widget.existingOrder!.timestamp,
      );
      await _dbHelper.updateOrder(updatedOrder);
    }

    if (mounted) {
      Navigator.pop(context, true); // indicate refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingOrder != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Order' : 'Add Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _restaurantController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Restaurant is required'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Food Item',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Food item is required'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Preparing', child: Text('Preparing')),
                  DropdownMenuItem(
                      value: 'Out for Delivery',
                      child: Text('Out for Delivery')),
                  DropdownMenuItem(
                      value: 'Delivered', child: Text('Delivered')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveOrder,
                      child: Text(isEditing ? 'Save Changes' : 'Add Order'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
