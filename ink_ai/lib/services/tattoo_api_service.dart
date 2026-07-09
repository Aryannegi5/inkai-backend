import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!   IMPORTANT: You MUST replace 192.168.1.X below with your computer's       !!!
// !!!   actual IPv4 address before running the app.                              !!!
// !!!                                                                           !!!
// !!!   How to find your IPv4 address:                                          !!!
// !!!     macOS/Linux : Run `ifconfig` or `ip addr` in your terminal            !!!
// !!!     Windows    : Run `ipconfig` in Command Prompt                         !!!
// !!!                                                                           !!!
// !!!   Look for an entry like "inet 192.168.1.42" (usually under en0/wlan0).   !!!
// !!!   Replace 192.168.1.X with that number.                                  !!!
// !!!   Do NOT use "localhost" or "127.0.0.1" — the Android emulator/device     !!!
// !!!   needs your host machine's LAN IP.                                        !!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
const kBaseUrl = 'http://192.168.1.X:3000';

class TattooApiService {
  final String baseUrl;
  final http.Client _client;

  TattooApiService({
    this.baseUrl = kBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Uint8List> generateTattooPreview({
    required Uint8List image,
    String? textPrompt,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/generate'),
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
