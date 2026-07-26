import 'package:shamsi_date/shamsi_date.dart';

class DateHelper {
  DateHelper._();

  //--------------------------------------------------
  // Gregorian -> Jalali
  //--------------------------------------------------

  static Jalali toJalali(DateTime date) {
    return Jalali.fromDateTime(date);
  }

  //--------------------------------------------------
  // yyyy/MM/dd
  //--------------------------------------------------

  static String toDate(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.year}/${_two(j.month)}/${_two(j.day)}";
  }

  //--------------------------------------------------
  // yyyy/MM/dd HH:mm
  //--------------------------------------------------

  static String toDateTime(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.year}/${_two(j.month)}/${_two(j.day)} "
        "${_two(date.hour)}:${_two(date.minute)}";
  }

  //--------------------------------------------------
  // HH:mm
  //--------------------------------------------------

  static String toTime(DateTime? date) {
    if (date == null) return "";

    return "${_two(date.hour)}:${_two(date.minute)}";
  }

  //--------------------------------------------------
  // yyyy/MM
  //--------------------------------------------------

  static String toMonth(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.year}/${_two(j.month)}";
  }

  //--------------------------------------------------
  // yyyy
  //--------------------------------------------------

  static String toYear(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return j.year.toString();
  }

  //--------------------------------------------------
  // yyyy/MM/dd HH:mm:ss
  //--------------------------------------------------

  static String toFull(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.year}/${_two(j.month)}/${_two(j.day)} "
        "${_two(date.hour)}:${_two(date.minute)}:${_two(date.second)}";
  }

  //--------------------------------------------------
  // Month Name
  //--------------------------------------------------

  static String monthName(int month) {
    const months = [
      "فروردین",
      "اردیبهشت",
      "خرداد",
      "تیر",
      "مرداد",
      "شهریور",
      "مهر",
      "آبان",
      "آذر",
      "دی",
      "بهمن",
      "اسفند",
    ];

    return months[month - 1];
  }

  //--------------------------------------------------
  // 1405 مرداد 12
  //--------------------------------------------------

  static String longDate(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.day} ${monthName(j.month)} ${j.year}";
  }

  //--------------------------------------------------
  // 1405 مرداد 12 - 08:30
  //--------------------------------------------------

  static String longDateTime(DateTime? date) {
    if (date == null) return "";

    final j = Jalali.fromDateTime(date);

    return "${j.day} ${monthName(j.month)} ${j.year}"
        " - "
        "${_two(date.hour)}:${_two(date.minute)}";
  }

  //--------------------------------------------------
  // Pad
  //--------------------------------------------------

  static String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}