# AthleteHub App

تطبيق AthleteHub هو منصة مراسلة متكاملة ومتقدمة مبنية باستخدام إطار عمل Flutter. يقدم التطبيق تجربة دردشة فورية تشمل المحادثات الفردية والجماعية مع دعم كامل للفعاليات ومشاركة الملفات بأنواعها المختلفة.

## الميزات (Features)
- محادثات فردية وجماعية (Private & Group Chat).
- إدارة الفعاليات داخل الدردشة (Events inside chat - RSVP).
- مشاركة الملفات (صورة، صوت، موقع جغرافي، وجهة اتصال) (File sharing: image, audio, location, contact).
- حالة الرسائل (مرسلة، تم التسليم، مقروءة) (Message status: sent, delivered, seen).
- عداد الرسائل غير المقروءة (Unread messages count).
- التصفح المقسم للرسائل (Pagination).
- تحديثات فورية للبيانات (Real-time updates) باستخدام WebSockets عبر (Laravel Reverb).

## لقطات الشاشة (Screenshots)
(سيتم إضافة الصور لاحقاً)

## التقنيات المستخدمة (Tech Stack)
- **Flutter**: لبناء واجهة المستخدم (UI).
- **Provider**: لإدارة الحالة (State Management).
- **Dio**: لمعالجة طلبات الـ API والتواصل مع الخادم.

## هيكلة المشروع (Clean Architecture)
يعتمد هذا المشروع على معمارية Clean Architecture لضمان كود نظيف وقابل للتوسع والصيانة:
- **Presentation Layer**: يحتوي على الـ UI (Screens & Widgets) والـ Providers لإدارة الحالة المرئية.
- **Domain Layer**: يحتوي على الـ Models والكيانات (Entities) الأساسية.
- **Data Layer**: يحتوي على المستودعات (Repositories) وخدمات الاتصال بالشبكة (Network Services/API) للتعامل مع البيانات.

## كيفية التشغيل (How to Run)
لتشغيل التطبيق على بيئتك المحلية، اتبع الخطوات التالية:

1. جلب الحزم المعتمدة:
```bash
flutter pub get
```

2. تشغيل التطبيق:
```bash
flutter run
```

## إعدادات الـ API (API Configuration)
تم تكوين الاتصال بالخادم باستخدام `Dio`. يجب التأكد من صحة الرابط الأساسي للـ API (Base URL) وإعدادات المصادقة باستخدام الـ Token.
- يتم إرسال `Bearer Token` في الترويسة (Headers) مع كل طلب آمن.
- تأكد من تحديث الـ Base URL في إعدادات التطبيق ليتطابق مع خادم Laravel المحلي لديك. مثال:
  `http://127.0.0.1:8000/api/v1`

> **ملاحظة حول الاتصال بالخادم:** للحصول على تجربة متكاملة للتحديثات الفورية (Real-time)، يجب التأكد من تشغيل خادم Laravel Backend وكذلك إعداد WebSockets (Laravel Reverb) بشكل صحيح على نفس الشبكة.

---

## المطور (Developer)
Developer: Aisha Yahya
