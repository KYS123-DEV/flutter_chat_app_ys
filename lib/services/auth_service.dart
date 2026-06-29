import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 현재 로그인한 유저 정보 가져오기 (없으면 null)
  User? get currentUser => _auth.currentUser;

  // 2. 인증 상태 변화를 감지하는 스트림 (로그인/로그아웃 실시간 감지)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 3. 이름/이메일/비밀번호 회원가입
Future<UserCredential?> signUp(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // .png 확장자를 명시하고, 플러터가 렌더링하기 가장 좋은 포맷으로 변경.
      String profileUrl = 'https://api.dicebear.com/7.x/bottts/png?seed=${credential.user!.uid}';

      UserModel newUser = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        profileUrl: profileUrl,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // 4. 이메일/비밀번호 로그인
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      ('로그인 에러: ${e.message}');
      rethrow;
    }
  }

  // 5. 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 6. 내 프로필 정보 실시간 스트림 (프로필 화면 렌더링용)
  Stream<UserModel> getMyProfileStream() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .map((snapshot) => UserModel.fromMap(snapshot.data() as Map<String, dynamic>));
  }

  // 7. 실명 업데이트 함수
  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'name': newName});
  }
}

