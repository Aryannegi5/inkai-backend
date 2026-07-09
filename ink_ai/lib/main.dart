import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/auth_screen.dart';
import 'screens/result_screen.dart';
import 'services/tattoo_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Firebase init error: $e');
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    print('dotenv load failed, using fallback defaults');
  }

  runApp(const InkAI());
}

class InkAI extends StatelessWidget {
  const InkAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ink AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const TattooStudioScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class TattooStudioScreen extends StatefulWidget {
  const TattooStudioScreen({super.key});

  @override
  State<TattooStudioScreen> createState() => _TattooStudioScreenState();
}

enum _TattooInputMode { upload, describe }

class _DemoBodyPart {
  final String label;
  final String assetPath;
  const _DemoBodyPart(this.label, this.assetPath);
}

const _demoBodyParts = [
  _DemoBodyPart('Forearm', 'assets/demo_forearm.png'),
  _DemoBodyPart('Chest', 'assets/demo_chest.png'),
  _DemoBodyPart('Back', 'assets/demo_back.png'),
  _DemoBodyPart('Calf', 'assets/demo_calf.png'),
];

class _TattooStudioScreenState extends State<TattooStudioScreen> {
  File? _bodyPartImage;
  String? _demoBodyPartPath;
  File? _tattooIdeaImage;
  String _tattooPrompt = '';
  _TattooInputMode _tattooInputMode = _TattooInputMode.upload;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final _apiService = TattooApiService();
  final _screenshotController = ScreenshotController();
  final _tattooWidth = 120.0;
  Offset _tattooOffset = Offset.zero;
  double _tattooScale = 1.0;
  double _tattooRotation = 0.0;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  bool get _hasBodyImage => _bodyPartImage != null || _demoBodyPartPath != null;

  bool get _canGenerate =>
      _hasBodyImage &&
      (_tattooIdeaImage != null || _tattooPrompt.trim().isNotEmpty);

