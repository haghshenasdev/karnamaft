import 'package:flutter/material.dart';
import 'package:karnamaft/models/search_item.dart';

class SearchGroupHeader extends StatelessWidget {
  final SearchType type;

  final int count;

  final bool expanded;

  final VoidCallback onTap;

  const SearchGroupHeader({
    super.key,
    required this.type,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              //-----------------------------------
              // Icon
              //-----------------------------------
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(.12),
                child: Icon(type.icon, color: color, size: 20),
              ),

              const SizedBox(width: 12),

              //-----------------------------------
              // Title
              //-----------------------------------
              Expanded(
                child: Text(
                  type.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),

              //-----------------------------------
              // Count
              //-----------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 8),

              //-----------------------------------
              // Expand
              //-----------------------------------
              AnimatedRotation(
                turns: expanded ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
