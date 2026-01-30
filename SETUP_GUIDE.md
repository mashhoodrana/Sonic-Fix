# Zero to Hero Setup Guide for "Resonate"

It looks like you are starting fresh! Follow this guide step-by-step to get everything running on your Windows machine.

## Step 1: Install Flutter (The "Frontend" Framework)
Since `flutter` command was not found, you need to install it manually.

1.  **Download Flutter SDK**:
    *   Click this link: [Download Flutter for Windows](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_stable.zip)
2.  **Extract**:
    *   Extract the zip file to `C:\src\flutter`.
    *   **Important**: Do NOT put it in "Program Files" (it causes permission issues).
3.  **Add to PATH** (So your terminal knows the `flutter` command):
    *   Press the **Windows Key** and type **"env"**.
    *   Select **"Edit the system environment variables"**.
    *   Click the **"Environment Variables..."** button.
    *   In the top box ("User variables"), look for a variable named **Path**. Select it and click **Edit**.
    *   Click **New** and paste this exact path: `C:\src\flutter\bin`
    *   Click **OK** on all windows to save.
4.  **Verify**:
    *   **Close this VS Code window** completely and reopen it (to load the new settings).
    *   Open the terminal (Ctrl+`) and run:
        ```powershell
        flutter doctor
        ```
    *   If it works, it will show a checklist.

## Step 2: Install Firebase Tools (The "Backend" Tools)
You need Node.js to use Firebase.

1.  **Install Node.js**:
    *   Download the "LTS" version from [nodejs.org](https://nodejs.org/) and install it.
2.  **Install Firebase CLI**:
    *   In your VS Code terminal, run:
        ```powershell
        npm install -g firebase-tools
        ```
3.  **Login**:
    *   Run:
        ```powershell
        firebase login
        ```
    *   Follow the browser prompt to log in with your Google account.

## Step 3: Link Project to Firebase
Now we connect this code to your cloud project.

1.  **Get the FlutterFire CLI**:
    *   In the terminal, run:
        ```powershell
        dart pub global activate flutterfire_cli
        ```
2.  **Configure**:
    *   Run:
        ```powershell
        flutterfire configure
        ```
    *   Use arrow keys to select your Firebase project (create one in [Firebase Console](https://console.firebase.google.com/) if you haven't).
    *   Select `android` (and `web` if you want) when asked for platforms.
    *   This will automatically create a `firebase_options.dart` file for you.

## Step 4: Setup the Gemini API Key
The backend needs your secret key to talk to the AI.

**Option A: The Secure Way (Recommended for Production)**
1.  Navigate to the functions directory:
    ```powershell
    cd backend/functions
    ```
2.  Set the secret:
    ```powershell
    firebase functions:secrets:set GOOGLE_API_KEY
    ```
    *   Paste your key when asked.
3.  **Update code**:
    *   I have set up the code to look for the environment variable `GOOGLE_API_KEY`.
    *   When deploying, you need to tell Firebase to expose this secret to the function.
    *   Run:
        ```powershell
        firebase deploy --only functions
        ```

**Option B: The Quick Local Way (For Testing)**
1.  Create a `.env` file in `backend/functions/`:
    ```
    GOOGLE_API_KEY=your_actual_api_key_here
    ```
2.  The verification script `verify_gemini.py` will read this if you run it locally.

## Step 5: Run the App!
Once everything above is done:

1.  **Go to project root**:
    ```powershell
    cd e:\github\SonicFix
    ```
2.  **Get packages**:
    ```powershell
    flutter pub get
    ```
3.  **Run**:
    ```powershell
    flutter run
    ```
    *   Choose your Android Emulator or Chrome when asked.

---
**Need Help?**
If any command fails, copy the error message and paste it here!
