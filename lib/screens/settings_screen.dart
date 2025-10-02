import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryBudgetController = TextEditingController();

  bool _isEditingName = false;
  ExpenseCategory? _selectedCategoryForBudget;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final provider = context.read<ExpenseProvider>();
    _nameController.text = provider.userName;
    _budgetController.text = provider.monthlyBudget.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                _buildSectionCard(
                  title: 'Profile',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              provider.userName.isNotEmpty
                                  ? provider.userName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isEditingName
                                ? TextField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      provider.updateUserName(value);
                                      setState(() {
                                        _isEditingName = false;
                                      });
                                    },
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditingName = true;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            provider.userName.isEmpty ? 'Tap to set name' : provider.userName,
                                            style: TextStyle(
                                              color: provider.userName.isEmpty ? Colors.grey : Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Icon(
                                            Icons.edit,
                                            color: Colors.grey.withValues(alpha: 0.7),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Budget Section
                _buildSectionCard(
                  title: 'Monthly Budget',
                  child: Column(
                    children: [
                      TextField(
                        controller: _budgetController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Budget (₹)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        onSubmitted: (value) {
                          final budget = double.tryParse(value) ?? 0;
                          provider.updateMonthlyBudget(budget);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final budget = double.tryParse(_budgetController.text) ?? 0;
                          provider.updateMonthlyBudget(budget);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Budget updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Update Budget'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Categories Section
                _buildSectionCard(
                  title: 'Categories',
                  child: Column(
                    children: [
                      // Add Category Button
                      ElevatedButton.icon(
                        onPressed: _showAddCategoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categories List
                      ...ExpenseCategory.values.map((category) {
                        final budget = provider.getCategoryBudget(category);
                        final spent = provider.getCategoryExpenses(category);
                        final isOverBudget = budget > 0 && spent > budget;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isOverBudget
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _showCategoryBudgetDialog(category),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                      if (category != ExpenseCategory.food) // Don't allow deleting default categories
                                        IconButton(
                                          onPressed: () => _showDeleteCategoryDialog(category),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    budget > 0 ? 'Budget: ₹${budget.toStringAsFixed(0)}' : 'No limit',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Spent: ₹${spent.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: isOverBudget ? Colors.red : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (budget > 0) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: spent / budget,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget ? Colors.red : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    _categoryNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _categoryNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Category Name',
            labelStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // For now, we'll show a message that custom categories aren't implemented yet
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom categories feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCategoryBudgetDialog(ExpenseCategory category) {
    final provider = context.read<ExpenseProvider>();
    _categoryBudgetController.text = provider.getCategoryBudget(category).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Set Budget for ${category.displayName}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _categoryBudgetController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget Amount (₹) - Enter 0 for unlimited',
            labelStyle: const TextStyle(color: Colors.grey),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(_categoryBudgetController.text) ?? 0;
              provider.setCategoryBudget(category, budget);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    budget > 0
                        ? 'Budget set to ₹${budget.toStringAsFixed(0)} for ${category.displayName}'
                        : 'Budget removed for ${category.displayName}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${category.displayName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete category feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _categoryNameController.dispose();
    _categoryBudgetController.dispose();
    super.dispose();
  }
}



