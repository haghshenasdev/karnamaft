import 'package:flutter/material.dart';
import 'package:karnamaft/services/RecordService.dart';

import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import '../models/minutes_group_model.dart';
import '../models/page_result.dart';
import '../models/record_filter.dart';
import '../models/record_item.dart';

class MinutesGroupService implements RecordService {
  const MinutesGroupService();

  static const String rootPath = "/admin/minutes-groups";

  @override
  Future<PageResult<RecordItem>> list({
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

      if (search != null && search.isNotEmpty) {
        query["search"] = search;
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

      final items = (json["data"] as List)
          .map((e) => MinutesGroupModel.fromJson(e).toRecord())
          .toList();

      return PageResult<RecordItem>(
        data: items,
        currentPage: json["meta"]["current_page"] ?? 1,
        lastPage: json["meta"]["last_page"] ?? 1,
        total: json["meta"]["total"] ?? items.length,
        perPage: json["meta"]["per_page"] ?? items.length,
      );
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<MinutesGroupModel> show(int id) async {
    try {
      final response = await ApiClient.dio.get("$rootPath/$id");

      return MinutesGroupModel.fromJson(response.data["data"]);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  List<RecordFilter> get filters => const [];
  
  @override
  Future<bool> delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }
}
