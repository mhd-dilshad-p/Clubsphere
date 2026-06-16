import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/club_session_provider.dart';
import '../../../core/providers/auth_session_provider.dart';
import 'finance_service.dart';

class AddFinanceSheet extends StatefulWidget {
  const AddFinanceSheet({super.key});

  @override
  State<AddFinanceSheet> createState() => _AddFinanceSheetState();
}

class _AddFinanceSheetState extends State<AddFinanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'income';
  DateTime _date = DateTime.now();
  bool _isVisible = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final session = context.read<ClubSessionNotifier>();
    final authState = context.read<AuthSessionNotifier>();
    
    if (session.clubId == null || authState.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final success = await FinanceService.addEntry(
      clubId: session.clubId!,
      userId: authState.user!.id,
      userRole: session.userRole ?? 'member',
      type: _type,
      category: _categoryController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      description: _descController.text.trim(),
      transactionDate: _date,
      isVisibleToMembers: _isVisible,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (success) {
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add entry'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Finance Entry', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Income'),
                      value: 'income',
                      // ignore: deprecated_member_use
                      groupValue: _type,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _type = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Expenditure'),
                      value: 'expenditure',
                      // ignore: deprecated_member_use
                      groupValue: _type,
                      // ignore: deprecated_member_use
                      onChanged: (v) => setState(() => _type = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category * (e.g., Subscription, Rent)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount *', prefixText: '₹ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Transaction Date'),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
              ),
              SwitchListTile(
                title: const Text('Visible to all members'),
                value: _isVisible,
                onChanged: (v) => setState(() => _isVisible = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Entry'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
