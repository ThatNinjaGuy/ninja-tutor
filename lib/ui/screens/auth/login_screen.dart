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

    return Scaffold(
      body: Stack(
        children: [
          AuthAnimatedBackground(controller: _introController),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
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
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(theme, colorScheme),
                                const SizedBox(height: 28),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _emailFocusNode,
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
                                const SizedBox(height: 18),
                                _buildAnimatedField(
                                  context,
                                  focusNode: _passwordFocusNode,
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
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: AnimatedSwitcher(
                                    duration: AnimationHelper.normal,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: _isLoading
                                        ? const SizedBox(
                                            key: ValueKey('loader'),
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2.2),
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
                                const SizedBox(height: 16),
                                SocialLoginButtons(isLoading: _isLoading),
                                const SizedBox(height: 12),
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
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.createGlow(colorScheme.primary, intensity: 0.4),
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 40),
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
          AppStrings.signInToAccount,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
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
  }) {
    final theme = Theme.of(context);
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: AnimationHelper.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? AppTheme.createGlow(theme.colorScheme.primary, intensity: 0.25)
            : [],
      ),
      child: child,
    );
  }
}
