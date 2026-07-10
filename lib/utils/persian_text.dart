class PersianText {
  PersianText._();

  static String normalize(String text) {
    if (text.isEmpty) return "";

    return text
        //--------------------------------------------------
        // Arabic -> Persian
        //--------------------------------------------------
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll('ۀ', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ی')
        //--------------------------------------------------
        // Alef
        //--------------------------------------------------
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('آ', 'آ') // اگر خواستی می‌توانی به "ا" تبدیلش کنی.
        //--------------------------------------------------
        // Remove Diacritics
        //--------------------------------------------------
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        //--------------------------------------------------
        // Remove Tatweel
        //--------------------------------------------------
        .replaceAll('ـ', '')
        //--------------------------------------------------
        // Remove Zero Width
        //--------------------------------------------------
        .replaceAll('\u200C', ' ')
        .replaceAll('\u200D', '')
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '')
        .replaceAll('\uFEFF', '')
        //--------------------------------------------------
        // Persian digits
        //--------------------------------------------------
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        //--------------------------------------------------
        // Arabic digits
        //--------------------------------------------------
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        //--------------------------------------------------
        // Multiple spaces
        //--------------------------------------------------
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
