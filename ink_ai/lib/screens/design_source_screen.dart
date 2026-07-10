import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'body_canvas_screen.dart';

enum _DesignSource { unsplash, describe, upload }

class DesignSourceScreen extends StatefulWidget {
  const DesignSourceScreen({super.key});

  @override
  State<DesignSourceScreen> createState() => _DesignSourceScreenState();
}

class _DesignSourceScreenState extends State<DesignSourceScreen> {
  _DesignSource _source = _DesignSource.unsplash;

  final _searchController = TextEditingController();
  final _promptController = TextEditingController();
  final _picker = ImagePicker();

  List<_UnsplashPhoto> _searchResults = [];
  String? _selectedImageUrl;
  File? _localImage;
  bool _isSearching = false;

  String get _accessKey => dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';

  bool get _hasSelection {
    switch (_source) {
      case _DesignSource.unsplash:
        return _selectedImageUrl != null;
      case _DesignSource.describe:
        return _promptController.text.trim().isNotEmpty;
      case _DesignSource.upload:
        return _localImage != null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _searchUnsplash(String query) async {
    if (query.trim().isEmpty || _accessKey.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://api.unsplash.com/search/photos'
        '?query=${Uri.encodeComponent(query)}&per_page=30',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        setState(() {
          _searchResults =
              results.map((e) => _UnsplashPhoto.fromJson(e)).toList();
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _localImage = File(picked.path));
    }
  }

  void _next() {
    if (!_hasSelection) return;

    switch (_source) {
      case _DesignSource.unsplash:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BodyCanvasScreen(unsplashUrl: _selectedImageUrl),
          ),
        );
      case _DesignSource.describe:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BodyCanvasScreen(prompt: _promptController.text.trim()),
          ),
        );
      case _DesignSource.upload:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BodyCanvasScreen(localImagePath: _localImage!.path),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'Choose your ink.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildSourceTabs(),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
            _buildNextButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          _tab('Search', _DesignSource.unsplash),
          const SizedBox(width: 24),
          _tab('Describe', _DesignSource.describe),
          const SizedBox(width: 24),
          _tab('Upload', _DesignSource.upload),
        ],
      ),
    );
  }

  Widget _tab(String label, _DesignSource source) {
    final isActive = _source == source;
    return GestureDetector(
      onTap: () => setState(() => _source = source),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF111111)
                  : const Color(0xFF7E7E7E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2.5,
            width: 64,
            color: isActive ? const Color(0xFF000000) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_source) {
      case _DesignSource.unsplash:
        return _buildUnsplashTab();
      case _DesignSource.describe:
        return _buildDescribeTab();
      case _DesignSource.upload:
        return _buildUploadTab();
    }
  }

  Widget _buildUnsplashTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: TextField(
            controller: _searchController,
            onSubmitted: _searchUnsplash,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 16, color: Color(0xFF111111)),
            decoration: InputDecoration(
              hintText: 'Search tattoo ideas...',
              hintStyle: const TextStyle(color: Color(0xFF7E7E7E)),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF7E7E7E),
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF7E7E7E),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF111111), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF000000),
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _accessKey.isEmpty
                            ? 'Set UNSPLASH_ACCESS_KEY in your .env file'
                            : 'Search for tattoo inspiration',
                        style: const TextStyle(
                          color: Color(0xFF7E7E7E),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final photo = _searchResults[index];
                        final isSelected =
                            _selectedImageUrl == photo.regularUrl;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedImageUrl = photo.regularUrl),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AspectRatio(
                                  aspectRatio: photo.aspectRatio,
                                  child: Image.network(
                                    photo.regularUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: const Color(0xFFF5F5F5),
                                      );
                                    },
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                      color: const Color(0xFFF5F5F5),
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withValues(alpha: 0.3),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF000000),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDescribeTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe your dream tattoo',
            style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE5E5E5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _promptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111111),
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. A cyberpunk samurai with neon accents',
                  hintStyle: TextStyle(color: Color(0xFF7E7E7E)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload a reference image',
            style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _localImage != null
                        ? const Color(0xFF000000)
                        : const Color(0xFFE5E5E5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _localImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          _localImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: const Color(0xFF7E7E7E),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to upload from gallery',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7E7E7E),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return AnimatedOpacity(
      opacity: _hasSelection ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: MaterialButton(
            onPressed: _hasSelection ? _next : null,
            height: 54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: const Color(0xFF000000),
            disabledColor:
                const Color(0xFF000000).withValues(alpha: 0.5),
            elevation: 0,
            highlightElevation: 0,
            child: const Text(
              'Next: Choose Canvas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsplashPhoto {
  final String regularUrl;
  final double aspectRatio;

  _UnsplashPhoto({
    required this.regularUrl,
    required this.aspectRatio,
  });

  factory _UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return _UnsplashPhoto(
      regularUrl: json['urls']?['regular'] ?? '',
      aspectRatio: (json['width'] ?? 1) / (json['height'] ?? 1),
    );
  }
}
