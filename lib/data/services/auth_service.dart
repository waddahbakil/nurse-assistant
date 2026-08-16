import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SubscriptionPlan { trial24h, month, halfYear, year }

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // حساب تاريخ الانتهاء حسب الخطة - calcExpiry
  DateTime calcExpiry(SubscriptionPlan plan, {DateTime? from}) {
    final base = from ?? DateTime.now();
    switch (plan) {
      case SubscriptionPlan.trial24h:
        return base.add(const Duration(hours: 24));
      case SubscriptionPlan.month:
        return DateTime(base.year, base.month + 1, base.day, base.hour, base.minute);
      case SubscriptionPlan.halfYear:
        return DateTime(base.year, base.month + 6, base.day, base.hour, base.minute);
      case SubscriptionPlan.year:
        return DateTime(base.year + 1, base.month, base.day, base.hour, base.minute);
    }
  }

  Duration getPlanDuration(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial24h: return const Duration(hours: 24);
      case SubscriptionPlan.month: return const Duration(days: 30);
      case SubscriptionPlan.halfYear: return const Duration(days: 182);
      case SubscriptionPlan.year: return const Duration(days: 365);
    }
  }

  String getPlanNameAr(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial24h: return 'تجربة 24 ساعة';
      case SubscriptionPlan.month: return 'شهري';
      case SubscriptionPlan.halfYear: return 'نصف سنوي - خصم 15%';
      case SubscriptionPlan.year: return 'سنوي - خصم 30%';
    }
  }

  double getPlanPrice(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial24h: return 0.0;
      case SubscriptionPlan.month: return 29.99;
      case SubscriptionPlan.halfYear: return 149.99;
      case SubscriptionPlan.year: return 249.99;
    }
  }

  Future<UserCredential> signInNurse(String email, String password) async {
    // تحقق أن المستخدم ممرض فقط
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _firestore.collection('nurses').doc(cred.user!.uid).get();
    
    if (!doc.exists || doc.data()?['role'] != 'nurse') {
      await _auth.signOut();
      throw Exception('هذا التطبيق للممرضين المعتمدين فقط');
    }
    
    // تحقق من الاشتراك
    final expiry = (doc.data()?['subscriptionExpiry'] as Timestamp?)?.toDate();
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      throw Exception('انتهى اشتراكك، يرجى التجديد');
    }
    
    return cred;
  }

  Future<void> activateSubscription(String uid, SubscriptionPlan plan) async {
    final expiry = calcExpiry(plan);
    await _firestore.collection('nurses').doc(uid).update({
      'subscriptionPlan': plan.name,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'isActive': true,
      'activatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> isSubscriptionValid(String uid) {
    return _firestore.collection('nurses').doc(uid).snapshots().map((doc) {
      final expiry = (doc.data()?['subscriptionExpiry'] as Timestamp?)?.toDate();
      if (expiry == null) return false;
      return expiry.isAfter(DateTime.now());
    });
  }
}

