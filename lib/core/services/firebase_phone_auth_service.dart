import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebasePhoneAuthProvider = Provider((ref) => FirebasePhoneAuthService());

class FirebasePhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This will store the verification ID when code is sent
  String? _verificationId;
  String? get verificationId => _verificationId;

  // Sends the OTP to the specified phone number (needs to include country code e.g. +201012345678)
  Future<void> sendOtp({
    required String phone,
    required Function() onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on some Android devices
          debugPrint('Verification completed automatically');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.message}');
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verifies the OTP entered by the user
  Future<String?> verifyOtpAndGetIdToken(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('Verification ID is null. Please request OTP first.');
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final String? idToken = await userCredential.user?.getIdToken(true);

      // Note: We might want to sign out immediately if we only use Firebase for verification
      // await _auth.signOut();

      return idToken;
    } catch (e) {
      debugPrint('OTP Verification error: $e');
      return null;
    }
  }
}
