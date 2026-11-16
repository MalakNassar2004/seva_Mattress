import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/inventory/inventory_models.dart';

/// Where the units are. The order matches the Adjust Stock sheet.
enum StockLocation { warehouse, showroom, damaged }

String _fieldOf(StockLocation l) {
  switch (l) {
    case StockLocation.warehouse:
      return 'units';
    case StockLocation.showroom:
      return 'showroomUnits';
    case StockLocation.damaged:
      return 'damagedUnits';
  }
}

String _nameOf(StockLocation l) {
  switch (l) {
    case StockLocation.warehouse:
      return 'warehouse';
    case StockLocation.showroom:
      return 'showroom';
    case StockLocation.damaged:
      return 'damaged';
  }
}

String _labelOf(StockLocation l) {
  switch (l) {
    case StockLocation.warehouse:
      return 'the warehouse';
    case StockLocation.showroom:
      return 'the showroom';
    case StockLocation.damaged:
      return 'the damaged stock';
  }
}

/// Stock changes. The quantities live on the product document:
/// `units` (warehouse), `showroomUnits` and `damagedUnits`.
/// Every change is written to the audit log in the same transaction.
class StockRepository {
  static const int maxUnits = 100000;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  /// OWNER ONLY. Live map: product id -> cost price.
  Stream<Map<String, double>> watchCosts() {
    return _db.collection('product_costs').snapshots().map(
          (snap) => {
        for (final d in snap.docs)
          if (d.data()['costPrice'] is num)
            d.id: (d.data()['costPrice'] as num).toDouble(),
      },
    );
  }

  /// OWNER ONLY (only the owner can read the audit log).
  /// The latest stock movements, newest first.
  Stream<List<StockMovement>> watchMovements({int limit = 100}) {
    return _db
        .collection('audit_log')
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = <StockMovement>[];

      for (final d in snap.docs) {
        final m = d.data();
        final type = m['type'] as String?;
        final raw = m['details'];
        final details = raw is Map ? raw : const <String, dynamic>{};
        final at = (m['at'] as Timestamp?)?.toDate() ?? DateTime.now();
        final name = (m['productName'] as String?) ?? '';
        final actor = (m['actorEmail'] as String?) ?? '';
        final sku = (details['sku'] as String?) ?? '';

        if (type == 'stock_adjusted') {
          final reason = (details['reason'] as String?) ?? '';
          final note = (details['note'] as String?) ?? '';
          list.add(StockMovement(
            id: d.id,
            at: at,
            productName: name,
            sku: sku,
            location: (details['location'] as String?) ?? 'warehouse',
            from: (details['from'] as num?)?.toInt() ?? 0,
            to: (details['to'] as num?)?.toInt() ?? 0,
            reason: reason,
            note: note,
            actor: actor,
          ));
          // Units removed as "Damaged goods" are added to the damaged stock.
          final damaged = details['damaged'];
          if (damaged is Map) {
            list.add(StockMovement(
              id: '${d.id}-damaged',
              at: at,
              productName: name,
              sku: sku,
              location: 'damaged',
              from: (damaged['from'] as num?)?.toInt() ?? 0,
              to: (damaged['to'] as num?)?.toInt() ?? 0,
              reason: reason,
              note: note,
              actor: actor,
            ));
          }
        } else if (type == 'product_updated') {
          final units = details['units'];
          if (units is Map) {
            list.add(StockMovement(
              id: d.id,
              at: at,
              productName: name,
              sku: sku,
              location: 'warehouse',
              from: (units['from'] as num?)?.toInt() ?? 0,
              to: (units['to'] as num?)?.toInt() ?? 0,
              reason: 'Edited in the product form',
              actor: actor,
            ));
          }
        } else if (type == 'product_created') {
          final units = (details['units'] as num?)?.toInt() ?? 0;
          if (units > 0) {
            list.add(StockMovement(
              id: d.id,
              at: at,
              productName: name,
              sku: sku,
              location: 'warehouse',
              from: 0,
              to: units,
              reason: 'Product created',
              actor: actor,
            ));
          }
        }
      }
      return list;
    });
  }

  /// Adds [delta] units (negative removes) at [location].
  ///
  /// It applies the DIFFERENCE on the server value, so two people changing
  /// the same product at the same time never overwrite each other.
  /// With [moveToDamaged] the removed units are added to the damaged stock.
  Future<void> adjust({
    required String productId,
    required StockLocation location,
    required int delta,
    required String reason,
    required String note,
    bool moveToDamaged = false,
  }) async {
    if (delta == 0) throw StateError('There is nothing to change.');
    final ref = _db.collection('products').doc(productId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final p = snap.data();
      if (!snap.exists || p == null || p['deleted'] == true) {
        throw StateError('This product no longer exists.');
      }

      int read(String field) => (p[field] as num?)?.toInt() ?? 0;

      final field = _fieldOf(location);
      final before = read(field);
      final after = before + delta;
      if (after < 0) {
        throw StateError(
          'There ${before == 1 ? 'is' : 'are'} only $before '
              'unit${before == 1 ? '' : 's'} in ${_labelOf(location)}. '
              'You cannot remove ${-delta}.',
        );
      }
      if (after > maxUnits) {
        throw StateError('The quantity is too high (max $maxUnits).');
      }

      final updates = <String, dynamic>{field: after};
      final details = <String, dynamic>{
        'sku': p['sku'],
        'location': _nameOf(location),
        'from': before,
        'to': after,
        'delta': delta,
        'reason': reason,
        if (note.isNotEmpty) 'note': note,
      };

      if (moveToDamaged && location != StockLocation.damaged && delta < 0) {
        final damagedBefore = read('damagedUnits');
        final damagedAfter = damagedBefore + (-delta);
        updates['damagedUnits'] = damagedAfter;
        details['damaged'] = {'from': damagedBefore, 'to': damagedAfter};
      }

      tx.update(ref, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      tx.set(_db.collection('audit_log').doc(), {
        'type': 'stock_adjusted',
        'productId': productId,
        'productName': p['name'],
        'details': details,
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }
}