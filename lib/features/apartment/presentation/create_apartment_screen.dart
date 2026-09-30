import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/widgets/ellimate_button.dart';
import '../../../shared/widgets/ellimate_text_field.dart';

class CreateApartmentScreen extends ConsumerStatefulWidget {
  const CreateApartmentScreen({super.key});

  @override
  ConsumerState<CreateApartmentScreen> createState() =>
      _CreateApartmentScreenState();
}

class _CreateApartmentScreenState extends ConsumerState<CreateApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createApartment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw const AppAuthException(message: 'Not authenticated.');

      await ref.read(apartmentRepositoryProvider).createApartment(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        userId: user.id,
      );

      if (mounted) context.go('/home');
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unable to create apartment. Please try again.');
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
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/apartment/setup'),
        ),
        title: Text('Create Apartment', style: AppTypography.sectionHeading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryCoral.withValues(alpha: 0.8), AppColors.blue.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_home_rounded, size: 52, color: AppColors.white),
                    const SizedBox(height: 8),
                    Text(
                      'Create your apartment',
                      style: AppTypography.sectionHeading.copyWith(color: AppColors.white),
                    ),
                    Text(
                      'Set up and invite your roommates.',
                      style: AppTypography.small.copyWith(color: AppColors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              ElliMateTextField(
                label: 'Apartment name',
                hint: 'e.g. Apartment 4B',
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                prefixIcon: Icons.apartment_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Apartment name is required';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElliMateTextField(
                label: 'Description (optional)',
                hint: 'A short description about your apartment.',
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
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
                label: 'Create Apartment',
                onPressed: _createApartment,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/apartment/join'),
                  child: Text(
                    'Already have a code? Join instead',
                    style: AppTypography.smallMedium.copyWith(
                      color: AppColors.primaryCoral,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryCoral,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
