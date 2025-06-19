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

## How to Build the Images
- Customize the image repository name in build.sh if needed.
    ```
    # In build.sh
    IMAGE_REPO="localhost/playwright-vnc"
    ```
- Run the build script
    - To build all image variants
        ```
        sh build.sh
        ```
    - To build only a specific variant (e.g., Firefox and Chrome):
        ```
        sh build.sh firefox chrome
        ```

### Available Image Variants
The build script will create the following images:

| Image Tag Suffix | Default Browser | Installed Browsers |
| :--- | :--- | :--- |
| `:firefox-latest` | Firefox | Playwright's Firefox |
| `:chromium-latest`| Chromium | Playwright's Chromium |
| `:chrome-latest` | Google Chrome | Google Chrome (Stable) |
| `:all-latest` | Chromium | Google Chrome, Playwright's Firefox, Playwright's Chromium |


## How to Run the Images
Use podman/docker run to start a container. You need to map the VNC port (5900) and the Playwright server port (3000).
- Run the Specific browser image (example firefox)
    ```
    podman run -it -p 5900:5900 -p 3000:3000 localhost/playwright-vnc:firefox-latest

    ```
- All browser image (run google chrome)
    ```
    podman run -it -e PW_BROWSER="chrome" -p 5900:5900 -p 3000:3000 localhost/playwright-vnc:all-latest
    ```
- Note: Important environmental variables are
    - PW_BROWSER : Help you to specify browser
    - PW_HEADLESS: Help you to run in healess mode default its false.

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