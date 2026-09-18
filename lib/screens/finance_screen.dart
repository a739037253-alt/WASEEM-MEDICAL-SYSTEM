import 'package:flutter/material.dart';
import '../services/database_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override State<FinanceScreen> createState()=>_FinanceScreenState();
}
class _FinanceScreenState extends State<FinanceScreen>{
  double receipts=0;
  @override void initState(){super.initState();load();}
  Future<void> load()async{receipts=await DatabaseService.instance.todayReceipts();if(mounted)setState((){});}
  Future<void> receipt()async{
    final patients=await DatabaseService.instance.patients();
    int? pid=patients.isEmpty?null:patients.first['id'] as int;
    final amount=TextEditingController(),desc=TextEditingController();
    if(patients.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مريضًا أولًا')));return;}
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:const Text('سند قبض'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int>(value:pid,items:[for(final p in patients)DropdownMenuItem(value:p['id'] as int,child:Text('${p['full_name']}'))],onChanged:(v)=>set(()=>pid=v!),decoration:const InputDecoration(labelText:'المريض')),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ')),TextField(controller:desc,decoration:const InputDecoration(labelText:'البيان'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حفظ'))])));
    if(ok==true){
      final a=double.tryParse(amount.text)??0;if(a<=0)return;
      final no=await DatabaseService.instance.nextNumber('receipts','receipt_no','RV');
      await DatabaseService.instance.db.insert('receipts',{'receipt_no':no,'patient_id':pid,'receipt_date':DateTime.now().toIso8601String(),'amount':a,'account_name':'الصندوق الرئيسي','description':desc.text});
      final cash=(await DatabaseService.instance.db.query('accounts',where:'name=?',whereArgs:['الصندوق الرئيسي'])).first['id'] as int;
      final ar=(await DatabaseService.instance.db.query('accounts',where:'name=?',whereArgs:['ذمم المرضى والعملاء'])).first['id'] as int;
      await DatabaseService.instance.createBalancedJournal(description:'سند قبض $no',lines:[{'account_id':cash,'debit':a,'credit':0.0,'description':'قبض'},{'account_id':ar,'debit':0.0,'credit':a,'description':'قبض من مريض'},],referenceType:'receipt');
      await load();
    }
  }
  Future<void> expense()async{
    final category=TextEditingController(),amount=TextEditingController(),desc=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('سند صرف / مصروف'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:category,decoration:const InputDecoration(labelText:'حساب المصروف')),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المبلغ')),TextField(controller:desc,decoration:const InputDecoration(labelText:'البيان'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('حفظ'))]));
    if(ok==true){
      final a=double.tryParse(amount.text)??0;if(a<=0)return;
      final no=await DatabaseService.instance.nextNumber('expenses','expense_no','EX');
      await DatabaseService.instance.db.insert('expenses',{'expense_no':no,'expense_date':DateTime.now().toIso8601String(),'category':category.text.isEmpty?'المصروفات العمومية':category.text,'amount':a,'description':desc.text});
      final cash=(await DatabaseService.instance.db.query('accounts',where:'name=?',whereArgs:['الصندوق الرئيسي'])).first['id'] as int;
      final exp=(await DatabaseService.instance.db.query('accounts',where:'name=?',whereArgs:['المصروفات العمومية'])).first['id'] as int;
      await DatabaseService.instance.createBalancedJournal(description:'مصروف $no',lines:[{'account_id':exp,'debit':a,'credit':0.0,'description':desc.text},{'account_id':cash,'debit':0.0,'credit':a,'description':desc.text}],referenceType:'expense');
      await load();
    }
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإدارة المالية')),body:ListView(padding:const EdgeInsets.all(14),children:[
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.payments),title:const Text('مقبوضات اليوم'),subtitle:Text(receipts.toStringAsFixed(2),style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)))),
    const SizedBox(height:10),
    Wrap(spacing:8,runSpacing:8,children:[FilledButton.icon(onPressed:receipt,icon:const Icon(Icons.receipt_long),label:const Text('سند قبض')),OutlinedButton.icon(onPressed:expense,icon:const Icon(Icons.money_off),label:const Text('سند صرف'))]),
    const SizedBox(height:18),
    Card(elevation:0,child:ListTile(leading:const Icon(Icons.account_tree),title:const Text('المحاسبة بالقيد المزدوج'),subtitle:const Text('لا يُحفظ القيد إلا عندما يتساوى إجمالي المدين مع إجمالي الدائن.'))),
  ]));
}
