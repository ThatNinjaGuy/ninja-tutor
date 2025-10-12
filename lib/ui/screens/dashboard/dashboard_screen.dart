import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/content/book_model.dart';
import '../../../models/user/user_model.dart';
import '../../widgets/common/progress_card.dart';
import '../../widgets/common/book_card.dart';
import '../../widgets/common/ai_tip_card.dart';
import '../../widgets/common/empty_state.dart';

/// Dashboard screen showing user overview and recommendations
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authProvider);
    final user = ref.watch(currentUserProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final books = libraryState.myBooks;
    
    // Show login prompt if not authenticated
    if (authUser == null) {
      return _buildLoginPrompt(context, ref);
    }
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: theme.colorScheme.background,
              elevation: 0,
              flexibleSpace: _buildAppBar(context, ref, user.value),
            ),
            
            // Main content
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Progress overview
                  _buildProgressSection(context, ref, user.value),
                  
                  const SizedBox(height: 24),
                  
                  // Continue reading
                  _buildContinueReading(context, ref, books),
                  
                  const SizedBox(height: 24),
                  
                  // AI recommendations
                  _buildAiRecommendations(context, ref),
                  
                  const SizedBox(height: 24),
                  
                  // Quick actions
                  _buildQuickActions(context, ref),
                  
                  const SizedBox(height: 24),
                  
                  // Recent activity
                  _buildRecentActivity(context, ref),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider);
    
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          // User greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                Text(
                  user?.name ?? AppStrings.student,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Theme toggle
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          
          // Settings
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref, UserModel? user) {
    final theme = Theme.of(context);
    final progress = user?.progress;
    
    if (progress == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourProgress,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Progress cards row
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ProgressCard(
                title: 'Books Read',
                value: progress.totalBooksRead.toString(),
                subtitle: 'This month',
                color: AppTheme.readingColor,
                icon: Icons.menu_book,
              ),
              const SizedBox(width: 16),
              
              ProgressCard(
                title: 'Study Streak',
                value: '${progress.currentStreak}',
                subtitle: 'Days',
                color: AppTheme.practiceColor,
                icon: Icons.local_fire_department,
              ),
              const SizedBox(width: 16),
              
              ProgressCard(
                title: 'Quiz Score',
                value: '${(progress.averageQuizScore * 100).toInt()}%',
                subtitle: 'Average',
                color: AppTheme.aiTipColor,
                icon: Icons.quiz,
              ),
              const SizedBox(width: 16),
              
              ProgressCard(
                title: 'Study Time',
                value: '${(progress.totalTimeSpent / 60).toInt()}h',
                subtitle: 'Total',
                color: AppTheme.noteColor,
                icon: Icons.access_time,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReading(BuildContext context, WidgetRef ref, List<BookModel> books) {
    final theme = Theme.of(context);
    
    if (books.isEmpty) {
      return _buildEmptyState(
        context,
        AppStrings.noBooksYet,
        AppStrings.addFirstBook,
        Icons.library_books_outlined,
        () => context.push(AppRoutes.library),
      );
    }
    
    // Get recently read books
    final recentBooks = books.where((book) => book.lastReadAt != null).toList()
      ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.continueReading,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.library),
              child: const Text(AppStrings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentBooks.take(5).length,
            itemBuilder: (context, index) {
              final book = recentBooks[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < recentBooks.length - 1 ? 16 : 0,
                ),
                child: BookCard(
                  book: book,
                  onTap: () => context.push('${AppRoutes.reading}/book/${book.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiRecommendations(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.aiRecommendations,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // AI tip cards
        const AiTipCard(
          title: 'Study Tip',
          content: 'Try the spaced repetition technique: review material at increasing intervals to improve long-term retention.',
          icon: Icons.psychology,
        ),
        const SizedBox(height: 12),
        
        const AiTipCard(
          title: 'Practice Suggestion',
          content: 'Based on your reading pattern, consider taking a quiz on Chapter 3 of your Biology textbook.',
          icon: Icons.lightbulb_outline,
          actionText: 'Start Quiz',
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Add Book',
                icon: Icons.add_circle_outline,
                color: AppTheme.readingColor,
                onTap: () => context.push(AppRoutes.library),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: _QuickActionCard(
                title: 'Practice Quiz',
                icon: Icons.quiz_outlined,
                color: AppTheme.practiceColor,
                onTap: () => context.push(AppRoutes.practice),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'View Notes',
                icon: Icons.sticky_note_2_outlined,
                color: AppTheme.noteColor,
                onTap: () => context.push(AppRoutes.notes),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: _QuickActionCard(
                title: 'Study Timer',
                icon: Icons.timer_outlined,
                color: AppTheme.aiTipColor,
                onTap: () {
                  // TODO: Implement study timer
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentActivity,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Activity items
        _ActivityItem(
          icon: Icons.menu_book,
          title: 'Read Chapter 5',
          subtitle: 'Biology Textbook • 25 minutes ago',
          color: AppTheme.readingColor,
        ),
        const SizedBox(height: 12),
        
        _ActivityItem(
          icon: Icons.quiz,
          title: 'Completed Chemistry Quiz',
          subtitle: 'Score: 85% • 2 hours ago',
          color: AppTheme.practiceColor,
        ),
        const SizedBox(height: 12),
        
        _ActivityItem(
          icon: Icons.highlight,
          title: 'Added 3 highlights',
          subtitle: 'Physics Notes • Yesterday',
          color: AppTheme.noteColor,
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onAction,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onBackground.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: onAction,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  Widget _buildLoginPrompt(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboard)),
      body: EmptyStateWidget(
        icon: Icons.dashboard_outlined,
        title: AppStrings.pleaseLogin,
        subtitle: AppStrings.booksWillBeSaved,
        actionText: AppStrings.signIn,
        onAction: () {
          // Save current route to return to after login
          ref.read(authStateProvider.notifier).setReturnRoute(AppRoutes.dashboard);
          context.go('/login');
        },
      ),
    );
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Activity item widget
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
