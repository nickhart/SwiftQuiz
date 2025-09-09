#!/usr/bin/env bash

# Shared helper functions for SwiftQuiz scripts
# Source this file in other scripts: source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

# Detect native architecture of the current Mac
get_native_arch() {
  case $(uname -m) in
    arm64)
      echo "arm64"
      ;;
    x86_64)
      echo "x86_64"
      ;;
    *)
      echo "arm64"  # Default to arm64 for Apple Silicon
      ;;
  esac
}

# Find simulator UDID by name, OS version, and architecture
# Usage: find_simulator_udid "iPhone 15" "18.1" "arm64"
find_simulator_udid() {
  local device_name="$1"
  local os_version="$2"
  local arch="$3"

  # Convert version format (18.5 -> 18-5) for runtime identifier matching
  local runtime_version="${os_version//./-}"

  # Search through all iOS runtimes for matching device
  xcrun simctl list devices --json | jq -r "
    .devices |
    to_entries[] |
    select(.key | contains(\"$runtime_version\")) |
    .value[] |
    select(.name == \"$device_name\" and .isAvailable == true) |
    .udid
  " | head -n 1
}

# Get best matching simulator for device name, OS, and arch preference
# Returns: UDID-based destination if found, name-based destination as fallback
# Exit codes: 0=UDID found, 1=fallback used, 2=no simulators found at all
# Usage: get_simulator_destination "iPhone 15" "18.1" "arm64"
get_simulator_destination() {
  local device_name="$1"
  local os_version="$2"
  local preferred_arch="$3"

  local udid
  udid=$(find_simulator_udid "$device_name" "$os_version" "$preferred_arch")

  if [[ -n "$udid" ]]; then
    echo "platform=iOS Simulator,id=$udid"
    return 0
  fi

  # Fallback: try the other architecture
  local other_arch
  if [[ "$preferred_arch" == "arm64" ]]; then
    other_arch="x86_64"
  else
    other_arch="arm64"
  fi

  udid=$(find_simulator_udid "$device_name" "$os_version" "$other_arch")

  if [[ -n "$udid" ]]; then
    echo "platform=iOS Simulator,id=$udid"
    return 0
  fi

  # Check if any simulators exist for this device name and OS
  local any_devices
  local runtime_version="${os_version//./-}"
  any_devices=$(xcrun simctl list devices --json | jq -r "
    .devices |
    to_entries[] |
    select(.key | contains(\"$runtime_version\")) |
    .value[] |
    select(.name == \"$device_name\" and .isAvailable == true) |
    .udid
  " | head -n 1)

  if [[ -n "$any_devices" ]]; then
    # Device exists but with different architecture - use fallback
    echo "platform=iOS Simulator,name=$device_name,OS=$os_version"
    return 1
  else
    # No devices found at all
    echo "Error: No simulators found for $device_name with iOS $os_version" >&2
    echo "Available devices:" >&2
    xcrun simctl list devices --json | jq -r "
      .devices |
      to_entries[] |
      select(.key | contains(\"iOS\")) |
      .key as \$runtime |
      .value[] |
      select(.isAvailable == true) |
      \"  \" + .name + \" (\" + (\$runtime | split(\".\")[-1] | gsub(\"-\"; \" \")) + \")\"
    " | sort -u >&2
    return 2
  fi
}

# Validate architecture parameter
validate_arch() {
  local arch="$1"
  case "$arch" in
    arm64|x86_64)
      return 0
      ;;
    *)
      echo "Error: Invalid architecture '$arch'. Must be 'arm64' or 'x86_64'" >&2
      return 1
      ;;
  esac
}

# Get available architectures for a given device and OS
# Usage: get_available_archs "iPhone 15" "18.1"
get_available_archs() {
  local device_name="$1"
  local os_version="$2"

  xcrun simctl list devices --json | jq -r "
    .devices |
    to_entries[] |
    select(.key | contains(\"$os_version\")) |
    .value[] |
    select(.name == \"$device_name\" and .isAvailable == true) |
    \"Found: \" + .name + \" (\" + .udid + \")\""
}

# Check if jq is available (required for JSON parsing)
check_dependencies() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed. Please run: brew install jq" >&2
    return 1
  fi
  return 0
}