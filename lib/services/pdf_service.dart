import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// طباعة بطاقة تسجيل المريض بصيغة PDF.
  static Future<void> printPatientCard(
    Map<String, Object?> patient,
    String center,
  ) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final boldFont = await PdfGoogleFonts.notoSansArabicBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ترويسة المركز
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey700,
                      width: 1,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        center.trim().isEmpty
                            ? 'نظام وسيم الطبي PRO'
                            : center,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 20,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'نظام وسيم الطبي PRO',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // عنوان التقرير
                pw.Text(
                  'بطاقة تسجيل مريض',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                  ),
                ),

                pw.SizedBox(height: 6),

                pw.Text(
                  'بيانات المريض الأساسية',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),

                pw.SizedBox(height: 16),

                pw.Divider(
                  thickness: 1,
                ),

                pw.SizedBox(height: 8),

                // بيانات المريض
                _row(
                  'رقم الملف',
                  _value(patient['file_no']),
                  font,
                  boldFont,
                ),

                _row(
                  'الاسم الكامل',
                  _value(patient['full_name']),
                  font,
                  boldFont,
                ),

                _row(
                  'رقم الهاتف',
                  _value(patient['phone']),
                  font,
                  boldFont,
                ),

                _row(
                  'رقم الهوية',
                  _value(patient['national_id']),
                  font,
                  boldFont,
                ),

                _row(
                  'العمر',
                  _value(patient['age']),
                  font,
                  boldFont,
                ),

                _row(
                  'الجنس',
                  _value(patient['gender']),
                  font,
                  boldFont,
                ),

                _row(
                  'تاريخ الميلاد',
                  _value(patient['birth_date']),
                  font,
                  boldFont,
                ),

                _row(
                  'العنوان',
                  _value(patient['address']),
                  font,
                  boldFont,
                ),

                _row(
                  'القسم',
                  _value(patient['department']),
                  font,
                  boldFont,
                ),

                _row(
                  'الخدمة',
                  _value(patient['service']),
                  font,
                  boldFont,
                ),

                _row(
                  'الطبيب / الأخصائي',
                  _value(patient['doctor']),
                  font,
                  boldFont,
                ),

                _row(
                  'مصدر معرفة المركز',
                  _value(patient['referral_source']),
                  font,
                  boldFont,
                ),

                _row(
                  'تاريخ التسجيل',
                  _value(patient['created_at']),
                  font,
                  boldFont,
                ),

                pw.SizedBox(height: 16),

                // الملاحظات
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey500,
                    ),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(
                        'ملاحظات أولية',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        _value(patient['notes']),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // التوقيعات
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'توقيع الاستقبال / الموظف\n\n.................................',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Text(
                        'توقيع الطبيب / الأخصائي\n\n.................................',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 18),

                // تذييل
                pw.Divider(),

                pw.Text(
                  'تم إصدار هذا المستند بواسطة نظام وسيم الطبي PRO',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return doc.save();
      },
    );
  }

  /// تحويل القيمة إلى نص آمن.
  static String _value(Object? value) {
    if (value == null) {
      return 'غير محدد';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return 'غير محدد';
    }

    return text;
  }

  /// صف بيانات منسق داخل التقرير.
  static pw.Widget _row(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 7,
        horizontal: 8,
      ),
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 135,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
