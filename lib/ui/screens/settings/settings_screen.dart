import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';

/// Simple user preferences for fallback
class _SimpleUserPrefs {
  final double fontSize = 16.0;
  final String language = 'en';
  final bool aiTipsEnabled = true;
  final bool notificationsEnabled = true;
  final bool soundEnabled = true;
  final _SimpleReadingPrefs readingPreferences = _SimpleReadingPrefs();
}

class _SimpleReadingPrefs {
  final double lineHeight = 1.5;
  final bool autoScroll = false;
  final int autoScrollSpeed = 200;
  final bool highlightDifficultWords = true;
  final bool showDefinitionsOnTap = true;
}

/// Settings screen for app preferences and configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);
    final isDarkMode = ref.watch(themeModeProvider);
    
    // Simple user preferences fallback
    final userPrefs = _SimpleUserPrefs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
        // User profile section
        _buildUserProfileSection(context, ref, user),
          
          const SizedBox(height: 24),
          
          // Appearance section
          _buildAppearanceSection(context, ref, isDarkMode, userPrefs),
          
          const SizedBox(height: 24),
          
          // Reading preferences section
          _buildReadingPreferencesSection(context, ref, userPrefs),
          
          const SizedBox(height: 24),
          
          // AI & Features section
          _buildAiFeaturesSection(context, ref, userPrefs),
          
          const SizedBox(height: 24),
          
          // Notifications section
          _buildNotificationsSection(context, ref, userPrefs),
          
          const SizedBox(height: 24),
          
          // Data & Storage section
          _buildDataStorageSection(context, ref),
          
          const SizedBox(height: 24),
          
          // About section
          _buildAboutSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(BuildContext context, WidgetRef ref, user) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? AppStrings.notSignedIn,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? AppStrings.loginToAccess,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (user != null)
                  IconButton(
                    onPressed: () => _editProfile(context, ref),
                    icon: const Icon(Icons.edit_outlined),
                  )
                else
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(AppStrings.signIn),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, WidgetRef ref, bool isDarkMode, userPrefs) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            
            ListTile(
              title: const Text('Font Size'),
              subtitle: Text('${userPrefs.fontSize.toInt()}sp'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Font size adjustment coming soon!')),
                );
              },
            ),
            
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_getLanguageName(userPrefs.language)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectLanguage(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingPreferencesSection(BuildContext context, WidgetRef ref, userPrefs) {
    final theme = Theme.of(context);
    final readingPrefs = userPrefs.readingPreferences;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Line Height'),
              subtitle: Text('${readingPrefs.lineHeight}x'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Line height settings coming soon!')),
                );
              },
            ),
            
            SwitchListTile(
              title: const Text('Auto-scroll'),
              subtitle: const Text('Automatically scroll while reading'),
              value: readingPrefs.autoScroll,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-scroll settings coming soon!')),
                );
              },
            ),
            
            if (readingPrefs.autoScroll)
              ListTile(
                title: const Text('Auto-scroll Speed'),
                subtitle: Text('${readingPrefs.autoScrollSpeed} WPM'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auto-scroll speed settings coming soon!')),
                  );
                },
              ),
            
            SwitchListTile(
              title: const Text('Highlight Difficult Words'),
              subtitle: const Text('Highlight words you might find challenging'),
              value: readingPrefs.highlightDifficultWords,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Highlight settings coming soon!')),
                );
              },
            ),
            
            SwitchListTile(
              title: const Text('Show Definitions on Tap'),
              subtitle: const Text('Display word definitions when tapped'),
              value: readingPrefs.showDefinitionsOnTap,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Definition settings coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiFeaturesSection(BuildContext context, WidgetRef ref, userPrefs) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Features',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('AI Tips'),
              subtitle: const Text('Show contextual AI suggestions and tips'),
              value: userPrefs.aiTipsEnabled,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Tips settings coming soon!')),
                );
              },
            ),
            
            ListTile(
              title: const Text('AI Response Speed'),
              subtitle: const Text('Balance between speed and accuracy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectAiResponseSpeed(context, ref),
            ),
            
            ListTile(
              title: const Text('AI Suggestions'),
              subtitle: const Text('Configure what AI can suggest'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _configureAiSuggestions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, WidgetRef ref, userPrefs) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive study reminders and updates'),
              value: userPrefs.notificationsEnabled,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon!')),
                );
              },
            ),
            
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sounds for notifications and feedback'),
              value: userPrefs.soundEnabled,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sound settings coming soon!')),
                );
              },
            ),
            
            ListTile(
              title: const Text('Study Reminders'),
              subtitle: const Text('Set daily study reminders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _configureStudyReminders(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStorageSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data & Storage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Storage Usage'),
              subtitle: const Text('View app storage usage'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _viewStorageUsage(context, ref),
            ),
            
            ListTile(
              title: const Text('Sync Data'),
              subtitle: const Text('Sync your data across devices'),
              trailing: const Icon(Icons.sync),
              onTap: () => _syncData(context, ref),
            ),
            
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your notes and progress'),
              trailing: const Icon(Icons.download),
              onTap: () => _exportData(context, ref),
            ),
            
            ListTile(
              title: const Text('Clear Cache'),
              subtitle: const Text('Free up space by clearing cached data'),
              trailing: const Icon(Icons.clear),
              onTap: () => _clearCache(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Version'),
              subtitle: Text(AppConstants.appVersion),
              trailing: const Icon(Icons.info_outline),
            ),
            
            ListTile(
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _viewPrivacyPolicy(context),
            ),
            
            ListTile(
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _viewTermsOfService(context),
            ),
            
            ListTile(
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.help_outline),
              onTap: () => _viewHelpSupport(context),
            ),
            
            ListTile(
              title: const Text('Rate App'),
              trailing: const Icon(Icons.star_outline),
              onTap: () => _rateApp(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }


  // Navigation methods
  void _editProfile(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    
    if (user == null) {
      // No user signed in, navigate to login
      context.go('/login');
    } else {
      // User signed in, show profile edit dialog or navigate to edit screen
      _showProfileEditDialog(context, ref, user);
    }
  }

  void _showProfileEditDialog(BuildContext context, WidgetRef ref, user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false, // Email usually shouldn't be editable
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Sign out functionality
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pop();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(AppStrings.signOut),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // Update user profile logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.profileUpdatedSuccessfully)),
              );
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _selectLanguage(BuildContext context, WidgetRef ref) {
    // TODO: Show language selection dialog
  }

  void _selectAiResponseSpeed(BuildContext context, WidgetRef ref) {
    // TODO: Show AI speed selection dialog
  }

  void _configureAiSuggestions(BuildContext context, WidgetRef ref) {
    // TODO: Show AI suggestions configuration
  }

  void _configureStudyReminders(BuildContext context, WidgetRef ref) {
    // TODO: Show study reminders configuration
  }

  void _viewStorageUsage(BuildContext context, WidgetRef ref) {
    // TODO: Show storage usage details
  }

  void _syncData(BuildContext context, WidgetRef ref) {
    // TODO: Implement data sync
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    // TODO: Implement data export
  }

  void _clearCache(BuildContext context, WidgetRef ref) {
    // TODO: Implement cache clearing
  }

  void _viewPrivacyPolicy(BuildContext context) {
    // TODO: Show privacy policy
  }

  void _viewTermsOfService(BuildContext context) {
    // TODO: Show terms of service
  }

  void _viewHelpSupport(BuildContext context) {
    // TODO: Show help and support
  }

  void _rateApp(BuildContext context) {
    // TODO: Open app store rating
  }
}
