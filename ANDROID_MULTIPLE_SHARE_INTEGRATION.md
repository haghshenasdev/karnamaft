# پشتیبانی اشتراک‌گذاری چند تصویر در Android

در ZIP ارسالی پوشه `android/` وجود ندارد؛ بنابراین کد Native قابل اصلاح نبود.

کد Dart اکنون کانال `karnama/incoming_share` را با این قرارداد پشتیبانی می‌کند:

- `getInitialSharedFiles` -> یک `List<String>` از مسیر فایل‌های دریافت‌شده
- `getPendingSharedFiles` -> یک `List<String>` از مسیر فایل‌های جدید
- `sharedFilesReceived` -> arguments شامل `List<String>`

برای سازگاری با نسخه قبلی، اگر این متدها وجود نداشته باشند:
- `getInitialSharedFile`
- `getPendingSharedFile`
- `sharedFileReceived`

همچنان پشتیبانی می‌شوند.

در Android باید برای Intent با `Intent.ACTION_SEND_MULTIPLE` تمام URIها به فایل‌های cache محلی تبدیل شده و مسیرهای آن‌ها در `List<String>` به Flutter ارسال شوند.

بعد از دریافت چند تصویر، Flutter همه تصاویر را به یک PDF چندصفحه‌ای تبدیل می‌کند و همان PDF در فرم ایجاد نامه/صورتجلسه/فعالیت قرار می‌گیرد.
