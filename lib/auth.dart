import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseAuth {
  Future<String> signInWithEmailAndPassword(String email, String password);
  Future<String> createUserWithEmailAndPassword(String email, String password);
  Future<String> currentUser();
  Future<String> currentUserEmail();
  Future<void> signOut();
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String> signInWithEmailAndPassword(String email, String password) async {
    UserCredential authResult = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);
    return authResult.user.uid;
  }

  Future<String> createUserWithEmailAndPassword(String email, String password) async {
    UserCredential authResult = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    return authResult.user.uid;
  }

  Future<String> currentUser() async {
    User user = _firebaseAuth.currentUser;
    print("user:" + user.toString());
    return user.uid;
  }

  Future<String> currentUserEmail() async {
    User user = _firebaseAuth.currentUser;
    return user.email;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }
}