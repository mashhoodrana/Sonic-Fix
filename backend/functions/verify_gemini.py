import os
import sys
from google import genai
from google.genai import types

def verify_gemini():
    # Try to load from .env if not in environment
    if "GOOGLE_API_KEY" not in os.environ:
        env_path = os.path.join(os.path.dirname(__file__), '.env')
        if os.path.exists(env_path):
            print(f"Reading from {env_path}...")
            with open(env_path, 'r') as f:
                for line in f:
                    if line.strip() and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        if key == "GOOGLE_API_KEY":
                            os.environ[key] = value
                            break

    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("❌ GOOGLE_API_KEY environment variable not found.")
        print("Please set it or create a .env file with GOOGLE_API_KEY=...")
        return

    print(f"✅ Found GOOGLE_API_KEY: {api_key[:5]}...{api_key[-5:]}")
    
    try:
        client = genai.Client(api_key=api_key)
        print("✅ Client initialized.")
        
        print("Testing model connection (gemini-3-flash-preview)...")
        response = client.models.generate_content(
            model='gemini-3-flash-preview',
            contents='Hello, say "Connection Successful" if you can hear me.',
        )
        print(f"🤖 Model Response: {response.text}")
        print("✅ Verification Complete!")
        
    except Exception as e:
        print(f"❌ Error connecting to Gemini: {e}")
        try:
             print("\nListing available models...")
             for m in client.models.list(config={'page_size': 100}):
                  try:
                      # Just print the name and supported methods if possible, or just the object
                      print(f"- {m.name}")
                  except:
                      print(f"- {m}")
        except Exception as list_e:
             print(f"Could not list models: {list_e}")

if __name__ == "__main__":
    verify_gemini()
