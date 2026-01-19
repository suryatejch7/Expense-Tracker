import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense_models.dart';

/// Performance logging helper for AddIncomeScreen
class _IncomePerfLog {
  static final Stopwatch _stopwatch = Stopwatch();
  static DateTime? _lastTimestamp;
  
  static void log(String message) {
    final now = DateTime.now();
    final elapsed = _lastTimestamp != null 
        ? now.difference(_lastTimestamp!).inMilliseconds 
        : 0;
    _lastTimestamp = now;
    debugPrint('[ADD_INCOME ${now.toString().substring(11, 23)}] (+${elapsed}ms) $message');
  }
  
  static void startTimer(String label) {
    _stopwatch.reset();
    _stopwatch.start();
    log('⏱️ START: $label');
  }
  
  static void endTimer(String label) {
    _stopwatch.stop();
    log('⏱️ END: $label - took ${_stopwatch.elapsedMilliseconds}ms');
  }
}

class AddIncomeScreen extends StatefulWidget {
  final Income? income; // For editing existing income

  const AddIncomeScreen({
    super.key,
    this.income,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  int _buildCount = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    _IncomePerfLog.log('🚀 initState() called');
    _IncomePerfLog.log('   - Editing existing: ${widget.income != null}');
    super.initState();

    if (widget.income != null) {
      // Editing existing income
      _titleController.text = widget.income!.title;
      _amountController.text = widget.income!.amount.toString();
      _sourceController.text = widget.income!.source;
      _noteController.text = widget.income!.notes ?? '';
      _selectedDate = widget.income!.date;
      _selectedAccountId = widget.income!.accountId;
      _IncomePerfLog.log('✅ Loaded existing income data');
    }
    _IncomePerfLog.log('✅ initState() complete');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize default account only once, synchronously during first build
    if (!_isInitialized) {
      _isInitialized = true;
      final provider = context.read<ExpenseProvider>();
      if (_selectedAccountId == null && provider.defaultAccount != null) {
        _selectedAccountId = provider.defaultAccount!.id;
        _IncomePerfLog.log('📋 Default account set: ${provider.defaultAccount?.name}');
      }
    }
  }

  @override
  void dispose() {
    _IncomePerfLog.log('🗑️ dispose() called - total builds: $_buildCount');
    _titleController.dispose();
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _IncomePerfLog.log('🔨 build() #$_buildCount called');
    final currency = context.watch<ExpenseProvider>().currency;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.income == null ? 'Add Income' : 'Edit Income'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income indicator banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Money coming into your account',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Field
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                labelText: 'Income Title',
                hintText: 'e.g., Salary, Loan Repayment, Refund',
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
                prefixText: '$currency ',
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

              // Source Field
              _buildSectionTitle('From (Source)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _sourceController,
                labelText: 'Source (Optional)',
                hintText: 'e.g., Friend\'s name, Company, Amazon',
              ),
              const SizedBox(height: 20),

              // Date and Account Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Date'),
                        const SizedBox(height: 8),
                        _buildDateSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('To Account'),
                        const SizedBox(height: 8),
                        _buildAccountSelector(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notes Field
              _buildSectionTitle('Notes (Optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _noteController,
                labelText: 'Notes',
                hintText: 'Additional details...',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.income == null ? 'Add Income' : 'Update Income',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        fillColor: const Color(0xFF1A1A1A),
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
          borderSide: const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.green,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final accounts = provider.accounts;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAccountId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
              hint: const Text(
                'Select Account',
                style: TextStyle(color: Colors.grey),
              ),
              items: accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account.id,
                  child: Text(
                    account.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _saveIncome() async {
    _IncomePerfLog.startTimer('Save income');
    _IncomePerfLog.log('💾 _saveIncome() called');
    
    if (_formKey.currentState!.validate()) {
      _IncomePerfLog.log('✅ Form validation passed');
      
      if (_selectedAccountId == null) {
        _IncomePerfLog.log('❌ No account selected');
        _IncomePerfLog.endTimer('Save income');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an account'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final now = DateTime.now();
      _IncomePerfLog.log('📝 Creating income object...');
      _IncomePerfLog.log('   - Title: ${_titleController.text.trim()}');
      _IncomePerfLog.log('   - Amount: ${_amountController.text}');
      _IncomePerfLog.log('   - Source: ${_sourceController.text.trim()}');
      _IncomePerfLog.log('   - Date: $_selectedDate');
      _IncomePerfLog.log('   - Account: $_selectedAccountId');
      
      final income = Income(
        id: widget.income?.id,
        amount: double.parse(_amountController.text),
        title: _titleController.text.trim(),
        source: _sourceController.text.trim(),
        date: _selectedDate,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        accountId: _selectedAccountId,
        createdAt: widget.income?.createdAt ?? now,
        updatedAt: now,
      );
      _IncomePerfLog.log('✅ Income object created');

      final provider = context.read<ExpenseProvider>();
      _IncomePerfLog.log('📤 Getting provider...');
      
      try {
        if (widget.income == null) {
          _IncomePerfLog.log('➕ Adding new income...');
          await provider.addIncome(income);
          _IncomePerfLog.log('✅ Income added to provider');
          _IncomePerfLog.log('   - Total incomes now: ${provider.incomes.length}');
        } else {
          _IncomePerfLog.log('🔄 Updating existing income...');
          await provider.updateIncome(income);
          _IncomePerfLog.log('✅ Income updated in provider');
        }

        _IncomePerfLog.endTimer('Save income');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.income == null ? 'Income added successfully!' : 'Income updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _IncomePerfLog.log('👈 Navigating back...');
          Navigator.pop(context);
        }
      } catch (e) {
        _IncomePerfLog.log('❌ ERROR saving income: $e');
        _IncomePerfLog.endTimer('Save income');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _IncomePerfLog.log('❌ Form validation failed');
      _IncomePerfLog.endTimer('Save income');
    }
  }
}
