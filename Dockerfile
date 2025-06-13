FROM node:22-bookworm-slim

# --- Set default environment variables ---
ENV PW_VERSION=1.52.0
ENV PW_PORT=3000
ENV PW_BROWSER="chromium"
ENV PW_HEADLESS="false"

ENV DISPLAY=:1
ENV VNC_PORT=5900

ENV APP_USER=pwuser
ENV APP_HOME=/home/${APP_USER}
ENV PLAYWRIGHT_BROWSERS_PATH=${APP_HOME}/.ms-playwright

# --- Configure dpkg to exclude docs and man pages ---
RUN echo 'path-exclude /usr/share/doc/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/groff/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/lintian/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
    echo 'path-exclude /usr/share/linda/*' >> /etc/dpkg/dpkg.cfg.d/01_nodoc

# --- Create application user and essential directories ---
RUN useradd --create-home --shell /bin/bash --uid 1001 ${APP_USER} && \
    mkdir -p ${PLAYWRIGHT_BROWSERS_PATH} && \
    chown -R ${APP_USER}:${APP_USER} ${APP_HOME}

USER root

# --- Installation and cleanup layer ---
RUN set -e; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        tigervnc-standalone-server \
        fluxbox \
        supervisor \
        xterm \
        fonts-liberation \
        xfonts-base \
        xfonts-utils \
        xfonts-75dpi \
        xfonts-100dpi \
        xfonts-scalable \
        # procps \ # Optional: Provides 'ps', 'top'. Uncomment if needed for debugging runtime. Saves a few MB if removed.
        wget \
        ca-certificates \
    && \
    echo "===== Downloading and installing Google Chrome Stable from .deb...=====" && \
    wget -O /tmp/google-chrome-stable_current_amd64.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" && \
    apt-get install -y --no-install-recommends /tmp/google-chrome-stable_current_amd64.deb && \
    google-chrome-stable --version && \
    echo "===== Installing Playwright browsers (Firefox, Chromium) and their OS dependencies... =====" && \
    npm config set cache /tmp/npm_cache_root --global && \
    npx --yes playwright@${PW_VERSION} install --with-deps firefox chromium && \
    echo "===== Updating X11 font caches... =====" && \
    update-font σαν || echo "Warning: update-font σαν failed but continuing. This may be okay." && \
    echo "===== Cleanup...=====" && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* && \
    echo "===== Cleaning up npm cache for root and temporary files... =====" && \
    rm -rf /tmp/npm_cache_root /root/.npm && \
    rm -rf /usr/share/doc /usr/share/man

# --- Application and Supervisor Setup ---
COPY --chown=${APP_USER}:${APP_USER} supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chown=${APP_USER}:${APP_USER} start-playwright-server.js ${APP_HOME}/start-playwright-server.js

USER ${APP_USER}
WORKDIR ${APP_HOME}

RUN echo "===== Installing local Playwright library for ${APP_USER}...=====" && \
    npm config set cache /tmp/npm_cache_pwuser && \
    npm install playwright@${PW_VERSION} && \
    echo "===== Cleaning up npm cache for ${APP_USER}... =====" && \
    rm -rf /tmp/* ~/.npm

# --- Expose network ports ---
EXPOSE ${VNC_PORT}
EXPOSE ${PW_PORT}

# --- Set default command ---
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
