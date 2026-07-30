import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/storage/auth_storage.dart';

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
      final formData = FormData.fromMap({
        "_method": "PUT",

        "title": model.title,

        "text": model.text ?? "",

        "file": model.file ?? "none",

        "date": model.date!.toIso8601String(),

        "typer_id": model.typer_id,

        "task_id": model.task_id,

        if (uploadFile != null)
          "upload_file": await MultipartFile.fromFile(uploadFile),
      });

      final response = await ApiClient.dio.post(
        "$rootPath/$id",

        data: formData,

        options: Options(contentType: "multipart/form-data"),
      );

      return MinuteModel.fromJson(response.data["data"]);
    } catch (e) {
      if (e is DioException) {
        print(e.response?.data);
      }

      throw ApiErrorHandler.handle(e);
    }
  }
}
