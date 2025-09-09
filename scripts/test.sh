#!/usr/bin/env bash
set -euo pipefail

# Test script for SwiftQuiz tests
# Usage:
#   ./scripts/test.sh                              # Run unit tests only (default)
#   ./scripts/test.sh --ui                         # Run UI tests only
#   ./scripts/test.sh --all                        # Run both unit and UI tests
#   ./scripts/test.sh --arch arm64                 # Specify architecture (arm64/x86_64)
#   ./scripts/test.sh --device-name "iPhone 16"   # Specify simulator device
#   ./scripts/test.sh --os 18.5                   # Specify iOS version
#   ./scripts/test.sh --configuration Release     # Run with specific configuration
#   ./scripts/test.sh --coverage                  # Generate code coverage (unit tests only)

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
COVERAGE=false
RUN_UI_TESTS=false
RUN_UNIT_TESTS=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
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
    --coverage)
      COVERAGE=true
      shift
      ;;
    --ui)
      RUN_UI_TESTS=true
      RUN_UNIT_TESTS=false
      shift
      ;;
    --all)
      RUN_UI_TESTS=true
      RUN_UNIT_TESTS=true
      shift
      ;;
    --help|-h)
      echo "Test script for SwiftQuiz tests"
      echo ""
      echo "OPTIONS:"
      echo "  --ui                         Run UI tests only"
      echo "  --all                        Run both unit and UI tests"
      echo "  --arch <arm64|x86_64>        Specify architecture (default: native)"
      echo "  --device-name <name>         Simulator device name (default: iPhone 16)"
      echo "  --os <version>               iOS version (default: 18.5)"
      echo "  --configuration <config>     Test configuration: Debug|Release (default: Debug)"
      echo "  --coverage                   Enable code coverage collection (unit tests only)"
      echo "  --help, -h                   Show this help"
      echo ""
      echo "EXAMPLES:"
      echo "  $0                           # Run unit tests with native arch"
      echo "  $0 --ui                      # Run UI tests only"
      echo "  $0 --all                     # Run both unit and UI tests"
      echo "  $0 --arch x86_64             # Run tests on x86_64 simulator"
      echo "  $0 --coverage                # Run unit tests with coverage"
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

# Determine what tests to run
if $RUN_UNIT_TESTS && $RUN_UI_TESTS; then
  TEST_TYPE="both unit and UI tests"
  TESTING_FLAGS=""
elif $RUN_UI_TESTS; then
  TEST_TYPE="UI tests"
  TESTING_FLAGS="-only-testing SwiftQuizUITests"
else
  TEST_TYPE="unit tests"
  TESTING_FLAGS="-skip-testing SwiftQuizUITests"
fi

echo "==> Running SwiftQuiz $TEST_TYPE..."
echo "    Configuration: $CONFIGURATION"
echo "    Architecture: $ARCHITECTURE"
echo "    Device: $DEVICE_NAME (iOS $OS_VERSION)"
echo "    Destination: $DESTINATION"
if $COVERAGE && $RUN_UNIT_TESTS; then
  echo "    Code Coverage: Enabled"
fi

# Build the test command
XCODEBUILD_CMD=(
  xcodebuild test
  -scheme SwiftQuiz
  -destination "$DESTINATION"
  -configuration "$CONFIGURATION"
  ARCHS="$ARCHITECTURE"
)

# Add testing flags
if [[ -n "$TESTING_FLAGS" ]]; then
  XCODEBUILD_CMD+=($TESTING_FLAGS)
fi

# Add coverage only for unit tests
if $COVERAGE && $RUN_UNIT_TESTS; then
  XCODEBUILD_CMD+=(
    -enableCodeCoverage YES
  )
fi

# Run the tests
"${XCODEBUILD_CMD[@]}"

if $COVERAGE && $RUN_UNIT_TESTS; then
  echo ""
  echo "==> Exporting code coverage report..."

  # Find the most recent test results file for SwiftQuiz
  TEST_RESULTS=$(find ~/Library/Developer/Xcode/DerivedData -name "*SwiftQuiz*.xcresult" -type d -mtime -1 | head -n 1)

  if [[ -n "$TEST_RESULTS" ]]; then
    echo "Found test results: $TEST_RESULTS"
    # Export coverage report for display
    if xcrun xccov view "$TEST_RESULTS" --report --only-targets; then
      echo ""
      echo "Full coverage report available at: $TEST_RESULTS"

      # Export coverage data for Codecov (if running in CI)
      if [[ -n "${CI:-}" ]]; then
        echo "Exporting coverage data for Codecov..."
        xcrun xccov view --report --json "$TEST_RESULTS" > coverage.json
        echo "Coverage data exported to coverage.json"
      fi
    else
      echo "Warning: Failed to generate coverage report"
      exit 0  # Don't fail the entire script for coverage issues
    fi
  else
    echo "Warning: Could not find test results for coverage report"
    echo "Available xcresult files:"
    find ~/Library/Developer/Xcode/DerivedData -name "*.xcresult" -type d | head -5
  fi
fi

echo "✅ $TEST_TYPE completed successfully"