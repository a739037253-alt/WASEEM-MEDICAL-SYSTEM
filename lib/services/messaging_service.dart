import 'package:url_launcher/url_launcher.dart';

class MessagingService {
  // ============================================================
  // توحيد رقم الهاتف اليمني
  // ============================================================

  static String normalizeYemen(String phone) {
    var p = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');

    if (p.startsWith('+')) {
      p = p.substring(1);
    }

    if (p.startsWith('00')) {
      p = p.substring(2);
    }

    // 777123456 -> 967777123456
    if (p.startsWith('7') && p.length == 9) {
      p = '967$p';
    }

    return p;
  }

  // ============================================================
  // فتح WhatsApp العادي وتجهيز الرسالة
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

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // فتح SMS وتجهيز الرسالة
  // ============================================================

  static Future<bool> sms(
    String phone,
    String message,
  ) async {
    final p = normalizeYemen(phone);

    if (p.isEmpty) {
      return false;
    }

    final uri = Uri(
      scheme: 'sms',
      path: p,
      queryParameters: {
        'body': message,
      },
    );

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
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
    final supportText = support.trim().isEmpty
        ? ''
        : '\nللاستفسار والتواصل:\n$support';

    return '''
السلام عليكم ورحمة الله وبركاته 🌷

الأستاذ/ة: $patient

تم تسجيل بياناتكم بنجاح في:
$center

━━━━━━━━━━━━━━━━
رقم الملف الطبي: $fileNo
القسم / الخدمة: $service
تاريخ التسجيل: $date
━━━━━━━━━━━━━━━━

مع تمنياتنا لكم بدوام الصحة والعافية.

$center
$supportText
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
    String support = '',
  }) {
    final supportText = support.trim().isEmpty
        ? ''
        : '\nللاستفسار والتواصل:\n$support';

    return '''
السلام عليكم ورحمة الله وبركاته 🌷

إشعار قبض مالي

الأستاذ/ة: $patient

تم تسجيل سند قبض مالي بنجاح لدى:
$center

━━━━━━━━━━━━━━━━
رقم السند: $receiptNo
المبلغ: $amount
البيان: ${description.trim().isEmpty ? 'سند قبض' : description}
التاريخ: $date
━━━━━━━━━━━━━━━━

نشكر لكم تعاملكم معنا،
ونتمنى لكم دوام الصحة والعافية.

$center
$supportText
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
السلام عليكم ورحمة الله وبركاته

إشعار سند صرف

${recipient.trim().isEmpty ? '' : 'المستفيد: $recipient'}

تم تسجيل سند صرف مالي لدى:
$center

━━━━━━━━━━━━━━━━
رقم السند: $expenseNo
المبلغ: $amount
الحساب: $category
البيان: ${description.trim().isEmpty ? 'سند صرف' : description}
التاريخ: $date
━━━━━━━━━━━━━━━━

$center
''';
  }

  // ============================================================
  // إشعار تسجيل جلسة من الباقة
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
السلام عليكم ورحمة الله وبركاته 🌷

الأستاذ/ة: $patient

إشعار جلسات

تم تسجيل جلسة علاجية لكم لدى:
$center

━━━━━━━━━━━━━━━━
الباقة: $packageName
عدد الجلسات المستخدمة: $usedSessions
الجلسات المتبقية: $remainingSessions
التاريخ: $date
━━━━━━━━━━━━━━━━

تم تحديث رصيد الجلسات في ملفكم الطبي.

نشكركم على ثقتكم بنا،
ونتمنى لكم دوام الصحة والعافية.

$center
''';
  }

  // ============================================================
  // إشعار قرب انتهاء الباقة
  // ============================================================

  static String packageLowMessage({
    required String patient,
    required String center,
    required String packageName,
    required String remainingSessions,
    required String date,
  }) {
    return '''
السلام عليكم ورحمة الله وبركاته 🌷

تنبيه بخصوص باقة الجلسات

الأستاذ/ة: $patient

نفيدكم بأن باقة الجلسات الخاصة بكم لدى:
$center

━━━━━━━━━━━━━━━━
الباقة: $packageName
الجلسات المتبقية: $remainingSessions
التاريخ: $date
━━━━━━━━━━━━━━━━

نرجو التواصل مع المركز عند الحاجة إلى تجديد الباقة.

مع تمنياتنا لكم بدوام الصحة والعافية.

$center
''';
  }

  // ============================================================
  // رسالة تذكير بالموعد
  // ============================================================

  static String appointmentMessage({
    required String patient,
    required String center,
    required String date,
    required String time,
    required String doctor,
    required String support,
  }) {
    final doctorText = doctor.trim().isEmpty
        ? ''
        : '\nالطبيب / الأخصائي: $doctor';

    final supportText = support.trim().isEmpty
        ? ''
        : '\nللاستفسار والتواصل:\n$support';

    return '''
السلام عليكم ورحمة الله وبركاته 🌷

الأستاذ/ة: $patient

نذكّركم بموعدكم لدى:
$center

━━━━━━━━━━━━━━━━
التاريخ: $date
الوقت: $time
$doctorText
━━━━━━━━━━━━━━━━

نرجو الحضور في الموعد المحدد.

مع تمنياتنا لكم بالصحة والعافية.

$center
$supportText
''';
  }
}
