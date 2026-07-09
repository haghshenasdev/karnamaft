import 'package:flutter/material.dart';

class EmptySearchWidget extends StatelessWidget {
  final String keyword;

  const EmptySearchWidget({super.key, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //-----------------------------------
            // Icon
            //-----------------------------------
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded, size: 58, color: color),
            ),

            const SizedBox(height: 30),

            //-----------------------------------
            // Title
            //-----------------------------------
            const Text(
              "نتیجه‌ای پیدا نشد",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            //-----------------------------------
            // Description
            //-----------------------------------
            Text(
              keyword.isEmpty
                  ? "برای شروع، عبارت مورد نظر خود را جستجو کنید."
                  : "هیچ نتیجه‌ای برای\n\"$keyword\"\nیافت نشد.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 36),

            //-----------------------------------
            // Suggestions
            //-----------------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline),
                      SizedBox(width: 8),
                      Text(
                        "پیشنهادها",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _item("عبارت کوتاه‌تری را امتحان کنید."),

                  _item("نوع سند را از فیلترهای بالا انتخاب کنید."),

                  _item("از شماره نامه یا شماره مصوبه استفاده کنید."),

                  _item("املای عبارت جستجو را بررسی کنید."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),

          const SizedBox(width: 8),

          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
