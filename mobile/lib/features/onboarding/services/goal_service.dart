import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';

class GoalOwner {
  const GoalOwner({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  factory GoalOwner.fromJson(Map<String, dynamic> json) {
    return GoalOwner(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class GoalModel {
  const GoalModel({
    required this.id,
    required this.category,
    required this.title,
    required this.targetDescription,
    required this.pace,
    this.isMine = true,
    this.isSearching = false,
    this.owner,
  });

  final String id;
  final String category;
  final String title;
  final String targetDescription;
  final String pace;
  final bool isMine;
  final bool isSearching;
  final GoalOwner? owner;

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String? ?? '',
      targetDescription: json['target_description'] as String? ?? '',
      pace: json['pace'] as String? ?? 'steady',
      isMine: json['is_mine'] as bool? ?? true,
      isSearching: json['is_searching'] as bool? ?? false,
      owner: json['owner'] != null
          ? GoalOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}

class GoalService {
  GoalService(this._api);

  final ApiClient _api;

  Future<List<GoalModel>> listMyGoals({required String category}) async {
    return _fetchGoals(
      queryParameters: {
        'category': category,
        'scope': 'mine',
      },
    );
  }

  Future<List<GoalModel>> browseGoals({required String category}) async {
    return _fetchGoals(
      queryParameters: {
        'category': category,
        'scope': 'browse',
      },
    );
  }

  Future<List<GoalModel>> _fetchGoals({
    required Map<String, String> queryParameters,
  }) async {
    final response = await _api.get<List<dynamic>>(
      '/goals',
      queryParameters: queryParameters,
      fromJsonT: (json) => (json as List).toList(),
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GoalModel.fromJson)
        .toList();
  }

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
