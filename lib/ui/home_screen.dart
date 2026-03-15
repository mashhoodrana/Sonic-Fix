import 'dart:io'; // <--- ADDED THIS IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../models/chat_message.dart';
import 'widgets/app_drawer.dart';
import 'widgets/user_message_bubble.dart';
import 'widgets/diagnosis_card_bubble.dart';
import 'widgets/recording_wave.dart';
import 'widgets/progressive_loading.dart';
import 'widgets/typing_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Pending Input State
  String? _pendingImagePath;
  bool _isTyping = false;

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
        _pendingImagePath = path;
      });
    }
  }

  void _resetChat() {
      setState(() {
          _messages.clear();
          _pendingImagePath = null;
          // Add Welcome Message
          _messages.add(ChatMessage(
              id: 'init',
              isUser: false,
              text: "Hello! I'm SonicFix, your AI Mechanic. 🛠️\n\nPlease take a photo of the machine, then record the weird sound it's making.",
              timestamp: DateTime.now()
          ));
      });
  }

  @override
  void initState() {
      super.initState();
      // Initial greeting
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetChat());
  }

  Future<void> _handleRecording() async {
    if (_pendingImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📸 Please take a photo first!"))
        );
        return;
    }

    // Check mic permission
    var status = await Permission.microphone.request();
    if (status.isDenied) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Microphone permission required")));
         return;
    }

    final controller = ref.read(recordingControllerProvider.notifier);
    
    // START RECORDING
    await controller.toggleRecording();
    
    if (mounted) {
        // Show Modal Dialog while recording
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: const Text("Listening..."),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const SizedBox(height: 20),
                        const SizedBox(
                            height: 100,
                            child: RecordingWave(isRecording: true)
                        ),
                        const SizedBox(height: 20),
                        Text(
                            "Recording Machine Sound...", 
                            style: TextStyle(color: Theme.of(context).colorScheme.primary)
                        ),
                    ],
                ),
                actions: [
                    TextButton.icon(
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text("STOP & ANALYZE"),
                        onPressed: () async {
                            // CRITICAL FIX: Close dialog first
                            Navigator.pop(ctx); 
                            
                            debugPrint("--- Recording Step: STOPPING ---");
                            // Stop recording logic
                            await controller.toggleRecording(); 
                            
                            // Small delay to ensure file is closed by system
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            // Process
                            _processRecording();
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    )
                ],
            )
        );
    }
  }

  Future<void> _processRecording() async {
      final recordingState = ref.read(recordingControllerProvider);
      
      if (recordingState.path != null && _pendingImagePath != null) {
          final userAudioPath = recordingState.path!;
          final userImagePath = _pendingImagePath!; // Capture local var

          // 1. Add User Message
          final userMsg = ChatMessage(
              id: DateTime.now().toString(),
              isUser: true,
              imagePath: userImagePath,
              audioPath: userAudioPath,
              timestamp: DateTime.now(),
          );
          
          setState(() {
              _messages.add(userMsg);
              _pendingImagePath = null; // Clear pending
              _isTyping = true; // Show loading bubble
          });
          _scrollToBottom();
          
          // 2. VERIFY FILE SIZE
          try {
              final file = File(userAudioPath);
              if (await file.exists()) {
                  final size = await file.length();
                  debugPrint("--- Audio File Verified: ${size} bytes ---");
                  if (size == 0) {
                      throw Exception("Recording is empty. Please check your microphone permissions and try again.");
                  }
              } else {
                  throw Exception("Audio file not found at $userAudioPath");
              }
          } catch (e) {
              debugPrint("--- Recording Error: $e ---");
              setState(() => _isTyping = false);
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("⚠️ $e"), backgroundColor: Colors.red)
                  );
              }
              return;
          }
          
          try {
               // 3. Call API
               debugPrint("--- Starting API Analysis ---");
               final result = await ref.read(recordingControllerProvider.notifier).analyze(imagePath: userImagePath);
               
               if (result != null) {
                   // 3. Add AI Response
                   final aiMsg = ChatMessage(
                       id: DateTime.now().toString(),
                       isUser: false,
                       diagnosisData: result,
                       timestamp: DateTime.now(),
                   );
                   
                   setState(() {
                       _messages.add(aiMsg);
                       _isTyping = false;
                   });
                   _scrollToBottom();
                   
                   // SAVE TO FIRESTORE
                   final user = ref.read(currentUserProvider);
                   if (user != null) {
                       FirebaseFirestore.instance
                           .collection('users')
                           .doc(user.uid)
                           .collection('history')
                           .add({
                               'timestamp': FieldValue.serverTimestamp(),
                               'diagnosis': result,
                               'imagePath': userImagePath, // Note: Local path only suitable for same device
                               'audioPath': userAudioPath,
                           });
                   }
               }
           } catch (e) {
               setState(() => _isTyping = false);
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
           }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("SonicFix AI", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetChat,
                tooltip: "New Chat",
            )
        ],
      ),
      drawer: AppDrawer(
          onNewDiagnosis: _resetChat,
      ),
      body: Column(
        children: [
            // CHAT LIST
            Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                        if (index == _messages.length) {
                             return const Padding(
                                 padding: EdgeInsets.all(16),
                                 child: TypingIndicator(),
                             );
                        }
                        
                        final msg = _messages[index];
                        if (msg.isUser) {
                            return UserMessageBubble(message: msg);
                        } else {
                            if (msg.text != null) {
                                // Simple text message (Welcome)
                                return Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                            bottomRight: Radius.circular(20),
                                            bottomLeft: Radius.circular(4),
                                        )
                                    ),
                                    child: Text(msg.text!),
                                );
                            }
                            return DiagnosisCardBubble(diagnosis: msg.diagnosisData!);
                        }
                    },
                ),
            ),
            
            // INPUT AREA
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2)
                        )
                    ]
                ),
                child: SafeArea(
                    child: Column(
                        children: [
                            // Pending Image Preview
                            if (_pendingImagePath != null)
                                Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Row(
                                        children: [
                                            ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                    File(_pendingImagePath!), // NOW FIXED WITH IMPORT
                                                    width: 50, height: 50,
                                                    fit: BoxFit.cover,
                                                ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(child: Text("Photo Ready! Tap microphone to record.")),
                                            IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () => setState(() => _pendingImagePath = null),
                                            )
                                        ],
                                    ),
                                ),
                            
                            // Input Controls
                            Row(
                                children: [
                                    // Camera Button
                                    IconButton.filledTonal(
                                        onPressed: _takePhoto,
                                        icon: const Icon(Icons.camera_alt),
                                        iconSize: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Record Button (Center, Expanded)
                                    Expanded(
                                        child: GestureDetector(
                                            onTap: _handleRecording,
                                            child: Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                    color: _pendingImagePath == null 
                                                        ? Colors.grey 
                                                        : Theme.of(context).colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(25),
                                                ),
                                                child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                        const Icon(Icons.mic, color: Colors.white),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                            _pendingImagePath == null 
                                                                ? "Take Photo First" 
                                                                : "Hold / Tap to Record",
                                                            style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold
                                                            )
                                                        )
                                                    ],
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            )
        ],
      ),
    );
  }
}