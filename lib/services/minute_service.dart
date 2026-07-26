import 'package:dio/dio.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/models/page_result.dart';

import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class MinuteService {
  const MinuteService();
  final rootPath = "/admin/minutes";

  Future<LoginResponse> create(LoginRequest request) async {
    try {
      final response = await ApiClient.dio.post(
        rootPath,
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<PageResult<MinuteModel>> list({
    int page = 1,
    String? search,
    String? sort,
    Map<String, String>? filters,
  }) async {
    try {
      final query = <String, dynamic>{"page": page};

      if (sort != null) {
        query["sort"] = sort;
      }

      if (filters != null) {
        filters.forEach((key, value) {
          if (value.isNotEmpty) {
            query["filter[$key]"] = value;
          }
        });
      }

      final response = await ApiClient.dio.get(
        rootPath,
        queryParameters: query,
      );

      final json = response.data;

      final List<dynamic> items = json["data"] ?? [];

      return PageResult(
        data: items.map((e) => MinuteModel.fromJson(e)).toList(),

        currentPage: json["meta"]["current_page"] ?? 1,

        lastPage: json["meta"]["last_page"] ?? 1,

        total: json["meta"]["total"] ?? items.length,

        perPage: json["meta"]["per_page"] ?? items.length,
      );
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<MinuteModel> show(int id) async {
    try {
      final response = await ApiClient.dio.get("$rootPath/$id");

      return MinuteModel.fromJson(response.data["data"]);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await ApiClient.dio.delete("$rootPath/$id");

      return response.statusCode == 200 ? true : false;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }
}
