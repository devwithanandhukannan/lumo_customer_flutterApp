import 'package:flutter/services.dart';

class HapticService {
  /// Light haptic vibration for button taps and minor interactions
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium haptic vibration for actions like submitting a booking
  static Future<void> bookingSubmitted() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Distinct double heavy pulse celebration vibration when a Pro accepts customer's booking
  static Future<void> proAcceptedBooking() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Selection click feedback
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
