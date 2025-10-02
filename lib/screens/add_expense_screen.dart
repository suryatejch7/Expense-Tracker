import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final double? prefilledAmount;

  const AddExpenseScreen({super.key, this.expense, this.prefilledAmount});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  String? _selectedCustomCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      // Editing existing expense
      _titleController.text = widget.expense!.title;
      _amountController.text = widget.expense!.amount.toString();
      _noteController.text = widget.expense!.note ?? '';
      _selectedCategory = widget.expense!.category;
      _selectedCustomCategoryId = widget.expense!.customCategoryId;
      _selectedDate = widget.expense!.date;
    } else if (widget.prefilledAmount != null) {
      // OCR pre-filled amount
      _amountController.text = widget.prefilledAmount!.toString();

      // Show success message for OCR
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Amount ₹${widget.prefilledAmount} extracted from receipt'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1), // Fixed: 1 second duration
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: Text(
              isEditing ? 'UPDATE' : 'SAVE',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Expense Details'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter expense title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Category'),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Date'),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Note (Optional)'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Add a note about this expense',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final categories = provider.customCategories;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCustomCategoryId == category.id;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCustomCategoryId = category.id;
                      // Map to corresponding enum for backward compatibility
                      switch (category.id) {
                        case 'food':
                          _selectedCategory = ExpenseCategory.food;
                          break;
                        case 'transport':
                          _selectedCategory = ExpenseCategory.transport;
                          break;
                        case 'entertainment':
                          _selectedCategory = ExpenseCategory.entertainment;
                          break;
                        case 'shopping':
                          _selectedCategory = ExpenseCategory.shopping;
                          break;
                        case 'bills':
                          _selectedCategory = ExpenseCategory.bills;
                          break;
                        case 'health':
                          _selectedCategory = ExpenseCategory.health;
                          break;
                        case 'education':
                          _selectedCategory = ExpenseCategory.education;
                          break;
                        case 'travel':
                          _selectedCategory = ExpenseCategory.travel;
                          break;
                        default:
                          _selectedCategory = ExpenseCategory.other;
                      }
                    });
                  },
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color.withValues(alpha: 0.2)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? category.color
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          color: isSelected ? category.color : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? category.color : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      final expense = Expense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: note,
        customCategoryId: _selectedCustomCategoryId,
      );

      final provider = context.read<ExpenseProvider>();

      if (widget.expense != null) {
        provider.updateExpense(expense);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1), // Fixed: 1 second duration
          ),
        );
      } else {
        provider.addExpense(expense);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1), // Fixed: 1 second duration
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
