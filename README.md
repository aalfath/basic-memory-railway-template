[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/basic-memory?utm_medium=integration&utm_source=button&utm_campaign=basic-memory)

# Basic Memory on Railway

One-click Railway template for [Basic Memory](https://github.com/basicmachines-co/basic-memory), an open-source knowledge base that AI assistants read and write through MCP, with every note stored as Markdown.

## What it deploys

| Service | What it does |
|---|---|
| **Basic Memory** (built from this repo) | Basic Memory **1.0.0** (`ghcr.io/basicmachines-co/basic-memory:1.0.0@sha256:cad49f5433bcd8592fea547907a2b967435b3fa60d0f81ebc4d558e2b5cb55a8`) as a streamable-HTTP MCP server on `127.0.0.1:8000`, behind a Caddy 2.11.9 front on `$PORT` that requires a bearer token. Volume `/data` holds the notes (`/data/notes/main`), the SQLite index and config (`/data/.basic-memory`) and the cached FastEmbed model. |

Upstream's HTTP transport has no authentication, so this template never exposes it directly: every request except `GET /healthz` needs `Authorization: Bearer $MCP_BEARER_TOKEN`.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `MCP_BEARER_TOKEN` | `${{secret(48, …)}}` | Generated on deploy. Clients send it as `Authorization: Bearer …`. Change it in Railway's Variables tab to revoke old clients. |
| `PORT` | `8080` | Port Caddy listens on; the Railway domain points here. |

Nothing else is required. Semantic search runs locally (FastEmbed `bge-small-en-v1.5`, CPU), so no API key is needed. Upstream's other `BASIC_MEMORY_*` settings can be added as variables if you need them.

## Connect a client

The MCP endpoint is `https://YOUR-DOMAIN/mcp`.

```bash
claude mcp add --transport http basic-memory https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP_BEARER_TOKEN"
```

```json
{
  "mcpServers": {
    "basic-memory": {
      "url": "https://YOUR-DOMAIN/mcp",
      "headers": { "Authorization": "Bearer YOUR-MCP_BEARER_TOKEN" }
    }
  }
}
```

## Resources

Runs in Railway's 0.5 GB / 1 vCPU Free and Trial limits: about 200 MB idle and 420-460 MB of anonymous memory while it embeds notes (tested with 300 notes written back to back, no OOM). The image caps FastEmbed to one thread and tunes glibc malloc so memory is returned after each write. For imports of thousands of notes at once, give the service 1 GB. If the MCP server or Caddy stops, the start script exits 1 so Railway's `ON_FAILURE` restart policy restarts it.

## Updates

Railway notifies you when this repo's `main` changes (a new Basic Memory release). Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Your `/data` volume is kept across updates.

## Licence

Basic Memory is AGPL-3.0 (© Basic Machines). This wrapper only adds a Dockerfile, a Caddyfile and a start script.
