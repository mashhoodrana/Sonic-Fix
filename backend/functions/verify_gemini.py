import os
import sys
from google import genai
from google.genai import types

def verify_gemini():
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("❌ GOOGLE_API_KEY environment variable not found.")
        print("Please set it: $env:GOOGLE_API_KEY='your_key'")
        return

    print(f"✅ Found GOOGLE_API_KEY: {api_key[:5]}...{api_key[-5:]}")
    
    try:
        client = genai.Client(api_key=api_key)
        print("✅ Client initialized.")
        
        print("Testing model connection (gemini-2.0-flash-exp)...")
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',
            contents='Hello, say "Connection Successful" if you can hear me.',
        )
        print(f"🤖 Model Response: {response.text}")
        print("✅ Verification Complete!")
        
    except Exception as e:
        print(f"❌ Error connecting to Gemini: {e}")

if __name__ == "__main__":
    verify_gemini()
