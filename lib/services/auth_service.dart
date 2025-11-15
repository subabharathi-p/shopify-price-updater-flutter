import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _secure = FlutterSecureStorage();

  // 🔸 SIGN UP
  Future<String?> signUpUser(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _secure.write(key: 'uid', value: cred.user?.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 🔸 LOGIN
  Future<String?> loginUser(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _secure.write(key: 'uid', value: cred.user?.uid);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 🔸 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    await _secure.deleteAll();
  }

  // 🔸 CHECK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    final uid = await _secure.read(key: 'uid');
    return uid != null;
  }
}
