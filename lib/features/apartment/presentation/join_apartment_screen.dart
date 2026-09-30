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

class JoinApartmentScreen extends ConsumerStatefulWidget {
  const JoinApartmentScreen({super.key});

  @override
  ConsumerState<JoinApartmentScreen> createState() => _JoinApartmentScreenState();
}

class _JoinApartmentScreenState extends ConsumerState<JoinApartmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinApartment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw const AppAuthException(message: 'Not authenticated.');

      await ref.read(apartmentRepositoryProvider).joinApartment(
        inviteCode: _codeController.text,
        userId: user.id,
      );

      if (mounted) context.go('/home');
    } on NotFoundException catch (e) {
      setState(() => _errorMessage = e.message);
    } on ConflictException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Unable to join apartment. Please try again.');
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
        title: Text('Join Apartment', style: AppTypography.sectionHeading),
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
                    colors: [AppColors.blue.withValues(alpha: 0.9), AppColors.purple.withValues(alpha: 0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_rounded, size: 52, color: AppColors.white),
                    SizedBox(height: 8),
                    Text(
                      'Join an existing apartment',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enter your invite code.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Enter the invite code you received from your roommate or apartment admin.',
                style: AppTypography.body.copyWith(color: AppColors.secondaryText),
              ),

              const SizedBox(height: 20),

              ElliMateTextField(
                label: 'Invite code',
                hint: 'e.g. A4B72K',
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                prefixIcon: Icons.vpn_key_rounded,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _joinApartment(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Invite code is required';
                  if (v.trim().length < 4) return 'Enter a valid invite code';
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.small.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElliMateButton(
                label: 'Join Apartment',
                onPressed: _joinApartment,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
