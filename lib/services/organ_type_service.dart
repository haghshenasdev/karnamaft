import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/organ_model.dart';
import 'package:karnamaft/models/organ_type_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/widgets/date_record_filter.dart';

class OrganService implements RecordService<OrganTypeModel> {
  const OrganService();

  final String rootPath = "/admin/organs-types";

  /// دریافت لیست سازمان‌ها
  @override
  Future<PageResult<RecordItem>> list({
    int page = 1,
    String? search,
    String? sort,
    Map<String, String>? filters,
  }) async {
    try {
      final query = <String, dynamic>{"page": page};

      if (search != null && search.isNotEmpty) {
        query["search"] = search;
      }

      if (sort != null && sort.isNotEmpty) {
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

      final records = items
          .map((e) => OrganModel.fromJson(e).toRecord())
          .toList();

      return PageResult<RecordItem>(
        data: records,
        currentPage: json["meta"]["current_page"] ?? 1,
        lastPage: json["meta"]["last_page"] ?? 1,
        total: json["meta"]["total"] ?? records.length,
        perPage: json["meta"]["per_page"] ?? records.length,
      );
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<OrganModel> show(int id) async {
    try {
      final response = await ApiClient.dio.get("$rootPath/$id");

      return OrganModel.fromJson(response.data["data"]);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  List<RecordFilter> get filters => [
    RecordFilter(
      key: "date",
      field: "created_at",
      title: "تاریخ ثبت",
      icon: Icons.calendar_today,
      builder: (context, values, refresh, field) {
        return DateRecordFilter(
          values: values,
          field: field,
          onChanged: refresh,
        );
      },
    ),
  ];

  @override
  Future<bool> delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }
}
