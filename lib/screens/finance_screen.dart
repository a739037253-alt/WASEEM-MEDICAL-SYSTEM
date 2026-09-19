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
  double receipts = 0.0;
  double expenses = 0.0;

  bool loading = true;
  bool saving = false;

  List<Map<String, Object?>> todayReceipts = [];
  List<Map<String, Object?>> todayExpenses = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  // ============================================================
  // تحميل البيانات
  // ============================================================

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final db = DatabaseService.instance.db;

      final now = DateTime.now();

      final start = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final end = start.add(const Duration(days: 1));

      final startText = start.toIso8601String();
      final endText = end.toIso8601String();

      // --------------------------------------------------------
      // المقبوضات
      // --------------------------------------------------------

      final receiptRows = await db.query(
        'receipts',
        where: 'receipt_date >= ? AND receipt_date < ?',
        whereArgs: [
          startText,
          endText,
        ],
        orderBy: 'id DESC',
      );

      double receiptTotal = 0.0;

      for (final row in receiptRows) {
        receiptTotal += _toDouble(row['amount']);
      }

      // --------------------------------------------------------
      // المصروفات
      // --------------------------------------------------------

      final expenseRows = await db.query(
        'expenses',
        where: 'expense_date >= ? AND expense_date < ?',
        whereArgs: [
          startText,
          endText,
        ],
        orderBy: 'id DESC',
      );

      double expenseTotal = 0.0;

      for (final row in expenseRows) {
        expenseTotal += _toDouble(row['amount']);
      }

      if (!mounted) return;

      setState(() {
        receipts = receiptTotal;
        expenses = expenseTotal;

        todayReceipts = receiptRows
            .map(
              (e) => Map<String, Object?>.from(e),
            )
            .toList();

        todayExpenses = expenseRows
            .map(
              (e) => Map<String, Object?>.from(e),
            )
            .toList();

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل البيانات المالية: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // تحويل الرقم
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '').trim(),
        ) ??
        0.0;
  }

  // ============================================================
  // تنسيق المبلغ
  // ============================================================

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'\.00$'), '');
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // سند قبض
  // ============================================================

  Future<void> receipt() async {
    if (saving) return;

    final patients = await DatabaseService.instance.patients();

    if (patients.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أضف مريضًا أولًا قبل إنشاء سند قبض.',
          ),
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
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('سند قبض'),
                  ),
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
                        for (final patient in patients)
                          DropdownMenuItem<int>(
                            value: patient['id'] as int,
                            child: Text(
                              '${patient['full_name'] ?? ''}',
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
                        prefixIcon: Icon(
                          Icons.person_outline,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'البيان',
                        hintText: 'مثال: دفعة من حساب المريض',
                        prefixIcon: Icon(
                          Icons.notes_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final amount = double.tryParse(
                          amountController.text
                              .trim()
                              .replaceAll(',', ''),
                        ) ??
                        0.0;

                    if (patientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'اختر المريض أولًا.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'أدخل مبلغًا صحيحًا.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'patientId': patientId,
                        'amount': amount,
                        'description':
                            descController.text.trim(),
                      },
                    );
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

    final patientIdResult =
        result['patientId'] as int;

    final amount =
        result['amount'] as double;

    final description =
        result['description'] as String;

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    try {
      final db = DatabaseService.instance.db;

      // --------------------------------------------------------
      // التحقق من الحسابات قبل حفظ السند
      // --------------------------------------------------------

      final cashRows = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [
          'الصندوق الرئيسي',
        ],
        limit: 1,
      );

      final arRows = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [
          'ذمم المرضى والعملاء',
        ],
        limit: 1,
      );

      if (cashRows.isEmpty ||
          arRows.isEmpty) {
        throw Exception(
          'الحسابات الأساسية غير موجودة في دليل الحسابات. '
          'تأكد من وجود "الصندوق الرئيسي" و"ذمم المرضى والعملاء".',
        );
      }

      final cash =
          cashRows.first['id'] as int;

      final ar =
          arRows.first['id'] as int;

      // --------------------------------------------------------
      // رقم السند
      // --------------------------------------------------------

      final no =
          await DatabaseService.instance.nextNumber(
        'receipts',
        'receipt_no',
        'RV',
      );

      final now = DateTime.now();

      // --------------------------------------------------------
      // حفظ سند القبض
      // --------------------------------------------------------

      await db.insert(
        'receipts',
        {
          'receipt_no': no,
          'patient_id': patientIdResult,
          'receipt_date':
              now.toIso8601String(),
          'amount': amount,
          'account_name':
              'الصندوق الرئيسي',
          'description':
              description.isEmpty
                  ? 'سند قبض'
                  : description,
        },
      );

      // --------------------------------------------------------
      // القيد المحاسبي
      // --------------------------------------------------------

      await DatabaseService.instance
          .createBalancedJournal(
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
            'description':
                'قبض من مريض',
          },
        ],
        referenceType: 'receipt',
      );

      await load();

      final patient = patients.firstWhere(
        (p) => p['id'] == patientIdResult,
        orElse: () => <String, Object?>{},
      );

      if (mounted) {
        setState(() {
          saving = false;
        });
      }

      await _showDocumentActions(
        type: 'receipt',
        number: no,
        patient: patient,
        amount: amount,
        description: description,
        date: now,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر حفظ سند القبض:\n$e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // سند صرف
  // ============================================================

  Future<void> expense() async {
    if (saving) return;

    final categoryController =
        TextEditingController();

    final amountController =
        TextEditingController();

    final descController =
        TextEditingController();

    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.money_off),
              SizedBox(width: 8),
              Expanded(
                child: Text('سند صرف'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller:
                      categoryController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'حساب المصروف',
                    hintText:
                        'مثال: المصروفات العمومية',
                    prefixIcon: Icon(
                      Icons.account_balance_wallet_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      amountController,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                      const InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      descController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText: 'البيان',
                    hintText:
                        'مثال: شراء مستلزمات',
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                    ),
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                final amount =
                    double.tryParse(
                          amountController
                              .text
                              .trim()
                              .replaceAll(
                                ',',
                                '',
                              ),
                        ) ??
                        0.0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'أدخل مبلغًا صحيحًا.',
                      ),
                    ),
                  );
                  return;
                }

                final category =
                    categoryController
                        .text
                        .trim();

                Navigator.pop(
                  dialogContext,
                  {
                    'category':
                        category.isEmpty
                            ? 'المصروفات العمومية'
                            : category,
                    'amount': amount,
                    'description':
                        descController.text
                            .trim(),
                  },
                );
              },
              icon: const Icon(
                Icons.save,
              ),
              label: const Text(
                'حفظ',
              ),
            ),
          ],
        );
      },
    );

    categoryController.dispose();
    amountController.dispose();
    descController.dispose();

    if (result == null) return;

    final category =
        result['category'] as String;

    final amount =
        result['amount'] as double;

    final description =
        result['description'] as String;

    if (mounted) {
      setState(() {
        saving = true;
      });
    }

    try {
      final db =
          DatabaseService.instance.db;

      // --------------------------------------------------------
      // الصندوق
      // --------------------------------------------------------

      final cashRows = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [
          'الصندوق الرئيسي',
        ],
        limit: 1,
      );

      // --------------------------------------------------------
      // حساب المصروف
      // --------------------------------------------------------

      final expRows = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [
          category,
        ],
        limit: 1,
      );

      if (cashRows.isEmpty) {
        throw Exception(
          'حساب "الصندوق الرئيسي" غير موجود في دليل الحسابات.',
        );
      }

      if (expRows.isEmpty) {
        throw Exception(
          'الحساب "$category" غير موجود في دليل الحسابات.\n'
          'أنشئ الحساب أولًا ثم أعد تسجيل سند الصرف.',
        );
      }

      final cash =
          cashRows.first['id'] as int;

      final exp =
          expRows.first['id'] as int;

      // --------------------------------------------------------
      // رقم سند الصرف
      // --------------------------------------------------------

      final no =
          await DatabaseService.instance.nextNumber(
        'expenses',
        'expense_no',
        'EX',
      );

      final now = DateTime.now();

      // --------------------------------------------------------
      // حفظ سند الصرف
      // --------------------------------------------------------

      await db.insert(
        'expenses',
        {
          'expense_no': no,
          'expense_date':
              now.toIso8601String(),
          'category': category,
          'amount': amount,
          'description':
              description.isEmpty
                  ? 'سند صرف'
                  : description,
        },
      );

      // --------------------------------------------------------
      // القيد المحاسبي
      // --------------------------------------------------------

      await DatabaseService.instance
          .createBalancedJournal(
        description: 'مصروف $no',
        lines: [
          {
            'account_id': exp,
            'debit': amount,
            'credit': 0.0,
            'description':
                description.isEmpty
                    ? 'مصروف'
                    : description,
          },
          {
            'account_id': cash,
            'debit': 0.0,
            'credit': amount,
            'description':
                description.isEmpty
                    ? 'صرف من الصندوق'
                    : description,
          },
        ],
        referenceType: 'expense',
      );

      await load();

      if (mounted) {
        setState(() {
          saving = false;
        });
      }

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
      if (mounted) {
        setState(() {
          saving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر حفظ سند الصرف:\n$e',
            ),
          ),
        );
      }
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

    final action =
        await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  type == 'receipt'
                      ? 'تم حفظ سند القبض بنجاح'
                      : 'تم حفظ سند الصرف بنجاح',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'رقم السند: $number',
                  style:
                      const TextStyle(
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.check,
                    ),
                  ),
                  title: const Text(
                    'حفظ فقط',
                  ),
                  subtitle:
                      const Text(
                    'تم حفظ السند في النظام',
                  ),
                  onTap: () =>
                      Navigator.pop(
                    sheetContext,
                    'saved',
                  ),
                ),

                // ------------------------------------------------
                // واتساب لسند القبض فقط
                // ------------------------------------------------

                if (type == 'receipt')
                  ListTile(
                    leading:
                        const CircleAvatar(
                      child: Icon(
                        Icons.message,
                      ),
                    ),
                    title: const Text(
                      'حفظ وإرسال إشعار',
                    ),
                    subtitle:
                        const Text(
                      'فتح واتساب والرسالة مجهزة للإرسال',
                    ),
                    onTap: () =>
                        Navigator.pop(
                      sheetContext,
                      'whatsapp',
                    ),
                  ),

                ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.picture_as_pdf,
                    ),
                  ),
                  title: const Text(
                    'طباعة / معاينة PDF',
                  ),
                  subtitle:
                      const Text(
                    'مقاس A4 مناسب للحفظ والطباعة',
                  ),
                  onTap: () =>
                      Navigator.pop(
                    sheetContext,
                    'pdf',
                  ),
                ),

                ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons.receipt,
                    ),
                  ),
                  title: const Text(
                    'طباعة حرارية',
                  ),
                  subtitle:
                      const Text(
                    'تنسيق إيصال بعرض 80 مم',
                  ),
                  onTap: () =>
                      Navigator.pop(
                    sheetContext,
                    'thermal',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null ||
        action == 'saved') {
      return;
    }

    // ==========================================================
    // واتساب
    // ==========================================================

    if (action == 'whatsapp') {
      final phone =
          '${patient['phone'] ?? ''}';

      if (phone.trim().isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'لا يوجد رقم هاتف مسجل لهذا المريض.',
            ),
          ),
        );

        return;
      }

      final message =
          MessagingService.receiptMessage(
        patient:
            '${patient['full_name'] ?? ''}',
        center:
            'مركز وسيم الطبي',
        receiptNo: number,
        amount:
            _formatAmount(amount),
        date:
            _formatDate(date),
        description:
            description.isEmpty
                ? 'سند قبض'
                : description,
        support: '',
      );

      final success =
          await MessagingService.whatsapp(
        phone,
        message,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر فتح واتساب.',
            ),
          ),
        );
      }

      return;
    }

    // ==========================================================
    // PDF
    // ==========================================================

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

    // ==========================================================
    // حراري
    // ==========================================================

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
    try {
      final doc = pw.Document();

      final font =
          await PdfGoogleFonts.notoSansArabicRegular();

      final bold =
          await PdfGoogleFonts.notoSansArabicBold();

      final pageFormat = thermal
          ? PdfPageFormat(
              80 * PdfPageFormat.mm,
              200 * PdfPageFormat.mm,
              marginAll:
                  5 * PdfPageFormat.mm,
            )
          : PdfPageFormat.a4;

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          theme:
              pw.ThemeData.withFont(
            base: font,
            bold: bold,
          ),
          build: (context) {
            return pw.Directionality(
              textDirection:
                  pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .stretch,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'مركز وسيم الطبي',
                      style:
                          pw.TextStyle(
                        font: bold,
                        fontSize:
                            thermal
                                ? 15
                                : 22,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    height: 4,
                  ),

                  pw.Center(
                    child: pw.Text(
                      type == 'receipt'
                          ? 'سند قبض'
                          : 'سند صرف',
                      style:
                          pw.TextStyle(
                        font: bold,
                        fontSize:
                            thermal
                                ? 13
                                : 18,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    height: 8,
                  ),

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
                      '${patient['full_name'] ?? '-'}',
                      font,
                      bold,
                      thermal,
                    ),

                  if (type == 'expense')
                    _pdfRow(
                      'حساب المصروف',
                      category.isEmpty
                          ? '-'
                          : category,
                      font,
                      bold,
                      thermal,
                    ),

                  _pdfRow(
                    'المبلغ',
                    '${_formatAmount(amount)} ريال',
                    font,
                    bold,
                    thermal,
                  ),

                  _pdfRow(
                    'البيان',
                    description.isEmpty
                        ? (type ==
                                'receipt'
                            ? 'سند قبض'
                            : 'سند صرف')
                        : description,
                    font,
                    bold,
                    thermal,
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  pw.Divider(),

                  pw.SizedBox(
                    height: 8,
                  ),

                  pw.Center(
                    child: pw.Text(
                      type == 'receipt'
                          ? 'تم استلام المبلغ المذكور أعلاه.'
                          : 'تم صرف المبلغ المذكور أعلاه.',
                      textAlign:
                          pw.TextAlign.center,
                      style:
                          pw.TextStyle(
                        font: font,
                        fontSize:
                            thermal
                                ? 9
                                : 13,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    height: 18,
                  ),

                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,
                    children: [
                      pw.Text(
                        'المستلم',
                        style:
                            pw.TextStyle(
                          font: font,
                          fontSize:
                              thermal
                                  ? 8
                                  : 11,
                        ),
                      ),
                      pw.Text(
                        'المحاسب',
                        style:
                            pw.TextStyle(
                          font: font,
                          fontSize:
                              thermal
                                  ? 8
                                  : 11,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(
                    height: 30,
                  ),

                  pw.Center(
                    child: pw.Text(
                      'مركز وسيم الطبي',
                      style:
                          pw.TextStyle(
                        font: bold,
                        fontSize:
                            thermal
                                ? 9
                                : 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout:
            (PdfPageFormat format) async {
          return doc.save();
        },
        name:
            '${type == 'receipt' ? 'سند_قبض' : 'سند_صرف'}_$number.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إنشاء المستند:\n$e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // صف PDF
  // ============================================================

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
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: bold,
                fontSize:
                    thermal ? 8 : 11,
              ),
            ),
          ),
          pw.SizedBox(
            width: 8,
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Text(
              value,
              textAlign:
                  pw.TextAlign.right,
              style: pw.TextStyle(
                font: font,
                fontSize:
                    thermal ? 8 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // بطاقة إحصائية
  // ============================================================

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment:
                    AlignmentDirectional
                        .centerStart,
                child: Text(
                  '${_formatAmount(value == '0' ? 0 : double.tryParse(value) ?? 0)} ريال',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // زر العملية
  // ============================================================

  Widget _actionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_left,
        ),
        onTap: saving
            ? null
            : onTap,
      ),
    );
  }

  // ============================================================
  // عرض العمليات
  // ============================================================

  Widget _transactionsSection() {
    final items = <Map<String, dynamic>>[];

    for (final row
        in todayReceipts) {
      items.add({
        'type': 'receipt',
        'number':
            '${row['receipt_no'] ?? ''}',
        'amount':
            _toDouble(row['amount']),
        'description':
            '${row['description'] ?? 'سند قبض'}',
      });
    }

    for (final row
        in todayExpenses) {
      items.add({
        'type': 'expense',
        'number':
            '${row['expense_no'] ?? ''}',
        'amount':
            _toDouble(row['amount']),
        'description':
            '${row['description'] ?? 'سند صرف'}',
      });
    }

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            children: const [
              Icon(
                Icons.receipt_long_outlined,
                size: 45,
              ),
              SizedBox(height: 10),
              Text(
                'لا توجد عمليات مالية اليوم.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    items.sort(
      (a, b) => b['number']
          .toString()
          .compareTo(
            a['number'].toString(),
          ),
    );

    return Card(
      elevation: 0,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(
              Icons.history,
            ),
            title: Text(
              'عمليات اليوم',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const Divider(height: 1),

          ...items.map(
            (item) {
              final isReceipt =
                  item['type'] ==
                      'receipt';

              final amount =
                  item['amount']
                      as double;

              return ListTile(
                leading:
                    CircleAvatar(
                  child: Icon(
                    isReceipt
                        ? Icons
                            .arrow_downward
                        : Icons
                            .arrow_upward,
                  ),
                ),
                title: Text(
                  isReceipt
                      ? 'سند قبض ${item['number']}'
                      : 'سند صرف ${item['number']}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  item['description']
                      .toString(),
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
                trailing: Text(
                  '${_formatAmount(amount)} ريال',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // واجهة الشاشة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final net = receipts - expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الحسابات',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed:
                loading ? null : load,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : ListView(
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                children: [
                  // ------------------------------------------------
                  // العنوان
                  // ------------------------------------------------

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            child: Icon(
                              Icons
                                  .account_balance,
                              size: 28,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'الإدارة المالية',
                                  style:
                                      TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'إدارة المقبوضات والمصروفات وحركة الصندوق',
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ------------------------------------------------
                  // الإحصائيات
                  // ------------------------------------------------

                  Row(
                    children: [
                      _statCard(
                        title:
                            'مقبوضات اليوم',
                        value:
                            receipts.toString(),
                        icon:
                            Icons
                                .arrow_downward,
                      ),
                      _statCard(
                        title:
                            'مصروفات اليوم',
                        value:
                            expenses.toString(),
                        icon:
                            Icons
                                .arrow_upward,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 0,
                          child:
                              Padding(
                            padding:
                                const EdgeInsets
                                    .all(
                              14,
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Icon(
                                  Icons
                                      .account_balance_wallet,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                const Text(
                                  'صافي الحركة اليوم',
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                FittedBox(
                                  child:
                                      Text(
                                    '${_formatAmount(net)} ريال',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          19,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ------------------------------------------------
                  // العمليات
                  // ------------------------------------------------

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      'العمليات المالية',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  _actionButton(
                    title:
                        'سند قبض',
                    subtitle:
                        'تسجيل مبلغ مستلم من مريض',
                    icon:
                        Icons.receipt_long,
                    onTap: receipt,
                  ),

                  _actionButton(
                    title:
                        'سند صرف',
                    subtitle:
                        'تسجيل مصروف من الصندوق',
                    icon:
                        Icons.money_off,
                    onTap: expense,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      'حركة اليوم',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  _transactionsSection(),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
      ),
    );
  }
}
