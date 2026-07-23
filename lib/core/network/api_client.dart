import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/session_storage.dart';

class ApiClient {
  static String baseUrl = 'http://192.168.1.8:8000';

  static void updateBaseUrl(String url) {
    baseUrl = url.startsWith('http') ? url.trim() : 'http://$url';
  }

  static Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (SessionStorage.authToken != null)
          'Authorization': 'Bearer ${SessionStorage.authToken}',
      };

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/otp/send'),
      headers: _publicHeaders,
      body: jsonEncode({'phoneNumber': phoneNumber}),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send OTP');
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String role = 'CUSTOMER',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/otp/verify'),
      headers: _publicHeaders,
      body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp, 'role': role}),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid OTP');
  }

  static Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    String role = 'CUSTOMER',
    String? fullName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/firebase-login'),
      headers: _publicHeaders,
      body: jsonEncode({'idToken': idToken, 'role': role, 'fullName': fullName}),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Firebase authentication failed');
  }

  static Future<List<dynamic>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/catalog/categories'), headers: _publicHeaders)
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load categories');
  }

  static Future<List<dynamic>> getServices({String? categoryId}) async {
    final uri = categoryId != null
        ? Uri.parse('$baseUrl/api/v1/catalog/services?categoryId=$categoryId')
        : Uri.parse('$baseUrl/api/v1/catalog/services');
    final res = await http.get(uri, headers: _publicHeaders).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load services');
  }

  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String addressText,
    required double latitude,
    required double longitude,
    bool femaleProPreferred = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/bookings'),
      headers: _authHeaders,
      body: jsonEncode({
        'serviceId': serviceId,
        'addressText': addressText,
        'latitude': latitude,
        'longitude': longitude,
        'femaleProPreferred': femaleProPreferred,
      }),
    ).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body['message'] ?? 'Failed to create booking');
  }

  static Future<List<dynamic>> getMyBookings() async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/bookings/my-bookings'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load bookings');
  }

  static Future<void> triggerSos({
    required double latitude,
    required double longitude,
    String? bookingId,
    String notes = 'Emergency SOS',
  }) async {
    await http.post(
      Uri.parse('$baseUrl/api/v1/safety/sos/trigger'),
      headers: _authHeaders,
      body: jsonEncode({'latitude': latitude, 'longitude': longitude, 'notes': notes, if (bookingId != null) 'bookingId': bookingId}),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/users/me'), headers: _authHeaders)
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load profile');
  }
}
