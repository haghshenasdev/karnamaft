import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/letter_timeline.dart';

class LetterTimelineService {
  const LetterTimelineService();

  Future<List<LetterTimelineItem>> list(int letterId) async {
    try {
      final response = await ApiClient.dio.get(
        '/mobile/v1/letters/$letterId/timeline',
      );

      final data = response.data is Map ? response.data['data'] : null;

      return (data is List ? data : const [])
          .whereType<Map>()
          .map(
            (e) => LetterTimelineItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
