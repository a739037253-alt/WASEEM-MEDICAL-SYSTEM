import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  @override State<SessionsScreen> createState()=>_SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>{
  List<Map<String,Object?>> sessions=[];
  List<Map<String,Object?>> packages=[];
  @override void initState(){super.initState();load();}
  Future<void> load() async {sessions=await DatabaseService.instance.sessions();packages=await DatabaseService.instance.packages();if(mounted)setState((){});}

  Future<void> addSession() async{
    final patients=await DatabaseService.instance.patients();
    if(patients.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مريضًا أولًا')));return;}
    int pid=patients.first['id'] as int;
    int? packageId;
    final therapist=TextEditingController();
    final notes=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set)=>AlertDialog(
      title:const Text('إضافة جلسة'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<int>(value:pid,decoration:const InputDecoration(labelText:'المريض'),items:[for(final p in patients)DropdownMenuItem(value:p['id'] as int,child:Text('${p['full_name']}'))],onChanged:(v)=>set(()=>pid=v!)),
        const SizedBox(height:10),
        DropdownButtonFormField<int?>(value:packageId,decoration:const InputDecoration(labelText:'الباقة (اختياري)'),items:[const DropdownMenuItem<int?>(value:null,child:Text('جلسة فردية')),...packages.where((p)=>p['patient_id']==pid).map((p)=>DropdownMenuItem<int?>(value:p['id'] as int,child:Text('${p['name']} — متبقي ${p['remaining_sessions']}')))],onChanged:(v)=>set(()=>packageId=v)),
        const SizedBox(height:10),
        TextField(controller:therapist,decoration:const InputDecoration(labelText:'الأخصائي / المعالج')),
        const SizedBox(height:10),
        TextField(controller:notes,decoration:const InputDecoration(labelText:'الملاحظات')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))],
    )));
    if(ok==true){
      await DatabaseService.instance.db.insert('sessions',{'patient_id':pid,'package_id':packageId,'therapist':therapist.text,'session_type':packageId==null?'فردية':'من باقة','start_time':DateTime.now().toIso8601String(),'notes':notes.text});
      await load();
    }
  }

  Future<void> createPackage() async{
    final patients=await DatabaseService.instance.patients();
    if(patients.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مريضًا أولًا')));return;}
    int pid=patients.first['id'] as int;
    final name=TextEditingController(text:'باقة علاج طبيعي');
    final total=TextEditingController(text:'10');
    final price=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set)=>AlertDialog(
      title:const Text('إنشاء باقة'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<int>(value:pid,decoration:const InputDecoration(labelText:'المريض'),items:[for(final p in patients)DropdownMenuItem(value:p['id'] as int,child:Text('${p['full_name']}'))],onChanged:(v)=>set(()=>pid=v!)),
        TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الباقة')),
        TextField(controller:total,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'عدد الجلسات')),
        TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))],
    )));
    if(ok==true){
      final n=int.tryParse(total.text)??0;
      await DatabaseService.instance.db.insert('packages',{'patient_id':pid,'name':name.text,'service':'العلاج الطبيعي','total_sessions':n,'remaining_sessions':n,'price':double.tryParse(price.text)??0,'start_date':DateTime.now().toIso8601String(),'end_date':DateTime.now().add(const Duration(days:60)).toIso8601String(),'status':'فعالة'});
      await load();
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('الجلسات والباقات'),actions:[IconButton(onPressed:createPackage,icon:const Icon(Icons.inventory_2_outlined))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:addSession,icon:const Icon(Icons.add),label:const Text('جلسة')),
    body:ListView(padding:const EdgeInsets.all(12),children:[
      const Text('الباقات',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
      if(packages.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('لا توجد باقات')),
      ...packages.map((p)=>Card(elevation:0,child:ListTile(leading:const Icon(Icons.card_membership),title:Text('${p['name']} — ${p['full_name']}'),subtitle:Text('متبقي: ${p['remaining_sessions']} من ${p['total_sessions']}'),trailing:Text('${p['price']}')))),
      const SizedBox(height:16),
      const Text('الجلسات',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
      ...sessions.map((s)=>Card(elevation:0,child:ListTile(title:Text('${s['full_name']}'),subtitle:Text('${s['session_type']} • ${s['therapist']??''}'),trailing:PopupMenuButton<String>(onSelected:(v)async{try{if(v=='complete')await DatabaseService.instance.completeSession(s['id'] as int);if(v=='cancel')await DatabaseService.instance.cancelSession(s['id'] as int);await load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}},itemBuilder:(_)=>const[PopupMenuItem(value:'complete',child:Text('تسجيل مكتملة وخصم الجلسة')),PopupMenuItem(value:'cancel',child:Text('إلغاء الجلسة'))])))),
    ])
  );
}
