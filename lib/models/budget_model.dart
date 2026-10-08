import 'package:cloud_firestore/cloud_firestore.dart';

/// Monthly or category budget.
///
/// Firestore path: users/{uid}/budgets/{id}
/// A budget with category "Overall" (or "All") is the monthly total;
/// any other category value is a per-category budget for [month] ("yyyy-MM").
class BudgetModel {
  final String id;
  final String category;
  final double amount;
  final String month;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  bool get isOverall =>
      category.toLowerCase() == 'overall' || category.toLowerCase() == 'all';

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      category: map['category'] as String? ?? 'Overall',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      month: map['month'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category,
        'amount': amount,
        'month': month,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'month': month,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      BudgetModel.fromMap(
          json['id'] as String? ?? '', Map<String, dynamic>.from(json));

  BudgetModel copyWith({String? category, double? amount, String? month}) {
    return BudgetModel(
      id: id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
    );
  }
}

/// Budget progress helper (unit tested).
class BudgetProgress {
  final BudgetModel budget;
  final double spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get progress =>
      budget.amount <= 0 ? 0 : (spent / budget.amount).clamp(0.0, 1.0);

  double get remaining => budget.amount - spent;

  bool get isOver => spent > budget.amount;

  bool get isNearLimit =>
      budget.amount > 0 && spent >= budget.amount * 0.8 && spent <= budget.amount;
}
