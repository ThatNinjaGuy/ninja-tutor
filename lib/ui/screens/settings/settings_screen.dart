import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';

/// Settings screen for app preferences and configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isDarkMode = ref.watch(themeModeProvider);
    final userPrefs = ref.watch(userPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // User profile section
          _buildUserProfileSection(context, ref, user.value),
          
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
                  child: user?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.avatarUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
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
                        user?.name ?? 'Guest User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? 'Not signed in',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => _editProfile(context, ref),
                  icon: const Icon(Icons.edit_outlined),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: userPrefs.fontSize > 12
                        ? () => _updateFontSize(ref, userPrefs.fontSize - 2)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: userPrefs.fontSize < 24
                        ? () => _updateFontSize(ref, userPrefs.fontSize + 2)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: readingPrefs.lineHeight > 1.0
                        ? () => _updateLineHeight(ref, readingPrefs.lineHeight - 0.1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: readingPrefs.lineHeight < 2.0
                        ? () => _updateLineHeight(ref, readingPrefs.lineHeight + 0.1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            
            SwitchListTile(
              title: const Text('Auto-scroll'),
              subtitle: const Text('Automatically scroll while reading'),
              value: readingPrefs.autoScroll,
              onChanged: (value) => _updateAutoScroll(ref, value),
            ),
            
            if (readingPrefs.autoScroll)
              ListTile(
                title: const Text('Auto-scroll Speed'),
                subtitle: Text('${readingPrefs.autoScrollSpeed} WPM'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: readingPrefs.autoScrollSpeed > 100
                          ? () => _updateAutoScrollSpeed(ref, readingPrefs.autoScrollSpeed - 25)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: readingPrefs.autoScrollSpeed < 400
                          ? () => _updateAutoScrollSpeed(ref, readingPrefs.autoScrollSpeed + 25)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            
            SwitchListTile(
              title: const Text('Highlight Difficult Words'),
              subtitle: const Text('Highlight words you might find challenging'),
              value: readingPrefs.highlightDifficultWords,
              onChanged: (value) => _updateHighlightDifficultWords(ref, value),
            ),
            
            SwitchListTile(
              title: const Text('Show Definitions on Tap'),
              subtitle: const Text('Display word definitions when tapped'),
              value: readingPrefs.showDefinitionsOnTap,
              onChanged: (value) => _updateShowDefinitionsOnTap(ref, value),
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
                ref.read(userPreferencesProvider.notifier).toggleAiTips();
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
                ref.read(userPreferencesProvider.notifier).toggleNotifications();
              },
            ),
            
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sounds for notifications and feedback'),
              value: userPrefs.soundEnabled,
              onChanged: (value) => _updateSoundEnabled(ref, value),
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

  // Helper methods for updating preferences
  void _updateFontSize(WidgetRef ref, double fontSize) {
    final currentPrefs = ref.read(userPreferencesProvider);
    ref.read(userPreferencesProvider.notifier).updatePreferences(
      currentPrefs.copyWith(fontSize: fontSize),
    );
  }

  void _updateLineHeight(WidgetRef ref, double lineHeight) {
    final currentPrefs = ref.read(userPreferencesProvider);
    final readingPrefs = currentPrefs.readingPreferences.copyWith(
      lineHeight: lineHeight,
    );
    ref.read(userPreferencesProvider.notifier).updateReadingPreferences(readingPrefs);
  }

  void _updateAutoScroll(WidgetRef ref, bool autoScroll) {
    final currentPrefs = ref.read(userPreferencesProvider);
    final readingPrefs = currentPrefs.readingPreferences.copyWith(
      autoScroll: autoScroll,
    );
    ref.read(userPreferencesProvider.notifier).updateReadingPreferences(readingPrefs);
  }

  void _updateAutoScrollSpeed(WidgetRef ref, int speed) {
    final currentPrefs = ref.read(userPreferencesProvider);
    final readingPrefs = currentPrefs.readingPreferences.copyWith(
      autoScrollSpeed: speed,
    );
    ref.read(userPreferencesProvider.notifier).updateReadingPreferences(readingPrefs);
  }

  void _updateHighlightDifficultWords(WidgetRef ref, bool highlight) {
    final currentPrefs = ref.read(userPreferencesProvider);
    final readingPrefs = currentPrefs.readingPreferences.copyWith(
      highlightDifficultWords: highlight,
    );
    ref.read(userPreferencesProvider.notifier).updateReadingPreferences(readingPrefs);
  }

  void _updateShowDefinitionsOnTap(WidgetRef ref, bool show) {
    final currentPrefs = ref.read(userPreferencesProvider);
    final readingPrefs = currentPrefs.readingPreferences.copyWith(
      showDefinitionsOnTap: show,
    );
    ref.read(userPreferencesProvider.notifier).updateReadingPreferences(readingPrefs);
  }

  void _updateSoundEnabled(WidgetRef ref, bool enabled) {
    final currentPrefs = ref.read(userPreferencesProvider);
    ref.read(userPreferencesProvider.notifier).updatePreferences(
      currentPrefs.copyWith(soundEnabled: enabled),
    );
  }

  // Navigation methods
  void _editProfile(BuildContext context, WidgetRef ref) {
    // TODO: Navigate to profile edit screen
    print('Edit profile');
  }

  void _selectLanguage(BuildContext context, WidgetRef ref) {
    // TODO: Show language selection dialog
    print('Select language');
  }

  void _selectAiResponseSpeed(BuildContext context, WidgetRef ref) {
    // TODO: Show AI speed selection dialog
    print('Select AI response speed');
  }

  void _configureAiSuggestions(BuildContext context, WidgetRef ref) {
    // TODO: Show AI suggestions configuration
    print('Configure AI suggestions');
  }

  void _configureStudyReminders(BuildContext context, WidgetRef ref) {
    // TODO: Show study reminders configuration
    print('Configure study reminders');
  }

  void _viewStorageUsage(BuildContext context, WidgetRef ref) {
    // TODO: Show storage usage details
    print('View storage usage');
  }

  void _syncData(BuildContext context, WidgetRef ref) {
    // TODO: Implement data sync
    print('Sync data');
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    // TODO: Implement data export
    print('Export data');
  }

  void _clearCache(BuildContext context, WidgetRef ref) {
    // TODO: Implement cache clearing
    print('Clear cache');
  }

  void _viewPrivacyPolicy(BuildContext context) {
    // TODO: Show privacy policy
    print('View privacy policy');
  }

  void _viewTermsOfService(BuildContext context) {
    // TODO: Show terms of service
    print('View terms of service');
  }

  void _viewHelpSupport(BuildContext context) {
    // TODO: Show help and support
    print('View help and support');
  }

  void _rateApp(BuildContext context) {
    // TODO: Open app store rating
    print('Rate app');
  }
}
