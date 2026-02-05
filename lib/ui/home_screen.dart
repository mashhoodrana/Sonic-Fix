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
                        "Recording audio...",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap stop when ready",
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

              // Bottom action area - SINGLE BUTTON
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
                    if (!recordingState.isRecording &&
                        !recordingState.isProcessing)
                      Text(
                        "Tap to start diagnosis",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    if (recordingState.isRecording)
                      Text(
                        "Tap to stop recording",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red.withValues(alpha: 0.8),
                            ),
                      ),
                    const SizedBox(height: 16),
                    _buildRecordButton(recordingState),
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
            "Welcome to SonicFix",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Record the sound and get instant diagnosis",
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

              // Store context before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (!recordingState.isRecording) {
                // Start recording - CLEAR PREVIOUS MESSAGES
                setState(() {
                  _messages.clear(); // Clear previous diagnosis
                });

                await controller.toggleRecording();

                setState(() {
                  _messages.add({
                    'text': '🎤 Recording audio for diagnosis...',
                    'isUser': true,
                  });
                });
                _scrollToBottom();
              } else {
                // Stop recording and analyze
                await controller.toggleRecording();

                if (ref.read(recordingControllerProvider).path != null) {
                  try {
                    final result = await controller.analyze();
                    if (result != null && result['valid'] == false) {
                        if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Analysis Paused"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(result['error'] ?? "Sound rejected."),
                                    const SizedBox(height: 12),
                                    const Text("Detected:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text((result['detected_sounds'] as List?)?.join(", ") ?? "Unknown"),
                                    const SizedBox(height: 12),
                                    Text(result['tip'] ?? "Try getting closer to the source."),
                                  ],
                                ),
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

                        // Show detailed diagnosis sheet
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
    final problem = diagnosis['problem'] ?? 'Unknown Issue';
    final severity = diagnosis['severity'] ?? 'Unknown';
    final cost = diagnosis['estimated_cost'] ?? 'N/A';

    String severityEmoji = severity.toString().toLowerCase() == 'high'
        ? '🔴'
        : severity.toString().toLowerCase() == 'medium'
            ? '🟡'
            : '🟢';

    return '✅ Diagnosis Complete!\n\n'
        '$severityEmoji Issue Detected: $problem\n\n'
        '📊 Severity: ${severity.toString().toUpperCase()}\n'
        '💰 Estimated Cost: $cost\n\n'
        'Tap below to view detailed repair steps →';
  }
}
