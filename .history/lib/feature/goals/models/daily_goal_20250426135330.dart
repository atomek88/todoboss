import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_goal.freezed.dart';
part 'daily_goal.g.dart';

/// Model representing a daily goal for todos
@freezed
class DailyGoal with _$DailyGoal {
  const DailyGoal._();

  /// Factory constructor with default values
  const factory DailyGoal({
    /// Date of the goal (year, month, day)
    required DateTime date,

    /// Target number of todos to complete
    required int targetCount,

    /// Number of todos completed
    @Default(0) int completedCount,

    /// Whether the goal has been achieved
    @Default(false) bool achieved,

    /// When the goal was achieved (if applicable)
    DateTime? achievedAt,

    /// Whether the celebration has been shown
    @Default(false) bool celebrationShown,
  }) = _DailyGoal;

  /// Create a new daily goal for a specific date
  factory DailyGoal.forDate(DateTime date, int targetCount) {
    // Normalize the date to remove time component
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return DailyGoal(
      date: normalizedDate,
      targetCount: targetCount,
    );
  }

  /// Check if the goal is achieved based on completed count
  bool isAchieved() {
    return completedCount >= targetCount;
  }

  /// Mark the goal as achieved
  DailyGoal markAsAchieved() {
    if (achieved) return this;

    return copyWith(
      achieved: true,
      achievedAt: DateTime.now(),
    );
  }

  /// Mark the celebration as shown
  DailyGoal markCelebrationShown() {
    return copyWith(celebrationShown: true);
  }

  /// Update the completed count
  DailyGoal updateCompletedCount(int count) {
    final updatedGoal = copyWith(completedCount: count);

    // Auto-mark as achieved if target is met
    if (updatedGoal.isAchieved() && !updatedGoal.achieved) {
      return updatedGoal.markAsAchieved();
    }

    return updatedGoal;
  }

  /// Factory for creating from JSON
  factory DailyGoal.fromJson(Map<String, dynamic> json) =>
      _$DailyGoalFromJson(json);
}
