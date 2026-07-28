import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../storage/session_storage.dart';

class ApiClient {
  static void Function()? onUnauthorizedOrNotFound;

  static void _checkResponseForUserError(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 404) {
      SessionStorage.clearSession();
      onUnauthorizedOrNotFound?.call();
    }
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://192.168.1.8:8000';
      if (Platform.isIOS) return 'http://192.168.1.8:8000';
    } catch (_) {}
    return 'http://192.168.1.8:8000';
  }

  static String baseUrl = _defaultBaseUrl();

  static void updateBaseUrl(String url) {
    baseUrl = url.startsWith('http') ? url.trim() : 'http://$url';
  }

  static Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (SessionStorage.authToken != null)
          'Authorization': 'Bearer ${SessionStorage.authToken}',
      };

  static Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String currentUrl) requestFn,
  ) async {
    final candidateUrls = <String>{
      baseUrl,
      'http://192.168.1.8:8000',
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:8000',
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:5000',
      'http://127.0.0.1:8000',
      'http://localhost:8000',
    }.toList();

    Object? lastError;

    for (final candidate in candidateUrls) {
      try {
        final response = await requestFn(candidate).timeout(const Duration(seconds: 2));
        baseUrl = candidate;
        _checkResponseForUserError(response);
        return response;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      if (lastError.toString().contains('Socket') ||
          lastError.toString().contains('No route to host') ||
          lastError.toString().contains('TimeoutException')) {
        throw Exception(
          'Backend API Gateway unreachable at $baseUrl. Ensure ./run-all.sh is running in backend directory and your phone is on the same Wi-Fi network.',
        );
      }
      throw lastError;
    }

    throw Exception('Connection failed');
  }

  /// Verify current authenticated user profile exists in database
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await _requestWithFallback((url) => http.get(
            Uri.parse('$url/api/v1/users/me'),
            headers: _authHeaders,
          ));
      _checkResponseForUserError(res);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['data'] as Map<String, dynamic>?) ?? (body['user'] as Map<String, dynamic>?);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update 2: Pre-flight phone check — detect existing customers
  static Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final res = await _requestWithFallback((url) => http.get(
            Uri.parse('$url/api/v1/auth/check-phone?phone=${Uri.encodeComponent(phoneNumber)}'),
            headers: _publicHeaders,
          ));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return body;
      return {'data': {'exists': false, 'role': null}};
    } catch (_) {
      return {'data': {'exists': false, 'role': null}};
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/auth/otp/send'),
      headers: _publicHeaders,
      body: jsonEncode({'phoneNumber': phoneNumber}),
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Failed to send OTP');
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
    String fullName = 'Customer',
    String gender = 'OTHER',
  }) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/auth/otp/verify'),
      headers: _publicHeaders,
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'role': 'CUSTOMER',
        'fullName': fullName,
        'gender': gender,
      }),
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Invalid OTP');
  }

  static Future<Map<String, dynamic>> loginWithFirebaseToken(String idToken) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/auth/firebase-login'),
      headers: _publicHeaders,
      body: jsonEncode({'idToken': idToken}),
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body['message'] ?? 'Firebase Auth failed');
  }

  static Future<List<dynamic>> getCategories() async {
    final res = await _requestWithFallback((url) => http.get(
      Uri.parse('$url/api/v1/catalog/categories'),
      headers: _publicHeaders,
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load categories');
  }

  static Future<List<dynamic>> getServices({
    String? categoryId,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _requestWithFallback((url) {
      final queryParams = <String>[];
      if (categoryId != null) queryParams.add('categoryId=$categoryId');
      if (latitude != null) queryParams.add('latitude=$latitude');
      if (longitude != null) queryParams.add('longitude=$longitude');

      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      return http.get(Uri.parse('$url/api/v1/catalog/services$queryString'), headers: _publicHeaders);
    });
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load services');
  }

  // Update 3: Get professionals available for a service
  static Future<List<Map<String, dynamic>>> getProsForService({
    required String serviceId,
    required double lat,
    required double lng,
    bool femaleOnly = false,
    String sortBy = 'distance',
  }) async {
    final res = await _requestWithFallback((url) => http.get(
          Uri.parse('$url/api/v1/catalog/services/$serviceId/professionals?lat=$lat&lng=$lng&femaleOnly=$femaleOnly&sortBy=$sortBy'),
          headers: _publicHeaders,
        ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ((body['data'] as List?) ?? []).map((p) => Map<String, dynamic>.from(p)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required String scheduledAt,
    required String addressText,
    double? latitude,
    double? longitude,
    bool femaleProPreferred = false,
    String? selectedProId,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/bookings'),
      headers: _authHeaders,
      body: jsonEncode({
        'serviceId': serviceId,
        'scheduledAt': scheduledAt,
        'addressText': addressText,
        'latitude': latitude ?? SessionStorage.activeLat,
        'longitude': longitude ?? SessionStorage.activeLng,
        'femaleProPreferred': femaleProPreferred,
        if (selectedProId != null) 'selectedProId': selectedProId,
      }),
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to create booking');
  }

  static Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final res = await _requestWithFallback((url) => http.get(
      Uri.parse('$url/api/v1/bookings/$bookingId'),
      headers: _authHeaders,
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? {};
    throw Exception(body['message'] ?? 'Failed to load booking details');
  }

  static Future<List<dynamic>> getMyBookings() async {
    final res = await _requestWithFallback((url) => http.get(
      Uri.parse('$url/api/v1/bookings/my-bookings'),
      headers: _authHeaders,
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return (body['data'] as List?) ?? [];
    throw Exception(body['message'] ?? 'Failed to load bookings');
  }

  static Future<void> triggerSos({
    required double latitude,
    required double longitude,
    String? bookingId,
    String notes = 'Customer Emergency SOS',
  }) async {
    await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/safety/sos/trigger'),
      headers: _authHeaders,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        ...?bookingId == null ? null : {'bookingId': bookingId},
      }),
    ));
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await _requestWithFallback((url) => http.get(
      Uri.parse('$url/api/v1/users/me'),
      headers: _authHeaders,
    ));
    _checkResponseForUserError(res);
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to load user profile');
  }

  // Complete customer profile after OTP (name, age, sex, email, location)
  static Future<Map<String, dynamic>> completeProfile({
    required String name,
    required int age,
    required String sex,
    String? email,
    String? addressText,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/auth/customer/complete-profile'),
      headers: _authHeaders,
      body: jsonEncode({
        'fullName': name,
        'age': age,
        'sex': sex,
        'email': email,
        'addressText': addressText,
        'serviceArea': addressText,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ));
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body['data'] ?? body;
    throw Exception(body['message'] ?? 'Failed to update profile');
  }

  // Cancel an active booking
  static Future<void> cancelBooking(String bookingId) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/bookings/$bookingId/cancel'),
      headers: _authHeaders,
    ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to cancel booking');
    }
  }

  // Get assigned professional details for a booking
  static Future<Map<String, dynamic>?> getBookingProDetails(String bookingId) async {
    try {
      final res = await _requestWithFallback((url) => http.get(
        Uri.parse('$url/api/v1/bookings/$bookingId'),
        headers: _authHeaders,
      ));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return (body['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {}
    return null;
  }

  // Submit Rating & Review
  static Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/bookings/$bookingId/review'),
      headers: _authHeaders,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    ));
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to submit review');
    }
  }

  // Report booking issue
  static Future<void> reportBooking({
    required String bookingId,
    required String reason,
  }) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/bookings/$bookingId/report'),
      headers: _authHeaders,
      body: jsonEncode({'reason': reason}),
    ));
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to log report');
    }
  }

  // Change password
  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final res = await _requestWithFallback((url) => http.post(
      Uri.parse('$url/api/v1/users/change-password'),
      headers: _authHeaders,
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    ));
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to change password');
    }
  }
}
