import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/data/services/app_lock_settings.dart';
import 'package:seva_mattress/data/services/payment_methods.dart';

/// The company details printed on the invoice, the tax rates, the payment
/// methods and the security settings. They live in the Firestore document
/// settings/company, so the owner can change them without a new version of
/// the app. Anything missing falls back to [defaults].
class CompanyInfo {
  const CompanyInfo({
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.gstNumber = '',
    this.pstNumber = '',
    this.invoiceTitle = 'INVOICE',
    this.thankYou = '',
    this.terms = '',
    this.gstBp = 500,
    this.pstBp = 700,
    this.paymentMethods = PaymentMethodsConfig.all,
    this.lockMinutes = 0,
    this.requireSms = false,
  });

  final String name;
  final String address;
  final String phone;
  final String email;

  /// GST registration number and PST number. They are registered separately
  /// with the government, so each one is printed on its own line (and only
  /// when it is not empty).
  final String gstNumber;
  final String pstNumber;
  final String invoiceTitle;
  final String thankYou;

  /// Terms, return policy, warranty text at the bottom of the invoice.
  final String terms;

  /// Tax rates in basis points (500 = 5%).
  final int gstBp;
  final int pstBp;

  /// The payment methods that can be used (at least one).
  final List<String> paymentMethods;

  /// Minutes a phone can be away before Face ID is asked again (0 = always).
  final int lockMinutes;

  /// true = the SMS code is asked after the password.
  final bool requireSms;

  static const CompanyInfo defaults = CompanyInfo(
    name: 'SEVA SLEEP PRODUCTS INC.',
    email: 'ali@sevasleepproducts.com',
    thankYou: 'Thank you for your business.',
  );

  factory CompanyInfo.fromMap(Map<String, dynamic>? m) {
    // A field that exists is used as it is (it may be empty on purpose).
    String pick(String key, String fallback) {
      final v = m?[key];
      return v is String ? v.trim() : fallback;
    }

    // The name and the title are never empty.
    String pickNotEmpty(String key, String fallback) {
      final v = pick(key, fallback);
      return v.isEmpty ? fallback : v;
    }

    int pickInt(String key, int fallback) =>
        (m?[key] as num?)?.toInt() ?? fallback;

    List<String> pickMethods() {
      final v = m?['paymentMethods'];
      if (v is List) {
        final list = [
          for (final a in PaymentMethodsConfig.all)
            if (v.contains(a)) a,
        ];
        if (list.isNotEmpty) return list;
      }
      return PaymentMethodsConfig.all;
    }

    final lock = pickInt('lockMinutes', 0);

    return CompanyInfo(
      name: pickNotEmpty('name', defaults.name),
      address: pick('address', defaults.address),
      phone: pick('phone', defaults.phone),
      email: pick('email', defaults.email),
      gstNumber: pick('gstNumber', defaults.gstNumber),
      pstNumber: pick('pstNumber', defaults.pstNumber),
      invoiceTitle: pickNotEmpty('invoiceTitle', defaults.invoiceTitle),
      thankYou: pick('thankYou', defaults.thankYou),
      terms: pick('terms', defaults.terms),
      gstBp: pickInt('gstBp', defaults.gstBp),
      pstBp: pickInt('pstBp', defaults.pstBp),
      paymentMethods: pickMethods(),
      lockMinutes: AppLockSettings.options.contains(lock) ? lock : 0,
      requireSms: m?['requireSms'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'gstNumber': gstNumber,
    'pstNumber': pstNumber,
    'invoiceTitle': invoiceTitle,
    'thankYou': thankYou,
    'terms': terms,
    'gstBp': gstBp,
    'pstBp': pstBp,
    'paymentMethods': paymentMethods,
    'lockMinutes': lockMinutes,
    'requireSms': requireSms,
  };

  CompanyInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstNumber,
    String? pstNumber,
    String? invoiceTitle,
    String? thankYou,
    String? terms,
    int? gstBp,
    int? pstBp,
    List<String>? paymentMethods,
    int? lockMinutes,
    bool? requireSms,
  }) =>
      CompanyInfo(
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        gstNumber: gstNumber ?? this.gstNumber,
        pstNumber: pstNumber ?? this.pstNumber,
        invoiceTitle: invoiceTitle ?? this.invoiceTitle,
        thankYou: thankYou ?? this.thankYou,
        terms: terms ?? this.terms,
        gstBp: gstBp ?? this.gstBp,
        pstBp: pstBp ?? this.pstBp,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        lockMinutes: lockMinutes ?? this.lockMinutes,
        requireSms: requireSms ?? this.requireSms,
      );
}

/// Reads and saves the company details.
class CompanyRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('company');

  User? get _user => FirebaseAuth.instance.currentUser;

  CompanyInfo _read(Map<String, dynamic>? data) {
    final info = CompanyInfo.fromMap(data);
    // Keep the other screens (payments, app lock, sign-in) up to date.
    PaymentMethodsConfig.apply(info.paymentMethods);
    AppLockSettings.apply(info.lockMinutes, sms: info.requireSms);
    return info;
  }

  /// For the invoice, the app lock and the sign-in: if the details cannot be
  /// read (no connection, rules not published yet), the defaults are used.
  Future<CompanyInfo> load() async {
    try {
      return await loadStrict();
    } catch (_) {
      return CompanyInfo.defaults;
    }
  }

  /// For the edit sheets: a read error is thrown, so the defaults are never
  /// saved over real data by mistake.
  Future<CompanyInfo> loadStrict() async {
    final snap = await _doc.get();
    return _read(snap.data());
  }

  /// Live details.
  Stream<CompanyInfo> watch() => _doc.snapshots().map((s) => _read(s.data()));

  /// Saves the details. Changed fields are written to the audit log.
  Future<void> save(CompanyInfo info) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_doc);
      final oldMap = CompanyInfo.fromMap(snap.data()).toMap();
      final newMap = info.toMap();

      final changes = <String, dynamic>{};
      newMap.forEach((key, value) {
        // Compared as text, so two equal lists count as the same.
        if ('${oldMap[key]}' != '$value') {
          changes[key] = {'from': oldMap[key], 'to': value};
        }
      });
      if (changes.isEmpty) return;

      tx.set(_doc, newMap);
      tx.set(_db.collection('audit_log').doc(), {
        'type': 'settings_updated',
        'details': changes,
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }
}