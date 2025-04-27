import 'package:flutter_hive/flutter_hive.dart';
part 'voice_memo.g.dart';

@HiveType(typeId: 0)
class VoiceMemo extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String audioPath;

  @HiveField(2)
  final DateTime createdAt;

  VoiceMemo(
      {required this.text, required this.audioPath, required this.createdAt});
}