  Future<void> _generate() async {
    setState(() => _isLoading = true);

    try {
      Uint8List inputImage;

      if (_bothImagesSelected) {
        final composite = await _screenshotController.capture();
        if (composite == null) throw Exception('Failed to capture preview');
        inputImage = composite;
      } else if (_bodyPartImage != null) {
        inputImage = await _bodyPartImage!.readAsBytes();
      } else {
        final byteData = await rootBundle.load(_demoBodyPartPath!);
        inputImage = byteData.buffer.asUint8List();
      }

      final bytes = await _apiService.generateTattooPreview(
        image: inputImage,
        textPrompt: _tattooInputMode == _TattooInputMode.describe
            ? _tattooPrompt
            : null,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageBytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generation failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage({required bool isBodyPart}) async {
    if (isBodyPart) {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _bodyPartImage = File(picked.path);
          _demoBodyPartPath = null;
        });
      }
    } else {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _tattooIdeaImage = File(picked.path);
        });
      }
    }
  }

  bool get _bothImagesSelected =>
      _hasBodyImage && _tattooIdeaImage != null;

  void _selectDemoBody(String assetPath) {
    setState(() {
      _demoBodyPartPath = assetPath;
      _bodyPartImage = null;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Your Ink'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_bothImagesSelected) ...[
              Expanded(
                flex: 4,
                child: _buildPreviewStack(),
              ),
            ] else if (!_hasBodyImage) ...[
              Expanded(
                flex: 2,
                child: _UploadCard(
                  label: 'Upload Body Part',
                  icon: Icons.accessibility_new,
                  hasImage: null,
                  onTap: () => _pickImage(isBodyPart: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  'Or select a demo canvas:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _demoBodyParts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final part = _demoBodyParts[index];
                    return ChoiceChip(
                      label: Text(part.label),
                      selected: false,
                      onSelected: (_) => _selectDemoBody(part.assetPath),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Expanded(
                flex: 3,
                child: _UploadCard(
                  label: 'Upload Body Part',
                  icon: Icons.accessibility_new,
                  hasImage: _bodyPartImage,
                  assetImage: _demoBodyPartPath,
                  onTap: () => _pickImage(isBodyPart: true),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: SizedBox(
                height: 40,
                child: SegmentedButton<_TattooInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: _TattooInputMode.upload,
                      label: Text('Upload Image'),
                      icon: Icon(Icons.image),
                    ),
                    ButtonSegment(
                      value: _TattooInputMode.describe,
                      label: Text('Describe Tattoo'),
                      icon: Icon(Icons.text_fields),
                    ),
                  ],
                  selected: {_tattooInputMode},
                  onSelectionChanged: (selected) {
                    setState(() => _tattooInputMode = selected.first);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_bothImagesSelected) ...[
              if (_tattooInputMode == _TattooInputMode.describe)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundDecoration: _DashedBorderDecoration(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1.5,
                      radius: 16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'e.g. A minimalist geometric wolf',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        onChanged: (value) => _tattooPrompt = value,
                      ),
                    ),
                  ),
                ),
            ] else ...[
              Expanded(
                child: _tattooInputMode == _TattooInputMode.upload
                    ? _UploadCard(
                        label: 'Upload Tattoo Idea',
                        icon: Icons.auto_fix_high,
                        hasImage: _tattooIdeaImage,
                        onTap: () => _pickImage(isBodyPart: false),
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundDecoration: _DashedBorderDecoration(
                          color: theme.colorScheme.outlineVariant,
                          strokeWidth: 1.5,
                          radius: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            autofocus: true,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'e.g. A minimalist geometric wolf',
                              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            onChanged: (value) => _tattooPrompt = value,
                          ),
                      ),
                    ),
            ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI is applying your ink...',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _canGenerate ? _generate : null,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Tattoo'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStack() {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _pickImage(isBodyPart: true),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundDecoration: _DashedBorderDecoration(
          color: theme.colorScheme.outlineVariant,
          strokeWidth: 1.5,
          radius: 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Screenshot(
            controller: _screenshotController,
            child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: _demoBodyPartPath != null
                        ? Image.asset(
                            _demoBodyPartPath!,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            _bodyPartImage!,
                            fit: BoxFit.contain,
                          ),
                  ),
                  Positioned(
                    left: constraints.maxWidth / 2 - _tattooWidth / 2 +
                        _tattooOffset.dx,
                    top: constraints.maxHeight / 2 - _tattooWidth / 2 +
                        _tattooOffset.dy,
                    child: GestureDetector(
                      onTap: () => _pickImage(isBodyPart: false),
                      onScaleStart: (details) {
                        _baseScale = _tattooScale;
                        _baseRotation = _tattooRotation;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _tattooOffset += details.focalPointDelta;
                          _tattooScale =
                              (_baseScale * details.scale).clamp(0.3, 5.0);
                          _tattooRotation =
                              _baseRotation + details.rotation;
                        });
                      },
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(
                              _tattooScale, _tattooScale, 1.0)
                          ..rotateZ(_tattooRotation),
                        child: Container(
                          width: _tattooWidth,
                          height: _tattooWidth,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.file(
                            _tattooIdeaImage!,
                            fit: BoxFit.contain,
                          ),
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
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? hasImage;
  final String? assetImage;
  final VoidCallback onTap;

  const _UploadCard({
    required this.label,
    required this.icon,
    required this.hasImage,
    this.assetImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundDecoration: _DashedBorderDecoration(
          color: theme.colorScheme.outlineVariant,
          strokeWidth: 1.5,
          radius: 16,
        ),
        child: hasImage != null || assetImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: assetImage != null
                    ? Image.asset(
                        assetImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.file(
                        hasImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DashedBorderDecoration extends Decoration {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth = 8;
  final double dashGap = 4;

  const _DashedBorderDecoration({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 16,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DashedBorderPainter(
      color: color,
      strokeWidth: strokeWidth,
      radius: radius,
      dashWidth: dashWidth,
      dashGap: dashGap,
    );
  }
}

class _DashedBorderPainter extends BoxPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final path = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0, metric.length).toDouble();
        final segment = metric.extractPath(start, end);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashGap;
      }
    }
  }
}