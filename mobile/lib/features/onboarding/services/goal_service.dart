import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';

class GoalModel {
  const GoalModel({
    required this.id,
    required this.category,
    required this.title,
    required this.targetDescription,
    required this.pace,
  });

  final String id;
  final String category;
  final String title;
  final String targetDescription;
  final String pace;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      targetDescription: json['target_description'] as String,
      pace: json['pace'] as String,
    );
  }
}

class GoalService {
  GoalService(this._api);

  final ApiClient _api;

  Future<GoalModel> createGoal({
    required String category,
    required String title,
    required String targetDescription,
    required String pace,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/goals',
      data: {
        'category': category,
        'title': title,
        'target_description': targetDescription,
        'pace': pace,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return GoalModel.fromJson(response.data!);
  }
}

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService(ref.watch(apiClientProvider));
});
