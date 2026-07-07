import 'package:flutter/material.dart';

import 'category_model.dart';
import 'category_repository.dart';
import 'category_tree_tile.dart';

class CategoryDialog extends StatefulWidget {
  final String title;
  final List<CategoryModel> selected;

  const CategoryDialog({
    super.key,
    required this.title,
    required this.selected,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late List<CategoryModel> selected;

  late List<CategoryModel> tree;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    selected = List.from(widget.selected);

    tree = CategoryRepository.categories;

    searchController.addListener(_search);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  //--------------------------------------------------------
  // Search
  //--------------------------------------------------------

  void _search() {
    setState(() {
      tree = CategoryRepository.search(
        searchController.text,
      );
    });
  }

  //--------------------------------------------------------
  // Toggle Item
  //--------------------------------------------------------

  void _toggle(CategoryModel item) {
    setState(() {
      if (selected.contains(item)) {
        selected.remove(item);
      } else {
        selected.add(item);
      }
    });
  }

  bool _isSelected(CategoryModel item) {
    return selected.contains(item);
  }

  //--------------------------------------------------------
  // Build
  //--------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: SizedBox(
        width: 650,
        height: 700,

        child: Column(
          children: [
            //--------------------------------------------------
            // Header
            //--------------------------------------------------

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            //--------------------------------------------------
            // Search
            //--------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "جستجو در دسته بندی ها",

                  prefixIcon:
                      const Icon(Icons.search_rounded),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            //--------------------------------------------------
            // Top Categories
            //--------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),

              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "پر استفاده",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 42,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                children: CategoryRepository.topCategories
                    .map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.only(right: 8),

                        child: FilterChip(
                          label: Text(item.title),

                          selected: _isSelected(item),

                          onSelected: (_) {
                            _toggle(item);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const Divider(height: 30),            //--------------------------------------------------
            // Tree
            //--------------------------------------------------

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                itemCount: tree.length,
                itemBuilder: (context, index) {
                  return CategoryTreeTile(
                    category: tree[index],
                    selectedItems: selected,
                    onChanged: _toggle,
                  );
                },
              ),
            ),

            const Divider(height: 1),

            //--------------------------------------------------
            // Bottom
            //--------------------------------------------------

            Container(
              padding: const EdgeInsets.all(16),

              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${selected.length} دسته انتخاب شده",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("انصراف"),
                  ),

                  const SizedBox(width: 12),

                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("تایید"),

                    onPressed: () {
                      Navigator.pop(
                        context,
                        List<CategoryModel>.from(selected),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}