# Playwright with VNC: Headed Browser Docker Images

Official Playwright images from Microsoft are excellent for CI/CD pipelines and pure headless execution. However, they lack a graphical user interface.

This project solves that problem by providing a lightweight, VNC-enabled environment.

These images are built from the ground up on a slim Debian base (node:22-bookworm-slim) to be as optimized as possible while still providing a full graphical environment.

## Key Features
- VNC Server Built-in: Connect with any VNC client to view and interact with the browser.
- Headed Mode by Default: Designed specifically for running browsers with their UI visible.
- Multiple Browser Variants: Build tailored images for Firefox, Chromium, or Google Chrome.
- All-in-One Image: An all variant includes all three browsers for maximum flexibility.
- Optimized for Size: Multi-stage Dockerfile and careful package selection to keep images lean.
- Configurable: Control the browser type and headless mode at runtime with environment variables.
- Single Source: Manage all image variants from a single, easy-to-maintain Dockerfile.multibuild.
- Automated Builds: Daily CI/CD pipeline builds latest Playwright versions automatically.

## 🎭 Latest Release

<!-- RELEASE_INFO_START -->
<!-- RELEASE_INFO_START -->
**Current Playwright Version:** `1.55.0`  
**Released:** 2025-09-10 16:56 UTC  

### 🐳 Available Images
- `digitronik/playwright-vnc:latest` (all browsers)
- `digitronik/playwright-vnc:firefox-latest`
- `digitronik/playwright-vnc:chromium-latest`
- `digitronik/playwright-vnc:chrome-latest`

### 📦 Version-Specific Tags
- `digitronik/playwright-vnc:1.55.0`
- `digitronik/playwright-vnc:firefox-1.55.0`
- `digitronik/playwright-vnc:chromium-1.55.0`
- `digitronik/playwright-vnc:chrome-1.55.0`

### 🚀 Quick Start
```bash
# Run with all browsers available
docker run -p 5900:5900 -p 3000:3000 digitronik/playwright-vnc:latest

# Connect via VNC
vncviewer localhost:5900
```

*Last updated: 2025-09-10 16:56 UTC (automated)*
<!-- RELEASE_INFO_END -->

## How to Build the Images (Local Development)

**Note:** Images are automatically built daily via GitHub Actions. For local development:

```bash
# Build latest Playwright version (all browsers)
./build.sh

# Build specific Playwright version
./build.sh --playwright-version 1.55.0

# Build only specific browser variants  
./build.sh firefox chrome

# Customize repository name for local builds
./build.sh --repo "localhost/playwright-vnc"
```

### Available Image Variants

| Image Tag | Default Browser | Installed Browsers |
| :--- | :--- | :--- |
| `:latest` | Chromium | All browsers (Firefox, Chromium, Chrome) |
| `:firefox-latest` | Firefox | Playwright's Firefox |
| `:chromium-latest`| Chromium | Playwright's Chromium |
| `:chrome-latest` | Google Chrome | Google Chrome (Stable) |


## How to Run the Images

Use docker/podman to start a container. Map VNC port (5900) and Playwright server port (3000).

```bash
# Run specific browser image
docker run -p 5900:5900 -p 3000:3000 digitronik/playwright-vnc:firefox-latest

# Run all-browsers image with specific browser selection
docker run -e PW_BROWSER="chrome" -p 5900:5900 -p 3000:3000 digitronik/playwright-vnc:latest

# Run in headless mode  
docker run -e PW_HEADLESS="true" -p 3000:3000 digitronik/playwright-vnc:latest
```

### Environment Variables
- `PW_BROWSER`: Specify browser (`firefox`, `chromium`, `chrome`) 
- `PW_HEADLESS`: Run in headless mode (`true`/`false`, default: `false`)

### Connecting with a VNC Client
VNC will run at 5900 port. You can connect your favorite VNC client.
```
vncviewer localhost:5900 
```

## Connecting with a Playwright Client
- Connecting to a Chromium or Google Chrome Server
    ```python
    # client.py
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.connect("ws://localhost:3000/playwright")
        print("Connected to Chromium!")
        page = browser.new_page()
        page.goto("https://playwright.dev/")
        print(page.title())
        browser.close()
    ```
- Connecting to a Firefox Server:
    ```python
    # client.py
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.firefox.connect("ws://localhost:3000/playwright")
        print("Connected to Firefox!")
        page = browser.new_page()
        page.goto("https://playwright.dev/")
        print(page.title())
        browser.close()
    ```