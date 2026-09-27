import 'package:flutter/material.dart';
import 'package:karnamaft/services/file_service.dart';
import 'package:karnamaft/widgets/record_share_dialog.dart';
import 'package:intl/intl.dart';

import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/letter_show_page.dart';
import 'package:karnamaft/pages/minute_show_page.dart';
import 'package:karnamaft/pages/task_show_page.dart';
import 'package:karnamaft/pages/project_report_page.dart';
import 'package:karnamaft/models/project_model.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/utils/date_helper.dart';

import 'package:karnamaft/widgets/record_chip_list.dart';
import 'package:karnamaft/widgets/project_children_section.dart';
import 'package:karnamaft/widgets/show/record_field.dart';
import 'package:karnamaft/widgets/show/record_info_card.dart';
import 'package:karnamaft/widgets/show/record_text.dart';
import 'package:karnamaft/widgets/show/record_title.dart';

import 'package:provider/provider.dart';

class ProjectShowPage extends StatefulWidget {
  final int id;
  final String title;

  const ProjectShowPage({super.key, required this.id, required this.title});

  @override
  State<ProjectShowPage> createState() => _ProjectShowPageState();
}

class _ProjectShowPageState extends State<ProjectShowPage> {
  UserController get user => context.read<UserController>();

  final ProjectService _service = const ProjectService();

  bool loading = true;

  bool editing = false;

  String? error;

  ProjectModel? project;

  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController descriptionController = TextEditingController();
  late final TextEditingController requiredAmountController = TextEditingController();
  late final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadData();
  }

  @override
  void dispose() {
    nameController.dispose();

    descriptionController.dispose();

    requiredAmountController.dispose();

    amountController.dispose();

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
        project = result;

        nameController.text = result.name;
        descriptionController.text = result.description ?? "";
        requiredAmountController.text = result.requiredAmount?.toString() ?? "";
        amountController.text = result.amount?.toString() ?? "";
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

  Widget _relatedSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e9f2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Future<void> _shareRecord() async {
    final item = project;
    if (item == null) return;
    await showRecordShareDialog(
      context,
      title: 'دستورکار',
      fields: [
        ShareField(label: 'شناسه', value: '${item.id}'),
        ShareField(label: 'عنوان', value: item.name),
        ShareField(label: 'توضیحات', value: item.description ?? ''),
        ShareField(label: 'وضعیت', value: item.statusTitle),
        ShareField(label: 'سازمان', value: item.organ?.name ?? ''),
        ShareField(label: 'شهر', value: item.city?.name ?? ''),
        ShareField(label: 'تاریخ ثبت', value: DateHelper.toDateTime(item.createdAt)),
      ],
    );
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

    final item = project!;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: Text(widget.title),

        actions: [
          IconButton(
            tooltip: 'اشتراک‌گذاری',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareRecord(),
          ),
          IconButton(
            tooltip: 'گزارش آماری',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectReportPage(id: item.id, title: item.name),
              ),
            ),
          ),
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
              // نام پروژه
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: nameController,

                      decoration: const InputDecoration(
                        labelText: "نام پروژه",

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

                      minLines: 4,

                      maxLines: 10,

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

                  RecordField(title: "وضعیت", value: item.statusTitle),

                  RecordField(
                    title: "مبلغ مورد نیاز",

                    value: item.requiredAmount != null
                        ? item.requiredAmount!.toString()
                        : "-",
                  ),

                  RecordField(
                    title: "مبلغ انجام شده",

                    value: item.amount != null ? item.amount!.toString() : "-",
                  ),

                  if (item.organ != null)
                    RecordField(title: "سازمان", value: item.organ!.name),

                  if (item.city != null)
                    RecordField(title: "محدوده", value: item.city!.name),
                ],
              ),

              const SizedBox(height: 16),

              //--------------------------------------------------
              // گروه ها
              //--------------------------------------------------
              if (item.groups.isNotEmpty)
                RecordChipList(
                  title: "گروه‌ها",

                  icon: Icons.groups_outlined,

                  items: item.groups.map((e) => e.name).toList(),
                ),

              ProjectChildrenSection(projectId: widget.id),

              //--------------------------------------------------
              // کاربر ثبت کننده
              //--------------------------------------------------
              if (item.user != null)
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
                      CircleAvatar(
                        radius: 38,

                        backgroundColor: const Color(0xffe9eef6),

                        backgroundImage:
                            (item.user!.avatarUrl != null &&
                                item.user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(
                                "https://hajideligani.ir/api/get_avatar/${item.user!.avatarUrl}",

                                headers: {
                                  "Authorization": "Bearer ${user.token}",
                                },
                              )
                            : null,

                        child:
                            (item.user!.avatarUrl == null ||
                                item.user!.avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,

                                size: 32,

                                color: Colors.grey,
                              )
                            : null,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "مسئول",

                              style: TextStyle(
                                fontSize: 12,

                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              item.user!.name,

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
                ),

              const SizedBox(height: 28),

              //--------------------------------------------------
              // دکمه ها
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

  Future<void> save() async {
    if (project == null) {
      return;
    }

    final model = project!.copyWith(
      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      requiredAmount: double.tryParse(requiredAmountController.text.trim()),

      amount: double.tryParse(amountController.text.trim()),
    );

    setState(() {
      loading = true;
    });

    try {
      final result = await _service.update(project!.id, model);

      if (!mounted) {
        return;
      }

      setState(() {
        project = result;

        editing = false;

        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("پروژه با موفقیت ذخیره شد.")),
      );
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
