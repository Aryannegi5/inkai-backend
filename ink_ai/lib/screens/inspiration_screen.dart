import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart' as app;

class UnsplashPhoto {
  final String id;
  final String regularUrl;
  final String fullUrl;
  final String? description;
  final String authorName;
  final double aspectRatio;

  UnsplashPhoto({
    required this.id,
    required this.regularUrl,
    required this.fullUrl,
    this.description,
    required this.authorName,
    required this.aspectRatio,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) => UnsplashPhoto(
        id: json['id'] ?? '',
        regularUrl: json['urls']?['regular'] ?? '',
        fullUrl: json['urls']?['full'] ?? '',
        description: json['alt_description'] ?? json['description'],
        authorName: json['user']?['name'] ?? 'Unknown',
        aspectRatio: (json['width'] ?? 1) / (json['height'] ?? 1),
      );
}

class InspirationScreen extends StatefulWidget {
  const InspirationScreen({super.key});

  @override
  State<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends State<InspirationScreen> {
  List<UnsplashPhoto> _photos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final _searchController = TextEditingController();
  String _currentQuery = 'minimalist tattoo design';
  final _scrollController = ScrollController();
  int _page = 1;
  bool _hasMore = true;

  String get _accessKey => dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _fetchPhotos({bool reset = true}) async {
    if (_accessKey.isEmpty) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = reset;
      if (reset) _page = 1;
    });

    try {
      final uri = Uri.parse(
        'https://api.unsplash.com/search/photos'
        '?query=${Uri.encodeComponent(_currentQuery)}'
        '&per_page=30&page=$_page',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        final photos = results
            .map((e) => UnsplashPhoto.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          if (reset) {
            _photos = photos;
          } else {
            _photos.addAll(photos);
          }
          _hasMore = photos.length >= 30;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _page++;
    _fetchPhotos(reset: false);
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    _currentQuery = query.trim();
    _fetchPhotos();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentQuery = 'minimalist tattoo design';
    _fetchPhotos();
  }

  void _showPhotoDetail(UnsplashPhoto photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PhotoDetailSheet(
        photo: photo,
        onTryItYourself: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => app.TattooStudioScreen(
                prefilledTattooUrl: photo.regularUrl,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Inspiration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search tattoo ideas...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _photos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _accessKey.isEmpty
                                ? 'Set UNSPLASH_ACCESS_KEY in your .env file'
                                : 'No results found\nTry a different search term',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _photos.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _photos.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final photo = _photos[index];
                          return GestureDetector(
                            onTap: () => _showPhotoDetail(photo),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: photo.aspectRatio,
                                child: Image.network(
                                  photo.regularUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade200,
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PhotoDetailSheet extends StatelessWidget {
  final UnsplashPhoto photo;
  final VoidCallback onTryItYourself;

  const _PhotoDetailSheet({
    required this.photo,
    required this.onTryItYourself,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (photo.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                photo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Text(
              'by ${photo.authorName}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photo.fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onTryItYourself,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Try it yourself',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
