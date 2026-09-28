import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';

class ReferenceRecordFilter extends StatefulWidget {
  final String resource;
  final Map<String, String> values;
  final String field;
  final VoidCallback refresh;
  final String label;

  const ReferenceRecordFilter({
    super.key,
    required this.resource,
    required this.values,
    required this.field,
    required this.refresh,
    required this.label,
  });

  @override
  State<ReferenceRecordFilter> createState() => _ReferenceRecordFilterState();
}

class _ReferenceRecordFilterState extends State<ReferenceRecordFilter> {
  String get selectedId => widget.values[widget.field] ?? '';

  String get selectedLabel {
    return widget.values['__label__${widget.field}'] ?? '';
  }

  Future<void> openPicker() async {
    final result = await showDialog<_ReferenceChoice>(
      context: context,
      builder: (_) {
        return _ReferencePickerDialog(
          resource: widget.resource,
          title: widget.label,
          initialId: selectedId,
          initialLabel: selectedLabel,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.cleared) {
      widget.values.remove(widget.field);
      widget.values.remove('__label__${widget.field}');
    } else {
      widget.values[widget.field] = result.id;
      widget.values['__label__${widget.field}'] = result.label;
    }

    widget.refresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = selectedLabel.isEmpty ? 'همه' : selectedLabel;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: openPicker,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: selectedId.isEmpty
              ? const Icon(Icons.keyboard_arrow_down)
              : IconButton(
                  tooltip: 'پاک کردن',
                  onPressed: () {
                    widget.values.remove(widget.field);
                    widget.values.remove('__label__${widget.field}');
                    widget.refresh();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
        ),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _ReferenceChoice {
  final String id;
  final String label;
  final bool cleared;

  const _ReferenceChoice({
    required this.id,
    required this.label,
    this.cleared = false,
  });
}

class _ReferencePickerDialog extends StatefulWidget {
  final String resource;
  final String title;
  final String initialId;
  final String initialLabel;

  const _ReferencePickerDialog({
    required this.resource,
    required this.title,
    required this.initialId,
    required this.initialLabel,
  });

  @override
  State<_ReferencePickerDialog> createState() => _ReferencePickerDialogState();
}

class _ReferencePickerDialogState extends State<_ReferencePickerDialog> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> items = [];

  Timer? debounce;

  int page = 1;
  int lastPage = 1;

  bool loading = true;
  bool loadingMore = false;

  String search = '';

  @override
  void initState() {
    super.initState();

    scrollController.addListener(onScroll);
    load(reset: true);
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void onScroll() {
    if (!scrollController.hasClients) {
      return;
    }

    if (loadingMore || loading) {
      return;
    }

    if (page >= lastPage) {
      return;
    }

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 250) {
      loadMore();
    }
  }

  /// بارگذاری صفحه بعدی
  Future<void> loadMore() async {
    if (loadingMore || loading) {
      return;
    }

    if (page >= lastPage) {
      return;
    }

    await load(reset: false);
  }

  Future<void> load({required bool reset}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          loading = true;
          loadingMore = false;
          page = 1;
          lastPage = 1;
          items.clear();
        });
      }
    } else {
      if (loadingMore || page >= lastPage) {
        return;
      }

      if (mounted) {
        setState(() {
          loadingMore = true;
        });
      }
    }

    try {
      final int nextPage = reset ? 1 : page + 1;

      final response = await ApiClient.dio.get(
        '/mobile/v1/${widget.resource}/reference',
        queryParameters: {
          'page': nextPage,
          'per_page': 30,
          if (search.isNotEmpty) 'search': search,
        },
      );

      final Map<String, dynamic> data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final List<Map<String, dynamic>> rows = (data['data'] as List? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final Map<String, dynamic> meta = data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : <String, dynamic>{};

      if (!mounted) {
        return;
      }

      setState(() {
        if (reset) {
          items
            ..clear()
            ..addAll(rows);
        } else {
          items.addAll(rows);
        }

        page = _toInt(meta['current_page'], nextPage);

        lastPage = _toInt(meta['last_page'], page);

        loading = false;
        loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        loadingMore = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void onSearchChanged(String value) {
    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      search = value.trim();
      load(reset: true);
    });
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double height = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 450 ? 10 : 24,
        vertical: 24,
      ),
      child: SizedBox(
        width: width < 600 ? width - 20 : 560,
        height: height < 700 ? height - 48 : 650,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'انتخاب ${widget.title}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'بستن',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس نام یا شماره...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            search = '';
                            load(reset: true);
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) {
                  onSearchChanged(value);
                  setState(() {});
                },
              ),
            ),

            ListTile(
              dense: true,
              leading: const Icon(Icons.all_inclusive),
              title: const Text('همه'),
              selected: widget.initialId.isEmpty,
              onTap: () {
                Navigator.pop(
                  context,
                  const _ReferenceChoice(id: '', label: '', cleared: true),
                );
              },
            ),

            const Divider(height: 1),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? const Center(child: Text('موردی پیدا نشد.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length + (loadingMore ? 1 : 0),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final Map<String, dynamic> item = items[index];

                        final String id = item['id']?.toString() ?? '';

                        final String label = item['name']?.toString() ?? '';

                        return ListTile(
                          dense: true,
                          title: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Radio<String>(
                            value: id,
                            groupValue: widget.initialId,
                            onChanged: (_) {
                              Navigator.pop(
                                context,
                                _ReferenceChoice(id: id, label: label),
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                              _ReferenceChoice(id: id, label: label),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
