import '../api/api_client.dart';
import '../api/api_error_handler.dart';

class TitleSuggestion {
  final int id;
  final String name;

  const TitleSuggestion({required this.id, required this.name});

  factory TitleSuggestion.fromJson(dynamic value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    return TitleSuggestion(
      id: int.tryParse('${json['id'] ?? ''}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class TitleAnalysisResult {
  final String? cityName;
  final int? organId;
  final String? organName;
  final List<int> categoryIds;
  final List<String> categoryNames;
  final List<TitleSuggestion> projects;
  final List<TitleSuggestion> tasks;

  const TitleAnalysisResult({
    this.cityName,
    this.organId,
    this.organName,
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.projects = const [],
    this.tasks = const [],
  });

  factory TitleAnalysisResult.fromJson(Map<String, dynamic> json) => TitleAnalysisResult(
    cityName: json['city_name']?.toString(),
    organId: int.tryParse('${json['organ_id'] ?? ''}'),
    organName: json['organ_name']?.toString(),
    categoryIds: (json['category_ids'] as List? ?? [])
        .map((e) => int.tryParse(e.toString())).whereType<int>().toList(),
    categoryNames: (json['category_names'] as List? ?? []).map((e) => e.toString()).toList(),
    projects: (json['projects'] as List? ?? []).map(TitleSuggestion.fromJson)
        .where((e) => e.id > 0 && e.name.isNotEmpty).toList(),
    tasks: (json['tasks'] as List? ?? []).map(TitleSuggestion.fromJson)
        .where((e) => e.id > 0 && e.name.isNotEmpty).toList(),
  );
}

class TitleAnalysisService {
  const TitleAnalysisService();

  Future<TitleAnalysisResult> analyze(String title, {String resource = 'letters'}) async {
    try {
      final response = await ApiClient.dio.post(
        '/mobile/v1/analyze-title',
        data: {'title': title.trim(), 'resource': resource},
      );
      final body = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
      final data = body['data'] is Map ? Map<String, dynamic>.from(body['data']) : <String, dynamic>{};
      return TitleAnalysisResult.fromJson(data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
