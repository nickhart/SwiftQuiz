#!/usr/bin/env bash
set -euo pipefail

# Build script for SwiftQuiz
# Usage:
#   ./scripts/build.sh                              # Build for simulator (default)
#   ./scripts/build.sh --device                     # Build for device
#   ./scripts/build.sh --arch arm64                 # Specify architecture (arm64/x86_64)
#   ./scripts/build.sh --device-name "iPhone 16"   # Specify simulator device
#   ./scripts/build.sh --os 18.5                   # Specify iOS version
#   ./scripts/build.sh --configuration Debug|Release
#   ./scripts/build.sh --clean                     # Clean before build

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Source helper functions
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

# Check dependencies
check_dependencies

# Generate Xcode project if it doesn't exist
if [[ ! -d "SwiftQuiz.xcodeproj" ]]; then
  echo "==> Generating Xcode project..."
  xcodegen generate
fi

# Default values
DEVICE_NAME="iPhone 16"
OS_VERSION="18.5"
ARCHITECTURE=""
CONFIGURATION="Debug"
CLEAN=false
IS_DEVICE_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --device)
      IS_DEVICE_BUILD=true
      shift
      ;;
    --arch)
      ARCHITECTURE="$2"
      if ! validate_arch "$ARCHITECTURE"; then
        exit 1
      fi
      shift 2
      ;;
    --device-name)
      DEVICE_NAME="$2"
      shift 2
      ;;
    --os)
      OS_VERSION="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    --help|-h)
      echo "Build script for SwiftQuiz"
      echo ""
      echo "OPTIONS:"
      echo "  --device                     Build for device (default: simulator)"
      echo "  --arch <arm64|x86_64>        Specify architecture (default: native)"
      echo "  --device-name <name>         Simulator device name (default: iPhone 16)"
      echo "  --os <version>               iOS version (default: 18.5)"
      echo "  --configuration <config>     Build configuration: Debug|Release (default: Debug)"
      echo "  --clean                      Clean before build"
      echo "  --help, -h                   Show this help"
      echo ""
      echo "EXAMPLES:"
      echo "  $0                           # Build for simulator with native arch"
      echo "  $0 --arch x86_64             # Build for x86_64 simulator"
      echo "  $0 --device                  # Build for device"
      echo "  $0 --device-name 'iPhone 16' --os 18.2"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Set default architecture if not specified
if [[ -z "$ARCHITECTURE" ]]; then
  ARCHITECTURE=$(get_native_arch)
fi

# Determine destination
if $IS_DEVICE_BUILD; then
  DESTINATION="generic/platform=iOS"
else
  DESTINATION=$(get_simulator_destination "$DEVICE_NAME" "$OS_VERSION" "$ARCHITECTURE")
  dest_status=$?
  case $dest_status in
    0)
      echo "✓ Found exact simulator match"
      ;;
    1)
      echo "⚠️  Warning: Using fallback destination - may show multiple destination warning"
      ;;
    2)
      echo "❌ Error: No suitable simulators found"
      echo "Use './scripts/simulator.sh list --family iPhone' to see available simulators"
      exit 1
      ;;
  esac
fi

if $CLEAN; then
  echo "==> Cleaning build..."
  xcodebuild -scheme SwiftQuiz clean
fi

echo "==> Building SwiftQuiz..."
echo "    Configuration: $CONFIGURATION"
echo "    Architecture: $ARCHITECTURE"
if ! $IS_DEVICE_BUILD; then
  echo "    Device: $DEVICE_NAME (iOS $OS_VERSION)"
fi
echo "    Destination: $DESTINATION"

# Build the command
XCODEBUILD_CMD=(
  xcodebuild
  -scheme SwiftQuiz
  -destination "$DESTINATION"
  -configuration "$CONFIGURATION"
)

# Add architecture setting for simulator builds
if ! $IS_DEVICE_BUILD; then
  XCODEBUILD_CMD+=(ARCHS="$ARCHITECTURE")
fi

XCODEBUILD_CMD+=(build)

# Execute the build
"${XCODEBUILD_CMD[@]}"

echo "✅ Build completed successfully"