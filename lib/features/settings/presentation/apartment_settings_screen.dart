import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../features/auth/domain/auth_providers.dart';
import '../../../shared/widgets/ellimate_button.dart';
import '../../../shared/widgets/ellimate_text_field.dart';
import '../../../shared/widgets/ellimate_states.dart';

class ApartmentSettingsScreen extends ConsumerStatefulWidget {
  const ApartmentSettingsScreen({super.key});

  @override
  ConsumerState<ApartmentSettingsScreen> createState() =>
      _ApartmentSettingsScreenState();
}

class _ApartmentSettingsScreenState
    extends ConsumerState<ApartmentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;

  void _initFromApartment() {
    final apt = ref.read(currentApartmentProvider).value;
    if (apt != null && !_initialized) {
      _nameController.text = apt.name;
      _descriptionController.text = apt.description ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apartment = ref.read(currentApartmentProvider).value;
      if (apartment == null) {
        throw const DatabaseException(message: 'Apartment not found.');
      }

      await ref.read(apartmentRepositoryProvider).updateApartment(
            apartmentId: apartment.id,
            name: _nameController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
          );

      ref.invalidate(currentApartmentProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apartment settings saved!')),
        );
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final apartmentAsync = ref.watch(currentApartmentProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Apartment Settings', style: AppTypography.sectionHeading),
      ),
      body: apartmentAsync.when(
        loading: () => const ElliMateLoading(),
        error: (_, __) => const ElliMateErrorState(message: 'Unable to load apartment.'),
        data: (apartment) {
          _initFromApartment();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invite code card
                if (apartment != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite Code',
                          style: AppTypography.small.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              apartment.inviteCode,
                              style: AppTypography.display.copyWith(
                                color: AppColors.white,
                                letterSpacing: 6,
                                fontSize: 28,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: apartment.inviteCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Invite code copied!')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded,
                                  color: AppColors.white),
                            ),
                            IconButton(
                              onPressed: () async {
                                // Share invite code
                                await Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        'Join my apartment on ElliMate! Use invite code: ${apartment.inviteCode}',
                                  ),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Share text copied!')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.share_rounded,
                                  color: AppColors.white),
                            ),
                          ],
                        ),
                        Text(
                          'Share this with roommates to invite them.',
                          style: AppTypography.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (isAdmin) ...[
                  Text('Edit Apartment', style: AppTypography.sectionHeading),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ElliMateTextField(
                          label: 'Apartment name',
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: Icons.apartment_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElliMateTextField(
                          label: 'Description (optional)',
                          controller: _descriptionController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_errorMessage!,
                                style: AppTypography.small
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElliMateButton(
                          label: 'Save Changes',
                          onPressed: _save,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.secondaryText, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only the apartment admin can edit apartment settings.',
                            style: AppTypography.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
