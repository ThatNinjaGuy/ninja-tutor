import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';

/// Reusable profile menu button with sign in/sign out functionality
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({
    super.key,
    required this.currentRoute,
  });

  /// Current route to return to after login
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final authUser = authState.user;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.account_circle_outlined,
        color: theme.colorScheme.onBackground.withOpacity(0.7),
      ),
      onSelected: (value) {
        if (value == 'signin') {
          ref.read(authStateProvider.notifier).setReturnRoute(currentRoute);
          context.go('/login');
        } else if (value == 'signout') {
          _handleSignOut(ref, context);
        }
      },
      itemBuilder: (context) {
        if (authUser != null) {
          return [
            PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sign Out'),
                ],
              ),
            ),
          ];
        } else {
          return [
            PopupMenuItem<String>(
              value: 'signin',
              child: Row(
                children: [
                  Icon(
                    Icons.login,
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sign In'),
                ],
              ),
            ),
          ];
        }
      },
    );
  }

  Future<void> _handleSignOut(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

