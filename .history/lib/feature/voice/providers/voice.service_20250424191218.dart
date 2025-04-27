import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../models/voice_memo.dart';

class VoiceMemoService {
  final SpeechToText _speech = SpeechToText();
  final Record _recorder = Record();
  String _transcript = '';

  Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${dir.path}/memo_$timestamp.m4a';
  }

  Future<void> start() async {
    final path = await _getFilePath();
    await _recorder.start(path: path);
    await _speech.initialize();
    await _speech.listen(onResult: (result) {
      _transcript = result.recognizedWords;
    });
  }

  Future<VoiceMemo> stop() async {
    final audioPath = await _recorder.stop();
    await _speech.stop();
    return VoiceMemo(
      text: _transcript,
      audioPath: audioPath!,
      createdAt: DateTime.now(),
    );
  }
}
