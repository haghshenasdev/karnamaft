class PageResult<T> {
  /// داده‌های صفحه جاری
  final List<T> data;

  /// شماره صفحه جاری
  final int currentPage;

  /// آخرین صفحه
  final int lastPage;

  /// تعداد کل رکوردها
  final int total;

  /// تعداد هر صفحه
  final int perPage;

  const PageResult({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasNextPage => currentPage < lastPage;
}
