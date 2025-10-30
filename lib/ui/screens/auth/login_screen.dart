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

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _loginSuccess = false;

  late final AnimationController _introController;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final AnimationController _errorController;
  late final Animation<double> _shakeAnimation;

  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _introController.dispose();
    _errorController.dispose();
    _emailFocusNode.removeListener(_handleFocusChange);
    _passwordFocusNode.removeListener(_handleFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _cardSlide = AnimationHelper.createSlideAnimation(
      controller: _introController,
      begin: const Offset(0, 0.08),
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
      magnitude: 14,
    );

    _emailFocusNode = FocusNode()..addListener(_handleFocusChange);
    _passwordFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() => setState(() {});

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _errorController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _loginSuccess = false;
    });

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        setState(() => _loginSuccess = true);
        // Check if there's a return route saved
        final authState = ref.read(authStateProvider);
        final returnRoute = authState.returnRoute;
        
        // Clear the return route
        ref.read(authStateProvider.notifier).hideLoginDialog();
        
        if (returnRoute != null && returnRoute.isNotEmpty) {
          // Navigate back to the intended route
          context.go(returnRoute);
        } else {
          // Default to dashboard
          context.go(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        _errorController.forward(from: 0);
        final errorMessage = e is ApiException 
            ? e.message 
            : '${AppStrings.loginFailed}: ${e.toString()}';
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

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_reset, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Reset your password',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your email on the login screen and tap "Send reset link" to receive password recovery instructions. Contact support if you need additional help.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.72),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = !ResponsiveBreakpoints.isSmall(context);
    final maxContentWidth = context.responsiveValue(
      small: 480.0,
      medium: 620.0,
      large: 960.0,
      extraLarge: 1080.0,
    );
    final formMaxWidth = context.responsiveValue(
      small: 420.0,
      medium: 480.0,
      large: 520.0,
      extraLarge: 560.0,
    );
    final cardRadius = context.responsiveValue(
      small: 24.0,
      medium: 26.0,
      large: 28.0,
      extraLarge: 32.0,
    );
    final horizontalPadding = context.responsiveValue(
      small: AppConstants.spacingXL,
      medium: AppConstants.spacingXL,
      large: AppConstants.spacingXL + 8,
      extraLarge: AppConstants.spacingXXL,
    );
    final verticalPadding = context.responsiveValue(
      small: AppConstants.spacingXL,
      medium: AppConstants.spacingXL + 4,
      large: AppConstants.spacingXXL,
      extraLarge: AppConstants.spacingXXL,
    );
    final formInset = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final verticalSpacing = context.responsiveValue(
      small: 18.0,
      medium: 20.0,
      large: 24.0,
      extraLarge: 28.0,
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
                  padding: EdgeInsets.symmetric(
                    vertical: verticalSpacing,
                  ),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: gutter),
                                      child: _buildWelcomePanel(
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
              SizedBox(height: spacing * 1.2),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _emailFocusNode,
                borderRadius: cardRadius - 8,
                                  child: TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.email,
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppStrings.pleaseEnterEmail;
                                      }
                                      if (!value.contains('@')) {
                                        return AppStrings.pleaseEnterValidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
              SizedBox(height: spacing * 0.9),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _passwordFocusNode,
                borderRadius: cardRadius - 8,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
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
                                      return null;
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordSheet,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
              SizedBox(height: spacing * 0.7),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: AnimatedSwitcher(
                                    duration: AnimationHelper.normal,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: _isLoading
                      ? SizedBox(
                          key: const ValueKey('loader'),
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: colorScheme.onPrimary),
                                          )
                                        : _loginSuccess
                                            ? const Icon(
                                                Icons.check_circle,
                                                key: ValueKey('success'),
                                              )
                                            : const Text(
                                                AppStrings.signIn,
                                                key: ValueKey('label'),
                                              ),
                                  ),
                                ),
              SizedBox(height: spacing),
                                SocialLoginButtons(isLoading: _isLoading),
              SizedBox(height: spacing * 0.7),
                                TextButton(
                                  onPressed: () {
                                    context.push('/register');
                                  },
                                  child: const Text(AppStrings.dontHaveAccount),
                                ),
                              ],
                            ),
                          ),
      ),
    );
  }

  Widget _buildWelcomePanel(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double verticalSpacing,
  ) {
    final highlights = <String>[
      'Personalized study plans tailored by your AI mentor',
      'Sync progress across web, tablet, and mobile instantly',
      'Gamified streaks and XP to keep momentum strong',
    ];

    return Padding(
      padding: EdgeInsets.only(
        right: context.responsiveValue(
          small: 0,
          medium: AppConstants.spacingSM,
          large: AppConstants.spacingLG,
          extraLarge: AppConstants.spacingXL,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome back 👋',
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
            'Continue your learning journey with ninja-sharp focus across every device.',
            style: ResponsiveTypography.adjust(
              context,
              theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.75),
                    height: 1.5,
                  ) ??
                  TextStyle(
                    color: colorScheme.onBackground.withOpacity(0.75),
                    height: 1.5,
                  ),
            ),
          ),
          SizedBox(height: verticalSpacing),
          ...highlights.map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: verticalSpacing * 0.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.successGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
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
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double spacing,
  ) {
    final iconSize = context.responsiveValue(
      small: 60.0,
      medium: 68.0,
      large: 74.0,
      extraLarge: 80.0,
    );
    final ringSize = context.responsiveValue(
      small: 76.0,
      medium: 84.0,
      large: 94.0,
      extraLarge: 104.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.createGlow(colorScheme.primary, intensity: 0.4),
          ),
          child: Icon(Icons.school, color: Colors.white, size: iconSize),
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
          AppStrings.signInToAccount,
          style: ResponsiveTypography.adjust(
            context,
            theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ) ??
                TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
            ? AppTheme.createGlow(theme.colorScheme.primary, intensity: 0.25)
            : [],
      ),
      child: child,
    );
  }
}
