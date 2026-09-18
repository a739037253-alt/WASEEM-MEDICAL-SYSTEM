import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/messaging_service.dart';
import '../services/pdf_service.dart';
import '../widgets/section_card.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});
  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final age = TextEditingController();
  final birth = TextEditingController();
  final address = TextEditingController();
  final nationalId = TextEditingController();
  final notes = TextEditingController();
  final serviceController = TextEditingController();
  final doctorController = TextEditingController();
  String gender = 'ذكر';
  String department = 'العلاج الطبيعي';
  String service = '';
  String doctor = '';
  String referral = 'معرفة شخصية';
  DateTime registrationDate = DateTime.now();
  bool sending = false;

  @override
  void dispose() {
    name.dispose(); phone.dispose(); age.dispose(); birth.dispose(); address.dispose();
    nationalId.dispose();
    notes.dispose();
    serviceController.dispose();
    doctorController.dispose();
    super.dispose();
  }

  Future<void> pickBirth() async {
    final d = await showDatePicker(context: context, firstDate: DateTime(1920), lastDate: DateTime.now(), initialDate: DateTime(2000), locale: const Locale('ar'));
    if (d != null) birth.text = DateFormat('yyyy-MM-dd').format(d);
    setState(() {});
  }

  Future<void> save({bool notify = false, bool print = false}) async {
    if (!formKey.currentState!.validate()) return;
    setState(() => sending = true);
    try {
      final fileNo = await DatabaseService.instance.nextFileNo();
      final data = <String, Object?>{
        'file_no': fileNo,
        'full_name': name.text.trim(),
        'phone': phone.text.trim(),
        'gender': gender,
        'age': int.tryParse(age.text),
        'birth_date': birth.text.trim(),
        'address': address.text.trim(),
        'national_id': nationalId.text.trim(),
        'department': department,
        'service': serviceController.text.trim(),
        'doctor': doctorController.text.trim(),
        'referral_source': referral,
        'notes': notes.text.trim(),
        'created_at': registrationDate.toIso8601String(),
      };
      final id = await DatabaseService.instance.createPatient(data);
      final patient = {...data, 'id': id};
      if (print) {
        await PdfService.printPatientCard(patient, 'المركز الأول للعلاج الطبيعي والتأهيل - دمت');
      }
      if (notify) {
        final message = MessagingService.registrationMessage(
          patient: name.text.trim(),
          fileNo: fileNo,
          center: 'المركز الأول للعلاج الطبيعي والتأهيل - دمت',
          service: serviceController.text.trim().isEmpty ? department : serviceController.text.trim(),
          date: DateFormat('yyyy/MM/dd').format(registrationDate),
          support: '774486588',
        );
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Wrap(children: [
              ListTile(leading: const Icon(Icons.chat), title: const Text('فتح WhatsApp'), onTap: () => Navigator.pop(context, 'wa')),
              ListTile(leading: const Icon(Icons.sms), title: const Text('فتح SMS'), onTap: () => Navigator.pop(context, 'sms')),
            ]),
          ),
        );
        if (choice == 'wa') await MessagingService.whatsapp(phone.text.trim(), message);
        if (choice == 'sms') await MessagingService.sms(phone.text.trim(), message);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المريض بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('إضافة مريض جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('تسجيل بيانات المريض في النظام', style: TextStyle(fontSize: 12)),
        ]),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            SectionCard(
              title: 'البيانات الأساسية للمريض',
              icon: Icons.person,
              child: Column(children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الكامل *'), validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null),
                const SizedBox(height: 10),
                TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الجوال *', prefixIcon: Icon(Icons.phone)), validator: (v) => v == null || v.trim().length < 7 ? 'أدخل رقمًا صحيحًا' : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(controller: nationalId, decoration: const InputDecoration(labelText: 'رقم الهوية (اختياري)'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: gender, decoration: const InputDecoration(labelText: 'الجنس *'), items: const [
                    DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                    DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                  ], onChanged: (v) => setState(() => gender = v!))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: birth, readOnly: true, onTap: pickBirth, decoration: const InputDecoration(labelText: 'تاريخ الميلاد', suffixIcon: Icon(Icons.calendar_month)))),
                ]),
                const SizedBox(height: 10),
                TextFormField(controller: address, decoration: const InputDecoration(labelText: 'العنوان *'), validator: (v) => v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null),
              ]),
            ),
            SectionCard(
              title: 'المعلومات الإضافية',
              icon: Icons.folder_open,
              child: Column(children: [
                DropdownButtonFormField<String>(value: department, decoration: const InputDecoration(labelText: 'القسم *'), items: const [
                  DropdownMenuItem(value: 'العلاج الطبيعي', child: Text('العلاج الطبيعي')),
                  DropdownMenuItem(value: 'قسم الأطفال', child: Text('قسم الأطفال')),
                  DropdownMenuItem(value: 'قسم النساء', child: Text('قسم النساء')),
                  DropdownMenuItem(value: 'قسم الرجال', child: Text('قسم الرجال')),
                  DropdownMenuItem(value: 'الحجامة والمساج', child: Text('الحجامة والمساج')),
                  DropdownMenuItem(value: 'عيادة التغذية العلاجية', child: Text('عيادة التغذية العلاجية')),
                  DropdownMenuItem(value: 'عيادة المخ والأعصاب', child: Text('عيادة المخ والأعصاب')),
                ], onChanged: (v) => setState(() => department = v!)),
                const SizedBox(height: 10),
                TextFormField(controller: serviceController, decoration: const InputDecoration(labelText: 'الخدمة (اختياري)')),
                const SizedBox(height: 10),
                TextFormField(controller: doctorController, decoration: const InputDecoration(labelText: 'الطبيب / الأخصائي (اختياري)')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(value: referral, decoration: const InputDecoration(labelText: 'مصدر المعرفة بالمركز'), items: const [
                  DropdownMenuItem(value: 'معرفة شخصية', child: Text('معرفة شخصية')),
                  DropdownMenuItem(value: 'إحالة طبية', child: Text('إحالة طبية')),
                  DropdownMenuItem(value: 'وسائل التواصل', child: Text('وسائل التواصل')),
                  DropdownMenuItem(value: 'مريض سابق', child: Text('مريض سابق')),
                ], onChanged: (v) => setState(() => referral = v!)),
                const SizedBox(height: 10),
                TextFormField(controller: notes, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'ملاحظات أولية (اختياري)')),
              ]),
            ),
            if (sending) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                FilledButton.icon(onPressed: sending ? null : () => save(), icon: const Icon(Icons.save), label: const Text('حفظ المريض')),
                OutlinedButton.icon(onPressed: sending ? null : () => save(notify: true), icon: const Icon(Icons.send), label: const Text('حفظ وإرسال إشعار')),
                OutlinedButton.icon(onPressed: sending ? null : () => save(print: true), icon: const Icon(Icons.print), label: const Text('حفظ وطباعة')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
