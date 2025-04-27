import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:todoApp/feature/daily_summary/models/daily_summary.dart';
import 'package:uuid/uuid.dart';

part 'daily_summary_isar.g.dart';

/// Isar model for DailySummary
@collection
class DailySummaryIsar {
  /// Isar ID - auto-incremented
  Id id = Isar.autoIncrement;

  /// Unique string ID (UUID)
  @Index(unique: true, replace: true)
  late String uuid;

  /// Date of the summary
  @Index()
  late DateTime date;

  /// Number of todos completed on this date
  int todoCompletedCount = 0;

  /// Number of todos deleted on this date
  int todoDeletedCount = 0;

  /// Number of todos created on this date
  int todoCreatedCount = 0;

  /// Todo goal for this date
  int todoGoal = 0;

  /// IDs of todos completed on this date
  List<String> completedTodoIds = [];

  /// IDs of todos deleted on this date
  List<String> deletedTodoIds = [];

  /// IDs of todos created on this date
  List<String> createdTodoIds = [];

  /// Additional metrics stored as JSON string
  String? additionalMetricsJson;

  /// Convert from domain model to Isar model
  static DailySummaryIsar fromDomain(DailySummary summary) {
    final summaryIsar = DailySummaryIsar()
      ..uuid = summary.id
      ..date = summary.date
      ..todoCompletedCount = summary.todoCompletedCount
      ..todoDeletedCount = summary.todoDeletedCount
      ..todoCreatedCount = summary.todoCreatedCount
      ..todoGoal = summary.todoGoal
      ..completedTodoIds = summary.completedTodoIds
      ..deletedTodoIds = summary.deletedTodoIds
      ..createdTodoIds = summary.createdTodoIds;

    if (summary.additionalMetrics != null) {
      summaryIsar.additionalMetricsJson = jsonEncode(summary.additionalMetrics);
    }

    return summaryIsar;
  }

  /// Convert to domain model
  DailySummary toDomain() {
    Map<String, dynamic>? additionalMetrics;
    
    if (additionalMetricsJson != null && additionalMetricsJson!.isNotEmpty) {
      additionalMetrics = jsonDecode(additionalMetricsJson!) as Map<String, dynamic>;
    }

    return DailySummary(
      id: uuid,
      date: date,
      todoCompletedCount: todoCompletedCount,
      todoDeletedCount: todoDeletedCount,
      todoCreatedCount: todoCreatedCount,
      todoGoal: todoGoal,
      completedTodoIds: completedTodoIds,
      deletedTodoIds: deletedTodoIds,
      createdTodoIds: createdTodoIds,
      additionalMetrics: additionalMetrics,
    );
  }

  /// Factory method to create a new DailySummaryIsar
  static DailySummaryIsar create({
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

    final summaryIsar = DailySummaryIsar()
      ..uuid = const Uuid().v4()
      ..date = normalizedDate
      ..todoCompletedCount = todoCompletedCount
      ..todoDeletedCount = todoDeletedCount
      ..todoCreatedCount = todoCreatedCount
      ..todoGoal = todoGoal
      ..completedTodoIds = completedTodoIds ?? []
      ..deletedTodoIds = deletedTodoIds ?? []
      ..createdTodoIds = createdTodoIds ?? [];

    if (additionalMetrics != null) {
      summaryIsar.additionalMetricsJson = jsonEncode(additionalMetrics);
    }

    return summaryIsar;
  }
}
