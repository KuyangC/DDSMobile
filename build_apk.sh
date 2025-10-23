#!/bin/bash

# Flutter Fire Alarm Monitoring APK Build Script
# Version 1.0.0
# Created: October 16, 2025

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Flutter Fire Alarm Monitoring"
APP_VERSION="1.0.0"
BUILD_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BUILD_DIR="build"
APK_OUTPUT_DIR="$BUILD_DIR/app/outputs/flutter-apk"
BUNDLE_OUTPUT_DIR="$BUILD_DIR/app/outputs/bundle/release"

# Print header
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Flutter Fire Alarm Monitoring APK Build${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${YELLOW}App Name: $APP_NAME${NC}"
echo -e "${YELLOW}Version: $APP_VERSION${NC}"
echo -e "${YELLOW}Build Date: $BUILD_DATE${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo -e "[INFO] $message"
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "INFO" "Checking prerequisites..."
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        print_status "ERROR" "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    local flutter_version=$(flutter --version | grep -oE 'Flutter [0-9]+\.[0-9]+\.[0-9]+')
    print_status "INFO" "Flutter version: $flutter_version"
    
    # Check Flutter doctor
    print_status "INFO" "Running Flutter doctor..."
    if ! flutter doctor --android-licenses > /dev/null 2>&1; then
        print_status "WARNING" "Flutter doctor found some issues. Please check the output above."
    fi
    
    # Check for connected devices
    local device_count=$(flutter devices | grep -c "android")
    print_status "INFO" "Found $device_count Android device(s)"
    
    if [ $device_count -eq 0 ]; then
        print_status "WARNING" "No Android devices found. Make sure your device is connected and USB debugging is enabled."
    fi
    
    print_status "SUCCESS" "Prerequisites check completed"
    echo ""
}

# Function to clean build environment
clean_build() {
    print_status "INFO" "Cleaning build environment..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_status "INFO" "Removed existing build directory"
    fi
    
    flutter clean
    flutter pub get
    
    print_status "SUCCESS" "Build environment cleaned"
    echo ""
}

# Function to build APK
build_apk() {
    local build_type=$1
    local target_platform=$2
    
    print_status "INFO" "Building APK ($build_type)..."
    
    local build_command="flutter build apk"
    
    case $build_type in
        "release")
            build_command="$build_command --release"
            ;;
        "debug")
            build_command="$build_command --debug"
            ;;
        "profile")
            build_command="$build_command --profile"
            ;;
    esac
    
    if [ -n "$target_platform" ]; then
        build_command="$build_command --target-platform $target_platform"
    fi
    
    print_status "INFO" "Running: $build_command"
    
    # Execute build command
    eval $build_command
    
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "APK build completed successfully"
    else
        print_status "ERROR" "APK build failed"
        exit 1
    fi
    
    echo ""
}

# Function to build App Bundle
build_appbundle() {
    print_status "INFO" "Building App Bundle for Play Store..."
    
    local build_command="flutter build appbundle --release"
    
    print_status "INFO" "Running: $build_command"
    
    # Execute build command
    eval $build_command
    
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "App Bundle build completed successfully"
    else
        print_status "ERROR" "App Bundle build failed"
        exit 1
    fi
    
    echo ""
}

# Function to locate built files
locate_files() {
    print_status "INFO" "Locating built files..."
    
    if [ -f "$APK_OUTPUT_DIR/app-release.apk" ]; then
        local apk_path=$(realpath "$APK_OUTPUT_DIR/app-release.apk")
        local apk_size=$(du -h "$apk_path" | cut -f1)
        print_status "SUCCESS" "Release APK: $apk_path ($apk_size)"
    else
        print_status "ERROR" "Release APK not found at $APK_OUTPUT_DIR/app-release.apk"
    fi
    
    if [ -f "$APK_OUTPUT_DIR/app-debug.apk" ]; then
        local debug_apk_path=$(realpath "$APK_OUTPUT_DIR/app-debug.apk")
        local debug_apk_size=$(du -h "$debug_apk_path" | cut -f1)
        print_status "SUCCESS" "Debug APK: $debug_apk_path ($debug_apk_size)"
    fi
    
    if [ -f "$BUNDLE_OUTPUT_DIR/app-release.aab" ]; then
        local bundle_path=$(realpath "$BUNDLE_OUTPUT_DIR/app-release.aab")
        local bundle_size=$(du -h "$bundle_path" | cut -f1)
        print_status "SUCCESS" "App Bundle: $bundle_path ($bundle_size)"
    fi
    
    echo ""
}

