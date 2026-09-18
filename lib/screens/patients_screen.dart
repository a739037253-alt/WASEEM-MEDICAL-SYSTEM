import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'add_patient_screen.dart';
import 'patient_details_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});
  @override State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final search = TextEditingController();
  List<Map<String, Object?>> rows = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }
  @override void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => loading = true);
    rows = await DatabaseService.instance.patients(search: search.text);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المرضى')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPatientScreen())).then((_) => load()), icon: const Icon(Icons.person_add), label: const Text('مريض جديد')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: search, onChanged: (_) => load(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث بالاسم أو الهاتف أو رقم الملف'))),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : rows.isEmpty ? const Center(child: Text('لا توجد بيانات مرضى')) : ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = rows[i];
            return Card(elevation: 0, child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('${p['full_name']}'),
              subtitle: Text('${p['file_no']} • ${p['phone']}\n${p['department'] ?? ''}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'open') Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailsScreen(patientId: p['id'] as int))).then((_) => load());
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'open', child: Text('فتح الملف')),
                ],
              ),
            ));
          },
        )),
      ]),
    );
  }
}
