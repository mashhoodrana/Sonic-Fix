import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'widgets/recording_wave.dart';
import 'widgets/diagnosis_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingControllerProvider);
    final diagnosis = ref.watch(diagnosisResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resonate"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (recordingState.isProcessing)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        "Listening to the engine...",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  )
                else ...[
                  RecordingWave(isRecording: recordingState.isRecording),
                  const SizedBox(height: 48),
                  Text(
                    recordingState.isRecording ? "Listening..." : "Tap to Record",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ]
              ],
            ),
          ),
          // Diagnosis Result Listener
          if (diagnosis != null)
             Positioned.fill(
               child: DraggableScrollableSheet(
                 initialChildSize: 0.6,
                 minChildSize: 0.4,
                 maxChildSize: 0.9,
                 builder: (context, scrollController) {
                   return SingleChildScrollView(
                     controller: scrollController,
                     child: DiagnosisSheet(diagnosis: diagnosis),
                   );
                 },
               ),
             ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: recordingState.isProcessing 
          ? null 
          : () async {
              final controller = ref.read(recordingControllerProvider.notifier);
              await controller.toggleRecording();
              
              // If we just stopped recording, analyze automatically
              if (!ref.read(recordingControllerProvider).isRecording && ref.read(recordingControllerProvider).path != null) {
                  try {
                    final result = await controller.analyze();
                    ref.read(diagnosisResultProvider.notifier).setDiagnosis(result);
                    
                    if (result != null) {
                        showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DiagnosisSheet(diagnosis: result),
                        );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
              }
            },
        backgroundColor: recordingState.isRecording ? Colors.red : Theme.of(context).primaryColor,
        child: Icon(
          recordingState.isRecording ? Icons.stop : Icons.mic,
          size: 48,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
