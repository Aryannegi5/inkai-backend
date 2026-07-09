import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class ResultScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const ResultScreen({super.key, required this.imageBytes});

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      await Gal.putImageBytes(imageBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ink'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _saveToGallery(context),
                icon: const Icon(Icons.save_alt),
                label: const Text('Save to Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
