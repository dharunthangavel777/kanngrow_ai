import 'package:firebase_auth/firebase_auth.dart';

class TokenService {
  static Future<String?> getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }
}
