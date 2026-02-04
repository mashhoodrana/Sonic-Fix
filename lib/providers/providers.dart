import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/camera_service.dart';

// State for recording
class RecordingState {
  final bool isRecording;
  final String? path;
  final bool isProcessing;

  RecordingState(
      {this.isRecording = false, this.path, this.isProcessing = false});

  RecordingState copyWith(
      {bool? isRecording, String? path, bool? isProcessing}) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      path: path ?? this.path,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final cameraServiceProvider = Provider((ref) => CameraService());

// Mock mode toggle - set to true to test UI without backend
const bool useMockMode = true;

// Mock API service provider
final mockApiServiceProvider = Provider((ref) => MockApiService());

class RecordingController extends Notifier<RecordingState> {
  @override
  RecordingState build() {
    return RecordingState();
  }

  Future<void> toggleRecording() async {
    final audioService = ref.read(audioServiceProvider);

    if (state.isRecording) {
      final path = await audioService.stopRecording();
      state = state.copyWith(isRecording: false, path: path);
    } else {
      await audioService.startRecording();
      state = state.copyWith(isRecording: true, path: null);
    }
  }

  Future<Map<String, dynamic>?> analyze({String? imagePath}) async {
    if (state.path == null) return null;

    state = state.copyWith(isProcessing: true);
    try {
      if (useMockMode) {
        // Use mock service for testing
        final mockService = ref.read(mockApiServiceProvider);
        final result =
            await mockService.analyzeAudio(state.path!, imagePath: imagePath);
        return result;
      } else {
        // Use real API service
        final apiService = ref.read(apiServiceProvider);
        final result =
            await apiService.analyzeAudio(state.path!, imagePath: imagePath);
        return result;
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> refineWithPhoto() async {
    final cameraService = ref.read(cameraServiceProvider);
    final imagePath = await cameraService.takePhoto();
    if (imagePath != null) {
      try {
        final result = await analyze(imagePath: imagePath);
        ref.read(diagnosisResultProvider.notifier).setDiagnosis(result);
      } catch (e) {
        debugPrint("Error analyzing with photo: $e");
      }
    }
  }
}

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
        RecordingController.new);

// State for Diagnosis Result
class DiagnosisNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setDiagnosis(Map<String, dynamic>? diagnosis) {
    state = diagnosis;
  }
}

final diagnosisResultProvider =
    NotifierProvider<DiagnosisNotifier, Map<String, dynamic>?>(
        DiagnosisNotifier.new);
