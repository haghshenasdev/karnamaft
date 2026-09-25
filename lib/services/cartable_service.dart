import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import '../models/cartable_model.dart';
import '../models/page_result.dart';

class CartableService {
  const CartableService();

  Future<PageResult<CartableModel>> list({
    int page = 1,
    String? search,
    bool? checked,
  }) async {
    try {
      final query = <String,dynamic>{'page':page};
      if (search != null && search.trim().isNotEmpty) query['filter[search]'] = search.trim();
      if (checked != null) query['filter[checked]'] = checked ? '1' : '0';
      final response = await ApiClient.dio.get('/mobile/v1/cartable', queryParameters: query);
      final json = response.data as Map<String,dynamic>;
      final data = (json['data'] as List? ?? []).map((e)=>CartableModel.fromJson(e)).toList();
      final meta = json['meta'] as Map<String,dynamic>? ?? {};
      return PageResult<CartableModel>(
        data: data,
        currentPage: meta['current_page'] ?? 1,
        lastPage: meta['last_page'] ?? 1,
        total: meta['total'] ?? data.length,
        perPage: meta['per_page'] ?? data.length,
      );
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }

  Future<CartableModel> setChecked(int id, bool value) async {
    try {
      final response = await ApiClient.dio.patch('/mobile/v1/cartable/$id', data: {'checked':value});
      return CartableModel.fromJson(response.data['data']);
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }
}
