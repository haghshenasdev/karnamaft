import 'package:karnamaft/models/search_item.dart';

class SearchResultGroup {
  final SearchType type;

  final List<SearchItem> items;

  int page;

  int lastPage;

  bool loading;

  SearchResultGroup({
    required this.type,
    required this.items,
    this.page = 1,
    this.lastPage = 1,
    this.loading = false,
  });

  bool get hasMore => page < lastPage;
}
