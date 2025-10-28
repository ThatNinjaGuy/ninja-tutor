import 'package:equatable/equatable.dart';

/// Achievement types in the app
enum AchievementType {
  readingMilestone,   // Pages/books read
  quizMastery,        // Quiz scores
  streakRecord,       // Consecutive days
  timeInvested,       // Total study time
  noteCollection,     // Notes created
  perfectScore,       // 100% quiz scores
  earlyBird,          // Reading before 9 AM
  nightOwl,           // Reading after 9 PM
  speedReader,        // Pages per minute
  dedicated,          // Daily usage
}

/// Badge tier levels
enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Achievement model
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final BadgeTier tier;
  final int xpReward;
  final int targetValue;
  final String iconName;
  final DateTime? unlockedAt;
  final int currentProgress;
  
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.tier,
    required this.xpReward,
    required this.targetValue,
    required this.iconName,
    this.unlockedAt,
    this.currentProgress = 0,
  });
  
  bool get isUnlocked => unlockedAt != null;
  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);
  
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    BadgeTier? tier,
    int? xpReward,
    int? targetValue,
    String? iconName,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      tier: tier ?? this.tier,
      xpReward: xpReward ?? this.xpReward,
      targetValue: targetValue ?? this.targetValue,
      iconName: iconName ?? this.iconName,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }
  
  @override
  List<Object?> get props => [
    id, title, description, type, tier, xpReward, 
    targetValue, iconName, unlockedAt, currentProgress,
  ];
}

/// User's gamification profile
class GamificationProfile extends Equatable {
  final int totalXP;
  final int currentLevel;
  final List<Achievement> achievements;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int dailyGoalTarget; // Pages per day
  final int dailyGoalProgress;
  
  const GamificationProfile({
    this.totalXP = 0,
    this.currentLevel = 1,
    this.achievements = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.dailyGoalTarget = 10,
    this.dailyGoalProgress = 0,
  });
  
  /// Calculate XP needed for next level (linear: always 100 XP per level)
  int get xpForNextLevel => 100;
  
  /// Calculate current level progress (XP within current level)
  int get xpInCurrentLevel => totalXP % 100;
  
  /// Calculate progress percentage to next level
  double get levelProgressPercentage {
    return (xpInCurrentLevel / xpForNextLevel).clamp(0.0, 1.0);
  }
  
  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return achievements.where((a) => a.isUnlocked).toList();
  }
  
  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    return achievements.where((a) => !a.isUnlocked).toList();
  }
  
  /// Check if daily goal is met
  bool get isDailyGoalMet => dailyGoalProgress >= dailyGoalTarget;
  
  /// Calculate daily goal percentage
  double get dailyGoalPercentage {
    return (dailyGoalProgress / dailyGoalTarget).clamp(0.0, 1.0);
  }
  
  GamificationProfile copyWith({
    int? totalXP,
    int? currentLevel,
    List<Achievement>? achievements,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? dailyGoalTarget,
    int? dailyGoalProgress,
  }) {
    return GamificationProfile(
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      achievements: achievements ?? this.achievements,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      dailyGoalTarget: dailyGoalTarget ?? this.dailyGoalTarget,
      dailyGoalProgress: dailyGoalProgress ?? this.dailyGoalProgress,
    );
  }
  
  @override
  List<Object?> get props => [
    totalXP, currentLevel, achievements, currentStreak, 
    longestStreak, lastActivityDate, dailyGoalTarget, dailyGoalProgress,
  ];
}

/// XP gain event
class XPGainEvent {
  final int amount;
  final String reason;
  final DateTime timestamp;
  
  const XPGainEvent({
    required this.amount,
    required this.reason,
    required this.timestamp,
  });
}

