import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../widgets/stat_card.dart';
import 'add_patient_screen.dart';
import 'patients_screen.dart';
import 'appointments_screen.dart';
import 'sessions_screen.dart';
import 'departments_screen.dart';
import 'staff_screen.dart';
import 'finance_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int patients = 0, appointments = 0, sessions = 0;
  double receipts = 0;
  String center = 'وسيم ميديكال';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    patients = await DatabaseService.instance.patientCount();
    appointments = await DatabaseService.instance.todayAppointments();
    sessions = await DatabaseService.instance.todaySessions();
    receipts = await DatabaseService.instance.todayReceipts();
    center = await SettingsService.instance.centerName();
    if (mounted) setState(() {});
  }

  void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => load());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نظام وسيم الطبي PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
              IconButton(onPressed: widget.onThemeChanged, icon: const Icon(Icons.brightness_6_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFFE4F6F8), Color(0xFFF7FCFD)]),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نحو حياة أفضل .. بخطى واثقة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('إدارة المرضى والمواعيد والجلسات والمالية من مكان واحد.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            children: [
              StatCard(title: 'إجمالي المرضى', value: '$patients', icon: Icons.people, color: Colors.teal),
              StatCard(title: 'مواعيد اليوم', value: '$appointments', icon: Icons.calendar_month, color: Colors.blue),
              StatCard(title: 'جلسات اليوم', value: '$sessions', icon: Icons.accessibility_new, color: Colors.indigo),
              StatCard(title: 'مقبوضات اليوم', value: receipts.toStringAsFixed(0), icon: Icons.payments, color: Colors.amber.shade800),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _action('تسجيل مريض جديد', Icons.person_add, const Color(0xFF0A9A86), () => open(const AddPatientScreen())),
              _action('المواعيد', Icons.calendar_month, const Color(0xFF1675B8), () => open(const AppointmentsScreen())),
              _action('الأقسام والخدمات', Icons.medical_services, const Color(0xFFB28A2A), () => open(const DepartmentsScreen())),
              _action('الإدارة المالية', Icons.account_balance_wallet, Colors.blueGrey, () => open(const FinanceScreen())),
              _action('التقارير والإحصائيات', Icons.bar_chart, Colors.teal, () => open(const ReportsScreen())),
              _action('إدارة الموظفين', Icons.groups, Colors.indigo, () => open(const StaffScreen())),
              _action('الجلسات والباقات', Icons.healing, Colors.deepPurple, () => open(const SessionsScreen())),
              _action('المرضى', Icons.folder_shared, Colors.cyan.shade800, () => open(const PatientsScreen())),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('معلومة اليوم'),
              subtitle: const Text('الالتزام بالجلسات يساعد على متابعة الخطة العلاجية بصورة أفضل.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const SizedBox(height: 9),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_left, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
