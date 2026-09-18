# بناء APK لتطبيق وسيم ميديكال

## البناء من GitHub

هذا المستودع يحتوي على Workflow باسم `Build WASEEM MEDICAL PRO APK`.

1. ارفع محتويات هذا المجلد إلى جذر مستودع GitHub جديد.
2. تأكد من وجود `pubspec.yaml` في جذر المستودع.
3. افتح تبويب **Actions**.
4. اختر **Build WASEEM MEDICAL PRO APK**.
5. اضغط **Run workflow**.
6. بعد اكتمال البناء افتح تشغيل الـWorkflow ثم قسم **Artifacts** وحمّل `waseem-medical-pro-apk`.

الـWorkflow ينشئ منصة Android تلقائياً إذا لم يكن مجلد `android/` موجوداً، ثم ينفذ `flutter pub get` و`flutter analyze` و`flutter test` ويبني نسخة Release.
