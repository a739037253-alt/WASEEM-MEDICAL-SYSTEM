# بناء APK عبر Codemagic

هذا المشروع يحتوي على مجلد Android وملف `codemagic.yaml`، لذلك يمكن لـ Codemagic تنفيذ `flutter build apk --release` مباشرة.

1. اربط المستودع `WASEEM-MEDICAL-SYSTEM` في Codemagic.
2. اجعل Codemagic يقرأ ملف `codemagic.yaml` الموجود في جذر المشروع.
3. شغّل Workflow: `android-release`.
4. بعد نجاح البناء افتح نتيجة الـ Build.
5. حمّل الملف من قسم Artifacts: `app-release.apk`.

ملاحظة: ملف `.github/workflows/build-apk.yml` مخصص لـ GitHub Actions، بينما Codemagic يستخدم `codemagic.yaml`.
