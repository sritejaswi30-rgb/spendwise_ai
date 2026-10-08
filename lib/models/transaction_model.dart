import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction type: income or expense.
enum TransactionType { income, expense }

/// A single income/expense record.
///
/// Firestore path: users/{uid}/transactions/{id}
class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
    this.paymentMethod = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isExpense => type == TransactionType.expense;

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    final typeStr = (map['type'] as String? ?? 'expense').toLowerCase();
    return TransactionModel(
      id: id,
      type: typeStr == 'income' ? TransactionType.income : TransactionType.expense,
      amount: (map['amount'] as num? ?? 0).toDouble(),
      category: map['category'] as String? ?? 'Other',
      date: parseDate(map['date']),
      note: map['note'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromMap(json['id'] as String? ?? '', json);

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'note': note,
        'paymentMethod': paymentMethod,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'paymentMethod': paymentMethod,
      };

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? paymentMethod,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Aggregation helpers (covered by unit tests).
class TransactionStats {
  final List<TransactionModel> transactions;

  const TransactionStats(this.transactions);

  List<TransactionModel> inMonth(String monthKey) {
    return transactions.where((t) {
      final k =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      return k == monthKey;
    }).toList();
  }

  double totalIncome([List<TransactionModel>? list]) {
    final src = list ?? transactions;
    return src
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double totalExpense([List<TransactionModel>? list]) {
    final src = list ?? transactions;
    return src
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
  }

  /// Category -> total expense, sorted descending.
  Map<String, double> expenseByCategory([List<TransactionModel>? list]) {
    final src = (list ?? transactions)
        .where((t) => t.type == TransactionType.expense);
    final map = <String, double>{};
    for (final t in src) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }
}
