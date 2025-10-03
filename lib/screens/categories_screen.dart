import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_models.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          final categoryTotals = expenseProvider.categoryTotals;

          if (categoryTotals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some expenses to see category breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              final categoryName = entry.key;
              final amount = entry.value;
              final percentage = (amount / expenseProvider.totalExpense * 100);

              // Find the category object
              final category = expenseProvider.categories.firstWhere(
                (cat) => cat.name == categoryName,
                orElse: () => ExpenseCategory(
                  id: categoryName,
                  name: categoryName,
                  icon: '📦',
                  colorHex: '#747D8C',
                ),
              );

              // Backend logic for overspending detection
              final budget = expenseProvider.getCategoryBudget(categoryName);
              final isOverBudget = expenseProvider.isCategoryOverBudget(categoryName);
              final budgetExcess = expenseProvider.getCategoryBudgetExcess(categoryName);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CategoryDetailScreen(categoryName: categoryName),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isOverBudget
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isOverBudget
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : category.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    category.icon,
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: isOverBudget ? Colors.red : category.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          category.displayName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isOverBudget ? Colors.red : Colors.white,
                                          ),
                                        ),
                                        if (isOverBudget) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'OVER',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${amount.toStringAsFixed(2)} • ${percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (budget > 0) ...[
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: (amount / budget).clamp(0.0, 1.0),
                                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOverBudget ? Colors.red : category.color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Budget: ₹${budget.toStringAsFixed(0)}${isOverBudget ? ' (Over by ₹${budgetExcess.toStringAsFixed(0)})' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isOverBudget ? Colors.red : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isOverBudget ? Colors.red : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${expenseProvider.getExpensesByCategory(categoryName).length} transactions',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Find the category object
        final category = expenseProvider.categories.firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => ExpenseCategory(
            id: categoryName,
            name: categoryName,
            icon: '📦',
            colorHex: '#747D8C',
          ),
        );

        final expenses = expenseProvider.getExpensesByCategory(categoryName);
        final totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

        return Scaffold(
          appBar: AppBar(
            title: Text(category.displayName),
            backgroundColor: category.color.withValues(alpha: 0.1),
          ),
          body: expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.icon,
                        style: TextStyle(
                          fontSize: 80,
                          color: category.color.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${category.displayName.toLowerCase()} expenses',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: category.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            category.icon,
                            style: TextStyle(
                              fontSize: 48,
                              color: category.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpenseCard(expense: expenses[index], index: index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
