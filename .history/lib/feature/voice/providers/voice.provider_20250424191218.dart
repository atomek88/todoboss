import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/voice_memo.dart';
import './voice_memo_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_memo_provider.g.dart';

final voiceMemoServiceProvider = Provider((ref) => VoiceMemoService());

@riverpod
class VoiceMemoList extends _$VoiceMemoList {
  @override
  List<VoiceMemo> build() => [];

  Future<void> loadMemos() async {
    final box = await Hive.openBox<VoiceMemo>('memos');
    state = box.values.toList();
  }

  Future<void> addMemo(VoiceMemo memo) async {
    final box = await Hive.openBox<VoiceMemo>('memos');
    await box.add(memo);
    state = [...state, memo];
  }
}
