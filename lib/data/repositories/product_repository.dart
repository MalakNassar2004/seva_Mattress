import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/products/product_item.dart';

/// Thrown when a SKU already belongs to another product.
class SkuTakenException implements Exception {
  SkuTakenException(this.sku, this.productName);

  final String sku;
  final String productName;

  @override
  String toString() => 'SKU $sku is already used by "$productName".';
}

/// All Firestore access for products. Screens never talk to Firestore directly.
///
/// The cost price lives in a separate collection (`product_costs`) that only
/// the owner can read or write.
///
/// Every SKU has its own document in `product_skus` (the document id is the
/// SKU). Creating that document in the same transaction as the product is
/// what guarantees that two products never share a SKU.
class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  CollectionReference<Map<String, dynamic>> get _costs =>
      _db.collection('product_costs');

  CollectionReference<Map<String, dynamic>> get _skus =>
      _db.collection('product_skus');

  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('audit_log');

  User? get _user => FirebaseAuth.instance.currentUser;

  /// A new product id. The form creates it ONCE, so pressing Save twice (or
  /// retrying on a bad connection) can never create two products.
  String newProductId() => _products.doc().id;

  /// Live list of products (soft-deleted ones are hidden).
  Stream<List<ProductItem>> watchProducts() {
    return _products.snapshots().map(
          (snap) => snap.docs
          .where((d) => d.data()['deleted'] != true)
          .map((d) => ProductItem.fromMap(d.id, d.data()))
          .toList(),
    );
  }

  /// OWNER ONLY. Returns null when no cost was saved for this product.
  Future<double?> loadCost(String id) async {
    final snap = await _costs.doc(id).get();
    return (snap.data()?['costPrice'] as num?)?.toDouble();
  }

  /// The product that owns this SKU, or null when the SKU is free.
  Future<ProductItem?> findBySku(String rawSku) async {
    final sku = normalizeSku(rawSku);
    if (sku.isEmpty || skuProblem(sku) != null) return null;

    final claim = await _skus.doc(sku).get();
    final productId = claim.data()?['productId'] as String?;
    if (!claim.exists || productId == null) return null;

    final snap = await _products.doc(productId).get();
    final m = snap.data();
    if (!snap.exists || m == null || m['deleted'] == true) return null;
    return ProductItem.fromMap(snap.id, m);
  }

  // ---------------- SKU helpers (used inside transactions) ----------------

  /// No 0/O/1/I: they are easy to mix up when reading a label.
  static const String _autoAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  String _randomSku() {
    final random = Random.secure();
    final code = List.generate(
      6,
          (_) => _autoAlphabet[random.nextInt(_autoAlphabet.length)],
    ).join();
    return 'SEV-$code';
  }

  /// An automatic SKU that nobody uses yet.
  Future<String> _pickFreeSku(Transaction tx) async {
    for (var i = 0; i < 6; i++) {
      final sku = _randomSku();
      final claim = await tx.get(_skus.doc(sku));
      if (!claim.exists) return sku;
    }
    throw StateError('Could not generate a free SKU. Please try again.');
  }

  /// Builds the error that tells who already uses the SKU.
  Future<SkuTakenException> _takenBy(
      Transaction tx,
      String sku,
      Map<String, dynamic>? claim,
      ) async {
    final otherId = claim?['productId'] as String?;
    var name = '';
    if (otherId != null) {
      final other = await tx.get(_products.doc(otherId));
      name = (other.data()?['name'] as String?) ?? '';
    }
    return SkuTakenException(sku, name.isEmpty ? 'another product' : name);
  }

  Map<String, dynamic> _claim(String sku, String productId) => {
    'sku': sku,
    'productId': productId,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': _user?.uid,
  };

  // ---------------- Create / update / delete ----------------

  /// Creates a product with id [id] and returns the SKU that was saved
  /// (the one typed, or an automatic one when it was left empty).
  ///
  /// [data] must NOT contain the cost price. Pass it in [costPrice] and set
  /// [canEditCost] only for the owner.
  Future<String> create(
      String id,
      Map<String, dynamic> data, {
        double? costPrice,
        required bool canEditCost,
      }) async {
    final ref = _products.doc(id);
    final costRef = _costs.doc(id);
    final saveCost = canEditCost && costPrice != null;
    var savedSku = '';

    await _db.runTransaction((tx) async {
      // All reads first.
      final existing = await tx.get(ref);
      if (existing.exists) {
        // A retry of a save that already went through (slow connection).
        savedSku = (existing.data()?['sku'] as String?) ?? '';
        return;
      }

      var sku = normalizeSku((data['sku'] as String?) ?? '');
      final problem = skuProblem(sku);
      if (problem != null) throw StateError(problem);

      if (sku.isEmpty) {
        sku = await _pickFreeSku(tx);
      } else {
        final claim = await tx.get(_skus.doc(sku));
        if (claim.exists) throw await _takenBy(tx, sku, claim.data());
      }

      // Then the writes.
      tx.set(ref, {
        ...data,
        'sku': sku,
        'photoUrls': <String>[],
        'reorderPo': null,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _user?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      tx.set(_skus.doc(sku), _claim(sku, id));

      if (saveCost) {
        tx.set(costRef, {
          'costPrice': costPrice,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _user?.uid,
        });
      }

      tx.set(
        _audit.doc(),
        _auditEntry(
          type: 'product_created',
          productId: id,
          productName: data['name'] as String,
          details: {
            'sku': sku,
            'units': data['units'],
            'retailPrice': data['retailPrice'],
            if (saveCost) 'costPrice': costPrice,
          },
        ),
      );

      savedSku = sku;
    });

    return savedSku;
  }

  /// Updates a product and returns the SKU that was saved. Stock, price,
  /// cost, SKU and visibility changes are written to the audit log with
  /// their old and new values (read inside a transaction so the "old"
  /// value is the real one on the server).
  ///
  /// A null [costPrice] means "leave the saved cost as it is".
  Future<String> update(
      String id,
      Map<String, dynamic> data, {
        double? costPrice,
        required bool canEditCost,
      }) async {
    final ref = _products.doc(id);
    final costRef = _costs.doc(id);
    var savedSku = '';

    await _db.runTransaction((tx) async {
      // All reads first.
      final snap = await tx.get(ref);
      final old = snap.data();
      if (!snap.exists || old == null || old['deleted'] == true) {
        throw StateError('This product no longer exists.');
      }

      double? oldCost;
      if (canEditCost) {
        final costSnap = await tx.get(costRef);
        oldCost = (costSnap.data()?['costPrice'] as num?)?.toDouble();
      }

      // A saved SKU that cannot be a document id (old test data) is ignored.
      final oldRaw = normalizeSku((old['sku'] as String?) ?? '');
      final oldSku = skuProblem(oldRaw) == null ? oldRaw : '';

      var newSku = normalizeSku((data['sku'] as String?) ?? '');
      final problem = skuProblem(newSku);
      if (problem != null) throw StateError(problem);
      if (newSku.isEmpty) {
        // Keep the saved SKU. A product that has none gets an automatic one.
        newSku = oldSku.isNotEmpty ? oldSku : await _pickFreeSku(tx);
      }

      final keyChanged = newSku != oldSku;
      final newClaimRef = _skus.doc(newSku);
      final newClaim = await tx.get(newClaimRef);
      if (newClaim.exists && newClaim.data()?['productId'] != id) {
        throw await _takenBy(tx, newSku, newClaim.data());
      }

      DocumentSnapshot<Map<String, dynamic>>? oldClaim;
      if (keyChanged && oldSku.isNotEmpty) {
        oldClaim = await tx.get(_skus.doc(oldSku));
      }

      // What changed (for the audit log).
      final changes = <String, dynamic>{};
      if (old['units'] != data['units']) {
        changes['units'] = {'from': old['units'], 'to': data['units']};
      }
      final oldPrice = (old['retailPrice'] as num?)?.toDouble();
      final newPrice = (data['retailPrice'] as num?)?.toDouble();
      if (oldPrice != newPrice) {
        changes['retailPrice'] = {'from': oldPrice, 'to': newPrice};
      }
      final costChanged =
          canEditCost && costPrice != null && oldCost != costPrice;
      if (costChanged) {
        changes['costPrice'] = {'from': oldCost, 'to': costPrice};
      }
      if (keyChanged) {
        changes['sku'] = {'from': oldSku, 'to': newSku};
      }
      if ((old['isActive'] != false) != (data['isActive'] != false)) {
        changes['isActive'] = {
          'from': old['isActive'] != false,
          'to': data['isActive'] != false,
        };
      }

      // Then the writes.
      tx.update(ref, {
        ...data,
        'sku': newSku,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      // A new SKU, or a product saved before SKUs were reserved.
      if (!newClaim.exists) {
        tx.set(newClaimRef, _claim(newSku, id));
      }
      // The old SKU becomes free for other products.
      if (oldClaim != null &&
          oldClaim.exists &&
          oldClaim.data()?['productId'] == id) {
        tx.delete(oldClaim.reference);
      }

      if (costChanged) {
        tx.set(
          costRef,
          {
            'costPrice': costPrice,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': _user?.uid,
          },
          SetOptions(merge: true),
        );
      }

      if (changes.isNotEmpty) {
        tx.set(
          _audit.doc(),
          _auditEntry(
            type: 'product_updated',
            productId: id,
            productName: data['name'] as String,
            details: changes,
          ),
        );
      }

      savedSku = newSku;
    });

    return savedSku;
  }

  /// Soft delete: the product disappears from the app but its data stays,
  /// so past sales keep working. Its SKU becomes free again.
  Future<void> softDelete(ProductItem p) async {
    final ref = _products.doc(p.id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists || snap.data()?['deleted'] == true) return;

      final raw = normalizeSku(p.sku);
      DocumentSnapshot<Map<String, dynamic>>? claim;
      if (raw.isNotEmpty && skuProblem(raw) == null) {
        claim = await tx.get(_skus.doc(raw));
      }

      tx.update(ref, {
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _user?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      if (claim != null &&
          claim.exists &&
          claim.data()?['productId'] == p.id) {
        tx.delete(claim.reference);
      }

      tx.set(
        _audit.doc(),
        _auditEntry(
          type: 'product_deleted',
          productId: p.id,
          productName: p.name,
          details: {'units': p.units, 'sku': p.sku},
        ),
      );
    });
  }

  Map<String, dynamic> _auditEntry({
    required String type,
    required String productId,
    required String productName,
    required Map<String, dynamic> details,
  }) {
    return {
      'type': type,
      'productId': productId,
      'productName': productName,
      'details': details,
      'actorUid': _user?.uid,
      'actorEmail': _user?.email,
      'at': FieldValue.serverTimestamp(),
    };
  }
}

/// Turns an error into a short message that is safe to show to the user.
String describeError(Object e) {
  if (e is SkuTakenException) {
    return 'This SKU is already used by "${e.productName}".';
  }
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'aborted':
      case 'failed-precondition':
        return 'No connection. Please try again.';
    }
  }
  if (e is StateError) return e.message;
  return 'Something went wrong. Please try again.';
}