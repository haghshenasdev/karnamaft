import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';

class TaskCreatePage extends StatefulWidget {
  final String? initialFilePath;

  const TaskCreatePage({
    super.key,
    this.initialFilePath,
  });

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final GlobalKey<FormState> form = GlobalKey<FormState>();

  final TextEditingController name = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController progress = TextEditingController();
  final TextEditingController amount = TextEditingController();

  final List<String> selectedFiles = [];

  int status = 0;
  bool completed = false;
  bool repeat = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final path = widget.initialFilePath;

    if (path != null && path.isNotEmpty) {
      selectedFiles.add(path);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    progress.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
      ],
    );

    if (result == null) return;

    final valid = <String>[];

    for (final file in result.files) {
      final path = file.path;

      if (path == null || path.isEmpty) {
        continue;
      }

      if (file.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فایل «${file.name}» بیشتر از ۲۰ مگابایت است و اضافه نشد.',
              ),
            ),
          );
        }
        continue;
      }

      if (!selectedFiles.contains(path)) {
        valid.add(path);
      }
    }

    if (!mounted || valid.isEmpty) return;

    setState(() {
      selectedFiles.addAll(valid);
    });
  }

  void removeFile(String path) {
    setState(() {
      selectedFiles.remove(path);
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final formData = FormData();

      formData.fields.addAll([
        MapEntry('name', name.text.trim()),
        MapEntry('description', description.text.trim()),
        MapEntry('status', status.toString()),
        MapEntry(
          'progress',
          int.tryParse(progress.text)?.toString() ?? '',
        ),
        MapEntry(
          'amount',
          double.tryParse(amount.text)?.toString() ?? '',
        ),
        MapEntry('completed', completed ? '1' : '0'),
        MapEntry('repeat', repeat ? '1' : '0'),
      ]);

      for (final path in selectedFiles) {
        formData.files.add(
          MapEntry(
            'upload_files[]',
            await MultipartFile.fromFile(
              path,
              filename: path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await ApiClient.dio.post(
        '/mobile/v1/tasks',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        response.data['data'],
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiErrorHandler.handle(e).toString(),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Widget buildFiles() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ضمیمه‌ها',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: saving ? null : pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('افزودن فایل'),
                ),
              ],
            ),
            if (selectedFiles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'فایلی انتخاب نشده است.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              for (final path in selectedFiles)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(
                    path.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'حذف',
                    onPressed: saving
                        ? null
                        : () => removeFile(path),
                    icon: const Icon(Icons.close),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ایجاد فعالیت'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('ذخیره'),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            buildFiles(),
            const SizedBox(height: 14),
            TextFormField(
              controller: name,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'عنوان *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'عنوان الزامی است';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: description,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'وضعیت',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text('جدید'),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text('اتمام'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('در حال پیگیری'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('غیرقابل پیگیری'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  status = value ?? 0;
                });
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: progress,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'درصد انجام',
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'اعتبار',
                      suffixText: 'ریال',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              value: completed,
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() {
                        completed = value;
                      });
                    },
              title: const Text('انجام شده'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              value: repeat,
              onChanged: saving
                  ? null
                  : (value) {
                      setState(() {
                        repeat = value;
                      });
                    },
              title: const Text('تکرارشونده'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
