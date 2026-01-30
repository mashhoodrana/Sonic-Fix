import os
import json
import tempfile
from firebase_functions import https_fn, options
from firebase_admin import initialize_app, storage, firestore, credentials
from google import genai
from google.genai import types

# Initialize Firebase Admin
initialize_app()

# Initialize Gemini Client
# We will initialize the client inside the function ensuring it retrieves the secret at runtime
# or global scope if the environment variable is available during init (Secrets populate env vars).

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    timeout_sec=300,
    memory_mb=512,
    region="us-central1",
    secrets=["GOOGLE_API_KEY"] # <--- IMPORTANT: Allow access to the secret
)
def analyze_audio(req: https_fn.Request) -> https_fn.Response:
    """
    Analyzes an audio file uploaded to Firebase Storage using Gemini 2.0 Flash.
    Expects a JSON body with: {"file_path": "path/to/audio.wav"}
    """
    # Initialize client here to ensure it gets the fresh secret if cold start
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
         print("Error: GOOGLE_API_KEY not set.")
         return https_fn.Response(json.dumps({"error": "Server configuration error"}), status=500)
    
    client = genai.Client(api_key=api_key)

    try:
        req_json = req.get_json()
        file_path = req_json.get("file_path")
        
        if not file_path:
            return https_fn.Response(json.dumps({"error": "Missing file_path"}), status=400, mimetype="application/json")

        # Download file from Firebase Storage
        bucket = storage.bucket()
        blob = bucket.blob(file_path)
        
        # Create a temporary file to store the audio
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
            blob.download_to_filename(temp_audio.name)
            temp_audio_path = temp_audio.name
            
        # Handle optional image
        image_path = req_json.get("image_path")
        temp_image_path = None
        
        if image_path:
            image_blob = bucket.blob(image_path)
            with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as temp_image:
                image_blob.download_to_filename(temp_image.name)
                temp_image_path = temp_image.name

        try:
            # Upload to Gemini
            audio_upload_result = client.files.upload(file=temp_audio_path)
            
            gemini_contents = [audio_upload_result]
            
            if temp_image_path:
                 image_upload_result = client.files.upload(file=temp_image_path)
                 gemini_contents.append(image_upload_result)
                 
            # Prompt
            base_prompt = """
            You are an expert mechanic. Listen to this audio. 
            Return ONLY a raw JSON object (no markdown formatting) with this schema: 
            { 
                'problem': string, 
                'severity': 'Low'|'Medium'|'High', 
                'fix_steps': list[string], 
                'estimated_cost': string,
                'confidence': 'high'|'low'
            }.
            """
            
            if temp_image_path:
                prompt = base_prompt + " I have also provided an image of the machine/component. Use it to confirm your diagnosis."
            else:
                prompt = base_prompt + " If the audio is unclear or you need visual confirmation, set 'confidence' to 'low'."

            gemini_contents.insert(0, prompt)

            # Generate Content
            response = client.models.generate_content(
                model='gemini-2.0-flash-exp',
                contents=gemini_contents,
                config=types.GenerateContentConfig(
                    response_mime_type='application/json'
                )
            )
            
            # Parse result
            try:
                diagnosis_json = json.loads(response.text)
            except json.JSONDecodeError:
                # Fallback if model returns something else
                print(f"Failed to parse JSON: {response.text}")
                diagnosis_json = {
                    "problem": "Unclear audio analysis",
                    "severity": "Unknown",
                    "fix_steps": ["Try recording again"],
                    "estimated_cost": "Unknown",
                    "raw_response": response.text
                }

            # Save to Firestore
            db = firestore.client()
            doc_ref = db.collection("diagnoses").document()
            doc_ref.set({
                "file_path": file_path,
                "diagnosis": diagnosis_json,
                "timestamp": firestore.SERVER_TIMESTAMP,
                "model": "gemini-2.0-flash-exp"
            })
            
            # Return result
            return https_fn.Response(json.dumps(diagnosis_json), status=200, mimetype="application/json")

        finally:
            # Cleanup temp file
            if os.path.exists(temp_audio_path):
                os.remove(temp_audio_path)
            if temp_image_path and os.path.exists(temp_image_path):
                os.remove(temp_image_path)

    except Exception as e:
        print(f"Error analyzing audio: {e}")
        return https_fn.Response(json.dumps({"error": str(e)}), status=500, mimetype="application/json")
