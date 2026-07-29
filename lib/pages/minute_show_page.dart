import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/show/record_field.dart';

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
  var user = UserController();
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
        titleController = TextEditingController(text: result.title);
        textController = TextEditingController(text: result.text);
        dateController = TextEditingController(
          text: DateHelper.toDate(result.date),
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

              //--------------------------------------------------
              // Title
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: titleController,
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
                            decoration: const InputDecoration(
                              labelText: "تاریخ",
                              border: OutlineInputBorder(),
                            ),
                          )
                        : RecordField(
                            title: "تاریخ",
                            value: DateHelper.toDate(item.date),
                          ),

                  if (item.typer != null)
                    RecordField(title: "نویسنده", value: item.typer!.name),
                  if (item.typer?.avatarUrl != null)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xffe9eef6),

                      backgroundImage: NetworkImage(
                        "https://hajideligani.ir/api/get_avatar/${item.typer?.avatarUrl}",
                        headers: {"Authorization": "Bearer ${user.token}"},
                      ),
                    ),

                  if (item.taskCreator != null)
                    RecordField(title: "جلسه", value: item.taskCreator!.name),
                  if (item.organs.isNotEmpty)
                    RecordField(
                      title: "امضا کنندگان",
                      value: item.organs.map((e) => e.name).join("، "),
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
    );

    setState(() {
      loading = true;
    });

    try {
      final result = await _service.update(minute!.id, model);

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
}
