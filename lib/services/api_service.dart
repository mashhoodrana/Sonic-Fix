import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  //Cloud Function URL after deployment
  final String _cloudFunctionUrl = 'https://us-central1-sonicfix-e2e1f.cloudfunctions.net/analyze_audio'; 

  Future<Map<String, dynamic>> analyzeAudio(String filePath, {String? imagePath}) async {
    // URL Check removed as it is now configured.

    try {
      // 1. Upload to Firebase Storage
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found at $filePath");
      }

      final fileName = '${const Uuid().v4()}.wav';
      var storageRef = FirebaseStorage.instance
          .ref()
          .child('audio_uploads/$fileName');

      await storageRef.putFile(file);
      final audioFullPath = 'audio_uploads/$fileName';

      String? imageFullPath;
      if (imagePath != null) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
              final imageName = '${const Uuid().v4()}.jpg';
              final imageRef = FirebaseStorage.instance.ref().child('image_uploads/$imageName');
              await imageRef.putFile(imageFile);
              imageFullPath = 'image_uploads/$imageName';
          }
      }

      // 2. Call Cloud Function
      final body = {
          'file_path': audioFullPath,
      };
      if (imageFullPath != null) {
          body['image_path'] = imageFullPath;
      }
      
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }
}
