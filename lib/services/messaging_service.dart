import 'package:url_launcher/url_launcher.dart';

class MessagingService {
  // ============================================================
  // توحيد رقم الهاتف اليمني
  // ============================================================
  static String normalizeYemen(String phone) {
    var p = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (p.startsWith('+')) {
      p = p.substring(1);
    }

    if (p.startsWith('00')) {
      p = p.substring(2);
    }

    if (p.startsWith('7') && p.length == 9) {
      p = '967$p';
    }

    return p;
  }

  // ============================================================
  // إرسال رسالة عبر WhatsApp العادي
  // ============================================================
  static Future<bool> whatsapp(
    String phone,
    String message,
  ) async {
    final p = normalizeYemen(phone);

    if (p.isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      'https://wa.me/$p?text=${Uri.encodeComponent(message)}',
    );

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // إرسال رسالة SMS
  // ============================================================
  static Future<bool> sms(
    String phone,
    String message,
  ) async {
    if (phone.trim().isEmpty) {
      return false;
    }

    final uri = Uri.parse(
      'sms:${Uri.encodeComponent(phone)}'
      '?body=${Uri.encodeComponent(message)}',
    );

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // إشعار تسجيل مريض جديد
  // ============================================================
  static String registrationMessage({
    required String patient,
    required String fileNo,
    required String center,
    required String service,
    required String date,
    required String support,
  }) {
    return '''
أهلاً بك $patient 🌷

تم تسجيل بياناتكم بنجاح في:
$center

━━━━━━━━━━━━━━━━
رقم الملف الطبي: $fileNo
القسم / الخدمة: $service
تاريخ التسجيل: $date
━━━━━━━━━━━━━━━━

مع تمنياتنا لكم بدوام الصحة والعافية.

$center
للاستفسار والتواصل:
$support
''';
  }

  // ============================================================
  // إشعار سند قبض
  // ============================================================
  static String receiptMessage({
    required String patient,
    required String receiptNo,
    required String amount,
    required String description,
    required String center,
    required String date,
  }) {
    return '''
إشعار قبض مالي

مرحباً $patient 🌷

تم تسجيل سند قبض مالي بنجاح لدى:
$center

━━━━━━━━━━━━━━━━
رقم السند: $receiptNo
المبلغ: $amount
البيان: $description
التاريخ: $date
━━━━━━━━━━━━━━━━

نشكر لكم تعاملكم معنا، ونتمنى لكم دوام الصحة والعافية.

$center
''';
  }

  // ============================================================
  // إشعار سند صرف
  // ============================================================
  static String expenseMessage({
    required String recipient,
    required String expenseNo,
    required String amount,
    required String category,
    required String description,
    required String center,
    required String date,
  }) {
    return '''
إشعار سند صرف

مرحباً $recipient

تم تسجيل سند صرف مالي لدى:
$center

━━━━━━━━━━━━━━━━
رقم السند: $expenseNo
المبلغ: $amount
الحساب: $category
البيان: $description
التاريخ: $date
━━━━━━━━━━━━━━━━

$center
''';
  }

  // ============================================================
  // إشعار استخدام الجلسات من الباقة
  // ============================================================
  static String sessionUsageMessage({
    required String patient,
    required String center,
    required String usedSessions,
    required String remainingSessions,
    required String packageName,
    required String date,
  }) {
    return '''
إشعار جلسات

مرحباً $patient 🌷

نود إبلاغكم بأنه تم تسجيل جلساتكم لدى:
$center

━━━━━━━━━━━━━━━━
الباقة: $packageName
عدد الجلسات المستخدمة: $usedSessions
الجلسات المتبقية: $remainingSessions
التاريخ: $date
━━━━━━━━━━━━━━━━

نشكركم على ثقتكم بنا، ونتمنى لكم دوام الصحة والعافية.

$center
''';
  }

  // ============================================================
  // إشعار انتهاء أو قرب انتهاء الباقة
  // ============================================================
  static String packageLowMessage({
    required String patient,
    required String center,
    required String packageName,
    required String remainingSessions,
    required String date,
  }) {
    return '''
تنبيه بخصوص الباقة

مرحباً $patient 🌷

نفيدكم بأن باقة الجلسات الخاصة بكم لدى:
$center

الباقة: $packageName
الجلسات المتبقية: $remainingSessions

نرجو التواصل مع المركز عند الحاجة إلى تجديد الباقة.

التاريخ: $date

$center
''';
  }
}
