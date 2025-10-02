import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class CategorySummary extends StatelessWidget {
  const CategorySummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final categoryTotals = expenseProvider.categoryTotals;

        if (categoryTotals.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryTotals.length,
                itemBuilder: (context, index) {
                  final category = categoryTotals.keys.elementAt(index);
                  final amount = categoryTotals[category]!;
                  final percentage = (amount / expenseProvider.totalExpense * 100);
                  final isOverBudget = expenseProvider.isCategoryOverBudget(category);
                  final budgetExcess = expenseProvider.getCategoryBudgetExcess(category);
                  final budget = expenseProvider.getCategoryBudget(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOverBudget
                              ? Colors.red.withValues(alpha: 0.5)
                              : category.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isOverBudget
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : category.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                category.icon,
                                color: isOverBudget ? Colors.red : category.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? Colors.red : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isOverBudget) ...[
                              Text(
                                '+₹${budgetExcess.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else if (budget > 0) ...[
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
