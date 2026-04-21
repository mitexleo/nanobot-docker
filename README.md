# nanobot-docker

Docker image for [nanobot](https://github.com/HKUDS/nanobot) — an open-source AI agent framework for building multi-channel LLM agents with session memory, cron scheduling, tool calling, and more.

## Features

- Multi-channel support (Telegram, Discord, Slack, Microsoft Teams, WebSocket, etc.)
- Session memory with automatic context compaction
- Cron job scheduling
- OpenAI-compatible API server with SSE streaming
- Built-in tools (file reading, web search, code execution, and more)
- Regular image updates via automated GitHub Actions (every 3 hours)

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose v2+
- (Optional) API key for your LLM provider (OpenAI, Anthropic, Google, DeepSeek, etc.)

### 1. Clone and configure

```bash
git clone https://github.com/mitexleo/nanobot-docker.git
cd nanobot-docker
cp .env.example .env
```

### 2. Set your API key

Edit the `.env` file and add your API key:

```bash
# .env
MODEL_PROVIDER=openai
OPENAI_API_KEY=sk-your-actual-api-key
GPT_MODEL=gpt-4o-mini
```

### 3. Start the container

```bash
docker compose up -d
```

### 4. Check logs

```bash
docker compose logs -f
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `MODEL_PROVIDER` | `openai` | LLM provider: `openai`, `anthropic`, `google`, `deepseek`, etc. |
| `GPT_MODEL` | `gpt-4o-mini` | Model name (provider-specific) |
| `OPENAI_API_KEY` | — | OpenAI API key |
| `ANTHROPIC_API_KEY` | — | Anthropic API key (for Claude) |
| `GOOGLE_API_KEY` | — | Google API key (for Gemini) |
| `DEEPSEEK_API_KEY` | — | DeepSeek API key |
| `API_SERVER_HOST` | `0.0.0.0` | API server bind host |
| `API_SERVER_PORT` | `8000` | API server port |
| `API_KEYS` | — | Comma-separated API keys for API server auth |
| `SESSION_NAME` | `nanobot_session` | Session name |
| `AUTO_COMPACT` | `true` | Enable automatic context compaction |

### Channel Configuration

For channel integrations (Telegram, Discord, etc.), mount a custom config file:

```bash
# config/nanobot.yml
channel:
  type: telegram
  telegram:
    bot_token: your-telegram-bot-token
```

Then update your `docker-compose.yml` to mount the config:

```yaml
services:
  nanobot:
    volumes:
      - ./config:/app/config:ro
```

### Custom Config File

Mount your own `nanobot.yml` to `./config/nanobot.yml`:

```bash
mkdir -p config
# Create your config/nanobot.yml
docker compose restart
```

## Usage

### Run interactively

```bash
docker compose run --rm nanobot
```

### Access the API server

The API server starts on port 8000 by default. Configure it via environment:

```bash
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8000
API_KEYS=your-secure-key
```

### Stop the container

```bash
docker compose down
```

### Update the image

```bash
docker compose pull
docker compose up -d
```

## Available Image Tags

| Tag | Description |
|---|---|
| `latest` | Most recent build |
| `vX.Y.Z` | Specific nanobot release (e.g., `v0.1.5.post2`) |

## Deployment

### VPS / Server Deployment

1. SSH into your server
2. Install Docker and Docker Compose
3. Clone the repo and configure `.env`
4. Run `docker compose up -d`
5. Set up a reverse proxy (nginx/caddy) for HTTPS if exposing the API server

### Railway

1. Create a new Railway project
2. Add a Dockerfile (already included)
3. Set environment variables via Railway dashboard
4. Deploy

### Render

1. Create a new Web Service on Render
2. Connect your GitHub repo
3. Set build command: leave empty (Dockerfile is used)
4. Set start command: `nanobot run --config-dir /app/config`
5. Add environment variables

### Fly.io

```bash
fly launch
fly secrets set OPENAI_API_KEY=sk-...
fly deploy
```

## Architecture

```
┌─────────────────────────────────────────┐
│         Docker Container                │
│  ┌─────────────────────────────────┐    │
│  │         nanobot                 │    │
│  │  ┌──────────┐  ┌─────────────┐  │    │
│  │  │ Channel  │  │  API Server │  │    │
│  │  │ Handlers │  │  (port 8000)│  │    │
│  │  └──────────┘  └─────────────┘  │    │
│  │  ┌──────────────────────────┐    │    │
│  │  │   Session Memory        │    │    │
│  │  └──────────────────────────┘    │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Building Locally

```bash
docker build -t mitexleo/nanobot-docker:local .
docker run -it --env-file .env mitexleo/nanobot-docker:local
```

## Troubleshooting

### Container exits immediately

Check logs: `docker compose logs`. Usually a missing API key or config error.

### API server not accessible

Ensure port 8000 is not in use and the container is running:
```bash
docker compose ps
docker compose logs | grep api
```

### Slow startup

The image installs nanobot on every build. Subsequent runs use the cached image. First start may take 1-2 minutes.

## License

This project is licensed under the same terms as [nanobot](https://github.com/HKUDS/nanobot).