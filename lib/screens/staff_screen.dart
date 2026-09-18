import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override State<StaffScreen> createState()=>_StaffScreenState();
}
class _StaffScreenState extends State<StaffScreen>{
  List<Map<String,Object?>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{rows=await DatabaseService.instance.staff();if(mounted)setState((){});}
  Future<void> add()async{
    final name=TextEditingController(),phone=TextEditingController(),job=TextEditingController(),salary=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('إضافة كادر / عامل'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'الاسم الكامل *')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'رقم الهاتف *')),TextField(controller:job,decoration:const InputDecoration(labelText:'المسمى الوظيفي')),TextField(controller:salary,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'الراتب الأساسي'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));
    if(ok==true&&name.text.trim().isNotEmpty){await DatabaseService.instance.db.insert('staff',{'name':name.text.trim(),'phone':phone.text.trim(),'job_type':job.text.trim().isEmpty?'موظف':job.text.trim(),'salary':double.tryParse(salary.text)??0,'status':'نشط'});await load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('إدارة الكادر والعمال')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.person_add),label:const Text('إضافة')),body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];return Card(elevation:0,child:ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${r['name']}'),subtitle:Text('${r['job_type']} • ${r['phone']}'),trailing:Text('${r['salary']}'));}));
}
