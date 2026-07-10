import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/auth/models/user_model.dart';
import 'package:dio/dio.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<UserModel> updateProfile({
    String? name,
    String? timezone,
    String? language,
  }) async {
    final response = await _api.patch<Map<String, dynamic>>(
      '/profile',
      data: {
        if (name != null) 'name': name,
        if (timezone != null) 'timezone': timezone,
        if (language != null) 'language': language,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return UserModel.fromJson(response.data!);
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _api.postMultipart<Map<String, dynamic>>(
      '/profile/avatar',
      formData: formData,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return UserModel.fromJson(response.data!);
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(apiClientProvider));
});
