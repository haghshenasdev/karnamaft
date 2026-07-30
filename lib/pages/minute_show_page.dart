import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/minute_file_editor.dart';
import 'package:karnamaft/widgets/record_chip_list.dart';
import 'package:karnamaft/widgets/show/record_field.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/show/record_info_card.dart';
import '../widgets/show/record_preview.dart';
import '../widgets/show/record_text.dart';
import '../widgets/show/record_title.dart';

class MinuteShowPage extends StatefulWidget {
  final int id;
  final String title;

  const MinuteShowPage({super.key, required this.id, required this.title});

  @override
  State<MinuteShowPage> createState() => _MinuteShowPageState();
}

class _MinuteShowPageState extends State<MinuteShowPage> {
  UserController get user => context.read<UserController>();
  //--------------------------------------------------
  // Service
  //--------------------------------------------------

  final MinuteService _service = const MinuteService();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool loading = true;
  bool editing = false;

  late TextEditingController titleController;
  late TextEditingController textController;
  late TextEditingController dateController;

  String? selectedFile;
  String? newUploadFile;

  String? error;

  MinuteModel? minute;

  //--------------------------------------------------
  // Init
  //--------------------------------------------------

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    titleController.dispose();
    textController.dispose();
    dateController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // Load
  //--------------------------------------------------

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await _service.show(widget.id);

      if (!mounted) return;

      setState(() {
        minute = result;
        selectedFile = result.file;
        titleController = TextEditingController(text: result.title);
        textController = TextEditingController(text: result.text);
        dateController = TextEditingController(
          text: result.date != null
              ? DateFormat("yyyy-MM-dd").format(result.date!)
              : "",
        );
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  //--------------------------------------------------
  // Date
  //--------------------------------------------------

  String formatDate(DateTime? date) {
    if (date == null) {
      return "-";
    }

    return DateFormat("yyyy/MM/dd HH:mm").format(date);
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    //--------------------------------------------------
    // Loading
    //--------------------------------------------------

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    //--------------------------------------------------
    // Error
    //--------------------------------------------------

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 70, color: Colors.red),

                const SizedBox(height: 20),

                Text(error!, textAlign: TextAlign.center),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("تلاش مجدد"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = minute!;

    //--------------------------------------------------
    // Success
    //--------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(editing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                editing = !editing;
              });
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //--------------------------------------------------
              // Preview
              //--------------------------------------------------
              RecordPreview(minute: item),

              const SizedBox(height: 20),

              if (editing)
                Column(
                  children: [
                    MinuteFileEditor(
                      file: selectedFile,

                      onChanged: (value) {
                        setState(() {
                          newUploadFile = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),

              //--------------------------------------------------
              // Title
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: titleController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "عنوان",
                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordTitle(title: item.title),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Text
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: textController,
                      minLines: 1,
                      maxLines: 20,
                      decoration: const InputDecoration(
                        labelText: "متن",
                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordText(text: item.text),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Information Card
              //--------------------------------------------------
              RecordInfoCard(
                children: [
                  if (item.id > 0)
                    RecordField(title: "شناسه", value: item.id.toString()),

                  if (item.date != null)
                    editing
                        ? TextField(
                            controller: dateController,

                            readOnly: true,

                            onTap: selectDate,

                            decoration: InputDecoration(
                              labelText: "تاریخ",

                              border: const OutlineInputBorder(),

                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: selectDate,
                              ),
                            ),
                          )
                        : RecordField(
                            title: "تاریخ",
                            value: DateHelper.toDate(item.date),
                          ),

                  if (item.taskCreator != null)
                    RecordField(title: "جلسه", value: item.taskCreator!.name),
                  if (item.organs.isNotEmpty)
                    RecordChipList(
                      title: "امضا کنندگان",
                      icon: Icons.business,
                      items: item.organs.map((e) => e.name).toList(),
                    ),
                  if (item.group.isNotEmpty)
                    RecordChipList(
                      title: "دسته بندی",
                      icon: Icons.sell_outlined,
                      items: item.group.map((e) => e.name).toList(),
                    ),
                  if (item.created_at != null)
                    RecordField(
                      title: "ایجاد شده",
                      value: DateHelper.toDateTime(item.created_at),
                    ),

                  if (item.updated_at != null)
                    RecordField(
                      title: "آخرین بروزرسانی",
                      value: DateHelper.toDateTime((item.updated_at)),
                    ),
                ],
              ),

              if (item.typer != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: const Color(0xffe5e9f2)),
                  ),

                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,

                        backgroundColor: const Color(0xffe9eef6),

                        backgroundImage:
                            (item.typer!.avatarUrl != null &&
                                item.typer!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(
                                "https://hajideligani.ir/api/get_avatar/${item.typer!.avatarUrl}",
                                headers: {
                                  "Authorization": "Bearer ${user.token}",
                                },
                              )
                            : null,

                        child:
                            (item.typer!.avatarUrl == null ||
                                item.typer!.avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey,
                              )
                            : null,
                      ),

                      const SizedBox(width: 14),

                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "نویسنده",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              item.typer!.name,

                              maxLines: 2,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 15,

                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // Actions
              //--------------------------------------------------
              if (editing)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),

                        label: const Text("ذخیره"),

                        onPressed: save,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            editing = false;
                          });
                        },

                        child: const Text("انصراف"),
                      ),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("بازگشت"),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    if (minute == null) {
      return;
    }

    final model = minute!.copyWith(
      title: titleController.text,
      text: textController.text,
      date: dateController.text.isNotEmpty
          ? DateTime.parse(dateController.text)
          : null,
      file: minute!.file,
    );

    // print(model.toUpdateJson());

    setState(() {
      loading = true;
    });

    try {
      final result = await _service.update(
        minute!.id,
        model,

        uploadFile: newUploadFile,
      );

      setState(() {
        minute = result;

        editing = false;

        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> selectDate() async {
    DateTime initial = minute?.date ?? DateTime.now();

    final jalali = await showJalaliDropdownDialog(
      context,
      initialDate: Jalali.fromDateTime(initial),
    );

    if (jalali == null) {
      return;
    }

    final gregorian = jalali.toDateTime();

    setState(() {
      dateController.text = DateFormat("yyyy-MM-dd").format(gregorian);
    });
  }
}
