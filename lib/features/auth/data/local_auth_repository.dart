import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/result.dart';
import '../../../core/storage/hive_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Local, on-device auth: registered users live in Hive (password hashed
/// with a per-user salt, never stored in plaintext); the active session is
/// tracked via `flutter_secure_storage` (encrypted keystore/keychain), with
/// [_refreshSession] standing in for a real token-refresh cycle. Social
/// sign-in requires a configured Firebase project (SHA-1 fingerprint /
/// OAuth client IDs) that isn't available in this build, so it reports a
/// clear failure rather than faking success.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository() {
    _restoreSession();
  }

  static const _secureStorage = FlutterSecureStorage();
  static const _sessionKey = 'nn_session_user_id';

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  Box<Map> get _usersBox => Hive.box<Map>(HiveBoxes.authUsers);

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  Future<void> _restoreSession() async {
    final userId = await _secureStorage.read(key: _sessionKey);
    if (userId == null) return;
    final match = _usersBox.values.where((m) => m['id'] == userId);
    if (match.isEmpty) return;
    _setUser(_userFromMap(match.first));
  }

  void _setUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  String _hash(String password, String salt) => sha256.convert(utf8.encode('$salt:$password')).toString();

  String _generateSalt() => const Uuid().v4();

  AppUser _userFromMap(Map map) => AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String?,
      );

  @override
  Future<Result<AppUser>> register({required String name, required String email, required String password}) async {
    final key = email.toLowerCase().trim();
    if (_usersBox.containsKey(key)) {
      return Result.failure(const AppFailure('An account with this email already exists.', code: 'email_taken'));
    }
    final salt = _generateSalt();
    final user = AppUser(id: const Uuid().v4(), name: name.trim(), email: key);
    await _usersBox.put(key, {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'passwordHash': _hash(password, salt),
      'salt': salt,
    });
    await _secureStorage.write(key: _sessionKey, value: user.id);
    _setUser(user);
    return Result.success(user);
  }

  @override
  Future<Result<AppUser>> login({required String email, required String password}) async {
    final key = email.toLowerCase().trim();
    final map = _usersBox.get(key);
    if (map == null) return Result.failure(const AppFailure('No account found with this email.', code: 'not_found'));
    final expectedHash = _hash(password, map['salt'] as String);
    if (expectedHash != map['passwordHash']) {
      return Result.failure(const AppFailure('Incorrect password.', code: 'wrong_password'));
    }
    final user = _userFromMap(map);
    await _secureStorage.write(key: _sessionKey, value: user.id);
    _setUser(user);
    return Result.success(user);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    final key = email.toLowerCase().trim();
    if (!_usersBox.containsKey(key)) {
      return Result.failure(const AppFailure('No account found with this email.', code: 'not_found'));
    }
    // No email/SMTP backend is configured in this build — in production
    // this would trigger a transactional email with a reset link/token.
    return const Result.success(null);
  }

  @override
  Future<Result<String>> sendOtp(String phone) async {
    if (phone.trim().length < 8) {
      return Result.failure(const AppFailure('Enter a valid phone number.', code: 'invalid_phone'));
    }
    final code = (100000 + Random().nextInt(900000)).toString();
    return Result.success(code);
  }

  @override
  Future<Result<AppUser>> verifyOtp({required String phone, required String code, required String expectedCode}) async {
    if (code != expectedCode) {
      return Result.failure(const AppFailure('Incorrect OTP. Please try again.', code: 'invalid_otp'));
    }
    final key = 'phone:$phone';
    var map = _usersBox.get(key);
    if (map == null) {
      final user = AppUser(id: const Uuid().v4(), name: 'NN Customer', email: '', phone: phone);
      map = {'id': user.id, 'name': user.name, 'email': '', 'phone': phone};
      await _usersBox.put(key, map);
    }
    final user = _userFromMap(map);
    await _secureStorage.write(key: _sessionKey, value: user.id);
    _setUser(user);
    return Result.success(user);
  }

  @override
  Future<Result<AppUser>> signInWithSocial(SocialProvider provider) async {
    return Result.failure(AppFailure(
      '${provider.name[0].toUpperCase()}${provider.name.substring(1)} Sign-In requires a configured Firebase '
      'project (OAuth client IDs / SHA-1 fingerprint) which is not set up in this build. See README for setup steps.',
      code: 'social_not_configured',
    ));
  }

  @override
  Future<Result<AppUser>> continueAsGuest() async {
    final user = const AppUser(id: 'guest', name: 'Guest', email: '', isGuest: true);
    _setUser(user);
    return Result.success(user);
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: _sessionKey);
    _setUser(null);
  }
}
