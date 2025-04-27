
/// Model representing a daily goal for todos
class DailyGoal {
  /// Date of the goal (year, month, day)
  final DateTime date;
  
  /// Target number of todos to complete
  final int targetCount;
  
  /// Number of todos completed
  final int completedCount;
  
  /// Whether the goal has been achieved
  final bool achieved;
  
  /// When the goal was achieved (if applicable)
  final DateTime? achievedAt;
  
  /// Whether the celebration has been shown
  final bool celebrationShown;

  const DailyGoal({
    required this.date,
    required this.targetCount,
    this.completedCount = 0,
    this.achieved = false,
    this.achievedAt,
    this.celebrationShown = false,
  });

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

  /// Create a copy with some fields replaced
  DailyGoal copyWith({
    DateTime? date,
    int? targetCount,
    int? completedCount,
    bool? achieved,
    DateTime? achievedAt,
    bool? celebrationShown,
  }) {
    return DailyGoal(
      date: date ?? this.date,
      targetCount: targetCount ?? this.targetCount,
      completedCount: completedCount ?? this.completedCount,
      achieved: achieved ?? this.achieved,
      achievedAt: achievedAt ?? this.achievedAt,
      celebrationShown: celebrationShown ?? this.celebrationShown,
    );
  }
  
  /// Create a DailyGoal from JSON
  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      date: DateTime.parse(json['date']),
      targetCount: json['targetCount'],
      completedCount: json['completedCount'] ?? 0,
      achieved: json['achieved'] ?? false,
      achievedAt: json['achievedAt'] != null ? DateTime.parse(json['achievedAt']) : null,
      celebrationShown: json['celebrationShown'] ?? false,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'targetCount': targetCount,
      'completedCount': completedCount,
      'achieved': achieved,
      'achievedAt': achievedAt?.toIso8601String(),
      'celebrationShown': celebrationShown,
    };
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyGoal &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.targetCount == targetCount &&
        other.completedCount == completedCount &&
        other.achieved == achieved &&
        other.celebrationShown == celebrationShown;
  }

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        targetCount,
        completedCount,
        achieved,
        celebrationShown,
      );
}
