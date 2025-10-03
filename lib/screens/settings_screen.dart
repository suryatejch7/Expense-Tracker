import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../models/expense_models.dart';
import 'user_selector_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = context.read<UserProvider>();
    _nameController.text = userProvider.userId;
    final provider = context.read<ExpenseProvider>();
    _budgetController.text = provider.monthlyBudget.toString();
  }

  void _saveUserName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != context.read<UserProvider>().userId) {
      await context.read<UserProvider>().setUserId(newName);
      await context.read<ExpenseProvider>().updateUserName(newName, context);
      setState(() {
        _isEditingName = false;
      });
    }
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
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            child: Column(
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
                              userProvider.userId.isNotEmpty
                                  ? userProvider.userId[0].toUpperCase()
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
                                    decoration: const InputDecoration(hintText: 'User Name'),
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
                                            userProvider.userId.isEmpty ? 'Tap to set name' : userProvider.userId,
                                            style: TextStyle(
                                              color: userProvider.userId.isEmpty ? Colors.grey : Colors.white,
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
                          context.read<ExpenseProvider>().updateMonthlyBudget(budget);
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final budget = double.tryParse(_budgetController.text) ?? 0;
                          context.read<ExpenseProvider>().updateMonthlyBudget(budget);
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

                      // Custom Categories List
                      ...context.read<ExpenseProvider>().customCategories.map((category) {
                        final budget = context.read<ExpenseProvider>().getCustomCategoryBudget(category.id);
                        final spent = context.read<ExpenseProvider>().getCustomCategoryExpenses(category.id);
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
                                      Text(
                                        category.icon,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: category.color,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (category.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Default',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _showExpenseCategoryBudgetDialog(category),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                      if (!category.isDefault) // Only allow deleting custom categories
                                        IconButton(
                                          onPressed: () => _showDeleteExpenseCategoryDialog(category),
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
                                  value: (spent / budget).clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget ? Colors.red : category.color,
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

                const SizedBox(height: 32),

                // Logout Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    // Clear user session
                    await context.read<UserProvider>().setUserId('');
                    // Navigate to main login page
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const UserSelectorScreen(onUserSelected: () {})),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 32),
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
    String selectedIcon = '📦';
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Add Category',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Name Input
                TextField(
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
                const SizedBox(height: 20),

                // Icon Selection (simplified)
                const Text(
                  'Choose Icon',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['📦', '🍽️', '🚗', '🛒', '🎬', '💡', '🏥', '📚', '💳', '🎯'].map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor.withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Color Selection (simplified)
                const Text(
                  'Choose Color',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.blue,
                    Colors.green,
                    Colors.red,
                    Colors.orange,
                    Colors.purple,
                    Colors.pink,
                    Colors.teal,
                    Colors.amber,
                  ].map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_categoryNameController.text.isNotEmpty) {
                  final newCategory = ExpenseCategory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _categoryNameController.text,
                    icon: selectedIcon,
                    colorHex: '#${(selectedColor.r * 255.0).round().toRadixString(16).padLeft(2, '0')}${(selectedColor.g * 255.0).round().toRadixString(16).padLeft(2, '0')}${(selectedColor.b * 255.0).round().toRadixString(16).padLeft(2, '0')}',
                    isDefault: false,
                  );

                  context.read<ExpenseProvider>().addCustomCategory(newCategory);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category "${_categoryNameController.text}" added successfully!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseCategoryBudgetDialog(ExpenseCategory category) {
    final provider = context.read<ExpenseProvider>();
    _categoryBudgetController.text = provider.getCustomCategoryBudget(category.id).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          'Set Budget for ${category.name}',
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
              provider.setCustomCategoryBudget(category.id, budget);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    budget > 0
                        ? 'Budget set to ₹${budget.toStringAsFixed(0)} for ${category.name}'
                        : 'Budget removed for ${category.name}',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
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

  void _showDeleteExpenseCategoryDialog(ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone and all expenses in this category will be moved to "Other".',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ExpenseProvider>().removeCustomCategory(category.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${category.name}" deleted successfully!'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 1),
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
