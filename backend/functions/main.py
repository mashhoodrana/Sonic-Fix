import os
import json
import tempfile
from firebase_functions import https_fn, options

# Global YAMNet Model Caching
yamnet_model_handle = 'https://tfhub.dev/google/yamnet/1'
yamnet_model = None

# Mechanical Whitelist (Lower case for robust matching)
MECHANICAL_WHITELIST = {
    'engine', 'idling', 'knock', 'motor', 'vehicle', 'clicking', 'squeal', 
    'thump', 'mechanism', 'rattle', 'clatter', 'grinding', 'hiss', 'machinery',
    'pump', 'compressor', 'vibration', 'acceleration', 'revving',
    # Broadening for aggressive mechanical sounds / misclassifications
    'tool', 'drill', 'saw', 'vacuum', 'razor', 'clipper', 'buzzer', 
    'scrape', 'creak', 'rub', 'bang', 'groan', 'tire', 'brake'
}

def load_yamnet():
    """Loads the YAMNet model from TF Hub if not already loaded."""
    import tensorflow_hub as hub
    global yamnet_model
    if yamnet_model is None:
        print("Loading YAMNet model...")
        yamnet_model = hub.load(yamnet_model_handle)
    return yamnet_model

def ensure_sample_rate(file_path, target_sr=16000):
    """
    Ensures input audio is 16kHz mono for YAMNet.
    Returns (waveform_data, sample_rate).
    """
    import numpy as np
    import scipy.io.wavfile as wav
    import scipy.signal
    try:
        sr, waveform = wav.read(file_path)
        
        # Convert to mono if stereo
        if len(waveform.shape) > 1:
            waveform = np.mean(waveform, axis=1)
            
        # Normalize to -1.0 to 1.0 (if int16)
        if waveform.dtype != np.float32:
             waveform = waveform.astype(np.float32) / 32768.0

        # Resample if needed
        if sr != target_sr:
            print(f"Resampling from {sr} to {target_sr}...")
            # Calculate number of samples
            num_samples = int(len(waveform) * target_sr / sr)
            waveform = scipy.signal.resample(waveform, num_samples)
            
        return waveform, target_sr
    except Exception as e:
        print(f"Error processing audio: {e}")
        return None, None

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    timeout_sec=300,
    memory=options.MemoryOption.GB_4, # Increased for TensorFlow
    region="us-central1",
    secrets=["GOOGLE_API_KEY"]
)
def analyze_audio(req: https_fn.Request) -> https_fn.Response:
    print("Function Version: 4.1.0 - 4GB Mem")
    """
    3-Layer Pipeline:
    1. Signal Validation (YAMNet)
    2. Logic Gate (Is it mechanical?)
    3. Contextual Reasoning (Gemini 1.5 Flash)
    """
    # Initialize imports locally to avoid cold-start timeout
    from firebase_admin import initialize_app, storage, firestore, _apps, get_app
    from google import genai
    from google.genai import types
    
    if not _apps:
        initialize_app()

    # Initialize Gemini Client
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
         return https_fn.Response(json.dumps({"error": "Configuration error: Missing API Key"}), status=500)
    
    client = genai.Client(api_key=api_key)

    try:
        req_json = req.get_json()
        file_path = req_json.get("file_path")
        
        if not file_path:
            return https_fn.Response(json.dumps({"error": "Missing file_path"}), status=400, mimetype="application/json")

        # Download file
        bucket = storage.bucket()
        blob = bucket.blob(file_path)
        
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
            blob.download_to_filename(temp_audio.name)
            temp_audio_path = temp_audio.name
            
        image_path = req_json.get("image_path")
        temp_image_path = None
        if image_path:
            image_blob = bucket.blob(image_path)
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_image:
                image_blob.download_to_filename(temp_image.name)
                temp_image_path = temp_image.name

        try:
            # --- LAYER 1: YAMNet Signal Validation ---
            import numpy as np
            import tensorflow as tf
            model = load_yamnet()
            waveform, sr = ensure_sample_rate(temp_audio_path)
            
            if waveform is None:
                 return https_fn.Response(json.dumps({"error": "Audio processing failed"}), status=400)
            
            print(f"Audio Analysis - Shape: {waveform.shape}, Max Amp: {np.max(waveform)}, Mean Amp: {np.mean(waveform)}")

            # Run Inference
            scores, embeddings, spectrogram = model(waveform)
            class_map_path = model.class_map_path().numpy()
            
            # Fix: Parse YAMNet CSV correctly (format: index, mid, display_name)
            def parse_yamnet_class(line):
                parts = line.strip().split(',')
                return parts[-1].strip()

            class_names = [parse_yamnet_class(x) for x in tf.io.gfile.GFile(class_map_path).readlines()]
            class_names = class_names[1:] # Skip header

            
            # Get Top 5 (Increased from 3 to catch 'engine' if it's lower down)
            mean_scores = np.mean(scores, axis=0)
            top_n_indices = np.argsort(mean_scores)[::-1][:5]
            top_sounds = [class_names[i] for i in top_n_indices]
            top_score_conf = int(mean_scores[top_n_indices[0]] * 100)
            
            print(f"YAMNet Detected: {top_sounds} ({top_score_conf}%)")

            # --- LAYER 2: Logic Gate ---
            is_mechanical = False
            detected_mechanical_sounds = []
            
            for sound in top_sounds:
                # Check for substring match (e.g. 'car engine' contains 'engine')
                if any(white in sound for white in MECHANICAL_WHITELIST):
                    is_mechanical = True
                    detected_mechanical_sounds.append(sound)

            if not is_mechanical:
                print(f"Blocked by Logic Gate. Detected: {top_sounds}")
                return https_fn.Response(json.dumps({
                    "valid": False,
                    "error": "No mechanical sound detected.",
                    "detected_sounds": top_sounds,
                    "tip": "Please get closer to the machinery and try again."
                }), status=200, mimetype="application/json") # Return 200 so app handles it gracefully

            # --- LAYER 3: Contextual Reasoning (Gemini) ---
            # Upload actual audio file to Gemini (using the original temp file, not the resampled array)
            audio_upload_result = client.files.upload(file=temp_audio_path)
            
            gemini_contents = [audio_upload_result]
            
            if temp_image_path:
                 image_upload_result = client.files.upload(file=temp_image_path)
                 gemini_contents.append(image_upload_result)
            
            # Construct Contextual Prompt
            primary_sound = top_sounds[0]
            context_str = f"Validated Signal Data: The audio contains {primary_sound} with {top_score_conf}% confidence. Secondary sounds: {top_sounds[1:]}."
            
            base_prompt = f"""
            You are an expert AI Mechanic. The user has uploaded an audio file.
            {context_str}
            
            Using this signal data as ground truth, diagnose the specific mechanical fault.
            Return ONLY a raw JSON object (no markdown) with this schema: 
            {{ 
                'problem': string, 
                'severity': 'Low'|'Medium'|'High', 
                'fix_steps': list[string], 
                'estimated_cost': string,
                'confidence': 'high'|'low'
            }}.
            """

            if temp_image_path:
                prompt = base_prompt + " I have also provided an image. Use it to confirm your diagnosis."
            else:
                prompt = base_prompt + " If the audio is unclear, set 'confidence' to 'low'."

            gemini_contents.insert(0, prompt)

            # Generate Content
            response = client.models.generate_content(
                model='gemini-1.5-flash',
                contents=gemini_contents,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            
            # Parse result
            try:
                diagnosis_json = json.loads(response.text)
            except json.JSONDecodeError:
                diagnosis_json = {
                    "problem": "Unclear analysis",
                    "severity": "Unknown",
                    "fix_steps": ["Try recording again"],
                    "estimated_cost": "Unknown",
                    "raw_response": response.text
                }

            # Enrich with Metadata
            diagnosis_json['signal_analysis'] = {
                'primary_sound': primary_sound,
                'confidence': top_score_conf,
                'all_detected': top_sounds
            }

            # Save to Firestore
            db = firestore.client()
            doc_ref = db.collection("diagnoses").document()
            doc_ref.set({
                "file_path": file_path,
                "diagnosis": diagnosis_json,
                "timestamp": firestore.SERVER_TIMESTAMP,
                "model": "gemini-1.5-flash+yamnet"
            })
            
            return https_fn.Response(json.dumps(diagnosis_json), status=200, mimetype="application/json")

        finally:
            if os.path.exists(temp_audio_path):
                os.remove(temp_audio_path)
            if temp_image_path and os.path.exists(temp_image_path):
                os.remove(temp_image_path)

    except Exception as e:
        print(f"Error: {e}")
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, mimetype="application/json")
