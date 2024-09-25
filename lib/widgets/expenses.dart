import 'package:expenses/models/expense.dart';
import 'package:expenses/widgets/chart/chart.dart';
import 'package:expenses/widgets/expenses_list/expenses_list.dart';
import 'package:expenses/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqlite_api.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key, required this.database});
  final Future<Database> database;

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  List<Expense> _registerExpenses = [];
  Future<List<Expense>> getAllExpenses() async {
    // Get a reference to the database.
    final db = await widget.database;

    // Query the table for all the dogs.
    final List<Map<String, Object?>> expensesMaps = await db.query('expenses');

    return [
      for (final {
            'id': id as String,
            'title': title as String,
            'amount': amount as double,
            'date': date as String,
            'category': category as int,
          } in expensesMaps)
        Expense.fromDb(
            id: id,
            title: title,
            amount: amount,
            date: DateFormat.yMd().parse(date),
            category: Category.values[category])
    ];
  }

  @override
  void initState() {
    super.initState();
    getAllExpenses().then((value) {
      setState(() {
        _registerExpenses = value;
      });
    });
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(
        onAddExpense: _addExpense,
      ),
    );
  }

  Future<void> _addExpense(Expense expense) async {
    final db = await widget.database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    setState(() {
      _registerExpenses.add(expense);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _removeExpense(Expense expense) async {
    final index = _registerExpenses.indexOf(expense);
    final db = await widget.database;
    await db.delete(
      'expenses',
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [expense.id],
    );
    setState(() {
      _registerExpenses.remove(expense);
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: const Duration(seconds: 10),
          content: const Text("Expense deleted"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () async {
              setState(() {
                _registerExpenses.insert(index, expense);
              });
              await db.insert(
                'expenses',
                expense.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            },
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text("No expense found. Start adding some!"),
    );
    if (_registerExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _registerExpenses,
        onRemoveExpense: _removeExpense,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseOverlay,
          )
        ],
      ),
      body: Column(
        children: [
          Chart(expenses: _registerExpenses),
          Expanded(
            child: mainContent,
          ),
        ],
      ),
    );
  }
}
