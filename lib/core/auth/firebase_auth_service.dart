import 'package:firebase_auth/firebase_auth.dart';
import '../network/api_client.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Trigger Firebase Phone SMS verification
  static Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Firebase verification failed: ${e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  /// 2. Sign in with auto-verified credential
  static Future<Map<String, dynamic>> signInWithCredential(
      PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Firebase sign-in failed');
    final idToken = await user.getIdToken();
    if (idToken == null) throw Exception('Failed to get Firebase ID token');
    return ApiClient.firebaseLogin(
      idToken: idToken,
      role: 'CUSTOMER',
      fullName: user.displayName ?? 'Customer User',
    );
  }

  /// 3. Sign in with SMS OTP code entered by user
  static Future<Map<String, dynamic>> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return signInWithCredential(credential);
  }

  /// Sign out
  static Future<void> signOut() => _auth.signOut();
}
