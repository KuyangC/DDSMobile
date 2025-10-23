@echo off
REM Flutter Fire Alarm Monitoring APK Build Script for Windows
REM Version 1.0.0
REM Created: October 16, 2025

setlocal enabledelayedexpansion

REM Configuration
set APP_NAME=Flutter Fire Alarm Monitoring
set APP_VERSION=1.0.0
set BUILD_DATE=%date% %time%
set BUILD_DIR=build
set APK_OUTPUT_DIR=%BUILD_DIR%\app\outputs\flutter-apk
set BUNDLE_OUTPUT_DIR=%BUILD_DIR%\app\outputs\bundle\release

REM Print header
echo ============================================
echo   Flutter Fire Alarm Monitoring APK Build
echo ============================================
echo   App Name: %APP_NAME%
echo   Version: %APP_VERSION%
echo   Build Date: %BUILD_DATE%
echo ============================================
echo.

REM Check if script is run as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Please run this script as Administrator for best results
    echo.
)

REM Function to check prerequisites
:check_prerequisites
echo [INFO] Checking prerequisites...

REM Check Flutter installation
flutter --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

REM Check Flutter doctor
echo [INFO] Running Flutter doctor...
flutter doctor --android-licenses >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Flutter doctor found some issues. Please check the output above.
)

REM Check for connected devices
for /f "tokens=2" %%i in ('flutter devices ^| findstr /c "android"') do set device_count=%%i
echo [INFO] Found %device_count% Android device(s)

if %device_count% equ 0 (
    echo [WARNING] No Android devices found. Make sure your device is connected and USB debugging is enabled.
)

echo [SUCCESS] Prerequisites check completed
echo.
goto :eof

REM Function to clean build environment
:clean_build
echo [INFO] Cleaning build environment...

if exist "%BUILD_DIR%" (
    echo [INFO] Removing existing build directory
    rmdir /s /q "%BUILD_DIR%"
)

flutter clean
flutter pub get

echo [SUCCESS] Build environment cleaned
echo.
goto :eof

REM Function to build APK
:build_apk
set build_type=%~1
set target_platform=%~2

echo [INFO] Building APK (%build_type%)...

set build_command=flutter build apk

if "%build_type%"=="release" (
    set build_command=%build_command% --release
) else if "%build_type%"=="debug" (
    set build_command=%build_command% --debug
) else if "%build_type%"=="profile" (
    set build_command=%build_command% --profile
)

if not "%target_platform%"=="" (
    set build_command=%build_command% --target-platform %target_platform%
)

echo [INFO] Running: %build_command%

REM Execute build command
%build_command%

if %errorLevel% neq 0 (
    echo [ERROR] APK build failed
    pause
    exit /b 1
)

echo [SUCCESS] APK build completed successfully
echo.
goto :eof

REM Function to build App Bundle
:build_appbundle
echo [INFO] Building App Bundle for Play Store...

set build_command=flutter build appbundle --release

echo [INFO] Running: %build_command%

REM Execute build command
%build_command%

if %errorLevel% neq 0 (
    echo [ERROR] App Bundle build failed
    pause
    exit /b 1
)

echo [SUCCESS] App Bundle build completed successfully
echo.
goto :eof

REM Function to locate built files
:locate_files
echo [INFO] Locating built files...

if exist "%APK_OUTPUT_DIR%\app-release.apk" (
    echo [SUCCESS] Release APK: %APK_OUTPUT_DIR%\app-release.apk
) else (
    echo [ERROR] Release APK not found at %APK_OUTPUT_DIR%\app-release.apk
)

if exist "%APK_OUTPUT_DIR%\app-debug.apk" (
    echo [SUCCESS] Debug APK: %APK_OUTPUT_DIR%\app-debug.apk
)

if exist "%BUNDLE_OUTPUT_DIR%\app-release.aab" (
    echo [SUCCESS] App Bundle: %BUNDLE_OUTPUT_DIR%\app-release.aab
)

echo.
goto :eof

REM Function to install APK via ADB
:install_apk
set apk_path=%~1

if "%apk_path%"=="" (
    echo [ERROR] APK path is required for installation
    goto :eof
)

if not exist "%apk_path%" (
    echo [ERROR] APK file not found: %apk_path%
    goto :eof
)

echo [INFO] Installing APK via ADB: %apk_path%

REM Check if device is connected
for /f "tokens=2" %%i in ('flutter devices ^| findstr /c "android"') do set device_count=%%i
if %device_count% equ 0 (
    echo [ERROR] No Android devices connected. Please connect your device and enable USB debugging.
    goto :eof
)

