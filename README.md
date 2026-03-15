# SonicFix: AI Acoustic Mechanic 🔧🔊

**SonicFix** is an intelligent mobile application that diagnoses mechanical issues by listening to the sound of your machine (car, appliance, etc.) and analyzing visual evidence. Built with a modern **Chat Interface**, it leverages **Gemini 3 Multimodal AI** to provide professional-grade diagnostics.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Gen2-orange?logo=firebase)
![Gemini](https://img.shields.io/badge/AI-Gemini_3_Native-8E75B2?logo=google-bard)
![Python](https://img.shields.io/badge/Backend-Python-yellow?logo=python)

---

## 🏗️ Architecture: "Smart Hearing" & Resilience

The app uses a **Visual-First, Native Audio** pipeline designed for speed and accuracy.

```mermaid
graph TD
    User["Flutter App (Chat UI)"] -->|Step 1: Photo| Storage["Firebase Storage"]
    User -->|Step 2: Audio (5s Clip)| Storage
    User -->|Step 3: Analyze| CloudFn["Cloud Function (Python)"]
    
    subgraph "Backend Intelligence"
    CloudFn -->|"Truncate Audio"| Opt["Optimization Layer"]
    Opt -->|"Try 1: Fast"| GemFlash["Gemini 3 Flash Preview"]
    GemFlash -.->|"Error 503/429"| GemPro["Gemini 3 Pro Preview"]
    GemPro -.->|"Error"| GemSafe["Gemini 2.0 Flash"]
    end
    
    GemFlash -->|"Diagnosis JSON"| Firestore[("Firestore DB")]
    Firestore -->|"Realtime Update"| User
```

### Key Technical Innovations
1.  **Gemini 3 Native Audio**: Instead of converting audio to text (which loses texture), we upload the raw audio file directly to Gemini 3, allowing it to "hear" grinding, hissing, or knocking.
2.  **Smart Truncation**: To prevent server memory crashes (`503`), audio is automatically capped at the first 5 seconds—sufficient for AI diagnosis but lightweight for the cloud.
3.  **Resilience Loop**: The backend implements a **Self-Healing Fallback Strategy**. If the primary model (`Gemini 3 Flash`) is overloaded, it instantly retries with `Gemini 3 Pro`, ensuring 99.9% uptime.

---

## ✨ Features

- **💬 Modern Chat Interface**: 
  - Diagnose machines via a natural conversation.
  - **User Bubble**: Displays your uploaded photo and a **playable audio player** to review your recording.
  - **AI Bubble**: Renders a rich **Diagnostic Card** with severity badges and fix steps.
  
- **🔬 Multimodal Diagnosis**:
  - **Visual-First**: The AI refuses to guess without seeing the machine first.
  - **Audio-Second**: Correlates the sound texture with the visual component (e.g., "I see a rusty fan, and I hear a rhythmic grinding...").

- **🎨 Adaptive UI**:
  - **Theme Switcher**: Toggle between Light and Dark modes.
  - **Tech Esthetic**: Cyan/Orange/Deep Blue palette.

---

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (ConsumerWidget, Providers)
- **Audio**: `record` (capture), `audioplayers` (playback)
- **UI**: Material 3, `animate_do` (micro-interactions)

### Backend (Serverless)
- **Runtime**: Python 3.11 (Firebase Cloud Functions Gen 2)
- **AI Integration**: `google-genai` SDK (Gemini 3)
- **Database**: Cloud Firestore

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed.
- Firebase CLI installed.
- Physical Device (recommended for Microphone/Camera).

### 1. Backend Setup
```bash
cd backend
# Deploy the optimized Python function
firebase deploy --only functions
```

### 2. Frontend Setup
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🔒 Security & Privacy
- **Direct-to-Cloud**: Audio is processed in memory and cleaned up immediately.
- **API Keys**: Stored securely in Firebase Secrets Manager.

---

*Built for the Gemini 3 Hackathon 2026*
