import 'package:flutter/material.dart';

import 'category_model.dart';

class CategoryTreeTile extends StatefulWidget {
  final CategoryModel category;

  final List<CategoryModel> selectedItems;

  final ValueChanged<CategoryModel> onChanged;

  final int level;

  const CategoryTreeTile({
    super.key,
    required this.category,
    required this.selectedItems,
    required this.onChanged,
    this.level = 0,
  });

  @override
  State<CategoryTreeTile> createState() =>
      _CategoryTreeTileState();
}

class _CategoryTreeTileState
    extends State<CategoryTreeTile> {
  late bool expanded;

  @override
  void initState() {
    super.initState();

    expanded = widget.level == 0;
  }

  bool get selected =>
      widget.selectedItems.contains(widget.category);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onChanged(widget.category),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: widget.level * 22,
                ),

                //-----------------------------------
                // Expand Button
                //-----------------------------------

                if (widget.category.hasChildren)
                  InkWell(
                    borderRadius:
                        BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    child: AnimatedRotation(
                      turns: expanded ? .25 : 0,
                      duration: const Duration(
                        milliseconds: 200,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 20),

                const SizedBox(width: 6),

                //-----------------------------------
                // Checkbox
                //-----------------------------------

                Checkbox(
                  value: selected,
                  onChanged: (_) {
                    widget.onChanged(widget.category);
                  },
                ),

                //-----------------------------------
                // Icon
                //-----------------------------------

                Icon(
                  widget.category.hasChildren
                      ? expanded
                          ? Icons.folder_open
                          : Icons.folder
                      : Icons.label_outline,
                  color: widget.category.hasChildren
                      ? Colors.amber.shade700
                      : Colors.blueGrey,
                ),

                const SizedBox(width: 10),

                //-----------------------------------
                // Title
                //-----------------------------------

                Expanded(
                  child: Text(
                    widget.category.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          widget.category.hasChildren
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),

                //-----------------------------------
                // Count
                //-----------------------------------

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.category.useCount.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        //-----------------------------------
        // Children
        //-----------------------------------

        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.category.children
                .map(
                  (child) => CategoryTreeTile(
                    category: child,
                    selectedItems:
                        widget.selectedItems,
                    onChanged: widget.onChanged,
                    level: widget.level + 1,
                  ),
                )
                .toList(),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration:
              const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}