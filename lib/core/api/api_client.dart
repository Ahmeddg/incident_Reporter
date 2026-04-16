import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:incident_reporter/core/services/auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String _baseUrl = 'http://10.0.2.2:8081'; // Backend port
  final AuthService _authService = AuthService();

  Future<http.Response> get(String path) async {
    final token = await _authService.getValidToken();
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> post(String path, dynamic body) async {
    final token = await _authService.getValidToken();
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return response;
  }
}
