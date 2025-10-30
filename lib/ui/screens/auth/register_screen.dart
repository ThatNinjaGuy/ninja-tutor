import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../core/utils/responsive_layout.dart';
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
    final isWide = !ResponsiveBreakpoints.isSmall(context);
    final maxContentWidth = context.responsiveValue(
      small: 520.0,
      medium: 660.0,
      large: 1000.0,
      extraLarge: 1160.0,
    );
    final formMaxWidth = context.responsiveValue(
      small: 440.0,
      medium: 520.0,
      large: 560.0,
      extraLarge: 600.0,
    );
    final cardRadius = context.responsiveValue(
      small: 26.0,
      medium: 28.0,
      large: 30.0,
      extraLarge: 34.0,
    );
    final horizontalPadding = context.responsiveValue(
      small: AppConstants.spacingXL,
      medium: AppConstants.spacingXL + 4,
      large: AppConstants.spacingXXL,
      extraLarge: AppConstants.spacingXXL,
    );
    final verticalPadding = context.responsiveValue(
      small: AppConstants.spacingXL + 4,
      medium: AppConstants.spacingXXL,
      large: AppConstants.spacingXXL + 4,
      extraLarge: AppConstants.spacingXXL + 8,
    );
    final formInset = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final verticalSpacing = context.responsiveValue(
      small: 20.0,
      medium: 22.0,
      large: 26.0,
      extraLarge: 30.0,
    );
    final gutter = context.responsiveGutter;

    return Scaffold(
      body: Stack(
        children: [
          AuthAnimatedBackground(controller: _introController),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: verticalSpacing),
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
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: gutter),
                                      child: _buildRegisterWelcomePanel(
                                        context,
                                        theme,
                                        colorScheme,
                                        verticalSpacing,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: formMaxWidth),
                                        child: _buildFormCard(
                                          context,
                                          theme,
                                          colorScheme,
                                          cardRadius,
                                          formInset,
                                          verticalSpacing,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: formMaxWidth),
                                child: _buildFormCard(
                                  context,
                                  theme,
                                  colorScheme,
                                  cardRadius,
                                  formInset,
                                  verticalSpacing,
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

  Widget _buildFormCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double cardRadius,
    EdgeInsetsGeometry inset,
    double spacing,
  ) {
    return Card(
                        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
                        ),
      elevation: 10,
                        child: Padding(
        padding: inset,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
              _buildHeader(context, theme, colorScheme, spacing),
              SizedBox(height: spacing * 0.9),
              _buildProgressIndicator(context, theme),
              SizedBox(height: spacing * 0.9),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _nameFocusNode,
                borderRadius: cardRadius - 10,
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
              SizedBox(height: spacing * 0.8),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _emailFocusNode,
                borderRadius: cardRadius - 10,
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
              SizedBox(height: spacing * 0.8),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _passwordFocusNode,
                borderRadius: cardRadius - 10,
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
              SizedBox(height: spacing * 0.8),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _confirmFocusNode,
                borderRadius: cardRadius - 10,
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
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
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
              SizedBox(height: spacing),
              _buildBenefitChips(theme, spacing),
              SizedBox(height: spacing),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  child: AnimatedSwitcher(
                                    duration: AnimationHelper.normal,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: _isLoading
                                        ? const SizedBox(
                                            key: ValueKey('register_loader'),
                          height: 24,
                          width: 24,
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
              SizedBox(height: spacing),
                                SocialLoginButtons(isLoading: _isLoading),
              SizedBox(height: spacing * 0.7),
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
    );
  }

  Widget _buildRegisterWelcomePanel(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double verticalSpacing,
  ) {
    final benefits = <String>[
      'Curate a smart library with AI-powered recommendations',
      'Unlock quizzes, notes, and reading analytics instantly',
      'Collaborate with mentors and track streaks effortlessly',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Create your learning hub',
          style: ResponsiveTypography.adjust(
            context,
            theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ) ??
                TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                  fontSize: 28,
                ),
          ),
        ),
        SizedBox(height: verticalSpacing * 0.4),
        Text(
          'Sign up to sync progress across every device and let Ninja Tutor personalize your study plan.',
          style: ResponsiveTypography.adjust(
            context,
            theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.72),
                  height: 1.5,
                ) ??
                TextStyle(
                  color: colorScheme.onBackground.withOpacity(0.72),
                  height: 1.5,
                ),
          ),
        ),
        SizedBox(height: verticalSpacing),
        ...benefits.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: verticalSpacing * 0.45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: ResponsiveTypography.adjust(
                      context,
                      theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.68),
                            height: 1.45,
                          ) ??
                          TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.68),
                            height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double spacing,
  ) {
    final iconSize = context.responsiveValue(
      small: 62.0,
      medium: 70.0,
      large: 78.0,
      extraLarge: 84.0,
    );
    final ringSize = context.responsiveValue(
      small: 78.0,
      medium: 88.0,
      large: 98.0,
      extraLarge: 110.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.successGradient,
            boxShadow:
                AppTheme.createGlow(colorScheme.secondary, intensity: 0.35),
          ),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
        ),
        SizedBox(height: spacing * 0.7),
        Text(
          AppConstants.appName,
          style: ResponsiveTypography.adjust(
            context,
            theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ) ??
                TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
                  fontSize: 26,
                ),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing * 0.35),
        Text(
          AppStrings.createYourAccount,
          style: ResponsiveTypography.adjust(
            context,
            theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.72),
                  height: 1.4,
                ) ??
                TextStyle(
            color: colorScheme.onSurface.withOpacity(0.72),
                  height: 1.4,
                ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ThemeData theme) {
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
        SizedBox(height: AppConstants.spacingSM),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _formCompletion.clamp(0.0, 1.0),
            minHeight: context.responsiveValue(
              small: 6.0,
              medium: 6.0,
              large: 8.0,
              extraLarge: 10.0,
            ),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitChips(ThemeData theme, double spacing) {
    const benefits = [
      'Personalized library',
      'AI study tips',
      'Gamified streaks',
      'Track progress',
    ];

    final gap = spacing * 0.45;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
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
    double? borderRadius,
  }) {
    final theme = Theme.of(context);
    final isFocused = focusNode.hasFocus;
    final radius = borderRadius ??
        context.responsiveValue(
          small: 18.0,
          medium: 20.0,
          large: 22.0,
          extraLarge: 24.0,
        ) ?? 16.0;

    return AnimatedContainer(
      duration: AnimationHelper.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isFocused
            ? AppTheme.createGlow(theme.colorScheme.primary, intensity: 0.22)
            : [],
      ),
      child: child,
    );
  }
}
