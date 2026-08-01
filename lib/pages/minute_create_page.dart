import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/models/login_request.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/minute_file_editor.dart';
import 'package:karnamaft/widgets/show/record_info_card.dart';
import 'package:karnamaft/widgets/show/record_field.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../models/minute_model.dart';

class MinuteCreatePage extends StatefulWidget {
  const MinuteCreatePage({super.key});

  @override
  State<MinuteCreatePage> createState() => _MinuteCreatePageState();
}

class _MinuteCreatePageState extends State<MinuteCreatePage> {
  final MinuteService _service = const MinuteService();

  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final titleController = TextEditingController();

  final textController = TextEditingController();

  final dateController = TextEditingController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  String? selectedFile;

  bool saving = false;

  DateTime selectedDate = DateTime.now();

  int? typerId;

  int? taskId;

  String? error;

  @override
  void dispose() {
    titleController.dispose();

    textController.dispose();

    dateController.dispose();

    super.dispose();
  }

  //--------------------------------------------------
  // Date
  //--------------------------------------------------

  Future<void> selectDate() async {
    final jalali = await showJalaliDropdownDialog(
      context,

      initialDate: Jalali.fromDateTime(selectedDate),
    );

    if (jalali == null) {
      return;
    }

    final gregorian = jalali.toDateTime();

    setState(() {
      selectedDate = gregorian;

      dateController.text = DateFormat("yyyy-MM-dd").format(gregorian);
    });
  }

  //--------------------------------------------------
  // Save
  //--------------------------------------------------

  Future<void> save() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("عنوان الزامی است")));

      return;
    }

    setState(() {
      saving = true;

      error = null;
    });

    try {
      final model = MinuteModel(
        id: 0,

        title: titleController.text,

        text: textController.text,

        date: selectedDate,

        file: selectedFile,

        typer_id: typerId,

        task_id: taskId, organs: [], group: [],
      );

      final result = await _service.create(model);

      if (!mounted) return;

      Navigator.pop(context, result);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(title: const Text("ایجاد صورتجلسه"), centerTitle: false),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            //--------------------------------------------------
            // File
            //--------------------------------------------------
            MinuteFileEditor(
              file: selectedFile,

              onChanged: (value) {
                setState(() {
                  selectedFile = value;
                });
              },
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Title
            //--------------------------------------------------
            TextField(
              controller: titleController,

              minLines: 1,

              maxLines: 4,

              decoration: InputDecoration(
                labelText: "عنوان",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                prefixIcon: const Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Text
            //--------------------------------------------------
            TextField(
              controller: textController,

              minLines: 5,

              maxLines: 15,

              decoration: InputDecoration(
                labelText: "متن صورتجلسه",

                alignLabelWithHint: true,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 120),

                  child: Icon(Icons.notes),
                ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Information
            //--------------------------------------------------
            RecordInfoCard(
              children: [
                TextField(
                  controller: dateController,

                  readOnly: true,

                  onTap: selectDate,

                  decoration: InputDecoration(
                    labelText: "تاریخ",

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),

                      onPressed: selectDate,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                //--------------------------------------------------
                // Task
                //--------------------------------------------------
                InkWell(
                  onTap: () {
                    // اینجا بعداً انتخاب جلسه اضافه می‌شود
                  },

                  child: Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffdddddd)),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [
                        const Icon(Icons.event_note),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            taskId == null
                                ? "انتخاب جلسه"
                                : "جلسه شماره $taskId",

                            style: const TextStyle(fontSize: 15),
                          ),
                        ),

                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                //--------------------------------------------------
                // Type
                //--------------------------------------------------
                InkWell(
                  onTap: () {
                    // انتخاب نویسنده
                  },

                  child: Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffdddddd)),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [
                        const Icon(Icons.person),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            typerId == null
                                ? "انتخاب نویسنده"
                                : "کاربر شماره $typerId",
                          ),
                        ),

                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),

                margin: const EdgeInsets.only(bottom: 16),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),

            //--------------------------------------------------
            // Save Button
            //--------------------------------------------------
            SizedBox(
              height: 52,

              child: FilledButton.icon(
                icon: saving
                    ? const SizedBox(
                        width: 22,

                        height: 22,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),

                label: Text(saving ? "در حال ثبت..." : "ثبت صورتجلسه"),

                onPressed: saving ? null : save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
