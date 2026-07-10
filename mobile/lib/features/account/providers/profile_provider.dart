import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/features/auth/models/user_model.dart';
import 'package:pair/features/onboarding/services/profile_service.dart';

final profileProvider = FutureProvider.autoDispose<UserModel>((ref) {
  return ref.watch(profileServiceProvider).getProfile();
});
