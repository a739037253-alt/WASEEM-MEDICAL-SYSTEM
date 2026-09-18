import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/database_service.dart';
import '../services/messaging_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  double receipts = 0;
  double expenses = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      receipts = await DatabaseService.instance.todayReceipts();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // سند قبض
  // ============================================================

  Future<void> receipt() async {
    final patients = await DatabaseService.instance.patients();

    if (patients.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف مريضًا أولًا قبل إنشاء سند قبض.'),
        ),
      );
      return;
    }

    int? patientId = patients.first['id'] as int?;

    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 8),
                  Text('سند قبض'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: patientId,
                      isExpanded: true,
                      items: [
                        for (final p in patients)
                          DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(
                              '${p['full_name'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          patientId = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'المريض',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        prefixIcon: Icon(Icons.payments),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'البيان',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;

                    if (patientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('اختر المريض أولًا.'),
                        ),
                      );
                      return;
                    }

                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أدخل مبلغًا صحيحًا.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'patientId': patientId,
                      'amount': amount,
                      'description': descController.text.trim(),
                    });
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    descController.dispose();

    if (result == null) return;

    final patientIdResult = result['patientId'] as int;
    final amount = result['amount'] as double;
    final description = result['description'] as String;

    try {
      final no = await DatabaseService.instance.nextNumber(
        'receipts',
        'receipt_no',
        'RV',
      );

      final now = DateTime.now();

      await DatabaseService.instance.db.insert(
        'receipts',
        {
          'receipt_no': no,
          'patient_id': patientIdResult,
          'receipt_date': now.toIso8601String(),
          'amount': amount,
          'account_name': 'الصندوق الرئيسي',
          'description': description,
        },
      );

      final cashRows = await DatabaseService.instance.db.query(
        'accounts',
        where: 'name=?',
        whereArgs: ['الصندوق الرئيسي'],
      );

      final arRows = await DatabaseService.instance.db.query(
        'accounts',
        where: 'name=?',
        whereArgs: ['ذمم المرضى والعملاء'],
      );

      if (cashRows.isEmpty || arRows.isEmpty) {
        throw Exception(
          'الحسابات الأساسية غير موجودة في دليل الحسابات.',
        );
      }

      final cash = cashRows.first['id'] as int;
      final ar = arRows.first['id'] as int;

      await DatabaseService.instance.createBalancedJournal(
        description: 'سند قبض $no',
        lines: [
          {
            'account_id': cash,
            'debit': amount,
            'credit': 0.0,
            'description': 'قبض',
          },
          {
            'account_id': ar,
            'debit': 0.0,
            'credit': amount,
            'description': 'قبض من مريض',
          },
        ],
        referenceType: 'receipt',
      );

      await load();

      final patient = patients.firstWhere(
        (p) => p['id'] == patientIdResult,
        orElse: () => <String, Object?>{},
      );

      await _showDocumentActions(
        type: 'receipt',
        number: no,
        patient: patient,
        amount: amount,
        description: description,
        date: now,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ سند القبض: $e'),
        ),
      );
    }
  }

  // ============================================================
  // سند صرف
  // ============================================================

  Future<void> expense() async {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.money_off),
              SizedBox(width: 8),
              Text('سند صرف'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'حساب المصروف',
                    hintText: 'مثال: المصروفات العمومية',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: Icon(Icons.payments),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'البيان',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('أدخل مبلغًا صحيحًا.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  'category': categoryController.text.trim().isEmpty
                      ? 'المصروفات العمومية'
                      : categoryController.text.trim(),
                  'amount': amount,
                  'description': descController.text.trim(),
                });
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    categoryController.dispose();
    amountController.dispose();
    descController.dispose();

    if (result == null) return;

    final category = result['category'] as String;
    final amount = result['amount'] as double;
    final description = result['description'] as String;

    try {
      final no = await DatabaseService.instance.nextNumber(
        'expenses',
        'expense_no',
        'EX',
      );

      final now = DateTime.now();

      await DatabaseService.instance.db.insert(
        'expenses',
        {
          'expense_no': no,
          'expense_date': now.toIso8601String(),
          'category': category,
          'amount': amount,
          'description': description,
        },
      );

      final cashRows = await DatabaseService.instance.db.query(
        'accounts',
        where: 'name=?',
        whereArgs: ['الصندوق الرئيسي'],
      );

      final expRows = await DatabaseService.instance.db.query(
        'accounts',
        where: 'name=?',
        whereArgs: ['المصروفات العمومية'],
      );

      if (cashRows.isEmpty || expRows.isEmpty) {
        throw Exception(
          'الحسابات الأساسية غير موجودة في دليل الحسابات.',
        );
      }

      final cash = cashRows.first['id'] as int;
      final exp = expRows.first['id'] as int;

      await DatabaseService.instance.createBalancedJournal(
        description: 'مصروف $no',
        lines: [
          {
            'account_id': exp,
            'debit': amount,
            'credit': 0.0,
            'description': description,
          },
          {
            'account_id': cash,
            'debit': 0.0,
            'credit': amount,
            'description': description,
          },
        ],
        referenceType: 'expense',
      );

      await load();

      await _showDocumentActions(
        type: 'expense',
        number: no,
        patient: const {},
        amount: amount,
        description: description,
        date: now,
        category: category,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ سند الصرف: $e'),
        ),
      );
    }
  }

  // ============================================================
  // خيارات السند بعد الحفظ
  // ============================================================

  Future<void> _showDocumentActions({
    required String type,
    required String number,
    required Map<String, Object?> patient,
    required double amount,
    required String description,
    required DateTime date,
    String category = '',
  }) async {
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type == 'receipt'
                      ? 'تم حفظ سند القبض بنجاح'
                      : 'تم حفظ سند الصرف بنجاح',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'رقم السند: $number',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 18),

                // حفظ فقط
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.check),
                  ),
                  title: const Text('حفظ فقط'),
                  subtitle: const Text('تم حفظ السند في النظام'),
                  onTap: () => Navigator.pop(context, 'saved'),
                ),

                // واتساب
                if (type == 'receipt')
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.message),
                    ),
                    title: const Text('حفظ وإرسال إشعار'),
                    subtitle: const Text(
                      'فتح واتساب والرسالة مجهزة للإرسال',
                    ),
                    onTap: () => Navigator.pop(context, 'whatsapp'),
                  ),

                // PDF
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.picture_as_pdf),
                  ),
                  title: const Text('طباعة / معاينة PDF'),
                  subtitle: const Text(
                    'مقاس A4 مناسب للحفظ والطباعة',
                  ),
                  onTap: () => Navigator.pop(context, 'pdf'),
                ),

                // حراري
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt),
                  ),
                  title: const Text('طباعة حرارية'),
                  subtitle: const Text(
                    'تنسيق إيصال بعرض 80 مم',
                  ),
                  onTap: () => Navigator.pop(context, 'thermal'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || action == 'saved') return;

    if (action == 'whatsapp') {
      final phone = '${patient['phone'] ?? ''}';

      if (phone.trim().isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد رقم هاتف مسجل لهذا المريض.'),
          ),
        );
        return;
      }

      final message = MessagingService.receiptMessage(
        patient: '${patient['full_name'] ?? ''}',
        center: 'مركز وسيم الطبي',
        receiptNo: number,
        amount: _formatAmount(amount),
        date: _formatDate(date),
        description: description.isEmpty ? 'سند قبض' : description,
        support: '',
      );

      final success = await MessagingService.whatsapp(
        phone,
        message,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح واتساب.'),
          ),
        );
      }

      return;
    }

    if (action == 'pdf') {
      await _printDocument(
        type: type,
        number: number,
        patient: patient,
        amount: amount,
        description: description,
        date: date,
        category: category,
        thermal: false,
      );
      return;
    }

    if (action == 'thermal') {
      await _printDocument(
        type: type,
        number: number,
        patient: patient,
        amount: amount,
        description: description,
        date: date,
        category: category,
        thermal: true,
      );
    }
  }

  // ============================================================
  // PDF والطباعة الحرارية
  // ============================================================

  Future<void> _printDocument({
    required String type,
    required String number,
    required Map<String, Object?> patient,
    required double amount,
    required String description,
    required DateTime date,
    required bool thermal,
    String category = '',
  }) async {
    final doc = pw.Document();

    final font =
        await PdfGoogleFonts.notoSansArabicRegular();
    final bold =
        await PdfGoogleFonts.notoSansArabicBold();

    final pageFormat = thermal
        ? PdfPageFormat(
            80 * PdfPageFormat.mm,
            200 * PdfPageFormat.mm,
            marginAll: 5 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: bold,
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'مركز وسيم الطبي',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: thermal ? 15 : 22,
                    ),
                  ),
                ),

                pw.SizedBox(height: 4),

                pw.Center(
                  child: pw.Text(
                    type == 'receipt'
                        ? 'سند قبض'
                        : 'سند صرف',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: thermal ? 13 : 18,
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),
                pw.Divider(),

                _pdfRow(
                  'رقم السند',
                  number,
                  font,
                  bold,
                  thermal,
                ),

                _pdfRow(
                  'التاريخ',
                  _formatDate(date),
                  font,
                  bold,
                  thermal,
                ),

                if (type == 'receipt')
                  _pdfRow(
                    'المريض',
                    '${patient['full_name'] ?? ''}',
                    font,
                    bold,
                    thermal,
                  ),

                if (type == 'receipt')
                  _pdfRow(
                    'رقم الملف',
                    '${patient['file_no'] ?? ''}',
                    font,
                    bold,
                    thermal,
                  ),

                if (type == 'receipt')
                  _pdfRow(
                    'الهاتف',
                    '${patient['phone'] ?? ''}',
                    font,
                    bold,
                    thermal,
                  ),

                if (type == 'expense')
                  _pdfRow(
                    'حساب المصروف',
                    category,
                    font,
                    bold,
                    thermal,
                  ),

                pw.SizedBox(height: 5),
                pw.Divider(),

                _pdfRow(
                  'المبلغ',
                  _formatAmount(amount),
                  font,
                  bold,
                  thermal,
                ),

                _pdfRow(
                  'البيان',
                  description.isEmpty
                      ? (type == 'receipt'
                          ? 'سند قبض'
                          : 'سند صرف')
                      : description,
                  font,
                  bold,
                  thermal,
                ),

                pw.SizedBox(height: 18),

                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius:
                        pw.BorderRadius.circular(5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'المبلغ المستلم: ${_formatAmount(amount)}',
                      style: pw.TextStyle(
                        font: bold,
                        fontSize: thermal ? 12 : 16,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 25),

                pw.Center(
                  child: pw.Text(
                    'شكرًا لتعاملكم معنا',
                    style: pw.TextStyle(font: font),
                  ),
                ),

                pw.SizedBox(height: 15),

                pw.Center(
                  child: pw.Text(
                    'توقيع الموظف: ........................',
                    style: pw.TextStyle(font: font),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: '$number.pdf',
      onLayout: (_) async => doc.save(),
    );
  }

  pw.Widget _pdfRow(
    String title,
    String value,
    pw.Font font,
    pw.Font bold,
    bool thermal,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: thermal ? 75 : 125,
            child: pw.Text(
              '$title:',
              style: pw.TextStyle(
                font: bold,
                fontSize: thermal ? 9 : 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: thermal ? 9 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();

    return '$d-$m-$y';
  }

  // ============================================================
  // الواجهة الرئيسية
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإدارة المالية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('مقبوضات اليوم'),
              subtitle: Text(
                _formatAmount(receipts),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: receipt,
                icon: const Icon(Icons.receipt_long),
                label: const Text('سند قبض'),
              ),
              OutlinedButton.icon(
                onPressed: expense,
                icon: const Icon(Icons.money_off),
                label: const Text('سند صرف'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text(
                'المحاسبة بالقيد المزدوج',
              ),
              subtitle: const Text(
                'لا يُحفظ القيد إلا عندما يتساوى إجمالي المدين مع إجمالي الدائن.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
