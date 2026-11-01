import 'dart:async';
import 'package:flutter/material.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/services/content_group_service.dart';
import '../utils/app_settings.dart';

/// انتخاب‌گر مشترک دسته‌بندی‌ها؛ شاخه‌ها فقط هنگام باز شدن از API دریافت می‌شوند.
class ContentGroupPicker {
  static Future<List<ContentGroupModel>?> show(
    BuildContext context, {
    Set<int> initialIds = const <int>{},
    List<ContentGroupModel> initialGroups = const <ContentGroupModel>[],
    String title = 'انتخاب دسته‌بندی',
    bool multiSelect = true,
  }) {
    return showDialog<List<ContentGroupModel>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentGroupDialog(
        initialIds: initialIds,
        initialGroups: initialGroups,
        title: title,
        multiSelect: multiSelect,
      ),
    );
  }
}

class ContentGroupFilter extends StatelessWidget {
  final Map<String, String> values;
  final String field;
  final VoidCallback onChanged;
  const ContentGroupFilter({super.key, required this.values, required this.field, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label = values['__label__$field'] ?? '';
    final selected = values[field] ?? '';
    return InkWell(
      onTap: () async {
        final result = await ContentGroupPicker.show(
          context,
          initialIds: selected.split(',').where((e) => e.isNotEmpty).map(int.tryParse).whereType<int>().toSet(),
        );
        if (result == null) return;
        if (result.isEmpty) {
          values.remove(field);
          values.remove('__label__$field');
        } else {
          values[field] = result.map((e) => e.id).join(',');
          values['__label__$field'] = result.map((e) => '${e.id} - ${e.name}').join('، ');
        }
        onChanged();
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'دسته‌بندی',
          prefixIcon: const Icon(Icons.account_tree_outlined),
          suffixIcon: selected.isEmpty
              ? const Icon(Icons.keyboard_arrow_down)
              : IconButton(tooltip: 'حذف فیلتر دسته‌بندی', onPressed: () { values.remove(field); values.remove('__label__$field'); onChanged(); }, icon: const Icon(Icons.clear)),
          border: const OutlineInputBorder(),
        ),
        child: Text(label.isEmpty ? 'همه دسته‌بندی‌ها' : label, maxLines: 3, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _ContentGroupDialog extends StatefulWidget {
  final Set<int> initialIds;
  final List<ContentGroupModel> initialGroups;
  final String title;
  final bool multiSelect;
  const _ContentGroupDialog({required this.initialIds, required this.initialGroups, required this.title, required this.multiSelect});
  @override State<_ContentGroupDialog> createState() => _ContentGroupDialogState();
}

class _ContentGroupDialogState extends State<_ContentGroupDialog> {
  final _service = const ContentGroupService();
  final _search = TextEditingController();
  final Set<int> _selected = <int>{};
  final Map<int, ContentGroupModel> _known = <int, ContentGroupModel>{};
  List<ContentGroupModel> _roots = <ContentGroupModel>[];
  List<ContentGroupModel> _searchResults = <ContentGroupModel>[];
  bool _loadingRoots = true;
  bool _searching = false;
  Timer? _searchDebounce;
  int _searchRequest = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialIds);
    for (final group in widget.initialGroups) { _known[group.id] = group; }
    _loadRoots();
  }

  @override
  void dispose() { _searchDebounce?.cancel(); _search.dispose(); super.dispose(); }

  Future<void> _loadRoots() async {
    try {
      final roots = await _service.children();
      if (!mounted) return;
      setState(() { _roots = roots; for (final g in roots) { _known[g.id] = g; } _loadingRoots = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loadingRoots = false; });
    }
  }

  Future<List<ContentGroupModel>> _loadChildren(int parentId) async {
    final result = await _service.children(parentId: parentId);
    for (final group in result) { _known[group.id] = group; }
    return result;
  }

  void _searchGroups(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() { _searching = false; _searchResults = []; });
      return;
    }
    setState(() { _searching = true; _searchResults = []; });
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final requestId = ++_searchRequest;
      try {
        final found = await _service.searchGroups(query);
        if (!mounted || requestId != _searchRequest || _search.text.trim() != query) return;
        setState(() { _searchResults = found; for (final g in found) { _known[g.id] = g; } });
      } catch (e) {
        if (mounted && requestId == _searchRequest) {
          setState(() { _searchResults = []; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جستجوی دسته‌بندی ناموفق بود: $e')));
        }
      } finally {
        if (mounted && requestId == _searchRequest) setState(() { _searching = false; });
      }
    });
  }

  void _toggle(ContentGroupModel group) {
    setState(() {
      if (_selected.contains(group.id)) { _selected.remove(group.id); }
      else { if (!widget.multiSelect) _selected.clear(); _selected.add(group.id); _known[group.id] = group; }
    });
  }

  Future<void> _createGroup() async {
    if (await AppSettings.getOfflineEnabled()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ایجاد دسته‌بندی در حالت آفلاین امکان‌پذیر نیست.')),
      );
      return;
    }
    List<ContentGroupModel> availableParents;
    try { availableParents = await _service.allGroups(); }
    catch (e) { availableParents = _roots; }
    final name = TextEditingController();
    bool asChild = false;
    int? parentId;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialog) => AlertDialog(
        title: const Text('ایجاد دسته‌بندی جدید'),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'نام دسته‌بندی', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<bool>(
            value: asChild,
            decoration: const InputDecoration(labelText: 'نوع دسته‌بندی', border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: false, child: Text('دسته اصلی')), DropdownMenuItem(value: true, child: Text('زیرمجموعه'))],
            onChanged: (value) => setDialog(() { asChild = value ?? false; if (!asChild) parentId = null; }),
          ),
          if (asChild) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: parentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'دسته والد', border: OutlineInputBorder()),
              items: availableParents.map((g) => DropdownMenuItem<int>(value: g.id, child: Text('${g.id} - ${g.name}', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setDialog(() => parentId = value),
            ),
          ],
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('انصراف')), FilledButton(onPressed: () { if (name.text.trim().isEmpty || (asChild && parentId == null)) return; Navigator.pop(dialogContext, {'name': name.text.trim(), 'parent_id': asChild ? parentId : null}); }, child: const Text('ایجاد'))],
      )),
    );
    final groupName = name.text.trim();
    name.dispose();
    if (result == null || groupName.isEmpty) return;
    try {
      final created = await _service.createGroup(name: result['name'] as String, parentId: result['parent_id'] as int?);
      _known[created.id] = created;
      await _loadRoots();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دسته‌بندی ایجاد شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ایجاد دسته‌بندی ناموفق بود: $e')));
    }
  }

  Widget _buildNode(ContentGroupModel group, int depth) => _LazyGroupNode(
    key: ValueKey(group.id), group: group, depth: depth, selected: _selected.contains(group.id),
    loadChildren: _loadChildren, onToggle: _toggle, isSelected: (id) => _selected.contains(id),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(width: 620, height: 620, child: Column(children: [
        TextField(controller: _search, onChanged: _searchGroups, decoration: const InputDecoration(hintText: 'جستجو بر اساس شماره یا نام دسته‌بندی', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: Text('${_selected.length} دسته انتخاب شده')), TextButton.icon(onPressed: _createGroup, icon: const Icon(Icons.create_new_folder_outlined), label: const Text('دسته‌بندی جدید'))]),
        const Divider(height: 1),
        Expanded(child: _loadingRoots
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text('خطا در دریافت دسته‌بندی‌ها: $_error'))
            : _searching
              ? const Center(child: CircularProgressIndicator())
              : _search.text.trim().isNotEmpty
                ? (_searchResults.isEmpty ? const Center(child: Text('دسته‌بندی‌ای پیدا نشد')) : ListView(children: _searchResults.map((g) => CheckboxListTile(value: _selected.contains(g.id), title: Text('${g.id} - ${g.name}'), onChanged: (_) => _toggle(g))).toList()))
                : _roots.isEmpty ? const Center(child: Text('دسته‌بندی‌ای وجود ندارد')) : ListView(children: _roots.map((g) => _buildNode(g, 0)).toList())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        TextButton(onPressed: () => Navigator.pop(context, <ContentGroupModel>[]), child: const Text('پاک کردن')),
        FilledButton(onPressed: () => Navigator.pop(context, _selected.map((id) => _known[id]).whereType<ContentGroupModel>().toList()), child: const Text('تأیید')),
      ],
    );
  }
}

