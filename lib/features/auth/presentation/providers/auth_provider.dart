import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local_auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => LocalAuthRepository());

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user != null && !user.isGuest;
});
