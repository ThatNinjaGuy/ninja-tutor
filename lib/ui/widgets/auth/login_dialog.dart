import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../services/api/api_service.dart';

/// Reusable login dialog that overlays on current screen
/// Appears when authentication errors occur
class LoginDialog extends ConsumerStatefulWidget {
  const LoginDialog({
    super.key,
    this.message,
    this.onLoginSuccess,
  });

  final String? message;
  final VoidCallback? onLoginSuccess;

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _loginSuccess = false;

  late final AnimationController _appearController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = AnimationHelper.createFadeAnimation(
      controller: _appearController,
      begin: 0,
      end: 1,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearController,
        curve: Curves.easeOutBack,
      ),
    );
    _appearController.forward();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = AnimationHelper.createShakeAnimation(
      controller: _shakeController,
      magnitude: 12,
    );

    _emailFocusNode = FocusNode()..addListener(_handleFocusChange);
    _passwordFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _appearController.dispose();
    _shakeController.dispose();
    _emailFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loginSuccess = false;
    });

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Login successful
      if (mounted) {
        setState(() => _loginSuccess = true);
        // Close dialog
        Navigator.of(context).pop();
        
        // Call success callback to refresh current screen
        widget.onLoginSuccess?.call();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.loginSuccessful),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException 
              ? e.message 
              : '${AppStrings.loginFailed}: ${e.toString()}';
        });
        _shakeController.forward(from: 0);
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeAnimation.value;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius * 1.2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: const Icon(Icons.lock_outlined, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.authenticationRequired,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: AnimationHelper.fast,
                        child: Container(
                          key: ValueKey(_errorMessage ?? 'info'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (_errorMessage != null
                                    ? colorScheme.error
                                    : colorScheme.primary)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _errorMessage != null
                                    ? Icons.error_outline
                                    : Icons.info_outline,
                                color: _errorMessage != null
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage ??
                                      widget.message ??
                                      AppStrings.pleaseLoginAgain,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _errorMessage != null
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAnimatedField(
                        context,
                        focusNode: _emailFocusNode,
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: Icon(Icons.email_outlined),
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: AnimatedSwitcher(
                          duration: AnimationHelper.normal,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: _isLoading
                              ? const SizedBox(
                                  key: ValueKey('dialog_loader'),
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : _loginSuccess
                                  ? const Icon(
                                      Icons.check_circle,
                                      key: ValueKey('dialog_success'),
                                    )
                                  : const Text(
                                      AppStrings.signIn,
                                      key: ValueKey('dialog_label'),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: isFocused
            ? AppTheme.createGlow(theme.colorScheme.primary, intensity: 0.22)
            : [],
      ),
      child: child,
    );
  }
}

