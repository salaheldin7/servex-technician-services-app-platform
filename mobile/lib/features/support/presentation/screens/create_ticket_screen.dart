import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/support_repository.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'general';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'general', 'label': 'General'},
    {'value': 'booking', 'label': 'Booking Issue'},
    {'value': 'payment', 'label': 'Payment Issue'},
    {'value': 'technician', 'label': 'Technician Complaint'},
    {'value': 'account', 'label': 'Account Issue'},
    {'value': 'app', 'label': 'App Problem'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return; // guard against double-submit

    setState(() => _isSubmitting = true);

    final result = await ref.read(supportRepositoryProvider).createTicket(
          subject: _subjectController.text.trim(),
          category: _category,
          message: _messageController.text.trim(),
        );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.invalidate(supportTicketsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket created successfully')),
      );
      context.pop();
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error?.message ?? 'Failed to create ticket'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.createTicket),
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ResponsiveCenter(
          maxWidth: Responsive.maxFormWidth(context),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c['value'],
                    child: Text(c['label']!),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),

              // Message
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 100),
                    child: Icon(Icons.message_outlined),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Ticket'),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
