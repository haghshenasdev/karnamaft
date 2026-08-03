import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/storage/auth_storage.dart';
import 'package:karnamaft/widgets/date_record_filter.dart';

import '../api/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class MinuteService implements RecordService<MinuteModel> {
  const MinuteService();
  final rootPath = "/admin/minutes";

  Future<MinuteModel> create(MinuteModel model, {String? uploadFile}) async {
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry("title", model.title),

        MapEntry("text", model.text ?? ""),

        MapEntry(
          "date",
          model.date != null ? model.date!.toIso8601String() : "",
        ),

        if (model.task_id != null)
          MapEntry("task_id", model.task_id.toString()),
      ]);

      // امضا کنندگان
      for (final organ in model.organs ?? []) {
        formData.fields.add(MapEntry("organ_ids[]", organ.id.toString()));
      }

      // دسته بندی ها
      for (final group in model.group ?? []) {
        formData.fields.add(MapEntry("group_ids[]", group.id.toString()));
      }

      // فایل
      if (uploadFile != null) {
        formData.files.add(
          MapEntry("upload_file", await MultipartFile.fromFile(uploadFile)),
        );
      }

      final response = await ApiClient.dio.post(
        rootPath,

        data: formData,

        options: Options(
          contentType: "multipart/form-data",
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      return MinuteModel.fromJson(response.data["data"]);
    } catch (e) {
      if (e is DioException) {
        print("CREATE MINUTE ERROR:");
        print(e.response?.data);
      }

      throw ApiErrorHandler.handle(e);
    }
  }

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
          .map((e) => MinuteModel.fromJson(e).toRecord())
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

  Future<Uint8List?> getFile(int id, String? fileName) async {
    if (fileName == null || fileName.trim().isEmpty) {
      return null;
    }

    final token = await AuthStorage.getToken();

    final response = await ApiClient.dio.get<List<int>>(
      "/appendix-other-show/minutes/$id/$id.$fileName",
      options: Options(
        responseType: ResponseType.bytes,
        headers: {"Authorization": "Bearer $token"},
      ),
    );

    if (response.data == null) {
      return null;
    }

    return Uint8List.fromList(response.data!);
  }

  Future<MinuteModel> update(
    int id,
    MinuteModel model, {
    String? uploadFile,
  }) async {
    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry("_method", "PUT"),

        MapEntry("title", model.title),

        MapEntry("text", model.text ?? ""),

        MapEntry("file", model.file ?? "none"),

        MapEntry("date", model.date!.toIso8601String()),

        MapEntry("typer_id", model.typer_id.toString()),

        MapEntry("task_id", model.task_id.toString()),
      ]);

      // اضافه کردن آرایه امضا کنندگان
      for (final organ in model.organs ?? []) {
        formData.fields.add(MapEntry("organ_ids[]", organ.id.toString()));
      }

      if (uploadFile != null) {
        formData.files.add(
          MapEntry("upload_file", await MultipartFile.fromFile(uploadFile)),
        );
      }

      final response = await ApiClient.dio.post(
        "$rootPath/$id",

        data: formData,

        options: Options(
          contentType: "multipart/form-data",
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      return MinuteModel.fromJson(response.data["data"]);
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

      field: "date",

      title: "تاریخ ",

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
}
