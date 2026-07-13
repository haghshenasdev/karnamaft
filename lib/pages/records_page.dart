import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/widgets/record_card.dart';

import '../../widgets/search/search_bar_widget.dart';

class RecordsPage extends StatefulWidget {
  final String title;

  const RecordsPage({super.key, required this.title});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final TextEditingController searchController = TextEditingController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool loading = false;

  int totalCount = 0;

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: Text(widget.title),

        centerTitle: false,

        elevation: 0,

        scrolledUnderElevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            //--------------------------------------------------
            // Search
            //--------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SearchBarWidget(
                controller: searchController,

                hint: "جستجو...",

                onChanged: (value) {},

                onClear: () {},

                onVoice: () {},
              ),
            ),

            //--------------------------------------------------
            // Filter Bar
            //--------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {},

                    icon: const Icon(Icons.filter_alt_outlined),

                    label: const Text("فیلتر"),
                  ),

                  const SizedBox(width: 8),

                  FilledButton.tonalIcon(
                    onPressed: () {},

                    icon: const Icon(Icons.sort),

                    label: const Text("مرتب سازی"),
                  ),

                  const Spacer(),

                  Text("$totalCount رکورد", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const Divider(height: 1),

            //--------------------------------------------------
            // Records
            //--------------------------------------------------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 100),
                      itemCount: 10,

                      itemBuilder: (_, index) {
                        final record = RecordItem(
                          id: index,

                          title:
                              "درخواست خرید تجهیزات آزمایشگاه شماره ${index + 1}",

                          description:
                              "این متن خلاصه‌ای از صورت جلسه یا نامه است که بعداً از API دریافت خواهد شد.",

                          from: "دبیرخانه مرکزی",

                          to: "معاون آموزشی",

                          number: "1405/${1000 + index}",

                          date: "1405/04/22",

                          tag: "فوری",

                          status: RecordStatus.pending,

                          hasAttachment: true,
                        );

                        return RecordCard(
                          record: record,

                          onTap: () {},

                          onOpen: () {},

                          onFile: () {},

                          onRefer: () {},

                          onMore: () {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},

        icon: const Icon(Icons.add),

        label: const Text("جدید"),
      ),
    );
  }
}
