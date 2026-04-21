# nanobot-docker

Docker image for [nanobot](https://github.com/HKUDS/nanobot) — an open-source AI agent framework that connects to multiple chat platforms (Telegram, Discord, Slack, Microsoft Teams, Email, WhatsApp, and more) with built-in session memory, cron scheduling, tool calling, and an OpenAI-compatible API server.

## Features

- Multi-channel support (Telegram, Discord, Slack, Teams, Email, WhatsApp, WebSocket, Matrix, and more)
- Session memory with automatic context compaction
- Dream — periodic long-term memory consolidation
- Cron job scheduling
- OpenAI-compatible API server with SSE streaming
- Built-in tools (file reading, web search, code execution, MCP integration)
- Non-root container with proper signal handling
- Image auto-updated every 3 hours via GitHub Actions when a new nanobot release is detected

## Quick Start

### Prerequisites

- Docker 20.10+ and Docker Compose v2+
- At least one LLM API key (OpenRouter, OpenAI, Anthropic, Google, or DeepSeek)

### 1. Clone and configure

```bash
git clone https://github.com/mitexleo/nanobot-docker.git
cd nanobot-docker
cp .env.example .env
```

Edit `.env` and add your API key. For the easiest setup, use [OpenRouter](https://openrouter.ai) — it gives access to 100+ models through a single key:

```bash
# .env
NANOBOT_PROVIDER=openrouter
NANOBOT_MODEL=anthropic/claude-sonnet-4-7
NANOBOT_TIMEZONE=America/New_York
OPENROUTER_API_KEY=sk-or-v1-your-key-here
```

### 2. First-time setup (generates config)

```bash
docker compose run --rm nanobot-cli onboard
```

Follow the prompts. This generates `~/.nanobot/config.json` inside the volume.

### 3. Start the gateway

```bash
docker compose up -d nanobot-gateway
docker compose logs -f nanobot-gateway
```

### 4. Chat with the agent

```bash
docker compose run --rm nanobot-cli agent
```

## Configuration

### Environment Variables

All settings use the `NANOBOT_` prefix with `__` as the nested key separator (e.g. `NANOBOT_AGENTS__DEFAULTS__MODEL`).

| Variable | Default | Description |
|---|---|---|
| `NANOBOT_PROVIDER` | `openrouter` | Provider name: `openrouter`, `openai`, `anthropic`, etc. |
| `NANOBOT_MODEL` | `anthropic/claude-sonnet-4-7` | Model in `provider/model` format |
| `NANOBOT_TIMEZONE` | `UTC` | IANA timezone for cron and timestamps |
| `OPENROUTER_API_KEY` | — | OpenRouter API key |
| `OPENAI_API_KEY` | — | OpenAI API key |
| `ANTHROPIC_API_KEY` | — | Anthropic API key |
| `GOOGLE_API_KEY` | — | Google API key |
| `DEEPSEEK_API_KEY` | — | DeepSeek API key |
| `TELEGRAM_BOT_TOKEN` | — | Telegram bot token |
| `DISCORD_BOT_TOKEN` | — | Discord bot token |
| `SLACK_BOT_TOKEN` | — | Slack bot token |
| `SLACK_SIGNING_SECRET` | — | Slack signing secret |
| `NANOBOT_TOOLS__EXEC__SANDBOX` | `""` | Sandbox backend: `""` or `"bwrap"` (Linux) |

For the full list of config options, see the [nanobot Configuration Reference](https://nanobot.wiki/docs/0.1.5.post2/use-nanobot/configuration).

### Customizing config.json

After `onboard`, your config is at `~/.nanobot/config.json` inside the Docker volume. You can also edit it directly:

```bash
# Find the volume mount path
docker volume inspect nanobot-docker_nanobot-config

# Or use a temporary container
docker run --rm -v nanobot-docker_nanobot-config:/data alpine vi /data/config.json
```

Alternatively, pass env vars at runtime — they override config.json values:

```bash
NANOBOT_CHANNELS__TELEGRAM__BOT_TOKEN=xxx docker compose up -d nanobot-gateway
```

## Services

### `nanobot-gateway` (default)

Persistent background service. Runs the channel gateway on port **18790** and the OpenAI-compatible API server on port **8900**. Auto-restarts on failure.

```bash
docker compose up -d nanobot-gateway
```

### `nanobot-cli`

Interactive or one-shot CLI. Only runs with `--profile cli`:

```bash
# Interactive agent chat
docker compose --profile cli run --rm nanobot-cli agent

# Onboard (first-time setup)
docker compose --profile cli run --rm nanobot-cli onboard --wizard

# Check status
docker compose --profile cli run --rm nanobot-cli status

# Run a one-shot command
docker compose --profile cli run --rm nanobot-cli agent -m "What is 2+2?"
```

## Port Reference

| Port | Service | Description |
|---|---|---|
| **18790** | Gateway | Webhook receiver for Telegram/Discord/etc. — expose via reverse proxy |
| **8900** | API Server | OpenAI-compatible REST API |

## Deployment

### VPS / Bare Metal

1. SSH into your server
2. Install Docker and Docker Compose v2
3. Clone the repo and configure `.env`
4. Run `docker compose run --rm nanobot-cli onboard` to generate config
5. Edit `config.json` to add API keys and channel tokens
6. Run `docker compose up -d nanobot-gateway`
7. (Optional) Set up nginx or Caddy as a reverse proxy in front of port 18790 for HTTPS webhook delivery

### Railway

1. Create a new Railway project
2. Add a Dockerfile-based deployment (the Dockerfile is included)
3. Set environment variables in the Railway dashboard
4. Deploy

For channel webhooks on Railway, set the webhook URL in your Telegram/Discord bot settings to your Railway app URL.

### Render

1. Create a new Web Service on Render
2. Connect your GitHub repo
3. Set **Build Command**: leave empty (uses Dockerfile)
4. Set **Start Command**: `gateway`
5. Add environment variables
6. Deploy

### Fly.io

```bash
fly launch
fly secrets set OPENROUTER_API_KEY=sk-or-v1-...
fly deploy
```

## Available Image Tags

| Tag | Description |
|---|---|
| `latest` | Most recent build |
| `X.Y.Z` | Specific nanobot release (e.g. `0.1.5.post2`) |

## Building Locally

```bash
# Build latest version
docker build -t mitexleo/nanobot-docker:local .

# Build a specific nanobot version
docker build --build-arg NANOBOT_VERSION=0.1.5.post2 -t mitexleo/nanobot-docker:local .

# Test run
docker run --rm -it -v nanobot-docker_nanobot-config:/home/nanobot/.nanobot mitexleo/nanobot-docker:local agent
```

## Troubleshooting

### Container exits with "not writable" error

The `~/.nanobot` directory on your host is owned by a different UID. Fix it:

```bash
sudo chown -R 1000:1000 ~/.nanobot
```

Or run the container as your user:

```bash
docker run --user $(id -u):$(id -g) ...
```

### Port 18790 already in use

Change the port in `.env`:

```bash
GATEWAY_PORT=18791
```

And update your Telegram/Discord webhook URL accordingly.

### Interactive login (WhatsApp QR, OAuth) doesn't work

Use `-it` for interactive terminals:

```bash
docker compose --profile cli run --rm -it nanobot-cli onboard --wizard
```

### Slow first start

The first run installs all Python dependencies (~1-2 minutes). Subsequent runs use the cached image and start in seconds.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                  Docker Container (non-root, nanobot:1000)    │
│                                                              │
│  ┌──────────────┐   ┌─────────────┐                         │
│  │   Gateway    │   │  API Server │                         │
│  │  (port 18790)│   │ (port 8900) │                         │
│  └──────┬───────┘   └──────┬──────┘                         │
│         │                  │                                  │
│  ┌──────┴──────────────────┴──────────────────────────────┐  │
│  │         nanobot CLI & Agent (via uv tool install)       │  │
│  │   Session Memory │ Dream │ Cron │ Tools │ MCP           │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                              │
│  ~/.nanobot/ (Docker volume)                                 │
│    config.json  workspace/  memory/  cron/  sessions/        │
└──────────────────────────────────────────────────────────────┘
```

## License

This project is licensed under **GNU Affero General Public License v3 (AGPL-3.0)**.
See the [LICENSE](LICENSE) file for full terms.

This is intentionally different from nanobot's MIT license. The AGPL-3.0 ensures
that anyone who uses this Docker image — especially in a networked/service context —
must also distribute their modifications under the same license.