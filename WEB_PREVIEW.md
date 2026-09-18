# معاينة التطبيق على الويب

هذا المشروع مجهز الآن ليُبنى كتطبيق Flutter Web إلى جانب Android.

## تشغيل المعاينة عبر GitHub Pages

1. ارفع المشروع إلى المستودع `WASEEM-MEDICAL-SYSTEM` على الفرع `main`.
2. افتح تبويب **Actions**.
3. اختر **Deploy Flutter Web Preview**.
4. شغّل Workflow يدويًا عبر **Run workflow**، أو ارفع Commit جديد إلى `main` ليبدأ تلقائيًا.
5. بعد نجاح البناء افتح **Settings → Pages** وتأكد أن المصدر هو **GitHub Actions**.
6. سيظهر رابط المعاينة في صفحة الـWorkflow وفي قسم Pages.

> ملاحظة: قاعدة البيانات في Web تعمل داخل متصفح المستخدم عبر SQLite/WebAssembly وIndexedDB. بيانات نسخة الويب منفصلة عن بيانات نسخة Android.
