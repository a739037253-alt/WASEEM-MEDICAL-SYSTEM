import 'package:url_launcher/url_launcher.dart';

class MessagingService {
  static String normalizeYemen(String phone) {
    var p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('00')) p = p.substring(2);
    if (p.startsWith('7') && p.length == 9) p = '967$p';
    if (p.startsWith('967')) return p;
    return p;
  }

  static Future<bool> whatsapp(String phone, String message) async {
    final p = normalizeYemen(phone);
    final uri = Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> sms(String phone, String message) async {
    final uri = Uri.parse('sms:${Uri.encodeComponent(phone)}?body=${Uri.encodeComponent(message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String registrationMessage({
    required String patient,
    required String fileNo,
    required String center,
    required String service,
    required String date,
    required String support,
  }) {
    return '''أهلاً بك $patient،
تم تسجيل بياناتكم بنجاح في $center.

رقم الملف الطبي: $fileNo
القسم/الخدمة: $service
التاريخ: $date

مع تمنياتنا لكم بدوام الصحة والعافية. 🌸
$center - للاتصال والاستفسار: $support''';
  }
}
