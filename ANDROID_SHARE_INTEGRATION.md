
# دریافت فایل با Share در Android

در ZIP فعلی پوشه `android/` وجود ندارد؛ بنابراین `package` واقعی اپ را نباید حدس زد.

کد Dart آماده شده است:
- `lib/services/incoming_share_service.dart`
- `lib/pages/incoming_share_page.dart`

## MainActivity

در `MainActivity` فعلی پروژه، یک `MethodChannel` با نام زیر اضافه کنید:

`karnama/incoming_share`

متدهای مورد نیاز:
- `getInitialSharedFile`
- `getPendingSharedFile`

هنگام دریافت `Intent.ACTION_SEND` با `type` های `application/pdf`، `image/*` یا `*/*`:
1. URI دریافتی از `Intent.EXTRA_STREAM` را بخوانید.
2. آن را داخل cache خصوصی برنامه با نام یکتا کپی کنید.
3. مسیر فایل cache را به Flutter برگردانید.

برای اینکه برنامه در Android در فهرست Share دیده شود، در Activity فعلی این intent-filter را اضافه کنید:

```xml
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="application/pdf" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="image/*" />
</intent-filter>
```

برای دریافت انواع فایل بیشتر می‌توان `application/*` و `*/*` را نیز اضافه کرد.

پس از دریافت مسیر فایل، برنامه باید `IncomingSharePage(filePath: path)` را باز کند. کاربر سپس یکی از این سه گزینه را انتخاب می‌کند:
- نامه
- صورتجلسه
- فعالیت

فایل برای نامه و فعالیت به صورت path و برای صورتجلسه به صورت bytes وارد فرم می‌شود.
