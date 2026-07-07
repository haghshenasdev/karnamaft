import 'package:flutter/material.dart';
import 'package:karnamaft/widgets/category_picker/category_dialog.dart';

import 'category_model.dart';
import 'category_repository.dart';

class CategoryPicker extends StatefulWidget {
  final List<CategoryModel> selectedItems;

  final ValueChanged<List<CategoryModel>> onChanged;

  final String title;

  const CategoryPicker({
    super.key,
    required this.selectedItems,
    required this.onChanged,
    this.title = "انتخاب دسته‌بندی",
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  late List<CategoryModel> _selected;

  @override
  void initState() {
    super.initState();

    _selected = List.from(widget.selectedItems);
  }

  //----------------------------------------------------------
  // Remove
  //----------------------------------------------------------

  void _remove(CategoryModel item) {
    setState(() {
      _selected.remove(item);
    });

    widget.onChanged(_selected);
  }

  //----------------------------------------------------------
  // Open Dialog
  //----------------------------------------------------------

  Future<void> _openDialog() async {
    final result = await showDialog<List<CategoryModel>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryDialog(title: widget.title, selected: _selected),
    );

    if (result != null) {
      setState(() {
        _selected = result;
      });

      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openDialog,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_copy_outlined, color: Colors.blue),

            const SizedBox(width: 10),

            //---------------------------------
            // Selected Categories
            //---------------------------------
            Expanded(
              child: _selected.isEmpty
                  ? Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selected.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final item = _selected[index];

                        return Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.folder, size: 16),
                          label: Text(item.title),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _remove(item),
                        );
                      },
                    ),
            ),

            const SizedBox(width: 10),

            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}
