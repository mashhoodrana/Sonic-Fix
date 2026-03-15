import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final audioServiceProvider = Provider((ref) => AudioService());

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _mockPath;
  bool _isMockRecording = false;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    // For web/mock mode, just simulate recording
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        // In mock mode, just create a fake path
        _isMockRecording = true;
        _mockPath = 'mock_recording_${const Uuid().v4()}.wav';
        return _mockPath!;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${const Uuid().v4()}.wav';
      final path = '${directory.path}/$fileName';

      // Start recording to file
      debugPrint("--- AudioService: Starting record to $path ---");
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav),
          path: path);
      return path;
    } catch (e) {
      // Fallback to mock mode if recording fails
      _isMockRecording = true;
      _mockPath = 'mock_recording_${const Uuid().v4()}.wav';
      return _mockPath!;
    }
  }

  Future<String?> stopRecording() async {
    if (_isMockRecording) {
      _isMockRecording = false;
      return _mockPath;
    }
    return await _recorder.stop();
  }

  Future<void> dispose() async {
    _recorder.dispose();
  }
}
