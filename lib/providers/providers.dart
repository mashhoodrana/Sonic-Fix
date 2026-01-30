import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';

// State for recording
class RecordingState {
  final bool isRecording;
  final String? path;
  final bool isProcessing;

  RecordingState({
    this.isRecording = false,
    this.path,
    this.isProcessing = false
  });

  RecordingState copyWith({bool? isRecording, String? path, bool? isProcessing}) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      path: path ?? this.path,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final cameraServiceProvider = Provider((ref) => CameraService());

class RecordingController extends StateNotifier<RecordingState> {
  final AudioService _audioService;
  final ApiService _apiService;
  final CameraService _cameraService;
  final Ref _ref;

  RecordingController(this._audioService, this._apiService, this._cameraService, this._ref) : super(RecordingState());

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      final path = await _audioService.stopRecording();
      state = state.copyWith(isRecording: false, path: path);
    } else {
      await _audioService.startRecording();
      state = state.copyWith(isRecording: true, path: null);
    }
  }

  Future<Map<String, dynamic>?> analyze({String? imagePath}) async {
    if (state.path == null) return null;

    state = state.copyWith(isProcessing: true);
    try {
      final result = await _apiService.analyzeAudio(state.path!, imagePath: imagePath);
      return result;
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> refineWithPhoto() async {
      final imagePath = await _cameraService.takePhoto();
      if (imagePath != null) {
          try {
             final result = await analyze(imagePath: imagePath);
             _ref.read(diagnosisResultProvider.notifier).state = result;
          } catch (e) {
              // Handle error (maybe show via a separate error provider or snackbar controller)
              print("Error analyzing with photo: $e");
          }
      }
  }
}

final recordingControllerProvider = StateNotifierProvider<RecordingController, RecordingState>((ref) {
  return RecordingController(
    ref.watch(audioServiceProvider),
    ref.watch(apiServiceProvider),
    ref.watch(cameraServiceProvider),
    ref,
  );
});

// State for Diagnosis Result
final diagnosisResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
