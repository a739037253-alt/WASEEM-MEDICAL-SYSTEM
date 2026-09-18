import 'package:flutter/material.dart';
import 'sessions_screen.dart';
import 'departments_screen.dart';
import 'staff_screen.dart';
import 'finance_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('المزيد')),body:ListView(padding:const EdgeInsets.all(12),children:[
    _item(context,'الجلسات والباقات',Icons.healing,const SessionsScreen()),
    _item(context,'الأقسام والخدمات',Icons.local_hospital,const DepartmentsScreen()),
    _item(context,'الكادر والعمال',Icons.groups,const StaffScreen()),
    _item(context,'الإدارة المالية',Icons.account_balance_wallet,const FinanceScreen()),
    _item(context,'التقارير',Icons.bar_chart,const ReportsScreen()),
    _item(context,'الإعدادات',Icons.settings,const SettingsScreen()),
  ]));
  Widget _item(BuildContext c,String t,IconData i,Widget page)=>Card(elevation:0,child:ListTile(leading:Icon(i,color:Theme.of(c).colorScheme.primary),title:Text(t),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page))));
}