class _LazyGroupNode extends StatefulWidget {
  final ContentGroupModel group;
  final int depth;
  final bool selected;
  final Future<List<ContentGroupModel>> Function(int) loadChildren;
  final ValueChanged<ContentGroupModel> onToggle;
  final bool Function(int) isSelected;
  const _LazyGroupNode({super.key, required this.group, required this.depth, required this.selected, required this.loadChildren, required this.onToggle, required this.isSelected});
  @override State<_LazyGroupNode> createState() => _LazyGroupNodeState();
}

class _LazyGroupNodeState extends State<_LazyGroupNode> {
  bool _expanded = false, _loading = false, _loaded = false;
  List<ContentGroupModel> _children = <ContentGroupModel>[];
  Future<void> _toggleExpanded() async {
    if (!_expanded && !_loaded) {
      setState(() => _loading = true);
      try { _children = await widget.loadChildren(widget.group.id); _loaded = true; }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('بارگذاری زیرمجموعه ناموفق بود: $e'))); }
      if (!mounted) return;
      setState(() => _loading = false);
    }
    if (mounted) setState(() => _expanded = !_expanded);
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: EdgeInsetsDirectional.only(start: widget.depth * 18), child: Row(children: [
      SizedBox(width: 32, child: widget.group.hasChildren ? IconButton(visualDensity: VisualDensity.compact, tooltip: _expanded ? 'بستن زیرمجموعه' : 'نمایش زیرمجموعه‌ها', onPressed: _toggleExpanded, icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_expanded ? Icons.expand_more : Icons.chevron_left)) : const SizedBox.shrink()),
      Checkbox(value: widget.selected, onChanged: (_) => widget.onToggle(widget.group)),
      Expanded(child: Text('${widget.group.id} - ${widget.group.name}', maxLines: 2, overflow: TextOverflow.ellipsis)),
    ])),
    if (_expanded) ..._children.map((child) => _LazyGroupNode(key: ValueKey(child.id), group: child, depth: widget.depth + 1, selected: widget.isSelected(child.id), loadChildren: widget.loadChildren, onToggle: widget.onToggle, isSelected: widget.isSelected)),
  ]);
}
