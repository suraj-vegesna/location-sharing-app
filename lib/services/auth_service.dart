import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.uid);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    final profile = UserProfile(
      id: user.uid,
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
    );
    await _firestore.collection('users').doc(user.uid).set(profile.toMap());
    return profile;
  }

  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final profile = await getProfile(credential.user!.uid);
    if (profile == null) {
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'User profile not found.',
      );
    }
    return profile;
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserProfile?> findUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Future<void> updateSharingPreference({
    required String userId,
    required bool isSharing,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'isSharingLocation': isSharing,
    });
  }
}
