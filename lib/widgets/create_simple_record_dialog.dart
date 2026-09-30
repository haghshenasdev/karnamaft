import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/record_item.dart';

Future<RecordItem?> showSimpleRecordCreateDialog(
  BuildContext context, {
  required String resource,
  required String title,
  String fieldLabel = 'عنوان',
}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<RecordItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText: fieldLabel,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) async {
            final item = await _create(context, resource, controller.text);
            if (item != null && dialogContext.mounted) Navigator.pop(dialogContext, item);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('ایجاد'),
            onPressed: () async {
              final item = await _create(context, resource, controller.text);
              if (item != null && dialogContext.mounted) Navigator.pop(dialogContext, item);
            },
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

Future<RecordItem?> _create(BuildContext context, String resource, String name) async {
  final value = name.trim();
  if (value.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عنوان را وارد کنید.')));
    return null;
  }
  try {
    final response = await ApiClient.dio.post(
      '/mobile/v1/$resource',
      data: {'name': value},
    );
    final data = Map<String, dynamic>.from(response.data['data'] ?? {});
    return RecordItem(
      id: data['id'] ?? 0,
      title: (data['name'] ?? data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      from: null,
      to: null,
      number: (data['id'] ?? '').toString(),
      date: data['created_at'] != null ? DateTime.tryParse(data['created_at'].toString()) : null,
      tag: null,
      status: null,
      hasAttachment: false,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiErrorHandler.handle(e).toString())),
      );
    }
    return null;
  }
}
