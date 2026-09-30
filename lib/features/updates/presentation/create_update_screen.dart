import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/models/apartment_update.dart';
import '../../../shared/widgets/ellimate_button.dart';
import '../../../shared/widgets/ellimate_text_field.dart';
import 'updates_screen.dart';

class CreateUpdateScreen extends ConsumerStatefulWidget {
  const CreateUpdateScreen({super.key});

  @override
  ConsumerState<CreateUpdateScreen> createState() => _CreateUpdateScreenState();
}

class _CreateUpdateScreenState extends ConsumerState<CreateUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  UpdateCategory _selectedCategory = UpdateCategory.general;
  DateTime? _scheduledAt;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final apartment = await ref.read(currentApartmentProvider.future);
      if (user == null || apartment == null) throw const AppAuthException(message: 'Not authenticated.');

      await ref.read(updatesRepositoryProvider).createUpdate(
        apartmentId: apartment.id,
        userId: user.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        scheduledAt: _scheduledAt,
      );

      ref.invalidate(updatesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update published!')),
        );
        context.pop();
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('New Update', style: AppTypography.sectionHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElliMateTextField(
                label: 'Title',
                hint: 'e.g. Water Maintenance',
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElliMateTextField(
                label: 'Description',
                hint: 'Describe the update...',
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text('Category', style: AppTypography.labelText),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: UpdateCategory.values.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryCoral : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryCoral : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${cat.icon} ${cat.displayName}',
                        style: AppTypography.small.copyWith(
                          color: isSelected ? AppColors.white : AppColors.primaryNavy,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text('Scheduled date (optional)', style: AppTypography.labelText),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primaryCoral,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _scheduledAt = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.secondaryText),
                      const SizedBox(width: 10),
                      Text(
                        _scheduledAt != null
                            ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}'
                            : 'Select a date',
                        style: AppTypography.body.copyWith(
                          color: _scheduledAt != null
                              ? AppColors.primaryNavy
                              : AppColors.secondaryText.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      if (_scheduledAt != null)
                        GestureDetector(
                          onTap: () => setState(() => _scheduledAt = null),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.secondaryText),
                        ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.small.copyWith(color: AppColors.error),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElliMateButton(
                label: 'Publish Update',
                onPressed: _publish,
                isLoading: _isLoading,
                icon: Icons.campaign_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
