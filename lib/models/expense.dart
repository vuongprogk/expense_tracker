import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

enum Category {
  food,
  travel,
  leisure,
  work,
}

const categoryIcons = {
  Category.travel: Icons.flight_takeoff,
  Category.food: Icons.lunch_dining,
  Category.leisure: Icons.movie,
  Category.work: Icons.work
};

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  }) : id = uuid.v4();

  Expense.fromDb({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
  String get formattedDate {
    return formatter.format(date);
  }

  Map<String, Object?> toMap() {
    return {
      "id": id,
      "title": title,
      "amount": amount,
      "date": formatter.format(date),
      "category": category.index
    };
  }
}

class ExpenseBucket {
  final Category category;
  final List<Expense> expenses;

  ExpenseBucket({required this.category, required this.expenses});
  ExpenseBucket.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((element) => element.category == category)
            .toList();
  double get totalExpenses {
    double sum = 0;
    for (Expense item in expenses) {
      sum += item.amount;
    }
    return sum;
  }
}
