import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'daily_summary.freezed.dart';
part 'daily_summary.g.dart';

/// DailySummary model to store daily activity metrics for todos
@freezed
class DailySummary with _$DailySummary {
  // Private constructor
  const DailySummary._();

  // Main constructor with all fields
  @JsonSerializable(explicitToJson: true)
  const factory DailySummary({
    required String id,
    required DateTime date,
    @Default(0) int todoCompletedCount,
    @Default(0) int todoDeletedCount,
    @Default(0) int todoCreatedCount,
    @Default(0) int todoGoal,
    @Default([]) List<String> completedTodoIds,
    @Default([]) List<String> deletedTodoIds,
    @Default([]) List<String> createdTodoIds,
    Map<String, dynamic>? additionalMetrics,
  }) = _DailySummary;

  // Factory to create from JSON
  factory DailySummary.fromJson(Map<String, dynamic> json) =>
      _$DailySummaryFromJson(json);
}

// Factory to create a new DailySummary
// This is separate from the freezed class to avoid code generation issues
DailySummary createDailySummary({
  required DateTime date,
  int todoCompletedCount = 0,
  int todoDeletedCount = 0,
  int todoCreatedCount = 0,
  int todoGoal = 0,
  List<String>? completedTodoIds,
  List<String>? deletedTodoIds,
  List<String>? createdTodoIds,
  Map<String, dynamic>? additionalMetrics,
}) {
  // Normalize date to midnight for consistent querying
  final normalizedDate = DateTime(date.year, date.month, date.day);

  return DailySummary(
    id: const Uuid().v4(),
    date: normalizedDate,
    todoCompletedCount: todoCompletedCount,
    todoDeletedCount: todoDeletedCount,
    todoCreatedCount: todoCreatedCount,
    todoGoal: todoGoal,
    completedTodoIds: completedTodoIds ?? [],
    deletedTodoIds: deletedTodoIds ?? [],
    createdTodoIds: createdTodoIds ?? [],
    additionalMetrics: additionalMetrics,
  );
}

// Extension to add computed properties to DailySummary
extension DailySummaryExtension on DailySummary {
  // Getters for derived properties
  double get completionRate => todoGoal > 0
      ? todoCompletedCount / todoGoal
      : todoCompletedCount > 0
          ? 1.0
          : 0.0;

  bool get goalAchieved => todoGoal > 0 && todoCompletedCount >= todoGoal;

  double get deletionRate =>
      todoCreatedCount > 0 ? todoDeletedCount / todoCreatedCount : 0.0;

  // Helper methods for date calculations
  int get weekNumber {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  int get dayOfWeek => date.weekday; // 1 = Monday, 7 = Sunday
}
