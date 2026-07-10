import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final String token;
  final Map<String, dynamic> user;

  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty) {
      throw HttpException('Authentication token missing in server response');
    }
    if (user is! Map<String, dynamic>) {
      throw HttpException('User data missing in server response');
    }
    return AuthResult(token: token, user: user);
  }
}

class ConfigException implements Exception {
  final String message;
  ConfigException(this.message);
  @override
  String toString() => message;
}

class TattooApiService {
  late final String baseUrl;
  late final String endpoint;
  final http.Client _client;

  TattooApiService({
    http.Client? client,
  }) : _client = client ?? http.Client() {
    baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw ConfigException('API Base URL configuration missing in .env');
    }
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    endpoint = '${normalized}api/generate-tattoo';
  }

  String get _authBase {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '${normalized}api/auth';
  }

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = '${_authBase}/signup';
    print('📤 [API] POST $url');

    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    print('📥 [API] Response status: ${response.statusCode}');
    print('📥 [API] Response body: ${response.body}');

    if (response.statusCode != 201) {
      final body = _safeDecode(response.body);
      final message = body['message'] as String? ?? 'Signup failed';
      print('❌ [API] Signup error: $message');
      throw HttpException(message);
    }

    final decoded = _safeDecode(response.body);
    if (decoded.isEmpty) {
      throw HttpException('Invalid JSON response from server');
    }
    return AuthResult.fromJson(decoded);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final url = '${_authBase}/login';
    print('📤 [API] POST $url');

    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('📥 [API] Response status: ${response.statusCode}');
    print('📥 [API] Response body: ${response.body}');

    if (response.statusCode != 200) {
      final body = _safeDecode(response.body);
      final message = body['message'] as String? ?? 'Login failed';
      print('❌ [API] Login error: $message');
      throw HttpException(message);
    }

    final decoded = _safeDecode(response.body);
    if (decoded.isEmpty) {
      throw HttpException('Invalid JSON response from server');
    }
    return AuthResult.fromJson(decoded);
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Uint8List> generateTattooPreview({
    Uint8List? bodyImage,
    Uint8List? designImage,
    String? textPrompt,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(endpoint),
    );

    if (bodyImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', bodyImage, filename: 'body.png'),
      );
    }

    if (designImage != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
            'design', designImage, filename: 'design.png'),
      );
    }

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