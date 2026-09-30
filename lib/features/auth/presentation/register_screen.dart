import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/providers.dart';
import '../../../shared/widgets/ellimate_button.dart';
import '../../../shared/widgets/ellimate_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  /// True once signUp() succeeds but email confirmation is still pending.
  /// In this state the form is replaced with a "check your email" banner.
  bool _emailConfirmationPending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
          );

      if (!mounted) return;

      // With "Confirm email" enabled in Supabase:
      //   response.user  != null  (user record created)
      //   response.session == null (no active session yet)
      //   currentUser     == null  (SDK only exposes confirmed users)
      //
      // We check the live session rather than the returned user to decide
      // whether the user is immediately authenticated or is awaiting
      // email confirmation.
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // Email confirmation disabled — user is immediately signed in.
        context.go('/apartment/setup');
      } else {
        // Email confirmation required — stay on this page and show banner.
        // Do NOT call context.go() here; any navigation would fail because
        // currentUser is null and the router guard would redirect to /welcome.
        setState(() => _emailConfirmationPending = true);
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage =
            'Unable to create your account. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Column(
        children: [
          // Gradient header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'ElliMate',
                          style: AppTypography.sectionHeading.copyWith(
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.search_outlined,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _emailConfirmationPending
                          ? 'Check your\nemail'
                          : 'Create your\naccount',
                      style: AppTypography.largeHeading.copyWith(
                        color: AppColors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailConfirmationPending
                          ? 'One last step before you join ElliMate.'
                          : 'Join ElliMate and make apartment life easier.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body — either the email-confirmation banner or the signup form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _emailConfirmationPending
                  ? _EmailConfirmationBanner(
                      email: _emailController.text.trim(),
                      onBack: () => setState(() {
                        _emailConfirmationPending = false;
                        _errorMessage = null;
                      }),
                    )
                  : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SmallFeature(icon: Icons.home_outlined),
              _SmallFeature(icon: Icons.key_outlined),
              _SmallFeature(icon: Icons.list_alt_outlined),
              _SmallFeature(icon: Icons.people_outline),
            ],
          ),
          const SizedBox(height: 28),

          ElliMateTextField(
            label: 'Name',
            hint: 'Your name',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            prefixIcon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          ElliMateTextField(
            label: 'Email',
            hint: 'example@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          ElliMateTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passwordController,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _register(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style:
                          AppTypography.small.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),
          ElliMateButton(
            label: 'Create Account',
            onPressed: _register,
            isLoading: _isLoading,
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTypography.small,
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Log in',
                  style: AppTypography.smallMedium.copyWith(
                    color: AppColors.primaryCoral,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryCoral,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Email confirmation banner — shown after a successful signup when Supabase
// requires email verification before activating the session.
// ---------------------------------------------------------------------------
class _EmailConfirmationBanner extends StatelessWidget {
  const _EmailConfirmationBanner({
    required this.email,
    required this.onBack,
  });

  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightCoral,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.primaryCoral,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Account created!',
          style: AppTypography.sectionHeading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Text(
          'We sent a verification link to:',
          style: AppTypography.small,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTypography.smallMedium.copyWith(
            color: AppColors.primaryCoral,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightCoral.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryCoral.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primaryCoral, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please check your inbox and click the link to verify '
                  'your email address before signing in.',
                  style: AppTypography.small,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        ElliMateButton(
          label: 'Go to Log In',
          icon: Icons.login_rounded,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: onBack,
          child: Text(
            'Back to sign up',
            style: AppTypography.smallMedium.copyWith(
              color: AppColors.secondaryText,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallFeature extends StatelessWidget {
  const _SmallFeature({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.lightCoral,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primaryCoral, size: 20),
    );
  }
}
