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

  Future<void> applyDueMonthlyCredits({
    required String uid,
    DateTime? now,
  }) async {
    final userRef = userDoc(uid);
    final txCollection = userTransactions(uid);
    final current = now ?? DateTime.now();

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data() ?? <String, dynamic>{};

      final monthlyEarnings = _asPositiveNum(
        userData['monthly_earnings'] ?? userData['monthly earnings'],
      );
      final creditDay = _asCreditDay(
        userData['credit_day'] ?? userData['credit date'],
      );

      if (monthlyEarnings == null || monthlyEarnings <= 0 || creditDay == null) {
        return;
      }

      final currentMonthStart = DateTime(current.year, current.month, 1);
      final currentScheduledDate = _scheduledDateForMonth(
        year: current.year,
        month: current.month,
        creditDay: creditDay,
      );

      final endMonth = !current.isBefore(currentScheduledDate)
          ? currentMonthStart
          : _addMonths(currentMonthStart, -1);

      DateTime? startMonth;
      final lastYm = (userData['last_salary_credit_ym'] as String?)?.trim();
      if (lastYm != null && lastYm.isNotEmpty) {
        final parsedLastMonth = _parseYearMonth(lastYm);
        if (parsedLastMonth != null) {
          startMonth = _addMonths(parsedLastMonth, 1);
        }
      }

      if (startMonth == null) {
        startMonth = currentMonthStart;
      }

      if (_compareYearMonth(startMonth, endMonth) > 0) {
        transaction.set(userRef, {
          'monthly_earnings': monthlyEarnings,
          'credit_day': creditDay,
        }, SetOptions(merge: true));
        return;
      }

      DateTime cursor = startMonth;
      DateTime lastCreditedMonth = startMonth;
      while (_compareYearMonth(cursor, endMonth) <= 0) {
        final scheduledDate = _scheduledDateForMonth(
          year: cursor.year,
          month: cursor.month,
          creditDay: creditDay,
        );
        final ym = _yearMonth(cursor);
        final docId = 'salary_${cursor.year}_${cursor.month.toString().padLeft(2, '0')}';
        final txRef = txCollection.doc(docId);

        transaction.set(txRef, {
          'title': 'Monthly Salary Credit',
          'amount': monthlyEarnings,
          'category': 'Income',
          'note': 'Auto salary credit',
          'timestamp': scheduledDate,
          'status': 'Normal',
          'color': 'green',
          'source': 'auto_salary',
          'credit_ym': ym,
        }, SetOptions(merge: true));

        lastCreditedMonth = cursor;
        cursor = _addMonths(cursor, 1);
      }

      transaction.set(userRef, {
        'monthly_earnings': monthlyEarnings,
        'credit_day': creditDay,
        'last_salary_credit_ym': _yearMonth(lastCreditedMonth),
      }, SetOptions(merge: true));
    });
  }

  String _yearMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  DateTime _scheduledDateForMonth({
    required int year,
    required int month,
    required int creditDay,
  }) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = creditDay.clamp(1, lastDayOfMonth);
    return DateTime(year, month, day);
  }

  num? _asPositiveNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  int? _asCreditDay(dynamic value) {
    final parsed = value is int
        ? value
        : value is String
            ? int.tryParse(value.trim())
            : null;
    if (parsed == null || parsed < 1 || parsed > 31) return null;
    return parsed;
  }

  DateTime? _parseYearMonth(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;

    return DateTime(year, month, 1);
  }

  DateTime _addMonths(DateTime monthDate, int count) {
    return DateTime(monthDate.year, monthDate.month + count, 1);
  }

  int _compareYearMonth(DateTime a, DateTime b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    return a.month.compareTo(b.month);
  }
}
