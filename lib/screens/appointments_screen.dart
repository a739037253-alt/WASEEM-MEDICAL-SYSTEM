import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String,Object?>> rows = [];
  @override void initState(){super.initState();load();}
  Future<void> load() async { rows = await DatabaseService.instance.appointments(); if(mounted)setState((){}); }

  Future<void> add() async {
    final patients = await DatabaseService.instance.patients();
    if (patients.isEmpty) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مريضًا أولًا'))); return; }
    int patientId = patients.first['id'] as int;
    DateTime date = DateTime.now().add(const Duration(days: 1));
    final doctor = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context,set) => AlertDialog(
      title: const Text('إضافة موعد'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: patientId, decoration: const InputDecoration(labelText:'المريض'), items: [for(final p in patients) DropdownMenuItem(value:p['id'] as int, child: Text('${p['full_name']}'))], onChanged:(v)=>set(()=>patientId=v!)),
        const SizedBox(height:10),
        TextField(controller: doctor, decoration: const InputDecoration(labelText:'الطبيب / الأخصائي')),
        const SizedBox(height:10),
        ListTile(title: Text('التاريخ: ${date.toString().substring(0,16)}'), trailing: const Icon(Icons.calendar_month), onTap: () async { final d=await showDatePicker(context:context, firstDate:DateTime.now(), lastDate:DateTime.now().add(const Duration(days:365)), initialDate:date); if(d!=null)set(()=>date=DateTime(d.year,d.month,d.day,10)); }),
        TextField(controller: notes, decoration: const InputDecoration(labelText:'ملاحظات')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))],
    )));
    if(result==true){
      final p=patients.firstWhere((e)=>e['id']==patientId);
      await DatabaseService.instance.db.insert('appointments', {'patient_id':patientId,'doctor':doctor.text,'department':p['department'],'service':p['service'],'appointment_date':date.toIso8601String(),'notes':notes.text});
      await load();
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('المواعيد')),
    floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('موعد جديد')),
    body:rows.isEmpty?const Center(child:Text('لا توجد مواعيد')):ListView.separated(
      padding:const EdgeInsets.all(12),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
      itemBuilder:(_,i){final r=rows[i];return Card(elevation:0,child:ListTile(leading:const Icon(Icons.calendar_month),title:Text('${r['full_name']}'),subtitle:Text('${r['appointment_date']}\n${r['doctor']??''}'),isThreeLine:true,trailing:Chip(label:Text('${r['status']}'))));}
    )
  );
}
