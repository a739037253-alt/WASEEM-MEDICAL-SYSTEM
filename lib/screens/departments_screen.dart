import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});
  @override State<DepartmentsScreen> createState()=>_DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen>{
  List<Map<String,Object?>> rows=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{rows=await DatabaseService.instance.departments();if(mounted)setState((){});}
  Future<void> add()async{
    final name=TextEditingController();final resp=TextEditingController();final days=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('إضافة قسم'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'اسم القسم')),TextField(controller:resp,decoration:const InputDecoration(labelText:'المسؤول')),TextField(controller:days,decoration:const InputDecoration(labelText:'أيام وساعات العمل'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));
    if(ok==true&&name.text.trim().isNotEmpty){await DatabaseService.instance.db.insert('departments',{'name':name.text.trim(),'responsible':resp.text,'work_days':days.text});await load();}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الأقسام والخدمات')),floatingActionButton:FloatingActionButton.extended(onPressed:add,icon:const Icon(Icons.add),label:const Text('قسم جديد')),body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(_,i){final r=rows[i];return Card(elevation:0,child:ListTile(leading:const Icon(Icons.local_hospital),title:Text('${r['name']}'),subtitle:Text('${r['responsible']??''}\n${r['work_days']??''}'),isThreeLine:true,trailing:const Icon(Icons.chevron_left)));}));
}
