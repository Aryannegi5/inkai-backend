import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'result_screen.dart';

enum _BodySource { myBody, demoCanvas }

const _demoParts = [
  'Male Forearm',
  'Female Forearm',
  'Male Calf',
  'Female Calf',
  'Male Chest',
  'Female Chest',
  'Male Back',
  'Female Back',
  'Neck',
  'Thigh',
];

class BodyCanvasScreen extends StatefulWidget {
  final String? unsplashUrl;
  final String? prompt;
  final String? localImagePath;

  const BodyCanvasScreen({
    super.key,
    this.unsplashUrl,
    this.prompt,
    this.localImagePath,
  });

  @override
  State<BodyCanvasScreen> createState() => _BodyCanvasScreenState();
}

class _BodyCanvasScreenState extends State<BodyCanvasScreen> {
  _BodySource _bodySource = _BodySource.myBody;
  File? _myBodyImage;
  String? _selectedDemoPart;
  bool _isGenerating = false;

  final _picker = ImagePicker();

  bool get _canGenerate =>
      _bodySource == _BodySource.myBody
          ? _myBodyImage != null
          : _selectedDemoPart != null;

  Future<void> _pickBodyImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _myBodyImage = File(picked.path));
    }
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() => _isGenerating = true);

    try {
      String designReference;
      if (widget.unsplashUrl != null) {
        designReference = widget.unsplashUrl!;
      } else if (widget.prompt != null) {
        designReference = widget.prompt!;
      } else if (widget.localImagePath != null) {
        designReference = 'the uploaded design image';
      } else {
        designReference = 'the selected design';
      }

      String? textPrompt;
      String? designBase64;
      String? bodyBase64;

      if (_bodySource == _BodySource.myBody) {
        if (_myBodyImage != null) {
          final bytes = await _myBodyImage!.readAsBytes();
          bodyBase64 = base64Encode(bytes);
        }

        if (widget.unsplashUrl != null) {
          final bytes = await _downloadImage(widget.unsplashUrl!);
          if (bytes != null) {
            designBase64 = base64Encode(bytes);
          }
        } else if (widget.localImagePath != null) {
          final bytes = await File(widget.localImagePath!).readAsBytes();
          designBase64 = base64Encode(bytes);
        }

        textPrompt =
            "You are an expert photo editor. Take the provided image of the user's real body part and seamlessly overlay this tattoo design onto their skin: $designReference. Do NOT generate a new body or change the background. Only edit the provided image to include the tattoo.";
      } else {
        textPrompt =
            'Generate a highly realistic, photorealistic image of a $_selectedDemoPart featuring this tattoo design: $designReference.';
      }

      final payload = <String, dynamic>{};
      if (designBase64 != null) {
        payload['base64Image'] = designBase64;
      }
      if (bodyBase64 != null) {
        payload['bodyBase64'] = bodyBase64;
      }
      payload['prompt'] = textPrompt;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL not configured in .env');
      }
      final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
      final endpoint = '${normalized}api/generate-tattoo';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(imageBytes: response.bodyBytes),
          ),
        );
      } else {
        print('Response body: ${response.body}');

        final errorMsg = 'Error ${response.statusCode}: ${response.body}';
        final truncated = errorMsg.length > 200
            ? '${errorMsg.substring(0, 200)}...'
            : errorMsg;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(truncated),
            backgroundColor: const Color(0xFFD9383A),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: $e'),
          backgroundColor: const Color(0xFFD9383A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Where is it going?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a body area for your design',
                style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
              ),
              const SizedBox(height: 28),
              _buildSourceToggle(),
              const SizedBox(height: 24),
              Expanded(child: _buildContent()),
              _buildDesignSummary(),
              const SizedBox(height: 16),
              _buildGenerateButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _bodySource = _BodySource.myBody),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _bodySource == _BodySource.myBody
                      ? const Color(0xFF000000)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Use My Body',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _bodySource == _BodySource.myBody
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _bodySource = _BodySource.demoCanvas),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _bodySource == _BodySource.demoCanvas
                      ? const Color(0xFF000000)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Demo Canvas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _bodySource == _BodySource.demoCanvas
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_bodySource) {
      case _BodySource.myBody:
        return _buildMyBodyContent();
      case _BodySource.demoCanvas:
        return _buildDemoCanvasContent();
    }
  }

  Widget _buildMyBodyContent() {
    if (_myBodyImage != null) {
      return GestureDetector(
        onTap: () => _pickBodyImage(ImageSource.gallery),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _myBodyImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: MaterialButton(
            onPressed: () => _pickBodyImage(ImageSource.camera),
            height: 54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: const Color(0xFF000000),
            elevation: 0,
            highlightElevation: 0,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Open Camera',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => _pickBodyImage(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: const BorderSide(color: Color(0xFF000000), width: 1.5),
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF111111),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, color: Color(0xFF111111), size: 20),
                SizedBox(width: 10),
                Text(
                  'Upload from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoCanvasContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a body part',
          style: TextStyle(fontSize: 14, color: Color(0xFF7E7E7E)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _demoParts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final part = _demoParts[index];
              final isSelected = _selectedDemoPart == part;
              return GestureDetector(
                onTap: () => setState(() => _selectedDemoPart = part),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF000000)
                          : const Color(0xFFE5E5E5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          part,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF111111)
                                : const Color(0xFF111111),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF000000),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesignSummary() {
    String summary;
    if (widget.unsplashUrl != null) {
      summary = 'Using an image from Unsplash';
    } else if (widget.prompt != null) {
      summary = 'Prompt: "${widget.prompt}"';
    } else if (widget.localImagePath != null) {
      summary = 'Using an uploaded design image';
    } else {
      summary = '';
    }

    if (summary.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        summary,
        style: const TextStyle(fontSize: 13, color: Color(0xFF7E7E7E)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: MaterialButton(
        onPressed: _canGenerate && !_isGenerating ? _generate : null,
        height: 54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        color: const Color(0xFF000000),
        disabledColor: const Color(0xFF000000).withValues(alpha: 0.5),
        elevation: 0,
        highlightElevation: 0,
        child: _isGenerating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Generate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
      ),
    );
  }
}
