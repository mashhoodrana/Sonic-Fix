# SonicFix: AI Acoustic Mechanic 🔧🔊

**SonicFix** is a next-generation intelligent diagnostic platform that "hears" and "sees" mechanical failures. By fusing **YAMNet Acoustic Classification** with **Gemini 3.1 Multimodal AI**, it provides professional-grade diagnostics for cars, appliances, and industrial machinery.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Gen2-orange?logo=firebase)
![Gemini](https://img.shields.io/badge/AI-Gemini_3.1_Pro-8E75B2?logo=google-bard)
![YAMNet](https://img.shields.io/badge/Acoustics-YAMNet-red?logo=tensorflow)

---

## 🏗️ The SonicFix Pipeline: "Sensory Fusion"

The system follows a strict **Visual-First, Audio-Second** architecture to ensure maximum accuracy.

```mermaid
graph TD
    %% Frontend
    User["Flutter Chat UI"] -->|"1. Snap Photo (Mandatory)"| Storage["Firebase Storage"]
    User -->|"2. Record Audio (5s Clip)"| Storage
    User -->|"3. Trigger Analysis"| CloudFn["Cloud Function (Python)"]

    %% Backend Pre-processing
    subgraph "Intelligent Pre-processing"
        CloudFn -->|"Resample 16kHz"| YAMNet["YAMNet Classifier"]
        YAMNet -->|"Mechanical Check"| Blacklist{"Is it Speech/Music?"}
        Blacklist -- "Yes" --> Flag["Flag for Gemini Context"]
        Blacklist -- "No" --> Signal["Signal Extraction"]
    end

    %% AI Fusion
    subgraph "Multimodal Fusion Loop"
        Signal --> Fusion["Gemini 3.1 Multimodal Engine"]
        Flag --> Fusion
        Storage -->|"Image + Audio Injection"| Fusion
        
        Fusion -->|"Model A: 3.1 Pro"| Result{"Success?"}
        Result -- "No (503/429)" -->|"Model B: 3.1 Flash"| Result
        Result -- "No" -->|"Model C: Flash Lite"| Result
    end

    %% Delivery
    Result -- "Yes" --> Firestore[("Firestore DB")]
    Firestore -->|"Realtime Update"| User
```

### 🧠 Core Engineering Principles

#### 1. YAMNet Acoustic Bottleneck Prevention
Before passing audio to the heavy AI, we use **YAMNet** (TensorFlow Hub) to classify the sound signature.
- **Signal Extraction**: We resample and normalize to 16kHz mono.
- **Blacklist Filter**: The system detects if the user is accidentally sending speech, music, or silence, providing context to Gemini to "ignore the background noise."
- **Efficiency**: Audio is capped at 5 seconds, ensuring sub-second classification.

#### 2. Multimodal Data Fusion
Unlike traditional apps that use Transcripts (Speech-to-Text), SonicFix injects the **Raw Waveform** directly into Gemini 3.1's native audio buffer.
- **Vision+Audio Correlation**: Gemini identifies the machine visually (e.g., "Haier AC Compressor") and matches the sound texture to known failure modes (e.g., "Rhythmic clicking" suggesting a faulty starter relay).

#### 3. Self-Healing Resilience Loop
The backend implements an automated **Priority Fallback Strategy**:
- 🏆 **Primary**: `gemini-3.1-pro-preview` (Highest accuracy)
- 🥈 **Secondary**: `gemini-3-flash-preview` (Faster response)
- 🥉 **Tertiary**: `gemini-3.1-flash-lite-preview` (Extreme low-latency fallback)

---

## ✨ Features

- **💬 Professional Chat Interface**: 
  - **Dynamic Bubbles**: Interactive messages with embedded image previews and custom **Waveform Audio Players**.
  - **Diagnostic Cards**: Rich, color-coded summaries featuring machine ID, visual evidence, and technical confidence scores.
  
- **🔬 Localized Intelligence**:
  - **Localized Pricing**: Cost estimations are tailored for the **Pakistan Market (2026)**, using actual local labor and part rates (PKR).
  - **Repair Steps**: Actionable, step-by-step guides for technicians.

- **🎨 Premium UX**:
  - **Theme Intelligence**: Fully adaptive Light/Dark modes.
  - **Micro-Animations**: Smooth transitions powered by `animate_do`.

---

## 🚀 Deployment

### Backend (Python 3.11)
```bash
cd backend
firebase deploy --only functions
```

### Frontend (Flutter)
```bash
flutter pub get
flutter run
```

---

