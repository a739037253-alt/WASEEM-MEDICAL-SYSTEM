import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/patients_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/more_screen.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const AppShell({super.key, required this.onThemeChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onThemeChanged: widget.onThemeChanged),
      const PatientsScreen(),
      const AppointmentsScreen(),
      const ReportsScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'المرضى'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'المواعيد'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}
