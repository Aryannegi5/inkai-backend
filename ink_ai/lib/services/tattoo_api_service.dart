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
    return AuthResult(
      token: json['token'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

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

  String get _authBase => '${baseUrl}api/auth';

  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_authBase/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw HttpException(
        body['message'] as String? ?? 'Signup failed',
      );
    }

    return AuthResult.fromJson(body);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_authBase/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw HttpException(
        body['message'] as String? ?? 'Login failed',
      );
    }

    return AuthResult.fromJson(body);
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
