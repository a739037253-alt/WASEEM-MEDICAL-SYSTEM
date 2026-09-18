import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  const SplashScreen({super.key, required this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(onThemeChanged: widget.onThemeChanged)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEAF7FA), Color(0xFFF9FCFD)]),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(color: const Color(0xFF0B7891), borderRadius: BorderRadius.circular(32)),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 62),
                ),
                const SizedBox(height: 24),
                const Text('وسيم ميديكال', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF063E4D))),
                const SizedBox(height: 6),
                const Text('WASEEM MEDICAL PRO', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('نظام طبي وإداري ومحاسبي متكامل', textAlign: TextAlign.center),
                const SizedBox(height: 18),
                const Text('الدعم: 774486588'),
                const SizedBox(height: 35),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
