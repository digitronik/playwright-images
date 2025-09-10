#!/bin/bash

set -e

# Simple script to detect browser versions
# Usage: ./detect-browser-versions.sh

echo "Browser Version Detection"
echo "========================"

# Detect Chrome version if available
if command -v google-chrome-stable &> /dev/null; then
    CHROME_VERSION=$(google-chrome-stable --version 2>/dev/null | sed 's/Google Chrome //' | awk '{print $1}')
    echo "Chrome: $CHROME_VERSION"
else
    echo "Chrome: Not installed"
fi

# Detect Playwright's bundled browsers
BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.ms-playwright}"

if [ -d "$BROWSERS_PATH" ]; then
    # Detect bundled Chromium
    CHROMIUM_DIR=$(find "$BROWSERS_PATH" -maxdepth 1 -name "chromium-*" -type d | head -1)
    if [ -n "$CHROMIUM_DIR" ] && [ -f "$CHROMIUM_DIR/chrome-linux/chrome" ]; then
        CHROMIUM_VERSION=$("$CHROMIUM_DIR/chrome-linux/chrome" --version 2>/dev/null | sed 's/Chromium //')
        echo "Chromium (Playwright): $CHROMIUM_VERSION"
    else
        echo "Chromium (Playwright): Not installed"
    fi
    
    # Detect bundled Firefox
    FIREFOX_DIR=$(find "$BROWSERS_PATH" -maxdepth 1 -name "firefox-*" -type d | head -1)
    if [ -n "$FIREFOX_DIR" ] && [ -f "$FIREFOX_DIR/firefox/firefox" ]; then
        FIREFOX_VERSION=$("$FIREFOX_DIR/firefox/firefox" --version 2>/dev/null | sed 's/Mozilla Firefox //')
        echo "Firefox (Playwright): $FIREFOX_VERSION"
    else
        echo "Firefox (Playwright): Not installed"
    fi
else
    echo "Chromium (Playwright): Not available (no browsers path)"
    echo "Firefox (Playwright): Not available (no browsers path)"
fi

# Show Playwright version
if [ -n "${PW_VERSION}" ]; then
    echo "Playwright: ${PW_VERSION}"
elif command -v npx &> /dev/null; then
    PW_VER=$(npx playwright --version 2>/dev/null | sed 's/Version //' || echo "Unknown")
    echo "Playwright: $PW_VER"
else
    echo "Playwright: Unknown"
fi

