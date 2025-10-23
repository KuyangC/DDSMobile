@echo off
echo ================================
echo  DDS FIRE ALARM APP BUILDER
echo ================================
echo.

:: Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH!
    echo Please install Flutter first: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo [1/6] Checking Flutter environment...
flutter doctor -v
echo.

echo [2/6] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo [ERROR] Failed to get dependencies!
    pause
    exit /b 1
)
echo.

echo [3/6] Checking for Android SDK...
if not exist "%ANDROID_HOME%" (
    echo [WARNING] ANDROID_HOME not set!
    echo Make sure Android Studio and SDK are installed.
)
echo.

echo [4/6] Building APK (this may take several minutes)...
echo This will create:
echo - build\app\outputs\flutter-apk\app-release.apk
echo.

flutter build apk --release --shrink --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/
if errorlevel 1 (
    echo [ERROR] Failed to build APK!
    pause
    exit /b 1
)

echo.
echo [5/6] Building App Bundle (for Play Store)...
flutter build appbundle --release --shrink
if errorlevel 1 (
    echo [WARNING] Failed to build App Bundle, but APK should be ready.
)
echo.

echo [6/6] Build completed!
echo ================================
echo.
echo APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo App Bundle Location (if created):
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo Installation instructions:
echo 1. Transfer app-release.apk to your Android device
echo 2. Enable "Install from unknown sources" in Settings
echo 3. Open the APK file to install
echo.
echo For Play Store upload, use the .aab file
echo.
pause