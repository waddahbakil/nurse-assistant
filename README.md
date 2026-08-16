# مساعد الممرض - Nurse Assistant

تطبيق Flutter للممرضين فقط مع:
- نظام اشتراكات (24 ساعة تجريبية، شهري، نصف سنوي، سنوي)
- مؤقت المحاليل الوريدية مع إشعارات
- فحص تداخل الأدوية IV Checker باستخدام RxNav API (أونلاين)
- طباعة PDF ومشاركة عبر واتساب

## 🔥 خطوات إعداد Firebase

### 1. إنشاء مشروع Firebase
1. اذهب إلى https://console.firebase.google.com
2. أنشئ مشروع جديد: nurse-assistant
3. فعل Authentication > Email/Password

### 2. إعداد Firestore
أنشئ collection باسم `nurses` بالحقول:
```
nurses/{uid}:
  email: string
  name: string
  role: "nurse"
  licenseNumber: string
  subscriptionPlan: "trial24h" | "month" | "halfYear" | "year"
  subscriptionExpiry: timestamp
  isActive: boolean
  activatedAt: timestamp
```

Rules:
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /nurses/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /infusions/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. ربط Flutter بـ Firebase
```bash
# تثبيت Firebase CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# تسجيل الدخول
firebase login

# تهيئة
flutterfire configure --project=nurse-assistant
```

سيُنشئ ملف `lib/firebase_options.dart`

### 4. تشغيل
```bash
flutter pub get
flutter run
```

### 5. الإشعارات (Android)
في `android/app/src/main/AndroidManifest.xml` أضف:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### 6. اختبار الاشتراكات
- `calcExpiry()` في `auth_service.dart` تحسب تاريخ الانتهاء تلقائياً
- التجربة 24 ساعة = 0 ريال
- استخدم `activateSubscription(uid, plan)` بعد الدفع

## 📦 البناء للإنتاج
```bash
flutter build apk --release
flutter build ios --release
```
