import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  Future<bool> isDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('dark_mode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark_mode', value);
  }

  Future<String> centerName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('center_name') ?? 'المركز الأول للعلاج الطبيعي والتأهيل - دمت';
  }

  Future<void> setCenterName(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('center_name', value);
  }

  Future<String> supportPhone() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('support_phone') ?? '774486588';
  }
}
