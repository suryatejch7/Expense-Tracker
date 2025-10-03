import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_models.dart';
import '../models/transaction_ocr_models.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final double? prefilledAmount;
  final String? prefilledPayee;
  final String? prefilledPaymentApp;
  final String? prefilledTransactionId;
  final ExtractedTransaction? extractedData;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.prefilledAmount,
    this.prefilledPayee,
    this.prefilledPaymentApp,
    this.prefilledTransactionId,
    this.extractedData,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Other';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Initialize provider data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
    });

    if (widget.expense != null) {
      // Editing existing expense
      _titleController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toString();
      _payeeController.text = widget.expense!.payee ?? '';
      _noteController.text = '';
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    } else {
      // Handle OCR pre-filled data
      if (widget.prefilledAmount != null) {
        _amountController.text = widget.prefilledAmount!.toString();
      }

      if (widget.prefilledPayee != null) {
        _payeeController.text = widget.prefilledPayee!;
        // Auto-generate title from payee if available
        if (widget.prefilledPayee!.isNotEmpty) {
          _titleController.text = 'Payment to ${widget.prefilledPayee}';
        }
      }

      // Show success message for OCR
      if (widget.prefilledAmount != null || widget.prefilledPayee != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OCR extracted: ${widget.prefilledAmount != null ? "₹${widget.prefilledAmount}" : ""} ${widget.prefilledPayee != null ? "to ${widget.prefilledPayee}" : ""}'.trim()
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _payeeController,
                decoration: const InputDecoration(
                  labelText: 'Payee (Optional)',
                  hintText: 'Enter payee name (optional)',
                ),
                // Removed validator to make payee optional
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
              final isSelected = _selectedCategory == category.name;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.name;
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
                        Text(
                          category.icon,
                          style: TextStyle(
                            fontSize: 24,
                            color: isSelected ? category.color : Colors.grey,
                          ),
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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        final title = _titleController.text.trim();
        final amount = double.parse(_amountController.text.trim());
        final payee = _payeeController.text.trim().isEmpty ? null : _payeeController.text.trim();
        final now = DateTime.now();

        final expense = Expense(
          id: widget.expense?.id,
          description: title,
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          payee: payee,
          paymentApp: widget.prefilledPaymentApp ?? 'PhonePe',
          transactionId: widget.prefilledTransactionId,
          createdAt: widget.expense?.createdAt ?? now,
          updatedAt: now,
        );

        final provider = context.read<ExpenseProvider>();

        if (widget.expense != null) {
          await provider.updateExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Expense updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          await provider.addExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Expense saved to cloud!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error saving expense: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _payeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
