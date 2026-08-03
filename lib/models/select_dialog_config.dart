class SelectDialogConfig {
  final String title;

  /// انتخاب چندتایی
  final bool multiSelect;

  /// کلید ذخیره تاریخچه
  final String historyKey;

  /// تعداد تاریخچه
  final int historyCount;

  const SelectDialogConfig({
    required this.title,
    this.multiSelect = false,
    required this.historyKey,
    this.historyCount = 10,
  });
}
