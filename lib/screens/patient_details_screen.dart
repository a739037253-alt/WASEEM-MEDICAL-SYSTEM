import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/messaging_service.dart';
import '../services/settings_service.dart';
import '../services/pdf_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final int patientId;
  const PatientDetailsScreen({super.key, required this.patientId});
  @override State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Map<String, Object?>? p;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { p = await DatabaseService.instance.patient(widget.patientId); if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('${p!['full_name']}')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${p!['full_name']}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          Text('رقم الملف: ${p!['file_no']}'),
          const Divider(),
          _info('الهاتف', p!['phone']),
          _info('الجنس', p!['gender']),
          _info('العمر', p!['age']),
          _info('العنوان', p!['address']),
          _info('القسم', p!['department']),
          _info('الخدمة', p!['service']),
          _info('الطبيب / الأخصائي', p!['doctor']),
          _info('الملاحظات', p!['notes']),
        ]))),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () async {
            final center = await SettingsService.instance.centerName();
            final msg = MessagingService.registrationMessage(patient: '${p!['full_name']}', fileNo: '${p!['file_no']}', center: center, service: '${p!['service'] ?? p!['department']}', date: '${p!['created_at']}'.substring(0,10), support: '774486588');
            await MessagingService.whatsapp('${p!['phone']}', msg);
          }, icon: const Icon(Icons.chat), label: const Text('WhatsApp')),
          OutlinedButton.icon(onPressed: () => PdfService.printPatientCard(p!, 'المركز الأول للعلاج الطبيعي والتأهيل - دمت'), icon: const Icon(Icons.print), label: const Text('طباعة')),
        ]),
      ]),
    );
  }

  Widget _info(String title, Object? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [SizedBox(width: 120, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(child: Text('${value ?? ''}'))]),
  );
}