# Function to install APK via ADB
install_apk() {
    local apk_path=$1
    
    if [ -z "$apk_path" ]; then
        print_status "ERROR" "APK path is required for installation"
        return 1
    fi
    
    if [ ! -f "$apk_path" ]; then
        print_status "ERROR" "APK file not found: $apk_path"
        return 1
    fi
    
    print_status "INFO" "Installing APK via ADB: $apk_path"
    
    # Check if device is connected
    local device_count=$(flutter devices | grep -c "android")
    if [ $device_count -eq 0 ]; then
        print_status "ERROR" "No Android devices connected. Please connect your device and enable USB debugging."
        return 1
    fi
    
    # Get app package name
    local package_name="com.example.flutter_application_1"
    
    # Uninstall previous version if exists
    if adb shell pm list packages | grep -q "$package_name"; then
        print_status "INFO" "Uninstalling previous version..."
        adb uninstall "$package_name"
    fi
    
    # Install APK
    adb install "$apk_path"
    
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "APK installed successfully"
    else
        print_status "ERROR" "APK installation failed"
        return 1
    fi
    
    echo ""
}

# Function to show build summary
show_summary() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Build Summary${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo -e "${YELLOW}App Name: $APP_NAME${NC}"
    echo -e "${YELLOW}Version: $APP_VERSION${NC}"
    echo -e "${YELLOW}Build Date: $BUILD_DATE${NC}"
    echo ""
    
    # Show file sizes
    if [ -f "$APK_OUTPUT_DIR/app-release.apk" ]; then
        local apk_size=$(du -h "$APK_OUTPUT_DIR/app-release.apk" | cut -f1)
        echo -e "${GREEN}✅ Release APK: $apk_size${NC}"
    fi
    
    if [ -f "$BUNDLE_OUTPUT_DIR/app-release.aab" ]; then
        local bundle_size=$(du -h "$BUNDLE_OUTPUT_DIR/app-release.aab" | cut -f1)
        echo -e "${GREEN}✅ App Bundle: $bundle_size${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "1. Install APK: adb install $APK_OUTPUT_DIR/app-release.apk"
    echo -e "2. Test on device: Run the app and verify functionality"
    echo -e "3. Upload to Play Store: Use app-release.aab for production deployment"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Function to display help
show_help() {
    echo "Flutter Fire Alarm Monitoring APK Build Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build-all              Build release APK for all architectures"
    echo "  build-arm64           Build release APK for ARM64 only"
    echo "  build-arm32           Build release APK for ARM32 only"
    echo "  build-x86              Build release APK for x86_64 (emulators)"
    echo "  build-debug            Build debug APK"
    echo "  build-bundle           Build App Bundle for Play Store"
    echo "  build-all-types         Build APK for all types and App Bundle"
    echo "  install                Install APK to connected device"
    echo "  clean                  Clean build environment"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build-all            # Build release APK"
    echo "  $0 build-arm64          # Build for ARM64 devices"
    echo "  $0 build-debug          # Build debug APK"
    echo "  $0 build-bundle         # Build App Bundle"
    echo "  $0 install              # Install built APK to device"
    echo ""
    echo "Options:"
    echo "  --install              Install APK after building"
    echo "  --debug                Build debug version instead of release"
    echo ""
}

# Main execution logic
main() {
    case "${1:-}" in
        "build-all")
            check_prerequisites
            clean_build
            build_apk "release"
            locate_files
            if [[ "${2:-}" == "--install" ]]; then
                install_apk "$APK_OUTPUT_DIR/app-release.apk"
            fi
            show_summary
            ;;
        "build-arm64")
            check_prerequisites
            clean_build
            build_apk "release" "android-arm64"
            locate_files
            if [[ "${2:-}" == "--install" ]]; then
                install_apk "$APK_OUTPUT_DIR/app-release.apk"
            fi
            show_summary
            ;;
        "build-arm32")
            check_prerequisites
            clean_build
            build_apk "release" "android-arm"
            locate_files
            if [[ "${2:-}" == "--install" ]]; then
                install_apk "$APK_OUTPUT_DIR/app-release.apk"
            fi
            show_summary
            ;;
        "build-x86")
            check_prerequisites
            clean_build
            build_apk "release" "android-x64"
            locate_files
            if [[ "${2:-}" == "--install" ]]; then
                install_apk "$APK_OUTPUT_DIR/app-release.apk"
            fi
            show_summary
            ;;
        "build-debug")
            check_prerequisites
            clean_build
            build_apk "debug"
            locate_files
            if [[ "${2:-}" == "--install" ]]; then
                install_apk "$APK_OUTPUT_DIR/app-debug.apk"
            fi
            show_summary
            ;;
        "build-bundle")
            check_prerequisites
            clean_build
            build_appbundle
            locate_files
            show_summary
            ;;
        "build-all-types")
            check_prerequisites
            clean_build
            build_apk "release"
            build_appbundle
            locate_files
            show_summary
            ;;
        "install")
            install_apk "$APK_OUTPUT_DIR/app-release.apk"
            ;;
        "clean")
            clean_build
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            print_status "ERROR" "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
