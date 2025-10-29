import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../services/api/api_service.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/auth/social_login_buttons.dart';

/// Registration screen for new user signup
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registrationSuccess = false;

  late final AnimationController _introController;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final AnimationController _errorController;
  late final Animation<double> _shakeAnimation;

  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmFocusNode;

  @override
  void dispose() {
    _nameController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _passwordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _introController.dispose();
    _errorController.dispose();
    _nameFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _emailFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _confirmFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _cardSlide = AnimationHelper.createSlideAnimation(
      controller: _introController,
      begin: const Offset(0, 0.12),
      end: Offset.zero,
      curve: AnimationHelper.easeOutCubic,
    );
    _cardFade = AnimationHelper.createFadeAnimation(
      controller: _introController,
      begin: 0,
      end: 1,
      curve: Curves.easeOut,
    );
    _introController.forward();

    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shakeAnimation = AnimationHelper.createShakeAnimation(
      controller: _errorController,
      magnitude: 16,
    );

    _nameFocusNode = FocusNode()..addListener(_handleFocusChange);
    _emailFocusNode = FocusNode()..addListener(_handleFocusChange);
    _passwordFocusNode = FocusNode()..addListener(_handleFocusChange);
    _confirmFocusNode = FocusNode()..addListener(_handleFocusChange);

    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _handleFocusChange() => setState(() {});

  void _onFieldChanged() => setState(() {});

  double get _formCompletion {
    final filledCount = [
      _nameController.text.trim().isNotEmpty,
      _emailController.text.trim().isNotEmpty,
      _passwordController.text.isNotEmpty,
      _confirmPasswordController.text.isNotEmpty,
    ].where((filled) => filled).length;

    return filledCount / 4;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _errorController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _registrationSuccess = false;
    });

    try {
      await ref.read(authProvider.notifier).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        setState(() => _registrationSuccess = true);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.accountCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        
        // Wait for auth state to update (user will be logged in automatically)
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Navigate to library screen so user can explore books for their grade
        if (mounted) {
          context.go(AppRoutes.library);
        }
      }
    } catch (e) {
      if (mounted) {
        _errorController.forward(from: 0);
        final errorMessage = e is ApiException 
            ? e.message 
            : '${AppStrings.registrationFailed}: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          AuthAnimatedBackground(controller: _introController),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final offset = _shakeAnimation.value;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 38),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(theme, colorScheme),
                                const SizedBox(height: 22),
                                _buildProgressIndicator(theme),
                                const SizedBox(height: 24),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _nameFocusNode,
                                  child: TextFormField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.fullName,
                                      prefixIcon: Icon(Icons.person_outline),
                                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.pleaseEnterName;
                                      }
                                      if (value.trim().length < 2) {
                                        return AppStrings.nameTooShort;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _emailFocusNode,
                                  child: TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.email,
                                      prefixIcon: Icon(Icons.email_outlined),
                                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.pleaseEnterEmail;
                                      }
                                      if (!value.contains('@') || !value.contains('.')) {
                                        return AppStrings.pleaseEnterValidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _passwordFocusNode,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.password,
                                      prefixIcon: const Icon(Icons.lock_outlined),
                                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.pleaseEnterPassword;
                                      }
                                      if (value.length < 6) {
                                        return AppStrings.passwordTooShort;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _confirmFocusNode,
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmFocusNode,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleRegister(),
                                    decoration: InputDecoration(
                                      labelText: AppStrings.confirmPassword,
                                      prefixIcon: const Icon(Icons.lock_outlined),
                                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(
                                              () => _obscureConfirmPassword = !_obscureConfirmPassword);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.pleaseConfirmPassword;
                                      }
                                      if (value != _passwordController.text) {
                                        return AppStrings.passwordsDoNotMatch;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildBenefitChips(theme),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  child: AnimatedSwitcher(
                                    duration: AnimationHelper.normal,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: _isLoading
                                        ? const SizedBox(
                                            key: ValueKey('register_loader'),
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.2),
                                          )
                                        : _registrationSuccess
                                            ? const Icon(
                                                Icons.check_circle,
                                                key: ValueKey('register_success'),
                                              )
                                            : const Text(
                                                AppStrings.createAccount,
                                                key: ValueKey('register_label'),
                                              ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SocialLoginButtons(isLoading: _isLoading),
                                const SizedBox(height: 14),
                                TextButton(
                                  onPressed: () {
                                    context.go('/login');
                                  },
                                  child: const Text(AppStrings.alreadyHaveAccount),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.successGradient,
            boxShadow: AppTheme.createGlow(colorScheme.secondary, intensity: 0.35),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 18),
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.createYourAccount,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.72),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Setup progress',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(_formCompletion * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _formCompletion.clamp(0.0, 1.0),
            minHeight: 6,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitChips(ThemeData theme) {
    const benefits = [
      'Personalized library',
      'AI study tips',
      'Gamified streaks',
      'Track progress',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: benefits
          .map(
            (benefit) => Chip(
              label: Text(benefit),
              avatar: const Icon(Icons.check, size: 16),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.09),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAnimatedField(
    BuildContext context, {
    required FocusNode focusNode,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: AnimationHelper.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? AppTheme.createGlow(theme.colorScheme.primary, intensity: 0.22)
            : [],
      ),
      child: child,
    );
  }
}
