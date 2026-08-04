import '../../../core/error/result.dart';
import 'app_user.dart';

enum SocialProvider { google, apple, facebook }

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<Result<AppUser>> register({required String name, required String email, required String password});

  Future<Result<AppUser>> login({required String email, required String password});

  Future<Result<void>> sendPasswordReset(String email);

  /// Demo-only OTP flow: no SMS gateway is configured, so the "sent" code
  /// is returned directly instead of dispatched over SMS. Swap for a real
  /// provider (Firebase Phone Auth / MSG91 / Twilio) before production use.
  Future<Result<String>> sendOtp(String phone);

  Future<Result<AppUser>> verifyOtp({required String phone, required String code, required String expectedCode});

  Future<Result<AppUser>> signInWithSocial(SocialProvider provider);

  Future<Result<AppUser>> continueAsGuest();

  Future<void> logout();
}
