import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

final audioServiceProvider = Provider((ref) => AudioService());

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission denied');
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${const Uuid().v4()}.wav';
    final path = '${directory.path}/$fileName';

    // Start recording to file
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
    return path;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> dispose() async {
    _recorder.dispose();
  }
}
