import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState()=>_SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen>{
  final center=TextEditingController();
  @override void initState(){super.initState();load();}
  Future<void> load()async{center.text=await SettingsService.instance.centerName();setState((){});}
  @override void dispose(){center.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(padding:const EdgeInsets.all(14),children:[
    Card(elevation:0,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('بيانات المركز',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),
      TextField(controller:center,decoration:const InputDecoration(labelText:'اسم المركز')),
      const SizedBox(height:10),
      FilledButton.icon(onPressed:()async{await SettingsService.instance.setCenterName(center.text.trim().isEmpty?'وسيم ميديكال':center.text.trim());if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الإعدادات')));},icon:const Icon(Icons.save),label:const Text('حفظ')),
    ]))),
    const Card(elevation:0,child:ListTile(title:Text('الدعم الفني'),subtitle:Text('774486588'))),
    const Card(elevation:0,child:ListTile(title:Text('اسم النظام'),subtitle:Text('وسيم ميديكال — WASEEM MEDICAL PRO'))),
  ]));
}
