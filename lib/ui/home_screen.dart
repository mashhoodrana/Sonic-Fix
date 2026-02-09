import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'widgets/recording_wave.dart';
import 'widgets/diagnosis_sheet.dart';
import 'widgets/gradient_background.dart';
import 'widgets/progressive_loading.dart';
import 'widgets/ai_message_bubble.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  // Doctor's Visit Workflow State
  String? _imagePath;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _takePhoto() async {
    final cameraService = ref.read(cameraServiceProvider);
    final path = await cameraService.takePhoto();
    if (path != null) {
        setState(() {
            _imagePath = path;
            _messages.clear(); // Clear previous session
            _messages.add({
                'text': '📸 Image captured! Now, let me hear the machine.',
                'isUser': false,
            });
        });
    }
  }

  void _resetWorkflow() {
      setState(() {
          _imagePath = null;
          _messages.clear();
      });
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "SonicFix",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
            if (_imagePath != null && !recordingState.isRecording && !recordingState.isProcessing)
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetWorkflow,
                    tooltip: "New Diagnosis",
                )
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Messages area
              Expanded(
                child: _messages.isEmpty && !recordingState.isProcessing
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length +
                            (recordingState.isProcessing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length &&
                              recordingState.isProcessing) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: GeminiStyleLoading(),
                            );
                          }

                          final message = _messages[index];
                          return AiMessageBubble(
                            message: message['text'],
                            isUser: message['isUser'],
                            icon: message['isUser'] ? null : Icons.psychology,
                          );
                        },
                      ),
              ),

              // Recording visualization - ONLY show when recording
              if (recordingState.isRecording)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      RecordingWave(isRecording: true),
                      const SizedBox(height: 16),
                      Text(
                        "Listening to Machine...",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap stop when ready to analyze",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),

              // Bottom action area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.8),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     // Workflow Logic
                     if (_imagePath == null) ...[
                         // STEP 1: TAKE PHOTO
                         Text(
                            "Step 1: Identify Machine",
                            style: Theme.of(context).textTheme.titleMedium,
                         ),
                         const SizedBox(height: 8),
                         Text(
                            "SonicFix needs to see what we're fixing first.",
                             style: Theme.of(context).textTheme.bodySmall,
                         ),
                         const SizedBox(height: 16),
                         GestureDetector(
                             onTap: _takePhoto,
                             child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                 decoration: BoxDecoration(
                                     color: Theme.of(context).colorScheme.primary,
                                     borderRadius: BorderRadius.circular(30),
                                     boxShadow: [
                                         BoxShadow(
                                             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                             blurRadius: 10,
                                             offset: const Offset(0, 4),
                                         )
                                     ]
                                 ),
                                 child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: const [
                                         Icon(Icons.camera_alt, color: Colors.white),
                                         SizedBox(width: 8),
                                         Text("Take Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                     ],
                                 ),
                             ),
                         )
                     ] else ...[
                         // STEP 2: RECORD AUDIO
                         if (!recordingState.isRecording && !recordingState.isProcessing) ...[
                             Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                     Container(
                                         width: 40, height: 40,
                                         margin: const EdgeInsets.only(right: 12),
                                         decoration: BoxDecoration(
                                             borderRadius: BorderRadius.circular(8),
                                             border: Border.all(color: Colors.grey),
                                             image: DecorationImage(
                                                 image: FileImage(File(_imagePath!)),
                                                 fit: BoxFit.cover,
                                             )
                                         ),
                                     ),
                                     const Text("✅ Photo Attached"),
                                 ],
                             ),
                             const SizedBox(height: 16),
                             const Text("Step 2: Record Sound"),
                             const SizedBox(height: 16),
                         ],
                         
                        _buildRecordButton(recordingState),
                     ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/sonicfix.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      size: 60,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "SonicFix Doctor",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Let's check your machine.\nFirst, I need to see it.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton(RecordingState recordingState) {
    return GestureDetector(
      onTap: recordingState.isProcessing
          ? null
          : () async {
              final controller = ref.read(recordingControllerProvider.notifier);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (!recordingState.isRecording) {
                // START RECORDING
                await controller.toggleRecording();

                setState(() {
                  _messages.add({
                    'text': '🎤 Listening for mechanical faults...',
                    'isUser': true,
                  });
                });
                _scrollToBottom();
              } else {
                // STOP AND ANALYZE
                await controller.toggleRecording();

                if (ref.read(recordingControllerProvider).path != null) {
                  try {
                    // PASS IMAGE PATH HERE
                    final result = await controller.analyze(imagePath: _imagePath);
                    
                    if (result != null && result['valid'] == false) {
                        if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Analysis Paused"),
                                content: Text(result['error'] ?? "Sound rejected."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                            );
                        }
                    } else if (result != null && context.mounted) {
                        ref.read(diagnosisResultProvider.notifier).setDiagnosis(result);
                        
                        setState(() {
                          _messages.add({
                            'text': _formatDiagnosisMessage(result),
                            'isUser': false,
                          });
                        });
                        _scrollToBottom();

                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DiagnosisSheet(diagnosis: result),
                            );
                          }
                        });
                    }
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: recordingState.isRecording
                ? [Colors.red, Colors.red.withValues(red: 0.7)]
                : [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (recordingState.isRecording
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          recordingState.isRecording ? Icons.stop : Icons.mic,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatDiagnosisMessage(Map<String, dynamic> diagnosis) {
    // Show visual evidence if available
    final machine = diagnosis['machine_detected'] ?? 'Unknown Machine';
    final problem = diagnosis['problem'] ?? 'Unknown Issue';
    final severity = diagnosis['severity'] ?? 'Unknown';
    final cost = diagnosis['estimated_cost'] ?? 'N/A';

    String severityEmoji = severity.toString().toLowerCase() == 'high'
        ? '🔴'
        : severity.toString().toLowerCase() == 'medium'
            ? '🟡'
            : '🟢';

    return '✅ Diagnosis Complete!\n\n'
        '👀 I see: $machine\n'
        '$severityEmoji Failure: $problem\n\n'
        '💰 Est. Cost: $cost\n'
        'Tap for details →';
  }
}
