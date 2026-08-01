import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';

import 'package:karnamaft/models/project_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';

import 'package:karnamaft/services/RecordService.dart';

import 'package:karnamaft/widgets/date_record_filter.dart';

class ProjectService implements RecordService<ProjectModel> {
  const ProjectService();

  final String rootPath = "/admin/projects";

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

      final List<dynamic> items = json["data"] ?? [];

      final records = items
          .map((e) => ProjectModel.fromJson(e).toRecord())
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

  Future<ProjectModel> show(int id) async {
    try {
      final response = await ApiClient.dio.get("$rootPath/$id");

      return ProjectModel.fromJson(response.data["data"]);
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await ApiClient.dio.delete("$rootPath/$id");

      return response.statusCode == 200;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<ProjectModel> update(int id, ProjectModel model) async {
    try {
      final formData = FormData.fromMap({
        "_method": "PUT",

        "name": model.name,

        "description": model.description ?? "",

        "status": model.status,

        "required_amount": model.requiredAmount,

        "amount": model.amount,
      });

      final response = await ApiClient.dio.post(
        "$rootPath/$id",

        data: formData,

        options: Options(contentType: "multipart/form-data"),
      );

      return ProjectModel.fromJson(response.data["data"]);
    } catch (e) {
      if (e is DioException) {
        print(e.response?.data);
      }

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

    RecordFilter(
      key: "status",

      field: "status",

      title: "وضعیت",

      icon: Icons.flag_outlined,

      builder: (context, values, refresh, field) {
        return DropdownButtonFormField<String>(
          value: values[field],

          items: [
            const DropdownMenuItem(value: "1", child: Text("فعال")),

            const DropdownMenuItem(value: "2", child: Text("در حال انجام")),

            const DropdownMenuItem(value: "3", child: Text("تکمیل شده")),
          ],

          onChanged: (v) {
            if (v != null) {
              values[field] = v;

              refresh();
            }
          },
        );
      },
    ),
  ];
}
