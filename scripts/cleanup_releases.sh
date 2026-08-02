#!/bin/bash
# Clean up old zip files that don't correspond to GitHub releases

set -e

cd "$(dirname "$0")/.."

echo "Checking for zip files not matching release tags..."
echo ""

# List current zip files
echo "Current zip files:"
ls -la *.zip 2>/dev/null || echo "No zip files found"
echo ""

# Clean up zip files
# Pattern 1: Date-based files like Codex-Launcher-macos-20260801.zip
# Pattern 2: Date with version suffix like Codex-Launcher-macos-20260801-2.zip
# Keep only release-named files: Codex-Launcher-macos-v*.zip

for f in *.zip; do
    if [[ "$f" == "Codex-Launcher-macos-20"*".zip" ]]; then
        echo "Removing (date-based, not a release): $f"
        rm -f "$f"
    fi
done

echo ""
echo "After cleanup:"
ls -la *.zip 2>/dev/null || echo "No zip files remaining"
