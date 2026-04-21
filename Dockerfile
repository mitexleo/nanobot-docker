# =============================================================================
# nanobot-docker — Dockerfile
# Uses `uv tool install nanobot-ai` — the official recommended install method.
# No source clone, no build step. The package is installed as an isolated tool.
# =============================================================================
# Build args:
#   NANOBOT_VERSION  — nanobot version to install (default: latest, e.g. "0.1.5.post2")
# =============================================================================

ARG NANOBOT_VERSION=

FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /app

# Install system dependencies needed at runtime:
#   bubblewrap  — exec tool sandbox (Linux only)
#   ca-certificates — HTTPS for API calls
#   git         — git-based skills
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bubblewrap \
        ca-certificates \
        git \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install nanobot as a uv tool (the officially recommended install method).
# uv tool install creates an isolated, self-contained environment — no need
# to pip install, clone source, or manage a virtualenv.
# Any extra dependencies (all, api, wecom, discord, pdf, etc.) can be added
# via the nanobot[extra] syntax.
#
# uv tool install nanobot-ai@<version>   — install a specific version
# uv tool install nanobot-ai             — install latest
RUN --mount=type=cache,target=/root/.local/share/uv \
    uv tool install ${NANOBOT_VERSION:+nanobot-ai@${NANOBOT_VERSION}} nanobot-ai

# Create non-root user and config directory
RUN useradd -m -u 1000 -s /bin/bash nanobot && \
    mkdir -p /home/nanobot/.nanobot && \
    chown -R nanobot:nanobot /home/nanobot

# Entrypoint checks config dir permissions and delegates to nanobot CLI
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER nanobot
ENV HOME=/home/nanobot

# Default port — can be overridden via NANOBOT_GATEWAY__PORT env var
EXPOSE 18790

ENTRYPOINT ["entrypoint.sh"]
CMD ["status"]
