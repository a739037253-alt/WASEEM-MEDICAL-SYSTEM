import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState()=>_ReportsScreenState();
}
class _ReportsScreenState extends State<ReportsScreen>{
  Map<String,double> balance={};
  @override void initState(){super.initState();load();}
  Future<void> load()async{balance=await DatabaseService.instance.trialBalance();if(mounted)setState((){});}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('التقارير والإحصائيات')),body:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('التقارير التشغيلية',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
    _report('تقرير المرضى',Icons.people),
    _report('تقرير المواعيد والجلسات',Icons.calendar_month),
    _report('التقارير المالية',Icons.account_balance),
    const SizedBox(height:18),
    Row(children:[const Expanded(child:Text('ميزان المراجعة',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),
    Card(elevation:0,child:Column(children:balance.entries.map((e)=>ListTile(title:Text(e.key),trailing:Text(e.value.toStringAsFixed(2)))).toList())),
  ]));
  Widget _report(String t,IconData i)=>Card(elevation:0,child:ListTile(leading:Icon(i),title:Text(t),subtitle:const Text('يعرض البيانات من قاعدة البيانات المحلية'),trailing:const Icon(Icons.chevron_left)));
}
