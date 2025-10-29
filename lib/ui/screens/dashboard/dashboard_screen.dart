import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/unified_library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../core/utils/animation_helper.dart';
import '../../../models/content/book_model.dart';
import '../../../models/user/user_model.dart';
import '../../widgets/common/progress_card.dart';
import '../../widgets/common/ai_tip_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/profile_menu_button.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/loading_state.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/gamification/streak_flame.dart';
import '../../widgets/gamification/xp_progress_bar.dart';
import '../../widgets/reading/reading_interface_mixin.dart';

/// Dashboard screen showing user overview and recommendations
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> 
    with ReadingInterfaceMixin {
  // Current book being read
  BookModel? _currentReadingBook;
  
  // Track if we've already synced gamification to prevent infinite loop
  bool _hasSyncedGamification = false;

  @override
  void initState() {
    super.initState();
    
    // Load only My Books for dashboard (shows recent books)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLibraryProvider.notifier).ensureMyBooksLoaded();
    });
  }
  
  /// Calculate dashboard stats from myBooks data
  Map<String, dynamic> _calculateDashboardStats(List<BookModel> books) {
    int booksRead = 0;
    int totalReadingTimeMinutes = 0;
    List<DateTime> lastReadDates = [];
    
    debugPrint('📊 Calculating dashboard stats for ${books.length} books:');
    
    for (final book in books) {
      final progress = book.progress;
      if (progress != null) {
        debugPrint('   📖 "${book.title}": ${progress.totalPagesRead} pages (60+ sec) / ${book.totalPages} total');
      
        // Count books with more than 1 page read (60+ seconds per page)
        if (progress.totalPagesRead >= 1) {
          booksRead++;
        }
        
        // Sum total reading time
        totalReadingTimeMinutes += progress.timeSpent;
        
        // Collect last read dates for streak calculation
        lastReadDates.add(progress.lastReadAt);
      } else {
        debugPrint('   📖 "${book.title}": No progress data');
      }
    }
    
    // Calculate study streak
    final studyStreak = _calculateStudyStreak(lastReadDates);
    
    debugPrint('📊 Final stats: booksRead=$booksRead, totalTime=${totalReadingTimeMinutes}min, streak=$studyStreak days');
    
    return {
      'books_read': booksRead,
      'study_streak': studyStreak,
      'total_study_time_minutes': totalReadingTimeMinutes,
      'average_quiz_score': 0.0, // TODO: Calculate from quiz results when available
    };
  }
  
  /// Calculate consecutive study streak in days
  int _calculateStudyStreak(List<DateTime> lastReadDates) {
    if (lastReadDates.isEmpty) return 0;
    
    // Sort dates in descending order (most recent first)
    final sortedDates = lastReadDates.toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    
    // Convert to dates without time
    final readDates = sortedDates.map((dt) => 
      DateTime(dt.year, dt.month, dt.day)
    ).toSet().toList()..sort((a, b) => b.compareTo(a));
    
    // Check if user read today or yesterday (streak is still active)
    if (!readDates.contains(todayDate) && !readDates.contains(yesterdayDate)) {
      return 0;
    }
    
    // Count consecutive days
    int streak = 0;
    DateTime currentDate = readDates.contains(todayDate) ? todayDate : yesterdayDate;
    
    while (readDates.contains(currentDate)) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final authUser = authState.user;
    final user = ref.watch(currentUserProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final books = libraryState.myBooks;
    
    // Show loading screen while syncing
    if (authState.isLoading || authState.isSyncing) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.dashboard)),
        body: const LoadingState(
          title: AppStrings.loadingYourLibrary,
          subtitle: 'Fetching your books, notes, and study streaks...',
          progressLabel: 'Syncing progress',
          progress: null,
          tip: 'Tip: Add a quick highlight to keep your streak alive once you hop in!',
        ),
      );
    }
    
    // Show login prompt if not authenticated
    if (authUser == null) {
      return _buildLoginPrompt(context);
    }

    // If in reading mode, show the reading interface from mixin
    if (isReadingMode && _currentReadingBook != null) {
      return buildReadingInterface(_currentReadingBook!);
    }
    
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              expandedHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildAppBar(context, ref, user.value),
              ),
            ),
            
            // Main content - Progress overview
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _buildProgressSection(context, ref, user.value),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Continue reading
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverToBoxAdapter(
                child: libraryState.isLoadingUserLibrary 
                  ? _buildLoadingState(context)
                  : _buildContinueReading(context, ref, books),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // AI recommendations
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _buildAiRecommendations(context, ref),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Quick actions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _buildQuickActions(context, ref),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Recent activity
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _buildRecentActivity(context, ref),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, UserModel? user) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();
    final emoji = _getGreetingEmoji();

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
                AnimatedSwitcher(
                  duration: AnimationHelper.fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Row(
                    key: ValueKey('$emoji$greeting'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        greeting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: AnimationHelper.normal,
                  child: Text(
                    user?.name ?? AppStrings.student,
                    key: ValueKey(user?.name ?? 'guest'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Profile menu (Sign in/Sign out)
          const ProfileMenuButton(currentRoute: AppRoutes.dashboard),
          
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
    final libraryState = ref.watch(unifiedLibraryProvider);
    final books = libraryState.myBooks;
    final gamification = ref.watch(gamificationProvider);
    
    // Show loading state while fetching books
    if (libraryState.isLoadingUserLibrary && books.isEmpty) {
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
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    
    // Calculate stats from books
    final stats = _calculateDashboardStats(books);
    
    // Update gamification state with current stats (only once per widget lifecycle)
    if (mounted && !_hasSyncedGamification) {
      _hasSyncedGamification = true;
      
      // Delay modification until after build is complete
      Future.microtask(() {
        if (!mounted) return;
        
        // Sync XP from total study time (5 hours = 100 XP)
        final studyTimeMinutes = stats['total_study_time_minutes'] ?? 0;
        final gamificationNotifier = ref.read(gamificationProvider.notifier);
        
        // Sync XP from study time
        gamificationNotifier.syncXPFromStudyTime(studyTimeMinutes);
        
        // Update streak if different
        if (stats['study_streak'] != gamification.currentStreak) {
          gamificationNotifier.updateStreak(true);
        }
        
        // Check for achievement unlocks
        gamificationNotifier.checkAchievements(
          booksRead: stats['books_read'] ?? 0,
          pagesRead: books.fold<int>(0, (sum, book) => sum + (book.progress?.totalPagesRead ?? 0)),
          studyTimeMinutes: studyTimeMinutes,
        );
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // XP and Level Section
        PremiumCard(
          padding: const EdgeInsets.all(20),
          accentColor: AppTheme.xpColor,
          child: Row(
            children: [
              // Level badge
              LevelBadge(
                level: gamification.currentLevel,
                size: 80,
                glowIntensity: 0.6,
              ),
              const SizedBox(width: 20),
              
              // Level info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPProgressBar(
                      currentXP: gamification.xpInCurrentLevel,
                      xpForNextLevel: gamification.xpForNextLevel,
                      currentLevel: gamification.currentLevel,
                      showLabel: true,
                      height: 12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${gamification.xpInCurrentLevel}/${gamification.xpForNextLevel} XP to Level ${gamification.currentLevel + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 16),
        
        Text(
          AppStrings.yourProgress,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Progress cards row with modern design
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _AnimatedStatCard(
                label: 'Books Read',
                icon: Icons.menu_book_rounded,
                color: AppTheme.readingColor,
                value: (stats['books_read'] ?? 0).toDouble(),
                formatter: (value) => value.toStringAsFixed(0),
                trendText: gamification.currentLevel > 1
                    ? 'Only ${((gamification.currentLevel + 1) * 5) - (stats['books_read'] ?? 0)} books to next level'
                    : 'Add 1 more book to build momentum',
                detailTitle: 'Recent highlight',
                detailBody: 'Keep exploring new titles to unlock personalized recommendations.',
              ),
              _AnimatedStatCard(
                label: 'Day Streak',
                icon: Icons.local_fire_department_outlined,
                color: AppTheme.streakColor,
                value: gamification.currentStreak.toDouble(),
                formatter: (value) => value.toStringAsFixed(0),
                trendText: gamification.currentStreak >= 3
                    ? '🔥 Amazing consistency!'
                    : 'Read today to keep your streak alive',
                detailTitle: 'Pro tip',
                detailBody: 'Schedule a 10-minute reading block to secure your streak early.',
              ),
              _AnimatedStatCard(
                label: 'Avg Quiz Score',
                icon: Icons.quiz_outlined,
                color: AppTheme.aiTipColor,
                value: (stats['average_quiz_score'] ?? 0).toDouble(),
                formatter: (value) => '${value.toStringAsFixed(0)}%',
                trendText: 'Review incorrect questions to boost retention.',
                detailTitle: 'Next step',
                detailBody: 'Retake last quiz to aim for +5% improvement.',
              ),
              _AnimatedStatCard(
                label: 'Study Time',
                icon: Icons.access_time_rounded,
                color: AppTheme.noteColor,
                value: ((stats['total_study_time_minutes'] ?? 0) / 60).toDouble(),
                formatter: (value) => '${value.toStringAsFixed(1)}h',
                trendText: 'Consistency earns bonus XP!',
                detailTitle: 'Focus tip',
                detailBody: 'Try a focused 25 min Pomodoro session to extend your streak.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReading(BuildContext context, WidgetRef ref, List<BookModel> books) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = AppConstants.defaultPadding * 2; // Total padding on both sides
    final availableWidth = screenWidth - horizontalPadding;
    
    // Define minimum card width for small screens
    const minCardWidth = 120.0;
    const maxCardsPerRow = 7; // View All + 6 books
    const cardSpacing = 8.0;
    
    // Calculate optimal number of cards and card width
    final cardLayout = _calculateOptimalCardLayout(
      availableWidth: availableWidth,
      minCardWidth: minCardWidth,
      maxCards: maxCardsPerRow,
      cardSpacing: cardSpacing,
    );
    
    final cardWidth = cardLayout.cardWidth;
    final cardsToShow = cardLayout.cardsToShow;
    
    if (books.isEmpty) {
      return _buildEmptyState(
        context,
        AppStrings.noBooksYet,
        AppStrings.addFirstBook,
        Icons.library_books_outlined,
        () => context.push(AppRoutes.library),
      );
    }
    
    // Get books for continue reading - prioritize recently read, then recently added
    final continueBooks = books.map((book) {
      // Use lastReadAt if available, otherwise use addedAt
      final sortDate = book.lastReadAt ?? book.addedAt;
      return MapEntry(book, sortDate);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by most recent first
    
    // Take books based on calculated layout
    final displayBooks = continueBooks.take(cardsToShow - 1).map((entry) => entry.key).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.continueReading,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: cardWidth * 1.2, // Optimized height for better proportions
          child: _buildCardsList(
            displayBooks: displayBooks,
            cardWidth: cardWidth,
            cardSpacing: cardSpacing,
            showCarousel: cardLayout.showCarousel,
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
                key: const ValueKey('quick_action_add_book'),
                title: 'Add Book',
                icon: Icons.add_circle_outline,
                color: AppTheme.readingColor,
                onTap: () => context.push(AppRoutes.library),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: _QuickActionCard(
                key: const ValueKey('quick_action_practice_quiz'),
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
                key: const ValueKey('quick_action_view_notes'),
                title: 'View Notes',
                icon: Icons.sticky_note_2_outlined,
                color: AppTheme.noteColor,
                onTap: () => context.push(AppRoutes.notes),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: _QuickActionCard(
                key: const ValueKey('quick_action_study_timer'),
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
          key: const ValueKey('activity_read_chapter'),
          icon: Icons.menu_book,
          title: 'Read Chapter 5',
          subtitle: 'Biology Textbook • 25 minutes ago',
          color: AppTheme.readingColor,
          showConnector: true,
        ),
        const SizedBox(height: 12),
        
        _ActivityItem(
          key: const ValueKey('activity_chemistry_quiz'),
          icon: Icons.quiz,
          title: 'Completed Chemistry Quiz',
          subtitle: 'Score: 85% • 2 hours ago',
          color: AppTheme.practiceColor,
          showConnector: true,
        ),
        const SizedBox(height: 12),
        
        _ActivityItem(
          key: const ValueKey('activity_highlights'),
          icon: Icons.highlight,
          title: 'Added 3 highlights',
          subtitle: 'Physics Notes • Yesterday',
          color: AppTheme.noteColor,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.continueReading,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
                child: SizedBox(
                  width: 120,
                  child: const BookCardSkeleton(isGrid: true),
                ),
              );
            },
          ),
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

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '🌞';
    return '🌙';
  }

  Widget _buildLoginPrompt(BuildContext context) {
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

  void _openBook(BookModel book) {
    setState(() {
      _currentReadingBook = book;
    });
    setReadingMode(true);
    ref.read(currentBookProvider.notifier).state = book;
  }

  /// Calculate optimal card layout for responsive design
  CardLayoutInfo _calculateOptimalCardLayout({
    required double availableWidth,
    required double minCardWidth,
    required int maxCards,
    required double cardSpacing,
  }) {
    // Try to fit maximum cards first
    for (int cards = maxCards; cards >= 3; cards--) {
      final totalSpacing = cardSpacing * (cards - 1);
      final cardWidth = (availableWidth - totalSpacing) / cards;
      
      if (cardWidth >= minCardWidth) {
        return CardLayoutInfo(
          cardWidth: cardWidth,
          cardsToShow: cards,
          showCarousel: false,
        );
      }
    }
    
    // If we can't fit minimum cards, use carousel with minimum width
    return CardLayoutInfo(
      cardWidth: minCardWidth,
      cardsToShow: maxCards,
      showCarousel: true,
    );
  }

  /// Build cards list with optional carousel
  Widget _buildCardsList({
    required List<BookModel> displayBooks,
    required double cardWidth,
    required double cardSpacing,
    required bool showCarousel,
  }) {
    if (showCarousel) {
      return PageView.builder(
        itemCount: displayBooks.length + 1, // +1 for View All card
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildCardAtIndex(index, displayBooks, cardWidth),
          );
        },
      );
    } else {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayBooks.length + 1, // +1 for View All card
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < displayBooks.length ? cardSpacing : 0),
            child: _buildCardAtIndex(index, displayBooks, cardWidth),
          );
        },
      );
    }
  }

  /// Build individual card at given index
  Widget _buildCardAtIndex(int index, List<BookModel> displayBooks, double cardWidth) {
    if (index == 0) {
      return _ViewAllCard(
        width: cardWidth,
        onTap: () => context.push(AppRoutes.reading),
      );
    }
    
    final book = displayBooks[index - 1];
    return _DashboardBookCard(
      key: ValueKey('dashboard_book_${book.id}'),
      book: book,
      width: cardWidth,
      onTap: () => _openBook(book),
    );
  }
}

/// Card layout information for responsive design
class CardLayoutInfo {
  const CardLayoutInfo({
    required this.cardWidth,
    required this.cardsToShow,
    required this.showCarousel,
  });

  final double cardWidth;
  final int cardsToShow;
  final bool showCarousel;
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    super.key,
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
        onTap: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          onTap();
        },
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
    ).animate().fadeIn(duration: 300.ms).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

/// Activity item widget
class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.showConnector = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        if (showConnector)
          Positioned(
            left: 15,
            top: 36,
            bottom: -12,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
        ),
      ],
    );
  }
}

/// View All card widget for continue reading section
class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({
    required this.width,
    required this.onTap,
  });

  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      child: Card(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: InkWell(
          onTap: () {
            // Add haptic feedback
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.library_books,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'View All',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'See all books',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simplified book card for dashboard continue reading section
class _DashboardBookCard extends StatelessWidget {
  const _DashboardBookCard({
    super.key,
    required this.book,
    required this.width,
    required this.onTap,
  });

  final BookModel book;
  final double width;
  final VoidCallback onTap;

  Color _getSubjectColor() {
    switch (book.subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF3B82F6); // Blue
      case 'science':
        return const Color(0xFF10B981); // Green
      case 'english':
        return const Color(0xFFF59E0B); // Amber
      case 'history':
        return const Color(0xFF8B5CF6); // Purple
      case 'computer science':
        return const Color(0xFF06B6D4); // Cyan
      case 'art':
        return const Color(0xFFEC4899); // Pink
      default:
        return AppTheme.readingColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      child: Card(
        elevation: AppConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Book cover - flexible size based on card dimensions
                Container(
                  height: width * 0.7, // 70% of card width for better proportions
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getSubjectColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: book.coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: _getSubjectColor().withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _getSubjectColor(),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildDefaultCover(theme),
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 100),
                          ),
                        )
                      : _buildDefaultCover(theme),
                ),
                
                const SizedBox(height: 6),
                
                // Title and progress section - tightly fitted
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title - max 2 lines
                      Text(
                        book.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          height: 1.2, // Better line height
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Gamified progress bar (energy bar style)
                      if (book.progress != null)
                        _buildProgressBar(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCover(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.menu_book,
        size: 32, // Increased from 20 to 32 for better visibility
        color: _getSubjectColor(),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = book.progressPercentage;
    
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981), // Emerald green
                const Color(0xFF059669), // Darker green
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  const _AnimatedStatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.formatter,
    required this.trendText,
    required this.detailTitle,
    required this.detailBody,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final String Function(double) formatter;
  final String trendText;
  final String detailTitle;
  final String detailBody;

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AnimationHelper.normal,
      margin: const EdgeInsets.only(right: 18),
      width: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        border: Border.all(color: widget.color.withOpacity(0.16)),
        boxShadow: AppTheme.createGlow(
          widget.color,
          intensity: _showDetails ? 0.28 : 0.18,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => _showDetails = !_showDetails),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedCrossFade(
              duration: AnimationHelper.normal,
              crossFadeState: _showDetails
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildFront(theme),
              secondChild: _buildBack(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(widget.icon, color: widget.color),
        ),
        const Spacer(),
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: widget.value),
          duration: const Duration(milliseconds: 720),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              widget.formatter(value),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          widget.trendText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildBack(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.detailTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.detailBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(Icons.touch_app, size: 16, color: widget.color.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              'Tap to go back',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
