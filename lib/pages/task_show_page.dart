import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/task_model.dart';
import 'package:karnamaft/services/task_service.dart';
import 'package:karnamaft/utils/date_helper.dart';

import 'package:provider/provider.dart';

import '../widgets/record_chip_list.dart';
import '../widgets/show/record_field.dart';
import '../widgets/show/record_info_card.dart';
import '../widgets/show/record_preview.dart';
import '../widgets/show/record_text.dart';
import '../widgets/show/record_title.dart';

class TaskShowPage extends StatefulWidget {
  final int id;
  final String title;

  const TaskShowPage({super.key, required this.id, required this.title});

  @override
  State<TaskShowPage> createState() => _TaskShowPageState();
}

class _TaskShowPageState extends State<TaskShowPage> {
  UserController get user => context.read<UserController>();

  final TaskService _service = const TaskService();

  bool loading = true;

  bool editing = false;

  String? error;

  TaskModel? task;

  String? newUploadFile;

  late TextEditingController nameController;

  late TextEditingController descriptionController;

  late TextEditingController progressController;

  @override
  void initState() {
    super.initState();

    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();

    descriptionController.dispose();

    progressController.dispose();

    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;

      error = null;
    });

    try {
      final result = await _service.show(widget.id);

      if (!mounted) return;

      setState(() {
        task = result;

        nameController = TextEditingController(text: result.name);

        descriptionController = TextEditingController(
          text: result.description ?? "",
        );

        progressController = TextEditingController(
          text: result.progress?.toString() ?? "",
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),

        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

    final item = task!;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: Text(widget.title),

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
              // عنوان
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: nameController,

                      decoration: const InputDecoration(
                        labelText: "عنوان",

                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordTitle(title: item.name),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // توضیحات
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: descriptionController,

                      minLines: 5,

                      maxLines: 12,

                      decoration: const InputDecoration(
                        labelText: "توضیحات",

                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordText(text: item.description),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // اطلاعات اصلی
              //--------------------------------------------------
              RecordInfoCard(
                children: [
                  RecordField(title: "شناسه", value: item.id.toString()),

                  if (item.createdAt != null)
                    RecordField(
                      title: "تاریخ ثبت",

                      value: DateHelper.toDate(item.createdAt),
                    ),

                  RecordField(
                    title: "وضعیت",

                    value: item.completed == 1 ? "تکمیل شده" : "در حال انجام",
                  ),

                  RecordField(title: "پیشرفت", value: "${item.progress ?? 0}٪"),

                  if (item.organ != null)
                    RecordField(title: "سازمان", value: item.organ!.name),

                  if (item.city != null)
                    RecordField(title: "محدوده", value: item.city!.name),
                ],
              ),

              const SizedBox(height: 16),

              //--------------------------------------------------
              // مسئول
              //--------------------------------------------------
              if (item.responsible != null)
                _userCard(title: "مسئول", user: item.responsible!),

              const SizedBox(height: 12),

              //--------------------------------------------------
              // ایجاد کننده
              //--------------------------------------------------
              if (item.creator != null)
                _userCard(title: "ایجاد کننده", user: item.creator!),

              //--------------------------------------------------
              // پروژه ها
              //--------------------------------------------------
              if (item.projects.isNotEmpty)
                RecordChipList(
                  title: "پروژه‌ها",

                  icon: Icons.folder_outlined,

                  items: item.projects.map((e) => e.name).toList(),
                ),

              //--------------------------------------------------
              // گروه ها
              //--------------------------------------------------
              if (item.taskGroups.isNotEmpty)
                RecordChipList(
                  title: "گروه کار",

                  icon: Icons.groups_outlined,

                  items: item.taskGroups.map((e) => e.name).toList(),
                ),

              //--------------------------------------------------
              // صورتجلسه
              //--------------------------------------------------
              if (item.minutes != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: const Color(0xffe5e9f2)),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "صورتجلسه مرتبط",

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(item.minutes!.title),

                      if (item.minutes!.date != null)
                        Text(
                          DateHelper.toDate(item.minutes!.date),

                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              //--------------------------------------------------
              // ذخیره
              //--------------------------------------------------
              if (editing)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: save,

                        icon: const Icon(Icons.save),

                        label: const Text("ذخیره"),
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

  Widget _userCard({required String title, required TaskUser user}) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xffe5e9f2)),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 32,

            backgroundColor: const Color(0xffe9eef6),

            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(
                    "https://hajideligani.ir/api/get_avatar/${user.avatarUrl}",

                    headers: {"Authorization": "Bearer ${this.user.token}"},
                  )
                : null,

            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                : null,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Text(
                  user.name,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight: FontWeight.w600,

                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    if (task == null) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final model = task!.copyWith(
        name: nameController.text.trim(),

        description: descriptionController.text.trim(),

        progress: int.tryParse(progressController.text),
      );

      final result = await _service.update(
        task!.id,

        model,

        uploadFile: newUploadFile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        task = result;

        editing = false;

        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تسک با موفقیت ذخیره شد.")));
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