REM Get app package name
set package_name=com.example.flutter_application_1

REM Uninstall previous version if exists
adb shell pm list packages ^| findstr "%package_name%" >nul
if %errorLevel% equ 0 (
    echo [INFO] Uninstalling previous version...
    adb uninstall "%package_name%"
)

REM Install APK
adb install "%apk_path%"

if %errorLevel% neq 0 (
    echo [ERROR] APK installation failed
    goto :eof
)

echo [SUCCESS] APK installed successfully
echo.
goto :eof

REM Function to show build summary
:show_summary
echo ============================================
echo   Build Summary
echo ============================================
echo   App Name: %APP_NAME%
echo   Version: %APP_VERSION%
echo   Build Date: %BUILD_DATE%
echo.

REM Show file sizes
if exist "%APK_OUTPUT_DIR%\app-release.apk" (
    for %%A in ("%APK_OUTPUT_DIR%\app-release.apk") do echo   ✅ Release APK: %%~zA
)

if exist "%BUNDLE_OUTPUT_DIR%\app-release.aab" (
    for %%A in ("%BUNDLE_OUTPUT_DIR%\app-release.aab") do echo   ✅ App Bundle: %%~zA
)

echo.
echo Next Steps:
echo 1. Install APK: adb install %APK_OUTPUT_DIR%\app-release.apk
echo 2. Test on device: Run the app and verify functionality
echo 3. Upload to Play Store: Use app-release.aab for production deployment
echo ============================================
echo.
goto :eof

REM Function to display help
:show_help
echo Flutter Fire Alarm Monitoring APK Build Script
echo.
echo Usage: %~nx0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   build-all              Build release APK for all architectures
echo   build-arm64           Build release APK for ARM64 only
echo   build-arm32           Build release APK for ARM32 only
echo   build-x86              Build release APK for x86_64 (emulators)
echo   build-debug            Build debug APK
echo   build-bundle           Build App Bundle for Play Store
echo   build-all-types         Build APK for all types and App Bundle
echo   install                Install APK to connected device
echo   clean                  Clean build environment
echo   help                   Show this help message
echo.
echo Examples:
echo   %~nx0 build-all            # Build release APK
echo   %~nx0 build-arm64          # Build for ARM64 devices
echo   %~nx0 build-debug          # Build debug APK
echo   %~nx0 build-bundle         # Build App Bundle
echo   %~nx0 install              # Install built APK to device
echo.
echo Options:
echo   --install              Install APK after building
echo   --debug                Build debug version instead of release
echo.
goto :eof

REM Main execution logic
if "%~1"=="" goto show_help
if "%~1"=="help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

if "%~1"=="build-all" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "release"
    call :locate_files
    if "%~2"=="--install" call :install_apk "%APK_OUTPUT_DIR%\app-release.apk"
    call :show_summary
    goto :end
)

if "%~1"=="build-arm64" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "release" "android-arm64"
    call :locate_files
    if "%~2"=="--install" call :install_apk "%APK_OUTPUT_DIR%\app-release.apk"
    call :show_summary
    goto :end
)

if "%~1"=="build-arm32" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "release" "android-arm"
    call :locate_files
    if "%~2"=="--install" call :install_apk "%APK_OUTPUT_DIR%\app-release.apk"
    call :show_summary
    goto :end
)

if "%~1"=="build-x86" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "release" "android-x64"
    call :locate_files
    if "%~2"=="--install" call :install_apk "%APK_OUTPUT_DIR%\app-release.apk"
    call :show_summary
    goto :end
)

if "%~1"=="build-debug" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "debug"
    call :locate_files
    if "%~2"=="--install" call :install_apk "%APK_OUTPUT_DIR%\app-debug.apk"
    call :show_summary
    goto :end
)

if "%~1"=="build-bundle" (
    call :check_prerequisites
    call :clean_build
    call :build_appbundle
    call :locate_files
    call :show_summary
    goto :end
)

if "%~1"=="build-all-types" (
    call :check_prerequisites
    call :clean_build
    call :build_apk "release"
    call :build_appbundle
    call :locate_files
    call :show_summary
    goto :end
)

if "%~1"=="install" (
    call :install_apk "%APK_OUTPUT_DIR%\app-release.apk"
    goto :end
)

if "%~1"=="clean" (
    call :clean_build
    goto :end
)

echo [ERROR] Unknown command: %~1
echo.
call :show_help
exit /b 1

:end
echo Build process completed successfully!
pause
