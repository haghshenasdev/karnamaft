import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/models/task_model.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/reference_service.dart';
import 'package:karnamaft/services/task_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';
import 'package:karnamaft/widgets/file_preview_tile.dart';
import 'package:shamsi_date/shamsi_date.dart';

class TaskCreatePage extends StatefulWidget {
  final String? initialFilePath;
  final int? initialMinutesId;

  const TaskCreatePage({
    super.key,
    this.initialFilePath,
    this.initialMinutesId,
  });

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  final GlobalKey<FormState> form = GlobalKey<FormState>();

  final name = TextEditingController();
  final description = TextEditingController();
  final progress = TextEditingController(text: '0');
  final amount = TextEditingController();

  final dateController = TextEditingController();
  final startedController = TextEditingController();
  final endedController = TextEditingController();

  final selectedFiles = <String>[];

  final service = const TaskService();

  int status = 0;
  bool completed = false;
  bool repeat = false;
  bool saving = false;

  DateTime selectedDate = DateTime.now();
  DateTime? startedAt;
  DateTime? endedAt;

  MinuteProject? selectedMinute;
  TaskUser? selectedResponsible;
  TaskCity? selectedCity;
  TaskOrgan? selectedOrgan;
  List<TaskProject> selectedProjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      selectedFiles.add(widget.initialFilePath!);
    }
    dateController.text = DateHelper.toDate(selectedDate);

    if (widget.initialMinutesId != null) {
      _loadInitialMinute(widget.initialMinutesId!);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    progress.dispose();
    amount.dispose();
    dateController.dispose();
    startedController.dispose();
    endedController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMinute(int id) async {
    try {
      final minute = await const MinuteService().show(id);
      if (!mounted) return;
      setState(() => selectedMinute = MinuteProject(id: minute.id, name: minute.title));
    } catch (_) {}
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        'pdf','jpg','jpeg','png','webp','gif','bmp','doc','docx','xls','xlsx','txt',
      ],
    );
    if (result == null || !mounted) return;

    final valid = <String>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty || selectedFiles.contains(path)) continue;
      if (file.size > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فایل «${file.name}» بیشتر از ۲۰ مگابایت است.')),
        );
        continue;
      }
      valid.add(path);
    }
    if (valid.isNotEmpty) setState(() => selectedFiles.addAll(valid));
  }

  Future<void> selectMinute() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const MinuteService(),
        config: const SelectDialogConfig(
          title: 'انتخاب صورتجلسه',
          multiSelect: false,
          historyKey: 'task_minutes',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => selectedMinute = MinuteProject(id: result.id, name: result.title));
    }
  }

  Future<void> selectResponsible() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ReferenceService('users'),
        config: const SelectDialogConfig(
          title: 'انتخاب مسئول',
          multiSelect: false,
          historyKey: 'task_responsible',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => selectedResponsible = TaskUser(id: result.id, name: result.title));
    }
  }

  Future<void> selectCity() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ReferenceService('cities'),
        config: const SelectDialogConfig(
          title: 'انتخاب محدوده (شهر)',
          multiSelect: false,
          historyKey: 'task_city',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => selectedCity = TaskCity(id: result.id, name: result.title));
    }
  }

  Future<void> selectOrgan() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ReferenceService('organs'),
        config: const SelectDialogConfig(
          title: 'انتخاب دستگاه مربوطه',
          multiSelect: false,
          historyKey: 'task_organ',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => selectedOrgan = TaskOrgan(id: result.id, name: result.title));
    }
  }

  Future<void> selectProjects() async {
    final result = await showDialog<List<RecordItem>>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ReferenceService('projects'),
        config: const SelectDialogConfig(
          title: 'انتخاب دستورکارها',
          multiSelect: true,
          historyKey: 'task_projects',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selectedProjects = result
            .map((e) => TaskProject(id: e.id, name: e.title))
            .toList();
      });
    }
  }

  Future<void> selectDate() async {
    final j = await showJalaliDropdownDialog(
      context,
      initialDate: Jalali.fromDateTime(selectedDate),
    );
    if (j == null || !mounted) return;
    selectedDate = j.toDateTime();
    setState(() => dateController.text = DateHelper.toDate(selectedDate));
  }

  Future<DateTime?> pickDateTime(DateTime? current) async {
    final j = await showJalaliDropdownDialog(
      context,
      initialDate: Jalali.fromDateTime(current ?? DateTime.now()),
    );
    if (j == null || !mounted) return null;

    final base = j.toDateTime();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }

  Future<void> selectStarted() async {
    final value = await pickDateTime(startedAt);
    if (value == null || !mounted) return;
    setState(() {
      startedAt = value;
      startedController.text = DateHelper.toDateTime(value);
    });
  }

  Future<void> selectEnded() async {
    final value = await pickDateTime(endedAt);
    if (value == null || !mounted) return;
    setState(() {
      endedAt = value;
      endedController.text = DateHelper.toDateTime(value);
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;

    setState(() => saving = true);
    try {
      final model = TaskModel(
        id: 0,
        name: name.text.trim(),
        description: description.text.trim(),
        status: status,
        progress: int.tryParse(progress.text) ?? 0,
        completed: completed ? 1 : 0,
        startedAt: startedAt?.toIso8601String(),
        endedAt: endedAt?.toIso8601String(),
        completedAt: completed ? DateTime.now().toIso8601String() : null,
        amount: double.tryParse(amount.text),
        repeat: repeat ? 1 : 0,
        createdAt: selectedDate,
        updatedAt: null,
        organ: selectedOrgan,
        city: selectedCity,
        creator: null,
        responsible: selectedResponsible,
        minutes: null,
        minutesId: selectedMinute?.id,
        projects: selectedProjects,
        taskGroups: const [],
        appendixOthers: const [],
        files: const [],
      );

      final result = await service.create(model, uploadFiles: selectedFiles);
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget selection({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
    IconData icon = Icons.search,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'انتخاب',
            onPressed: saving ? null : onTap,
            icon: const Icon(Icons.search),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'حذف',
              onPressed: saving ? null : onClear,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget buildFiles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ضمیمه‌ها',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  child: Text('فایلی انتخاب نشده است.'),
                ),
              )
            else
              for (final path in selectedFiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: LocalFilePreviewTile(
                    path: path,
                    onRemove: saving ? null : () => setState(() => selectedFiles.remove(path)),
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
      appBar: AppBar(title: const Text('ایجاد فعالیت')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'عنوان الزامی است'
                  : null,
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
            selection(
              label: 'تاریخ',
              value: dateController.text,
              icon: Icons.calendar_month,
              onTap: selectDate,
            ),
            const SizedBox(height: 14),
            selection(
              label: 'شروع',
              value: startedController.text.isEmpty ? 'بدون زمان شروع' : startedController.text,
              icon: Icons.play_arrow_outlined,
              onTap: selectStarted,
              onClear: startedAt == null ? null : () => setState(() {
                startedAt = null;
                startedController.clear();
              }),
            ),
            const SizedBox(height: 14),
            selection(
              label: 'پایان',
              value: endedController.text.isEmpty ? 'بدون زمان پایان' : endedController.text,
              icon: Icons.event_outlined,
              onTap: selectEnded,
              onClear: endedAt == null ? null : () => setState(() {
                endedAt = null;
                endedController.clear();
              }),
            ),
            const SizedBox(height: 14),
            selection(
              label: 'محدوده (شهر)',
              value: selectedCity?.name ?? 'انتخاب نشده',
              icon: Icons.location_city_outlined,
              onTap: selectCity,
              onClear: selectedCity == null ? null : () => setState(() => selectedCity = null),
            ),
            const SizedBox(height: 14),
            selection(
              label: 'مسئول',
              value: selectedResponsible?.name ?? 'انتخاب نشده',
              icon: Icons.person_outline,
              onTap: selectResponsible,
              onClear: selectedResponsible == null ? null : () => setState(() => selectedResponsible = null),
            ),
            const SizedBox(height: 14),
            selection(
              label: 'دستگاه مربوطه',
              value: selectedOrgan?.name ?? 'انتخاب نشده',
              icon: Icons.business_outlined,
              onTap: selectOrgan,
              onClear: selectedOrgan == null ? null : () => setState(() => selectedOrgan = null),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'دستورکارها',
                prefixIcon: Icon(Icons.folder_outlined),
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedProjects.isEmpty
                          ? [const Text('انتخاب نشده')]
                          : selectedProjects
                              .map((e) => Chip(label: Text(e.name)))
                              .toList(),
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : selectProjects,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            selection(
              label: 'صورتجلسه مرتبط',
              value: selectedMinute?.name ?? 'بدون صورتجلسه',
              icon: Icons.description_outlined,
              onTap: selectMinute,
              onClear: selectedMinute == null ? null : () => setState(() => selectedMinute = null),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'وضعیت',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('جدید')),
                DropdownMenuItem(value: 1, child: Text('اتمام')),
                DropdownMenuItem(value: 2, child: Text('در حال پیگیری')),
                DropdownMenuItem(value: 3, child: Text('غیرقابل پیگیری')),
              ],
              onChanged: saving ? null : (v) => setState(() => status = v ?? 0),
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
              onChanged: saving ? null : (v) => setState(() => completed = v),
              title: const Text('انجام شده'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              value: repeat,
              onChanged: saving ? null : (v) => setState(() => repeat = v),
              title: const Text('تکرارشونده'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
