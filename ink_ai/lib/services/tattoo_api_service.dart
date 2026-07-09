import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TattooApiService {
  late final String baseUrl;
  late final String endpoint;
  final http.Client _client;

  TattooApiService({
    http.Client? client,
  }) : _client = client ?? http.Client() {
    baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    endpoint = '${baseUrl}api/generate-tattoo';
  }

  Future<Uint8List> generateTattooPreview({
    required Uint8List image,
    String? textPrompt,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(endpoint),
    );

    request.files.add(
      http.MultipartFile.fromBytes('image', image, filename: 'composite.png'),
    );

    if (textPrompt != null && textPrompt.trim().isNotEmpty) {
      request.fields['prompt'] = textPrompt.trim();
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw HttpException(
        'API request failed with status ${response.statusCode}: ${response.body}',
      );
    }

    return response.bodyBytes;
  }

  void dispose() {
    _client.close();
  }
}
