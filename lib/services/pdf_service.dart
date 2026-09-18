import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> printPatientCard(Map<String, Object?> p, String center) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final bold = await PdfGoogleFonts.notoSansArabicBold();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (_) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(center, style: pw.TextStyle(font: bold, fontSize: 20)),
              pw.SizedBox(height: 8),
              pw.Text('بطاقة تسجيل مريض', style: pw.TextStyle(font: bold, fontSize: 16)),
              pw.Divider(),
              _row('رقم الملف', '${p['file_no'] ?? ''}', font, bold),
              _row('الاسم', '${p['full_name'] ?? ''}', font, bold),
              _row('رقم الهاتف', '${p['phone'] ?? ''}', font, bold),
              _row('الجنس', '${p['gender'] ?? ''}', font, bold),
              _row('القسم', '${p['department'] ?? ''}', font, bold),
              _row('الخدمة', '${p['service'] ?? ''}', font, bold),
              _row('الطبيب / الأخصائي', '${p['doctor'] ?? ''}', font, bold),
              _row('تاريخ التسجيل', '${p['created_at'] ?? ''}', font, bold),
              pw.SizedBox(height: 30),
              pw.Text('توقيع الاستقبال / الموظف: ........................', style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 15),
              pw.Text('توقيع الطبيب / الأخصائي: .........................', style: pw.TextStyle(font: font)),
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _row(String a, String b, pw.Font f, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 130, child: pw.Text('$a:', style: pw.TextStyle(font: bold))),
          pw.Expanded(child: pw.Text(b, style: pw.TextStyle(font: f))),
        ],
      ),
    );
  }
}
