import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/gamification/achievement_model.dart';

/// Gamification state notifier
class GamificationNotifier extends StateNotifier<GamificationProfile> {
  GamificationNotifier() : super(const GamificationProfile()) {
    _initializeAchievements();
  }

  /// Initialize default achievements
  void _initializeAchievements() {
    final defaultAchievements = [
      // Reading milestones
      const Achievement(
        id: 'first_book',
        title: 'First Steps',
        description: 'Read your first book',
        type: AchievementType.readingMilestone,
        tier: BadgeTier.bronze,
        xpReward: 50,
        targetValue: 1,
        iconName: 'book',
      ),
      const Achievement(
        id: 'page_turner',
        title: 'Page Turner',
        description: 'Read 100 pages',
        type: AchievementType.readingMilestone,
        tier: BadgeTier.silver,
        xpReward: 100,
        targetValue: 100,
        iconName: 'pages',
      ),
      const Achievement(
        id: 'bookworm',
        title: 'Bookworm',
        description: 'Read 5 books',
        type: AchievementType.readingMilestone,
        tier: BadgeTier.gold,
        xpReward: 250,
        targetValue: 5,
        iconName: 'books',
      ),
      
      // Streak achievements
      const Achievement(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Study for 7 days in a row',
        type: AchievementType.streakRecord,
        tier: BadgeTier.silver,
        xpReward: 150,
        targetValue: 7,
        iconName: 'flame',
      ),
      const Achievement(
        id: 'month_master',
        title: 'Month Master',
        description: 'Study for 30 days in a row',
        type: AchievementType.streakRecord,
        tier: BadgeTier.gold,
        xpReward: 500,
        targetValue: 30,
        iconName: 'fire',
      ),
      
      // Quiz achievements
      const Achievement(
        id: 'quiz_beginner',
        title: 'Quiz Novice',
        description: 'Complete 5 quizzes',
        type: AchievementType.quizMastery,
        tier: BadgeTier.bronze,
        xpReward: 75,
        targetValue: 5,
        iconName: 'quiz',
      ),
      const Achievement(
        id: 'perfect_score',
        title: 'Perfectionist',
        description: 'Get 100% on a quiz',
        type: AchievementType.perfectScore,
        tier: BadgeTier.gold,
        xpReward: 200,
        targetValue: 1,
        iconName: 'star',
      ),
      
      // Time achievements
      const Achievement(
        id: 'dedicated_hour',
        title: 'Dedicated Student',
        description: 'Study for 1 hour total',
        type: AchievementType.timeInvested,
        tier: BadgeTier.bronze,
        xpReward: 50,
        targetValue: 60,
        iconName: 'clock',
      ),
      
      // Note achievements
      const Achievement(
        id: 'note_taker',
        title: 'Note Taker',
        description: 'Create 10 notes',
        type: AchievementType.noteCollection,
        tier: BadgeTier.silver,
        xpReward: 100,
        targetValue: 10,
        iconName: 'note',
      ),
    ];
    
    state = state.copyWith(achievements: defaultAchievements);
  }

  /// Award XP and check for level up
  XPGainEvent awardXP(int amount, String reason) {
    final newTotalXP = state.totalXP + amount;
    final newLevel = _calculateLevel(newTotalXP);
    
    final event = XPGainEvent(
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      totalXP: newTotalXP,
      currentLevel: newLevel,
    );
    
    debugPrint('🎮 XP +$amount ($reason) → Total: $newTotalXP, Level: $newLevel');
    return event;
  }

  /// Calculate level from total XP
  /// Formula: 1 level = 100 XP, levels are linear (not progressive)
  int _calculateLevel(int totalXP) {
    // Simple linear leveling: 1 level = 100 XP
    // Level 1: 0-100 XP
    // Level 2: 100-200 XP
    // Level 3: 200-300 XP
    return (totalXP ~/ 100) + 1;
  }
  
  /// Calculate XP from study time in minutes
  /// Formula: 5 hours = 100 XP, so 300 minutes = 100 XP
  /// Therefore: XP = minutes × (100 / 300) = minutes / 3
  int calculateXPFromStudyTime(int studyTimeMinutes) {
    return (studyTimeMinutes / 3).floor();
  }
  
