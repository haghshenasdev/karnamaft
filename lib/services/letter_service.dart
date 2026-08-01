import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/letter_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/storage/auth_storage.dart';
import 'package:karnamaft/widgets/date_record_filter.dart';

class LetterService implements RecordService<LetterModel> {
  const LetterService();

  final String rootPath = "/admin/letters";

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
          .map((e) => LetterModel.fromJson(e).toRecord())
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

  Future<LetterModel> show(int id) async {
    try {
      final response = await ApiClient.dio.get("$rootPath/$id");

      return LetterModel.fromJson(response.data["data"]);
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

  Future<Uint8List?> getFile(int id, String? fileName) async {
    if (fileName == null || fileName.trim().isEmpty) {
      return null;
    }

    final token = await AuthStorage.getToken();

    final response = await ApiClient.dio.get<List<int>>(
      "/private-show/$id/$id.$fileName",
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

  Future<LetterModel> update(
    int id,
    LetterModel model, {
    String? uploadFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        "_method": "PUT",

        "subject": model.subject,
        "description": model.description ?? "",
        "summary": model.summary ?? "",
        "status": model.status,
        "kind": model.kind,
        "daftar_id": model.daftar?.id,
        "created_at": model.created_at,

        if (uploadFile != null)
          "upload_file": await MultipartFile.fromFile(uploadFile),
      });

      final response = await ApiClient.dio.post(
        "$rootPath/$id",
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      return LetterModel.fromJson(response.data["data"]);
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

    // RecordFilter(
    //   key: "status",
    //   title: "وضعیت",
    //   icon: Icons.flag,

    //   builder: (context, values, refresh) {
    //     return DropdownButtonFormField<String>(
    //       value: values["status"],

    //       items: [
    //         "فعال",
    //         "مختومه",
    //       ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),

    //       onChanged: (v) {
    //         if (v != null) {
    //           values["status"] = v;
    //           refresh();
    //         }
    //       },
    //     );
    //   },
    // ),
  ];
}
