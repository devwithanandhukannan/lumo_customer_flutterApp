import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/session_storage.dart';

/// Central API client for LUMO backend microservices gateway
class ApiClient {
  // Default IP — change this to your Mac's local Wi-Fi IP when on physical device
  static String baseUrl = 'http://192.168.1.8:8000';

  static void updateBaseUrl(String newUrl) {
    if (newUrl.startsWith('http://') || newUrl.startsWith('https://')) {
      baseUrl = newUrl.trimRight().replaceAll('/', '').endsWith(':8000')
          ? newUrl.trim()
          : newUrl.trim();
    } else {
      baseUrl = 'http://$newUrl';
    }
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (SessionStorage.authToken != null)
          'Authorization': 'Bearer ${SessionStorage.authToken}',
      };

  static Map<String, String> get _publicHeaders =>
      {'Content-Type': 'application/json'};

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// POST /api/v1/auth/otp/send
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/otp/send');
    final res = await http
        .post(uri,
            headers: _publicHeaders,
            body: jsonEncode({'phoneNumber': phoneNumber}))
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send OTP (${res.statusCode})');
  }

  /// POST /api/v1/auth/otp/verify
  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String role = 'CUSTOMER',
    String fullName = 'Customer User',
    String? gender,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/otp/verify');
    final res = await http
        .post(uri,
            headers: _publicHeaders,
            body: jsonEncode({
              'phoneNumber': phoneNumber,
              'otp': otp,
              'role': role,
              'fullName': fullName,
              if (gender != null) 'gender': gender,
            }))
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid OTP (${res.statusCode})');
  }

  /// POST /api/v1/auth/firebase-login
  static Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    String role = 'CUSTOMER',
    String fullName = 'Customer User',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/firebase-login');
    final res = await http
        .post(uri,
            headers: _publicHeaders,
            body: jsonEncode({
              'idToken': idToken,
              'role': role,
              'fullName': fullName,
            }))
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Firebase login failed');
  }

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  /// GET /api/v1/users/me
  static Future<Map<String, dynamic>> getMyProfile() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    final res =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to load profile');
  }

  // ─── SERVICE CATALOG ──────────────────────────────────────────────────────

  /// GET /api/v1/catalog/categories
  static Future<List<dynamic>> getCategories() async {
    final uri = Uri.parse('$baseUrl/api/v1/catalog/categories');
    final res =
        await http.get(uri, headers: _publicHeaders).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load categories');
  }

  /// GET /api/v1/catalog/services?categoryId=xxx
  static Future<List<dynamic>> getServices({String? categoryId}) async {
    final query = categoryId != null ? '?categoryId=$categoryId' : '';
    final uri = Uri.parse('$baseUrl/api/v1/catalog/services$query');
    final res =
        await http.get(uri, headers: _publicHeaders).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load services');
  }

  // ─── BOOKINGS ─────────────────────────────────────────────────────────────

  /// POST /api/v1/bookings
  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String addressText,
    required double latitude,
    required double longitude,
    bool femaleProPreferred = false,
    String? scheduledAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings');
    final res = await http
        .post(uri,
            headers: _headers,
            body: jsonEncode({
              'serviceId': serviceId,
              'addressText': addressText,
              'latitude': latitude,
              'longitude': longitude,
              'femaleProPreferred': femaleProPreferred,
              if (scheduledAt != null) 'scheduledAt': scheduledAt,
            }))
        .timeout(const Duration(seconds: 10));

    final body = jsonDecode(res.body);
    if (res.statusCode == 201 || res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Booking failed (${res.statusCode})');
  }

  /// GET /api/v1/bookings/my-bookings
  static Future<List<dynamic>> getMyBookings() async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings/my-bookings');
    final res =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load bookings');
  }

  // ─── SAFETY / SOS ─────────────────────────────────────────────────────────

  /// POST /api/v1/safety/sos/trigger
  static Future<void> triggerSos({
    required double latitude,
    required double longitude,
    String? bookingId,
    String notes = 'Mobile Emergency SOS Triggered',
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/safety/sos/trigger');
    await http
        .post(uri,
            headers: _headers,
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'notes': notes,
              if (bookingId != null) 'bookingId': bookingId,
            }))
        .timeout(const Duration(seconds: 10));
  }
}
