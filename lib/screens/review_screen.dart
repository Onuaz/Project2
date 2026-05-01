import 'package:flutter/material.dart';
import '../services/order_service.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;

  const ReviewScreen({super.key, required this.orderId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _review = TextEditingController();
  final _service = OrderService();

  Future<void> _submit() async {
    await _service.submitReview(widget.orderId, _rating, _review.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButton<int>(
              value: _rating,
              items: List.generate(
                5,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1} Stars'),
                ),
              ),
              onChanged: (v) => setState(() => _rating = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _review,
              decoration: const InputDecoration(labelText: 'Write a review'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
