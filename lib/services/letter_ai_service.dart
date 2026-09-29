import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_error_handler.dart';

class LetterAiResult {
  final String subject;
  final String description;
  final String summary;
  final String? mokatebe;
  final int? kind;
  final DateTime? date;
  final int? organId;
  final List<int> organOwnerIds;
  final List<int> customerOwnerIds;
  final int? cityId;
  final List<int> categoryIds;
  final String? organName;
  final String? cityName;
  final List<String> categoryNames;

  const LetterAiResult({
    required this.subject,
    required this.description,
    required this.summary,
    this.mokatebe,
    this.kind,
    this.date,
    this.organId,
    this.organOwnerIds = const [],
    this.customerOwnerIds = const [],
    this.cityId,
    this.categoryIds = const [],
    this.organName,
    this.cityName,
    this.categoryNames = const [],
  });

  factory LetterAiResult.fromJson(Map<String, dynamic> j) => LetterAiResult(
    subject: j['subject']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    summary: j['summary']?.toString() ?? '',
    mokatebe: j['mokatebe']?.toString(),
    kind: j['kind'] is int ? j['kind'] : int.tryParse('${j['kind']}'),
    date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
    organId: j['organ_id'] is int ? j['organ_id'] : int.tryParse('${j['organ_id']}'),
    organOwnerIds: _ints(j['organ_owner_ids']),
    customerOwnerIds: _ints(j['customer_owner_ids']),
    cityId: j['city_id'] is int ? j['city_id'] : int.tryParse('${j['city_id']}'),
    categoryIds: _ints(j['category_ids']),
    organName: j['organ_name']?.toString(),
    cityName: j['city_name']?.toString(),
    categoryNames: (j['category_names'] as List? ?? []).map((e) => e.toString()).toList(),
  );

  static List<int> _ints(dynamic value) => (value as List? ?? [])
      .map((e) => int.tryParse(e.toString()))
      .whereType<int>()
      .toList();
}

class LetterAiService {
  const LetterAiService();

  Future<LetterAiResult> analyzeText(String text, {CancelToken? cancelToken}) async {
    try {
      final response = await ApiClient.dio.post(
      '/mobile/v1/ai/letters',
      data: {'text': text},
      cancelToken: cancelToken,
    );
    return LetterAiResult.fromJson(response.data['data'] ?? {});
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<LetterAiResult> analyzeFile({
    String? filePath,
    Uint8List? bytes,
    String? fileName,
    CancelToken? cancelToken,
  }) async {
    try {
      MultipartFile file;
      if (bytes != null) {
        file = MultipartFile.fromBytes(bytes, filename: fileName ?? 'letter.png');
      } else if (filePath != null) {
        file = await MultipartFile.fromFile(filePath, filename: filePath.split(RegExp(r'[/\\]')).last);
      } else {
        throw Exception('فایلی برای تحلیل وجود ندارد');
      }

      final response = await ApiClient.dio.post(
        '/mobile/v1/ai/letters',
        data: FormData.fromMap({'file': file}),
        options: Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
      );
      return LetterAiResult.fromJson(response.data['data'] ?? {});
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) rethrow;
      throw ApiErrorHandler.handle(e);
    }
  }
}
