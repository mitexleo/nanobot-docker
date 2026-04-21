# =============================================================================
# nanobot-docker — Dockerfile
# Based on the official nanobot Dockerfile from https://github.com/HKUDS/nanobot
# =============================================================================
# Build args:
#   NANOBOT_BRANCH  — git branch/tag to build from (default: main)
#   NANOBOT_COMMIT  — specific git commit SHA (optional, overrides branch)
# =============================================================================

ARG NANOBOT_BRANCH=main
ARG NANOBOT_COMMIT=

# ------------------------------------------------------------------
# Stage 1: Build the source
# ------------------------------------------------------------------
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install Node.js 20 (required for WhatsApp bridge) + build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg git bubblewrap openssh-client && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get purge -y gnupg && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone nanobot source
RUN if [ -n "${NANOBOT_COMMIT}" ]; then \
        git clone --depth=1 --branch "${NANOBOT_COMMIT}" https://github.com/HKUDS/nanobot.git .; \
    else \
        git clone --depth=1 --branch "${NANOBOT_BRANCH}" https://github.com/HKUDS/nanobot.git .; \
    fi

# Install Python dependencies via uv
RUN mkdir -p nanobot bridge && touch nanobot/__init__.py && \
    uv pip install --system --no-cache .

# Copy full source and reinstall (ensures all local imports work)
COPY nanobot/ nanobot/
COPY bridge/ bridge/
COPY pyproject.toml README.md LICENSE ./
RUN uv pip install --system --no-cache .

# Build the WhatsApp bridge
WORKDIR /build/bridge
RUN git config --global --add url."https://github.com/".insteadOf ssh://git@github.com/ && \
    git config --global --add url."https://github.com/".insteadOf git@github.com: && \
    npm install && npm run build
WORKDIR /build

# ------------------------------------------------------------------
# Stage 2: Runtime image
# ------------------------------------------------------------------
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install runtime dependencies only (no git/node/build tools)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bubblewrap ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages/ /usr/local/lib/python3.12/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/

# Copy WhatsApp bridge from builder
COPY --from=builder /build/bridge/ /app/bridge/

# Copy nanobot source
COPY --from=builder /build/nanobot/ /app/nanobot/
COPY --from=builder /build/pyproject.toml /app/

# ------------------------------------------------------------------
# Runtime setup: non-root user + entrypoint
# ------------------------------------------------------------------
RUN useradd -m -u 1000 -s /bin/bash nanobot && \
    mkdir -p /home/nanobot/.nanobot && \
    chown -R nanobot:nanobot /app /home/nanobot

# Entrypoint handles config migration and permission checks
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER nanobot
ENV HOME=/home/nanobot

# Gateway default port (can be overridden via config or NANOBOT_GATEWAY__PORT)
EXPOSE 18790

ENTRYPOINT ["entrypoint.sh"]
CMD ["status"]
