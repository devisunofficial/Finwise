import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return _users.doc(uid);
  }

  CollectionReference<Map<String, dynamic>> userTransactions(String uid) {
    return userDoc(uid).collection('transactions');
  }

  Future<void> ensureUserDoc({required String uid, required String email}) async {
    final docRef = userDoc(uid);
    final snapshot = await docRef.get();
    final existingData = snapshot.data();
    final existingUsername = existingData?['username'];
    final username = existingUsername is String && existingUsername.trim().isNotEmpty
        ? existingUsername
        : 'User';

    await docRef.set({
      'username': username,
      'email': email,
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) {
    return userDoc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream(String uid) {
    return userTransactions(uid).orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> addTransaction({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await userTransactions(uid).add(data);
  }
}
