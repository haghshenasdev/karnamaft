import 'package:flutter/material.dart';
import 'package:karnamaft/models/search_item.dart';

class SearchFilterBar extends StatelessWidget {
  final SearchType? selected;

  final ValueChanged<SearchType?> onChanged;

  const SearchFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [null, ...SearchType.values];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final type = items[index];

          final isSelected = selected == type;

          return FilterChip(
            selected: isSelected,

            showCheckmark: false,

            avatar: type == null
                ? const Icon(Icons.apps, size: 18)
                : Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.white : type.color,
                  ),

            label: Text(type == null ? "همه" : type.title),

            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),

            backgroundColor: Colors.white,

            selectedColor: Theme.of(context).colorScheme.primary,

            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            onSelected: (_) {
              onChanged(type);
            },
          );
        },
      ),
    );
  }
}
