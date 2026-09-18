import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();
  Database? _db;

  Database get db => _db!;

  Future<void> initialize() async {
    if (_db != null) return;
    final path = join(await getDatabasesPath(), 'waseem_medical_pro.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_no TEXT UNIQUE NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        gender TEXT NOT NULL,
        age INTEGER,
        birth_date TEXT,
        address TEXT,
        national_id TEXT,
        department TEXT,
        service TEXT,
        doctor TEXT,
        referral_source TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'نشط',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        diagnosis TEXT,
        complaint TEXT,
        treatment_plan TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        doctor TEXT,
        department TEXT,
        service TEXT,
        appointment_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'مجدول',
        notes TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE packages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        service TEXT,
        total_sessions INTEGER NOT NULL,
        remaining_sessions INTEGER NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'فعالة',
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        package_id INTEGER,
        therapist TEXT,
        session_type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT NOT NULL DEFAULT 'مجدولة',
        notes TEXT,
        rating INTEGER,
        session_transaction_id TEXT UNIQUE,
        FOREIGN KEY(patient_id) REFERENCES patients(id),
        FOREIGN KEY(package_id) REFERENCES packages(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        parent_code TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_no TEXT UNIQUE NOT NULL,
        entry_date TEXT NOT NULL,
        description TEXT,
        reference_type TEXT,
        reference_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE journal_lines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journal_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        debit REAL NOT NULL DEFAULT 0,
        credit REAL NOT NULL DEFAULT 0,
        description TEXT,
        FOREIGN KEY(journal_id) REFERENCES journal_entries(id),
        FOREIGN KEY(account_id) REFERENCES accounts(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT UNIQUE NOT NULL,
        patient_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        total REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0,
        payment_method TEXT NOT NULL DEFAULT 'آجل',
        status TEXT NOT NULL DEFAULT 'غير مدفوعة',
        notes TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE receipts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_no TEXT UNIQUE NOT NULL,
        patient_id INTEGER,
        receipt_date TEXT NOT NULL,
        amount REAL NOT NULL,
        account_name TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_no TEXT UNIQUE NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        responsible TEXT,
        work_days TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        duration INTEGER NOT NULL DEFAULT 30,
        package_allowed INTEGER NOT NULL DEFAULT 1,
        active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(department_id) REFERENCES departments(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        national_id TEXT,
        job_type TEXT NOT NULL,
        department TEXT,
        hire_date TEXT,
        contract_type TEXT,
        status TEXT NOT NULL DEFAULT 'نشط',
        salary REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE audit_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        reference TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final departments = <Map<String, Object?>>[
      {'name': 'قسم الأطفال', 'responsible': '', 'work_days': 'بحسب الحجز'},
      {'name': 'قسم النساء', 'responsible': '', 'work_days': 'بحسب الحجز'},
      {'name': 'قسم الرجال', 'responsible': '', 'work_days': 'بحسب الحجز'},
      {'name': 'الحجامة والمساج', 'responsible': '', 'work_days': 'بحسب الحجز'},
      {'name': 'الصالة الرياضية', 'responsible': '', 'work_days': 'بحسب الحجز'},
      {'name': 'عيادة التغذية العلاجية', 'responsible': 'د. غمدان أحمد قاسم الجماعي', 'work_days': 'الأربعاء والخميس'},
      {'name': 'عيادة المخ والأعصاب', 'responsible': 'أخصائي المخ والأعصاب', 'work_days': 'يوم واحد شهرياً بحسب الحجز'},
    ];
    for (final d in departments) {
      await db.insert('departments', d, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final accounts = [
      ['1000', 'الأصول', 'أصول', null],
      ['1100', 'الصندوق الرئيسي', 'أصول', '1000'],
      ['1200', 'البنوك', 'أصول', '1000'],
      ['1300', 'ذمم المرضى والعملاء', 'أصول', '1000'],
      ['1400', 'المخزون', 'أصول', '1000'],
      ['2000', 'الالتزامات', 'التزامات', null],
      ['2100', 'ذمم الموردين', 'التزامات', '2000'],
      ['3000', 'حقوق الملكية', 'حقوق ملكية', null],
      ['3100', 'رأس المال', 'حقوق ملكية', '3000'],
      ['4000', 'الإيرادات', 'إيرادات', null],
      ['4100', 'إيرادات الخدمات الطبية', 'إيرادات', '4000'],
      ['5000', 'المصروفات', 'مصروفات', null],
      ['5100', 'المرتبات والأجور', 'مصروفات', '5000'],
      ['5200', 'الإيجارات', 'مصروفات', '5000'],
      ['5300', 'المستلزمات الطبية', 'مصروفات', '5000'],
      ['5400', 'الكهرباء والمياه', 'مصروفات', '5000'],
      ['5500', 'المصروفات العمومية', 'مصروفات', '5000'],
    ];
    for (final a in accounts) {
      await db.insert('accounts', {
        'code': a[0],
        'name': a[1],
        'type': a[2],
        'parent_code': a[3],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<int> addAudit(String action, String reference) {
    return db.insert('audit_log', {
      'action': action,
      'reference': reference,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> nextFileNo() async {
    final r = await db.rawQuery('SELECT COUNT(*) c FROM patients');
    final n = (r.first['c'] as int? ?? 0) + 1;
    return '#${n.toString().padLeft(4, '0')}';
  }

  Future<String> nextNumber(String table, String column, String prefix) async {
    final r = await db.rawQuery('SELECT COUNT(*) c FROM $table');
    final n = (r.first['c'] as int? ?? 0) + 1;
    return '$prefix${n.toString().padLeft(5, '0')}';
  }

  Future<int> createPatient(Map<String, Object?> data) async {
    return db.transaction((txn) async {
      final id = await txn.insert('patients', data);
      await txn.insert('medical_records', {
        'patient_id': id,
        'created_at': DateTime.now().toIso8601String(),
      });
      await txn.insert('audit_log', {
        'action': 'إنشاء ملف مريض',
        'reference': data['file_no'],
        'created_at': DateTime.now().toIso8601String(),
      });
      return id;
    });
  }

  Future<List<Map<String, Object?>>> patients({String search = ''}) async {
    if (search.trim().isEmpty) {
      return db.query('patients', orderBy: 'id DESC');
    }
    final q = '%${search.trim()}%';
    return db.query('patients',
        where: 'full_name LIKE ? OR phone LIKE ? OR file_no LIKE ? OR CAST(id AS TEXT) LIKE ?',
        whereArgs: [q, q, q, q],
        orderBy: 'id DESC');
  }

  Future<Map<String, Object?>?> patient(int id) async {
    final r = await db.query('patients', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : r.first;
  }

  Future<List<Map<String, Object?>>> appointments() async {
    return db.rawQuery('''
      SELECT a.*, p.full_name, p.file_no, p.phone
      FROM appointments a JOIN patients p ON p.id=a.patient_id
      ORDER BY a.appointment_date DESC
    ''');
  }

  Future<List<Map<String, Object?>>> packages() async {
    return db.rawQuery('''
      SELECT b.*, p.full_name, p.file_no
      FROM packages b JOIN patients p ON p.id=b.patient_id
      ORDER BY b.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> sessions() async {
    return db.rawQuery('''
      SELECT s.*, p.full_name, p.file_no, b.name package_name
      FROM sessions s JOIN patients p ON p.id=s.patient_id
      LEFT JOIN packages b ON b.id=s.package_id
      ORDER BY s.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> departments() => db.query('departments', orderBy: 'name');

  Future<List<Map<String, Object?>>> staff() => db.query('staff', orderBy: 'id DESC');

  Future<int> patientCount() async {
    final r = await db.rawQuery('SELECT COUNT(*) c FROM patients');
    return r.first['c'] as int? ?? 0;
  }

  Future<int> todayAppointments() async {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    final r = await db.rawQuery("SELECT COUNT(*) c FROM appointments WHERE appointment_date LIKE ?", ['$d%']);
    return r.first['c'] as int? ?? 0;
  }

  Future<int> todaySessions() async {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    final r = await db.rawQuery("SELECT COUNT(*) c FROM sessions WHERE start_time LIKE ?", ['$d%']);
    return r.first['c'] as int? ?? 0;
  }

  Future<double> todayReceipts() async {
    final d = DateTime.now().toIso8601String().substring(0, 10);
    final r = await db.rawQuery("SELECT COALESCE(SUM(amount),0) total FROM receipts WHERE receipt_date LIKE ?", ['$d%']);
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<void> completeSession(int sessionId) async {
    await db.transaction((txn) async {
      final rows = await txn.query('sessions', where: 'id=?', whereArgs: [sessionId], limit: 1);
      if (rows.isEmpty) throw Exception('الجلسة غير موجودة');
      final s = rows.first;
      if (s['status'] == 'مكتملة') return;
      final packageId = s['package_id'] as int?;
      final txId = s['session_transaction_id'] as String?;
      if (packageId != null) {
        final package = await txn.query('packages', where: 'id=?', whereArgs: [packageId], limit: 1);
        if (package.isNotEmpty) {
          final remaining = package.first['remaining_sessions'] as int? ?? 0;
          if (remaining <= 0) throw Exception('لا توجد جلسات متبقية في الباقة');
          final transactionId = txId ?? 'SESSION-$sessionId-${DateTime.now().microsecondsSinceEpoch}';
          final exists = await txn.query('sessions',
              where: 'session_transaction_id=? AND id<>?', whereArgs: [transactionId, sessionId]);
          if (exists.isEmpty) {
            await txn.update('packages', {'remaining_sessions': remaining - 1},
                where: 'id=?', whereArgs: [packageId]);
          }
          await txn.update('sessions', {
            'status': 'مكتملة',
            'session_transaction_id': transactionId,
          }, where: 'id=?', whereArgs: [sessionId]);
        }
      } else {
        await txn.update('sessions', {'status': 'مكتملة'}, where: 'id=?', whereArgs: [sessionId]);
      }
    });
  }

  Future<void> cancelSession(int sessionId) async {
    await db.transaction((txn) async {
      final rows = await txn.query('sessions', where: 'id=?', whereArgs: [sessionId], limit: 1);
      if (rows.isEmpty) return;
      final s = rows.first;
      final wasCompleted = s['status'] == 'مكتملة';
      final packageId = s['package_id'] as int?;
      if (wasCompleted && packageId != null) {
        final p = await txn.query('packages', where: 'id=?', whereArgs: [packageId], limit: 1);
        if (p.isNotEmpty) {
          final rem = p.first['remaining_sessions'] as int? ?? 0;
          final total = p.first['total_sessions'] as int? ?? 0;
          await txn.update('packages', {'remaining_sessions': (rem + 1).clamp(0, total)},
              where: 'id=?', whereArgs: [packageId]);
        }
      }
      await txn.update('sessions', {'status': 'ملغاة'}, where: 'id=?', whereArgs: [sessionId]);
    });
  }

  Future<int> createBalancedJournal({
    required String description,
    required List<Map<String, Object?>> lines,
    String? referenceType,
    int? referenceId,
  }) async {
    final debit = lines.fold<double>(0, (v, e) => v + ((e['debit'] as num?)?.toDouble() ?? 0));
    final credit = lines.fold<double>(0, (v, e) => v + ((e['credit'] as num?)?.toDouble() ?? 0));
    if ((debit - credit).abs() > 0.001) {
      throw Exception('القيد غير متوازن: المدين $debit والدائن $credit');
    }
    return db.transaction((txn) async {
      final no = 'JE${DateTime.now().millisecondsSinceEpoch}';
      final id = await txn.insert('journal_entries', {
        'entry_no': no,
        'entry_date': DateTime.now().toIso8601String(),
        'description': description,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final line in lines) {
        await txn.insert('journal_lines', {...line, 'journal_id': id});
      }
      return id;
    });
  }

  Future<Map<String, double>> trialBalance() async {
    final rows = await db.rawQuery('''
      SELECT a.name,
        COALESCE(SUM(l.debit),0) debit,
        COALESCE(SUM(l.credit),0) credit
      FROM accounts a
      LEFT JOIN journal_lines l ON l.account_id=a.id
      GROUP BY a.id, a.name
      ORDER BY a.code
    ''');
    return {for (final r in rows) r['name'] as String: ((r['debit'] as num).toDouble() - (r['credit'] as num).toDouble())};
  }
}
