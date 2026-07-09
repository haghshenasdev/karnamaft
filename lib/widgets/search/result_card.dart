import 'package:flutter/material.dart';
import 'package:karnamaft/models/search_item.dart';
import 'package:karnamaft/widgets/search/highlight_text.dart';

class SearchResultCard extends StatelessWidget {
  final SearchItem item;

  final String keyword;

  final VoidCallback? onTap;

  const SearchResultCard({
    super.key,
    required this.item,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.type.color;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: .5,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //----------------------------------
              // Icon
              //----------------------------------
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(.12),
                child: Icon(item.type.icon, color: color),
              ),

              const SizedBox(width: 14),

              //----------------------------------
              // Body
              //----------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //----------------------------------
                    // title
                    //----------------------------------
                    HighlightText(
                      text: item.title,
                      keyword: keyword,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),

                    HighlightText(
                      text: item.subtitle,
                      keyword: keyword,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),

                    const SizedBox(height: 8),

                    HighlightText(
                      text: item.description,
                      keyword: keyword,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.search, size: 16),
                          label: Text("در ${item.matchedField.title}"),
                        ),

                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.tag, size: 16),
                          label: Text(item.number),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              //----------------------------------
              // Date
              //----------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                      item.type.title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    _formatDate(item.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month}/${date.day}";
  }
}
