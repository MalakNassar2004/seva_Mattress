import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/products/product_item.dart';

/// All Firestore access for products. Screens never talk to Firestore directly.
///
/// The cost price lives in a separate collection (`product_costs`) that only
/// the owner can read or write.
class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  CollectionReference<Map<String, dynamic>> get _costs =>
      _db.collection('product_costs');

  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('audit_log');

  User? get _user => FirebaseAuth.instance.currentUser;

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

  /// [data] must NOT contain the cost price. Pass it in [costPrice] and set
  /// [canEditCost] only for the owner.
  Future<void> create(
      Map<String, dynamic> data, {
        double? costPrice,
        required bool canEditCost,
      }) async {
    final ref = _products.doc();
    final batch = _db.batch();
    final saveCost = canEditCost && costPrice != null;

    batch.set(ref, {
      ...data,
      'photoUrls': <String>[],
      'reorderPo': null,
      'deleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _user?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _user?.uid,
    });

    if (saveCost) {
      batch.set(_costs.doc(ref.id), {
        'costPrice': costPrice,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });
    }

    batch.set(
      _audit.doc(),
      _auditEntry(
        type: 'product_created',
        productId: ref.id,
        productName: data['name'] as String,
        details: {
          'units': data['units'],
          if (saveCost) 'costPrice': costPrice,
        },
      ),
    );

    await batch.commit();
  }

  /// Updates a product. Stock and cost changes are written to the audit log
  /// with their old and new values (read inside a transaction so the "old"
  /// value is the real one on the server).
  ///
  /// A null [costPrice] means "leave the saved cost as it is".
  Future<void> update(
      String id,
      Map<String, dynamic> data, {
        double? costPrice,
        required bool canEditCost,
      }) async {
    final ref = _products.doc(id);
    final costRef = _costs.doc(id);

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

      final changes = <String, dynamic>{};
      if (old['units'] != data['units']) {
        changes['units'] = {'from': old['units'], 'to': data['units']};
      }
      final costChanged =
          canEditCost && costPrice != null && oldCost != costPrice;
      if (costChanged) {
        changes['costPrice'] = {'from': oldCost, 'to': costPrice};
      }

      // Then the writes.
      tx.update(ref, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

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
    });
  }

  /// Soft delete: the product disappears from the app but its data stays,
  /// so past sales keep working.
  Future<void> softDelete(ProductItem p) async {
    final ref = _products.doc(p.id);
    final batch = _db.batch();

    batch.update(ref, {
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': _user?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _user?.uid,
    });

    batch.set(
      _audit.doc(),
      _auditEntry(
        type: 'product_deleted',
        productId: p.id,
        productName: p.name,
        details: {'units': p.units},
      ),
    );

    await batch.commit();
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
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'unavailable':
        return 'No connection. Please try again.';
    }
  }
  if (e is StateError) return e.message;
  return 'Something went wrong. Please try again.';
}