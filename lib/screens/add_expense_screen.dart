import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_models.dart';
import '../models/transaction_ocr_models.dart';

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

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                labelText: 'Expense Title',
                hintText: 'e.g., Grocery Shopping',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Amount Field
              _buildSectionTitle('Amount'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: '0.00',
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category Selector
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Date Selector
              _buildSectionTitle('Date'),
              const SizedBox(height: 8),
              _buildDateSelector(),
              const SizedBox(height: 20),

              // Payee Field
              _buildSectionTitle('Payee (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _payeeController,
                labelText: 'Payee',
                hintText: 'e.g., Amazon, Uber',
              ),
              const SizedBox(height: 20),

              // Notes Field
              _buildSectionTitle('Notes (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _noteController,
                labelText: 'Notes',
                hintText: 'Additional details...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Expense',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.grey),
        prefixStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final categories = provider.customCategories;

        return SizedBox(
          height: 120,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
            SnackBar(
              content: const Text('✅ Expense updated successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await provider.addExpense(expense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Expense saved to cloud!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save expense';
        if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('database')) {
          errorMessage = 'Database error. Please try again.';
        } else if (e.toString().contains('validation')) {
          errorMessage = 'Please check your input and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveExpense(),
            ),
          ),
        );
      }
    }
  }
}
