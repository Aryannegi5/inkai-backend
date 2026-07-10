import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? imageAsset;

  const ResultScreen({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.imageAsset,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isPaid = false;
  bool _isProcessingPayment = false;

  Future<void> _onUnlock() async {
    setState(() => _isProcessingPayment = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isProcessingPayment = false;
      _isPaid = true;
    });
  }

  Future<void> _saveToGallery() async {
    if (widget.imageBytes == null) return;
    try {
      await Gal.putImageBytes(widget.imageBytes!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard')),
    );
  }

  Widget _buildImage() {
    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!, fit: BoxFit.contain);
    }
    if (widget.imageUrl != null) {
      return Image.network(widget.imageUrl!, fit: BoxFit.contain);
    }
    if (widget.imageAsset != null) {
      return Image.asset(widget.imageAsset!, fit: BoxFit.contain);
    }
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Text(
          'No image available',
          style: TextStyle(color: Color(0xFF7E7E7E)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Ink',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPaid
                        ? 'Download or share your design'
                        : 'Unlock your design to save & share',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7E7E7E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final blurHeight = constraints.maxHeight * 0.4;
                      return Stack(
                        children: [
                          Positioned.fill(child: _buildImage()),
                          if (!_isPaid)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: blurHeight,
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_isPaid) _buildUnlockedActions(),
            if (!_isPaid) _buildPremiumContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumContainer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Unlock High-Res Download',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get full rights, unwatermarked access, and lifetime gallery saves.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7E7E7E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: MaterialButton(
              onPressed: _isProcessingPayment ? null : _onUnlock,
              height: 54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: const Color(0xFF000000),
              disabledColor: const Color(0xFF000000).withValues(alpha: 0.5),
              elevation: 0,
              highlightElevation: 0,
              child: _isProcessingPayment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Unlock for \$4.99',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: Icons.download_rounded,
            label: 'Download to Gallery',
            onTap: _saveToGallery,
          ),
          const SizedBox(width: 48),
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: _share,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
