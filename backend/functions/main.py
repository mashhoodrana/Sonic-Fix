import os
import json
import tempfile
from firebase_functions import https_fn, options

# --- CONFIGURATION ---
# Global YAMNet Model Caching
yamnet_model_handle = 'https://tfhub.dev/google/yamnet/1'
yamnet_model = None

# Blacklist (Only for logging warnings/context now - DOES NOT BLOCK)
NON_MECHANICAL_BLACKLIST = {
    'speech', 'silence', 'manipulation', 'conversation', 'narration', 'monologue', 
    'music', 'musical instrument', 'song', 'singing', 'whistle'
}

def load_yamnet():
    """Loads the YAMNet model from TF Hub if not already loaded."""
    # Lazy import
    import tensorflow_hub as hub
    global yamnet_model
    if yamnet_model is None:
        print("Loading YAMNet model...")
        yamnet_model = hub.load(yamnet_model_handle)
    return yamnet_model

def ensure_sample_rate(file_path, target_sr=16000):
    """Ensures input audio is 16kHz mono for YAMNet (Optimized)."""
    import numpy as np
    import scipy.io.wavfile as wav
    import scipy.signal
    
    try:
        sr, waveform = wav.read(file_path)
        
        # 1. Convert to Mono
        if len(waveform.shape) > 1:
            waveform = np.mean(waveform, axis=1)
            
        # 2. Normalize to Float32 [-1, 1]
        if waveform.dtype != np.float32:
             # Handle integer types correctly
             if waveform.dtype == np.int16:
                 waveform = waveform.astype(np.float32) / 32768.0
             elif waveform.dtype == np.uint8:
                 waveform = (waveform.astype(np.float32) - 128) / 128.0
             else:
                 waveform = waveform.astype(np.float32)

        # 3. Optimize Duration (Cap at 5 seconds for YAMNet speed/memory)
        # YAMNet only needs short clips to identify texture.
        max_samples = 5 * sr 
        if len(waveform) > max_samples:
            print(f"Truncating audio from {len(waveform)/sr:.1f}s to 5s for YAMNet bottleneck prevention.")
            waveform = waveform[:max_samples]

        # 4. Resample if needed
        if sr != target_sr:
            num_samples = int(len(waveform) * target_sr / sr)
            # Use lower-quality but faster/lighter resampling if needed in future
            waveform = scipy.signal.resample(waveform, num_samples)
            
        return waveform, target_sr
    except Exception as e:
        print(f"YAMNet Preprocessing Error: {e}")
        return None, None

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    timeout_sec=300,
    memory=options.MemoryOption.GB_4,
    region="us-central1",
    secrets=["GOOGLE_API_KEY"]
)
def analyze_audio(req: https_fn.Request) -> https_fn.Response:
    print("Function Version: 4.3.0 - Stable SDK (google-generativeai)")
    temp_audio_path = None
    temp_image_path = None

    try:
        # --- 0. SECURE IMPORTS & SETUP ---
        from firebase_admin import initialize_app, storage, firestore, _apps
        import google.generativeai as genai # The STABLE SDK
        import numpy as np
        import tensorflow as tf
        import time

        if not _apps:
            initialize_app()

        # Initialize Gemini Cleanly
        api_key_raw = os.environ.get("GOOGLE_API_KEY", "")
        if not api_key_raw:
             return https_fn.Response(json.dumps({"error": "Configuration error: Missing API Key"}), status=500, mimetype="application/json")
        
        # Sanitize key to prevent '503 illegal metadata' gRPC error
        api_key = api_key_raw.strip()
        genai.configure(api_key=api_key)

        # Parse Request
        req_json = req.get_json(silent=True)
        if not req_json:
             return https_fn.Response(json.dumps({"error": "Invalid or missing JSON body"}), status=400, mimetype="application/json")

        file_path = req_json.get("file_path")
        if not file_path:
            return https_fn.Response(json.dumps({"error": "Missing file_path"}), status=400, mimetype="application/json")

        print(f"Processing file: {file_path}")
        bucket = storage.bucket()
        blob = bucket.blob(file_path)
        
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
            blob.download_to_filename(temp_audio.name)
            temp_audio_path = temp_audio.name
            
        image_path = req_json.get("image_path")
        if image_path:
            image_blob = bucket.blob(image_path)
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_image:
                image_blob.download_to_filename(temp_image.name)
                temp_image_path = temp_image.name

        if not temp_image_path:
             return https_fn.Response(json.dumps({"error": "Visual context required. Please take a photo of the machine."}), status=400, mimetype="application/json")

        # --- STEP 1: YAMNet Analysis ---
        yamnet_data = {
            "primary_sound": "Sensor Bypass",
            "confidence": 0,
            "all_detected": [],
            "is_blacklisted": False
        }
        
        try:
            print("Starting YAMNet Analysis...")
            model = load_yamnet()
            waveform, sr = ensure_sample_rate(temp_audio_path)
            
            if waveform is not None:
                scores, embeddings, spectrogram = model(waveform)
                class_map_path = model.class_map_path().numpy()
                
                def parse_yamnet_class(line):
                    if isinstance(line, bytes):
                        line = line.decode('utf-8')
                    parts = line.strip().split(',')
                    return parts[-1].strip()

                class_names = [parse_yamnet_class(x) for x in tf.io.gfile.GFile(class_map_path).readlines()]
                class_names = class_names[1:]

                mean_scores = np.mean(scores, axis=0)
                top_n_indices = np.argsort(mean_scores)[::-1][:5]
                
                yamnet_data["all_detected"] = [class_names[i] for i in top_n_indices]
                yamnet_data["primary_sound"] = yamnet_data["all_detected"][0]
                yamnet_data["confidence"] = int(mean_scores[top_n_indices[0]] * 100)
                
                if any(b in yamnet_data["primary_sound"].lower() for b in NON_MECHANICAL_BLACKLIST):
                    yamnet_data["is_blacklisted"] = True
                    print(f"NOTICE: YAMNet detected '{yamnet_data['primary_sound']}'. Flagging for Gemini review.")
                else:
                    print(f"SUCCESS: YAMNet detected mechanical sound: {yamnet_data['primary_sound']}")
                    
        except Exception as e:
            print(f"WARNING: YAMNet failed (continuing to Gemini): {e}")

        # --- STEP 2: Gemini Multimodal Analysis ---
        print("Starting Gemini Analysis (Stable SDK)...")
        
        gemini_inputs = []
        
        # Add Prompt
        prompt = f"""
        Role: You are 'SonicFix', a Senior Mechanical Diagnostics AI.
        
        Task: Perform a "Visual-First" Multimodal Diagnosis.
        1. ANALYZE IMAGE FIRST: Identify the specific machine, component, or appliance in the photo. Look for visual signs of wear, rust, leakage, or damage.
        2. ANALYZE AUDIO SECOND: Listen to the sound to identify the specific failure mode (e.g., 'Grinding' = Bearings, 'Hissing' = Leak, 'Clicking' = Relay/Starter).
        3. FUSE DATA: Correlate the visual identification with the audio texture.
           - IF Audio Sensor says '{yamnet_data['primary_sound']}' ({yamnet_data['confidence']}%), use it as a hint but TRUST YOUR EARS and EYE more.
           - IGNORE non-mechanical sensor labels (like 'Speech' or 'Music') if you clearly see a machine and hear a motor.
        
        Pricing Context (Pakistan Market 2026):
        - Minor Fixes (Belts, capacitors, cleaning): 500 - 2,500 PKR
        - Major Fixes (Motors, Compressors, PCBs): 5,000 - 15,000 PKR
        - Critical (Engine overhaul, replacement): 50,000+ PKR
        
        Output Schema (Return Raw JSON Only):
        {{
            "machine_detected": "string (e.g. 'Haier Split AC Outdoor Unit')",
            "visual_evidence": "string (e.g. 'Visible rust on the fan grill, oil residue on pipes')",
            "audio_evidence": "string (e.g. 'Loud, rhythmic grinding noise correlating with fan rotation')",
            "problem": "string (The technical fault, e.g. 'Fan Motor Bearing Failure')",
            "severity": "Low|Medium|High",
            "fix_steps": ["step 1", "step 2", "step 3"],
            "estimated_cost": "string (e.g. '3500 PKR')",
            "confidence": "High|Medium|Low"
        }}
        """
        gemini_inputs.append(prompt)

        # Upload Audio
        print("Uploading audio to Gemini...")
        audio_file = genai.upload_file(path=temp_audio_path, mime_type="audio/wav")
        while audio_file.state.name == "PROCESSING":
            time.sleep(1)
            audio_file = genai.get_file(audio_file.name)
        gemini_inputs.append(audio_file)
        
        # Upload Image (Mandatory now)
        print("Uploading image to Gemini...")
        image_file = genai.upload_file(path=temp_image_path, mime_type="image/jpeg")
        gemini_inputs.append(image_file)

        # Generate Response (With Retry Logic)
        response = None
        current_model_name = 'gemini-3-flash-preview' # Verified working model
        
        for attempt in range(2): # Try twice
            try:
                print(f"Calling Gemini API ({current_model_name}, Attempt {attempt+1})...")
                model = genai.GenerativeModel(current_model_name)
                response = model.generate_content(
                    gemini_inputs,
                    generation_config=genai.types.GenerationConfig(
                        response_mime_type="application/json"
                    )
                )
                break # Success
            except Exception as e:
                print(f"Gemini API Error (Attempt {attempt+1}): {e}")
                if "429" in str(e) or "Resource exhausted" in str(e):
                    print("Hit Rate Limit. Sleeping for 2 seconds...")
                    time.sleep(2)
                    continue
                else:
                    raise Exception(f"Gemini Analysis Failed: {e}")
        
        if not response:
             raise Exception("Gemini failed after retries.")

        try:
            diagnosis_json = json.loads(response.text)
            # Smart Parser: Handle List vs Dict
            if isinstance(diagnosis_json, list):
                if len(diagnosis_json) > 0:
                    diagnosis_json = diagnosis_json[0]
                else:
                    raise Exception("Empty JSON list returned")
                    
        except Exception as e:
            print(f"JSON Parse Error: {e} | Raw: {response.text}")
            diagnosis_json = {
                "machine_detected": "Unknown Device",
                "visual_evidence": "Could not process image data",
                "audio_evidence": "Could not process audio data",
                "problem": "AI Analysis Failed",
                "severity": "Low",
                "fix_steps": ["Try taking a clearer photo", "Record closer to the sound"],
                "estimated_cost": "Unknown",
                "confidence": "Low"
            }

        diagnosis_json['signal_analysis'] = yamnet_data

        # Save to Firestore
        db = firestore.client()
        db.collection("diagnoses").add({
            "file_path": file_path,
            "diagnosis": diagnosis_json,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "model": "gemini-3-flash-preview+yamnet-fusion"
        })
        
        print(f"Diagnosis Complete: {diagnosis_json['problem']}")
        return https_fn.Response(json.dumps(diagnosis_json), status=200, mimetype="application/json")

    except Exception as e:
        print(f"CRITICAL FUNCTION ERROR: {e}")
        return https_fn.Response(json.dumps({
            "error": "Analysis Failed",
            "details": str(e)
        }), status=500, mimetype="application/json")

    finally:
        try:
            if temp_audio_path and os.path.exists(temp_audio_path):
                os.remove(temp_audio_path)
            if temp_image_path and os.path.exists(temp_image_path):
                os.remove(temp_image_path)
        except Exception:
            pass
