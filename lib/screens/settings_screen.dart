import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../models/expense_models.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/export_service.dart';
import '../services/backup_service.dart';
import 'package:file_picker/file_picker.dart';

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
  bool _isAddingCategory = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }


  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _categoryNameController.dispose();
    _categoryBudgetController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final provider = context.read<ExpenseProvider>();
    _nameController.text = provider.userName;
    _budgetController.text = provider.monthlyBudget.toString();
  }

  Future<void> _saveUserName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != context.read<ExpenseProvider>().userName) {
      // Update username through UserProvider only
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentUser != null) {
        await userProvider.updateUserName(newName);
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Consumer2<UserProvider, ExpenseProvider>(
        builder: (context, userProvider, expenseProvider, child) {
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
                              userProvider.userName.isNotEmpty
                                  ? userProvider.userName[0].toUpperCase()
                                  : 'U',
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
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(hintText: 'User Name'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                                          final theme = Theme.of(context);
                                          await _saveUserName();
                                          if (mounted) {
                                            scaffoldMessenger.showSnackBar(
                                              SnackBar(
                                                content: const Text('Name updated successfully!'),
                                                backgroundColor: theme.colorScheme.primary,
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 40),
                                        ),
                                        child: const Text('Update Name'),
                                      ),
                                    ],
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
                                        expenseProvider.userName.isEmpty ? 'Tap to set name' : expenseProvider.userName,
                                        style: TextStyle(
                                          color: expenseProvider.userName.isEmpty ? Colors.grey : Colors.white,
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                            expenseProvider.updateMonthlyBudget(budget);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final budget = double.tryParse(_budgetController.text) ?? 0;
                          expenseProvider.updateMonthlyBudget(budget);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Budget updated successfully!'),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Categories Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D0D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and add button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (expenseProvider.customCategories.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Category'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show empty state if no categories
                      if (expenseProvider.customCategories.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No categories yet',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first category to organize your expenses',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Add Category Button (when categories exist)
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
                        // Custom Categories Grid (2 columns)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: expenseProvider.customCategories.length,
                          itemBuilder: (context, index) {
                            final category = expenseProvider.customCategories[index];
                            final budget = expenseProvider.getCustomCategoryBudget(category.id);
                            final spent = expenseProvider.getCustomCategoryExpenses(category.id);
                            final isOverBudget = budget > 0 && spent > budget;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isOverBudget
                                      ? Colors.red.withValues(alpha: 0.5)
                                      : category.color.withValues(alpha: 0.3),
                                  width: isOverBudget ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: icon + actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: category.color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            category.icon,
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showExpenseCategoryBudgetDialog(category),
                                            child: const Icon(Icons.edit, color: Colors.grey, size: 18),
                                          ),
                                          if (!category.isDefault) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _showDeleteExpenseCategoryDialog(category),
                                              child: Icon(Icons.delete, color: Colors.grey.withValues(alpha: 0.7), size: 18),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Category name
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  // Budget info
                                  Text(
                                    budget > 0
                                        ? '₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}'
                                        : '₹${spent.toStringAsFixed(0)} spent',
                                    style: TextStyle(
                                      color: isOverBudget ? Colors.red : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (budget > 0) ...[
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (spent / budget).clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOverBudget ? Colors.red : category.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bank Accounts Section
                _buildAccountsSection(expenseProvider),

                const SizedBox(height: 20),

                // Notification Settings Section
                _buildNotificationSettingsSection(),

                const SizedBox(height: 20),

                // Data Management Section
                _buildDataManagementSection(userProvider, expenseProvider),

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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
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

  Widget _buildNotificationSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notification Toggle
          FutureBuilder<bool>(
            future: NotificationService.areNotificationsEnabled(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return SwitchListTile(
                title: const Text(
                  'Enable Notifications',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Get alerts about budget limits, spending patterns, and reminders',
                  style: TextStyle(color: Colors.grey),
                ),
                value: isEnabled,
                onChanged: (value) async {
                  await NotificationService.setNotificationsEnabled(value);
                  setState(() {});
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Test Notification Button
          ElevatedButton.icon(
            onPressed: () async {
              await NotificationService.checkMonthlyBudgetExceeded(26000, 25000);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent! Check your notification shade.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            icon: const Icon(Icons.notifications),
            label: const Text('Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification Types Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Types:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Monthly budget exceeded alert\n'
                  '• Category budget exceeded alert',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
                    Colors.cyan,
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
                        width: isSelected ? 50 : 40,
                        height: isSelected ? 50 : 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ] : null,
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
              onPressed: _isAddingCategory ? null : () async {
                if (_categoryNameController.text.isNotEmpty) {
                  setState(() {
                    _isAddingCategory = true;
                  });

                  try {
                    final newCategory = ExpenseCategory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _categoryNameController.text,
                      icon: selectedIcon,
                      colorHex: '#${(selectedColor.r * 255.0).round().toRadixString(16).padLeft(2, '0')}${(selectedColor.g * 255.0).round().toRadixString(16).padLeft(2, '0')}${(selectedColor.b * 255.0).round().toRadixString(16).padLeft(2, '0')}',
                      isDefault: false,
                    );

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final theme = Theme.of(context);
                    
                    await context.read<ExpenseProvider>().addCustomCategory(newCategory);
                    // No need for force refresh - addCustomCategory already handles local updates
                    navigator.pop();

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Category "${_categoryNameController.text}" added successfully!'),
                          backgroundColor: theme.colorScheme.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } finally {
                    setState(() {
                      _isAddingCategory = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: _isAddingCategory 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Add'),
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
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final theme = Theme.of(context);
              
              final budget = double.tryParse(_categoryBudgetController.text) ?? 0;
              await provider.setCustomCategoryBudget(category.id, budget);
              // No need for force refresh - setCustomCategoryBudget already handles local updates
              navigator.pop();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      budget > 0
                          ? 'Budget set to ₹${budget.toStringAsFixed(0)} for ${category.name}'
                          : 'Budget removed for ${category.name}',
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
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
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              await context.read<ExpenseProvider>().removeCustomCategory(category.id);
              // No need for force refresh - removeCustomCategory already handles local updates
              navigator.pop();

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted successfully!'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
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

  // ==================== ACCOUNTS SECTION ====================

  Widget _buildAccountsSection(ExpenseProvider expenseProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bank Accounts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show empty state if no accounts
          if (expenseProvider.accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accounts yet',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your bank accounts to track which account you spend from',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Accounts List
            ...expenseProvider.accounts.map((account) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: account.isDefault
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            account.isCreditCard
                                ? Icons.credit_card
                                : Icons.account_balance,
                            color: account.isDefault
                                ? Theme.of(context).colorScheme.primary
                                : (account.isCreditCard
                                      ? Colors.orange
                                      : Colors.grey),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  account.type.label,
                                  style: TextStyle(
                                    color: account.isCreditCard
                                        ? Colors.orange.withValues(alpha: 0.8)
                                        : Colors.grey.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (account.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!account.isDefault)
                          IconButton(
                            onPressed: () => _setDefaultAccount(account.id),
                            icon: const Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 20,
                            ),
                            tooltip: 'Set as default',
                          ),
                        IconButton(
                          onPressed: () => _showDeleteAccountDialog(account),
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
              );
            }),
        ],
      ),
    );
  }

  void _showAddAccountDialog() {
    final accountNameController = TextEditingController();
    AccountType selectedType = AccountType.savings;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Add Account',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountNameController,
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., SBI, HDFC, Axis',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    selectedType == AccountType.creditCard
                        ? Icons.credit_card
                        : Icons.account_balance,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Account type selector
              Row(
                children: AccountType.values.map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedType = type;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (type == AccountType.creditCard
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.2))
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (type == AccountType.creditCard
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.primary)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type == AccountType.creditCard
                                  ? Icons.credit_card
                                  : Icons.account_balance,
                              color: isSelected
                                  ? (type == AccountType.creditCard
                                        ? Colors.orange
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary)
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[400],
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = accountNameController.text.trim();
                if (name.isEmpty) return;

                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final provider = context.read<ExpenseProvider>();

                final newAccount = BankAccount(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  isDefault: provider.accounts.isEmpty,
                  type: selectedType,
                );

                await provider.addAccount(newAccount);
                navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          '${selectedType.label} "$name" added successfully!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
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

  Future<void> _setDefaultAccount(String accountId) async {
    final provider = context.read<ExpenseProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await provider.setDefaultAccount(accountId);

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Default account updated!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // ==================== DATA MANAGEMENT SECTION ====================

  Widget _buildDataManagementSection(
    UserProvider userProvider,
    ExpenseProvider expenseProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Export Data
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('Export Data (CSV)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ExportService.exportAndShare(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exports all expenses and income as a CSV file you can share or open in a spreadsheet app.',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // Backup Data (JSON)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.backup_rounded, size: 20),
              label: const Text('Backup Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                BackupService.createAndShareBackup(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creates a full JSON backup of all your data that you can save and restore later.',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          // Restore Data
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: const Text('Restore from Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _pickAndRestoreBackup(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a previously exported JSON backup file to restore all your data.',
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),

          const Divider(height: 32, color: Colors.grey),

          // Reset All Data
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text('Reset All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                foregroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onPressed: () =>
                  _showResetDataDialog(userProvider, expenseProvider),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently deletes all expenses, income, categories, accounts, and settings. This cannot be undone.',
            style: TextStyle(
              color: Colors.red.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndRestoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    if (!mounted) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Restore Backup?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will replace ALL current data with the data from the backup file.\n\nYour current data will be lost. Continue?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Restore',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await BackupService.restoreFromFile(context, path);
  }

  void _showResetDataDialog(
    UserProvider userProvider,
    ExpenseProvider expenseProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Reset All Data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete ALL your data including expenses, income, categories, and settings.\n\nThis action cannot be undone. Consider exporting your data first.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              await ExpenseSupabaseService.resetAllData();
              expenseProvider.clearUserData();
              await userProvider.clearUser();

              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Everything',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BankAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${account.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final provider = context.read<ExpenseProvider>();

              await provider.removeAccount(account.id);
              navigator.pop();

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Account "${account.name}" deleted!'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
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

}
