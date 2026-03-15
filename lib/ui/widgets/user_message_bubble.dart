import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import 'audio_player_bubble.dart';

class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const UserMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.centerRight,
        child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75
            ),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                ),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                    if (message.text != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                                message.text!, 
                                style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                        ),
                    
                    if (message.imagePath != null)
                         Padding(
                             padding: const EdgeInsets.only(bottom: 8),
                             child: ClipRRect(
                                 borderRadius: BorderRadius.circular(12),
                                 child: Image.file(
                                     File(message.imagePath!),
                                     height: 150,
                                     width: double.infinity,
                                     fit: BoxFit.cover,
                                 ),
                             ),
                         ),

                     if (message.audioPath != null)
                         AudioPlayerBubble(
                             audioPath: message.audioPath!,
                             baseColor: Theme.of(context).colorScheme.onPrimaryContainer
                         ),
                         
                     const SizedBox(height: 4),
                     Text(
                         _formatTime(message.timestamp),
                         style: TextStyle(
                             fontSize: 10,
                             color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5)
                         ),
                     )
                ],
            ),
        ),
    );
  }

  String _formatTime(DateTime time) {
      return "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
  }
}
