import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/minute_service.dart';
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
  final ScrollController scrollController = ScrollController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  final MinuteService service = MinuteService();

  bool loading = true;

  int totalCount = 0;

  List<RecordItem> records = [];

  bool loadingMore = false;

  int currentPage = 1;

  bool hasMore = true;

  String search = "";

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    loadData();

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      if (scrollController.position.pixels >
          scrollController.position.maxScrollExtent - 250) {
        loadMore();
      }
    });
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    final result = await service.list(page: 1, search: search, sort: "-id");

    records = result.data.map((e) => e.toRecord()).toList();

    totalCount = result.total;

    currentPage = result.currentPage;

    hasMore = result.hasNextPage;

    setState(() {
      loading = false;
    });
  }

  Future<void> loadMore() async {
    if (loadingMore) return;

    if (!hasMore) return;

    loadingMore = true;

    setState(() {});

    final result = await service.list(
      page: currentPage + 1,
      search: search,
      sort: "-id",
    );

    records.addAll(result.data.map((e) => e.toRecord()));

    currentPage = result.currentPage;

    hasMore = result.hasNextPage;

    loadingMore = false;

    setState(() {});
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
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 100),
                      itemCount: records.length + (loadingMore ? 1 : 0),

                      itemBuilder: (_, index) {
                        if (index == records.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final record = records[index];

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
