FROM python:3.12-slim

# Build arguments
ARG NANOBOT_TAG=v0.1.5.post2

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    NANOBOT_TAG=${NANOBOT_TAG}

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install nanobot from GitHub release
RUN pip install --upgrade pip && \
    pip install "nanobot[all]@git+https://github.com/HKUDS/nanobot.git@${NANOBOT_TAG}"

# Create nanobot config directory
ENV NANOBOT_CONFIG_DIR=/app/config

# Create a default config file if none exists
RUN mkdir -p /app/config && \
    if [ ! -f /app/config/nanobot.yml ]; then \
        cat > /app/config/nanobot.yml << 'EOF'
# Default nanobot configuration
# Copy this file and edit with your settings

# LLM Provider Configuration
model_provider: openai
gpt_model: gpt-4o-mini

# API Keys (set as environment variables in production)
# openai_api_key: your-api-key-here
# anthropic_api_key: your-api-key-here
# google_api_key: your-api-key-here

# Channel Configuration
# Uncomment and configure channels you want to use:
# channel:
#   type: telegram
#   telegram:
#     bot_token: your-telegram-bot-token
#
#   type: discord
#   discord:
#     bot_token: your-discord-bot-token
#     guild_id: your-guild-id
#
#   type: slack
#   slack:
#     bot_token: your-slack-bot-token
#     signing_secret: your-slack-signing-secret

# Session Configuration
session:
  name: nanobot_session
  auto_compact: true
  compact_trigger_tokens: 60000

# Memory Configuration
memory:
  provider: session
  max_history: 100

# API Server (optional)
# api_server:
#   host: 0.0.0.0
#   port: 8000
#   api_keys:
#     - your-api-key
EOF
    fi

# Create data directory for session storage
RUN mkdir -p /app/data

# Default command
CMD ["nanobot", "run", "--config-dir", "/app/config"]