  /// Sync XP from study time
  void syncXPFromStudyTime(int studyTimeMinutes) {
    final newTotalXP = calculateXPFromStudyTime(studyTimeMinutes);
    final newLevel = _calculateLevel(newTotalXP);
    
    state = state.copyWith(
      totalXP: newTotalXP,
      currentLevel: newLevel,
    );
    
    debugPrint('🎮 XP synced from study time: ${studyTimeMinutes}min → $newTotalXP XP, Level: $newLevel');
  }

  /// Update reading streak
  void updateStreak(bool readToday) {
    final now = DateTime.now();
    final lastActivity = state.lastActivityDate;
    
    int newStreak = state.currentStreak;
    
    if (lastActivity == null) {
      // First activity ever
      newStreak = 1;
    } else {
      final daysSinceLastActivity = now.difference(lastActivity).inDays;
      
      if (daysSinceLastActivity == 0 && !readToday) {
        // Same day, no change needed
        return;
      } else if (daysSinceLastActivity == 1 || (daysSinceLastActivity == 0 && readToday)) {
        // Consecutive day
        newStreak = state.currentStreak + 1;
      } else if (daysSinceLastActivity > 1) {
        // Streak broken
        newStreak = 1;
      }
    }
    
    final newLongestStreak = newStreak > state.longestStreak ? newStreak : state.longestStreak;
    
    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
    );
    
    // XP is derived strictly from study time; do not award bonus XP here
    
    debugPrint('🔥 Streak updated: $newStreak days');
  }

  /// Update daily goal progress
  void updateDailyGoal(int pagesRead) {
    final newProgress = state.dailyGoalProgress + pagesRead;
    state = state.copyWith(dailyGoalProgress: newProgress);
    
    // XP is derived strictly from study time; keep goal status only
    if (newProgress >= state.dailyGoalTarget && 
        state.dailyGoalProgress < state.dailyGoalTarget) {
      debugPrint('🎯 Daily goal met!');
    }
  }

  /// Reset daily goal (call at midnight)
  void resetDailyGoal() {
    state = state.copyWith(dailyGoalProgress: 0);
  }

  /// Check and unlock achievements
  List<Achievement> checkAchievements({
    int? booksRead,
    int? pagesRead,
    int? quizzesCompleted,
    int? perfectScores,
    int? notesCreated,
    int? studyTimeMinutes,
  }) {
    final unlockedAchievements = <Achievement>[];
    final updatedAchievements = <Achievement>[];
    
    for (final achievement in state.achievements) {
      if (achievement.isUnlocked) {
        updatedAchievements.add(achievement);
        continue;
      }
      
      int currentProgress = achievement.currentProgress;
      
      // Update progress based on type
      switch (achievement.type) {
        case AchievementType.readingMilestone:
          if (booksRead != null && achievement.id.contains('book')) {
            currentProgress = booksRead;
          } else if (pagesRead != null) {
            currentProgress = pagesRead;
          }
          break;
        case AchievementType.quizMastery:
          if (quizzesCompleted != null) {
            currentProgress = quizzesCompleted;
          }
          break;
        case AchievementType.perfectScore:
          if (perfectScores != null) {
            currentProgress = perfectScores;
          }
          break;
        case AchievementType.noteCollection:
          if (notesCreated != null) {
            currentProgress = notesCreated;
          }
          break;
        case AchievementType.timeInvested:
          if (studyTimeMinutes != null) {
            currentProgress = studyTimeMinutes;
          }
          break;
        case AchievementType.streakRecord:
          currentProgress = state.currentStreak;
          break;
        default:
          break;
      }
      
      // Check if unlocked
      if (currentProgress >= achievement.targetValue) {
        final unlockedAchievement = achievement.copyWith(
          unlockedAt: DateTime.now(),
          currentProgress: currentProgress,
        );
        updatedAchievements.add(unlockedAchievement);
        unlockedAchievements.add(unlockedAchievement);
        
        // XP is derived strictly from study time; unlock without awarding XP
      } else {
        updatedAchievements.add(achievement.copyWith(currentProgress: currentProgress));
      }
    }
    
    if (updatedAchievements.isNotEmpty) {
      state = state.copyWith(achievements: updatedAchievements);
    }
    
    return unlockedAchievements;
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return state.achievements.where((a) => a.type == type).toList();
  }

  /// Get recent unlocked achievements (last 5)
  List<Achievement> getRecentAchievements() {
    final unlocked = state.unlockedAchievements;
    unlocked.sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked.take(5).toList();
  }
}

/// Gamification provider
final gamificationProvider = StateNotifierProvider<GamificationNotifier, GamificationProfile>((ref) {
  return GamificationNotifier();
});

