import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'local_prefs.dart';

// ---------------------------------------------------------------------------
// Transaction repository abstraction: Firestore when configured,
// local persistence (SharedPreferences JSON) otherwise.
// ---------------------------------------------------------------------------

abstract class TransactionRepository {
  Stream<List<TransactionModel>> watch(String uid);
  Future<void> add(String uid, TransactionModel tx);
  Future<void> update(String uid, TransactionModel tx);
  Future<void> remove(String uid, String id);
  Future<void> clearAll(String uid);
}

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore db;
  FirestoreTransactionRepository(this.db);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection('users').doc(uid).collection('transactions');

  @override
  Stream<List<TransactionModel>> watch(String uid) {
    return _col(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => TransactionModel.fromMap(d.id, d.data()))
            .toList());
  }

  @override
  Future<void> add(String uid, TransactionModel tx) =>
      _col(uid).add(tx.toFirestore());

  @override
  Future<void> update(String uid, TransactionModel tx) =>
      _col(uid).doc(tx.id).update(tx.toFirestore());

  @override
  Future<void> remove(String uid, String id) => _col(uid).doc(id).delete();

  @override
  Future<void> clearAll(String uid) async {
    final snap = await _col(uid).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}

class LocalTransactionRepository implements TransactionRepository {
  final LocalPrefs prefs;
  final _ctrl = <String, StreamController<List<TransactionModel>>>{};

  LocalTransactionRepository(this.prefs);

  String _key(String uid) => '${AppConstants.keyLocalTxPrefix}$uid';

  List<TransactionModel> _read(String uid) {
    final raw = prefs.readString(_key(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => TransactionModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String uid, List<TransactionModel> items) async {
    await prefs.writeString(
        _key(uid), jsonEncode(items.map((e) => e.toJson()).toList()));
    _ctrl[uid]?.add(items);
  }

  @override
  Stream<List<TransactionModel>> watch(String uid) {
    _ctrl[uid] ??= StreamController<List<TransactionModel>>.broadcast();
    // Emit current snapshot asynchronously for new listeners.
    Future.microtask(() => _ctrl[uid]?.add(_read(uid)));
    return _ctrl[uid]!.stream;
  }

  @override
  Future<void> add(String uid, TransactionModel tx) async {
    final items = _read(uid);
    final id = tx.id.isEmpty ? const Uuid().v4() : tx.id;
    items.insert(0, tx.copyWith(id: id));
    items.sort((a, b) => b.date.compareTo(a.date));
    await _write(uid, items);
  }

  @override
  Future<void> update(String uid, TransactionModel tx) async {
    final items = _read(uid);
    final i = items.indexWhere((e) => e.id == tx.id);
    if (i == -1) return;
    items[i] = tx;
    items.sort((a, b) => b.date.compareTo(a.date));
    await _write(uid, items);
  }

  @override
  Future<void> remove(String uid, String id) async {
    final items = _read(uid)..removeWhere((e) => e.id == id);
    await _write(uid, items);
  }

  @override
  Future<void> clearAll(String uid) => _write(uid, []);
}

// ---------------------------------------------------------------------------
// Budget repository.
// ---------------------------------------------------------------------------

abstract class BudgetRepository {
  Stream<List<BudgetModel>> watch(String uid);
  Future<void> upsert(String uid, BudgetModel budget);
  Future<void> remove(String uid, String id);
  Future<void> clearAll(String uid);
}

class FirestoreBudgetRepository implements BudgetRepository {
  final FirebaseFirestore db;
  FirestoreBudgetRepository(this.db);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      db.collection('users').doc(uid).collection('budgets');

  @override
  Stream<List<BudgetModel>> watch(String uid) => _col(uid)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => BudgetModel.fromMap(d.id, d.data())).toList());

  @override
  Future<void> upsert(String uid, BudgetModel b) {
    if (b.id.isEmpty) return _col(uid).add(b.toFirestore()).then((_) {});
    return _col(uid).doc(b.id).set(b.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> remove(String uid, String id) => _col(uid).doc(id).delete();

  @override
  Future<void> clearAll(String uid) async {
    final snap = await _col(uid).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}

class LocalBudgetRepository implements BudgetRepository {
  final LocalPrefs prefs;
  final _ctrl = <String, StreamController<List<BudgetModel>>>{};

  LocalBudgetRepository(this.prefs);

  String _key(String uid) => '${AppConstants.keyLocalBudgetPrefix}$uid';

  List<BudgetModel> _read(String uid) {
    final raw = prefs.readString(_key(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) =>
              BudgetModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String uid, List<BudgetModel> items) async {
    await prefs.writeString(
        _key(uid), jsonEncode(items.map((e) => e.toJson()).toList()));
    _ctrl[uid]?.add(items);
  }

  @override
  Stream<List<BudgetModel>> watch(String uid) {
    _ctrl[uid] ??= StreamController<List<BudgetModel>>.broadcast();
    Future.microtask(() => _ctrl[uid]?.add(_read(uid)));
    return _ctrl[uid]!.stream;
  }

  @override
  Future<void> upsert(String uid, BudgetModel b) async {
    final items = _read(uid);
    if (b.id.isEmpty) {
      items.add(BudgetModel(
          id: const Uuid().v4(),
          category: b.category,
          amount: b.amount,
          month: b.month));
    } else {
      final i = items.indexWhere((e) => e.id == b.id);
      if (i == -1) {
        items.add(b);
      } else {
        items[i] = b;
      }
    }
    await _write(uid, items);
  }

  @override
  Future<void> remove(String uid, String id) async {
    final items = _read(uid)..removeWhere((e) => e.id == id);
    await _write(uid, items);
  }

  @override
  Future<void> clearAll(String uid) => _write(uid, []);
}
