import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // ---------------- ONBOARDING ----------------
  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', seen);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  // ---------------- USER DATA ----------------
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    if (avatar != null) {
      await prefs.setString('user_avatar', avatar);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('user_uid'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'avatar': prefs.getString('user_avatar'),
    };
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_avatar');
  }
}
