# Deploy and Host Basic Memory on Railway

Basic Memory is an open-source knowledge base that AI assistants read and write through the Model Context Protocol (MCP). Every note is a plain Markdown file, linked to other notes by wiki-style relations, and indexed for full-text and semantic search, so an assistant can pick up context from earlier conversations.

## About Hosting Basic Memory

This template runs Basic Memory 1.0.0 as a remote MCP server (streamable HTTP) on one Railway service, built from a public GitHub repo that pins the official image by version and digest. Upstream's HTTP server has no login of its own, so a small Caddy front in the same container requires a bearer token that Railway generates on deploy. Notes, the SQLite index and the cached embedding model live on a Railway volume at `/data`, so they survive redeploys and restarts. After deploy, copy `MCP_BEARER_TOKEN` from the service's Variables tab and add the server to your MCP client. No API key is needed: semantic search runs locally on the CPU.

## Common Use Cases

* Give Claude, Cursor, Codex or another MCP client a long-term memory that persists across chats and machines
* Keep project notes, decisions and research as linked Markdown that both you and your assistant can edit
* Share one knowledge base between several AI tools and devices through a single HTTPS endpoint

## Dependencies for Basic Memory Hosting

* A Railway volume for notes, the search index and the embedding model cache
* An MCP client that supports remote servers with a custom `Authorization` header

### Deployment Dependencies

* Basic Memory on GitHub: https://github.com/basicmachines-co/basic-memory
* Basic Memory documentation: https://docs.basicmemory.com
* Template source and changelog: https://github.com/aalfath/basic-memory-railway-template

### Implementation Details

The template deploys one service, **Basic Memory**: the MCP server on `127.0.0.1:8000` and Caddy on Railway's `PORT`. `/healthz` answers without a token for Railway's health check; every other path needs the header `Authorization: Bearer YOUR-MCP_BEARER_TOKEN`. The MCP endpoint is `https://YOUR-DOMAIN/mcp`.

Claude Code:

```bash
claude mcp add --transport http basic-memory https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP_BEARER_TOKEN"
```

Clients that use a JSON config (Cursor, VS Code and others):

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

Notes go into the project `main` at `/data/notes/main`. Memory: the server runs in Railway's 0.5 GB Free/Trial limit (about 200 MB idle and 420-460 MB while it embeds notes, tested with 300 notes written in a row); give it 1 GB if you import thousands of notes at once. If the server stops unexpectedly the container exits non-zero, so Railway's restart policy brings it back. Updates: when the template repo moves to a new Basic Memory release, Railway shows an update notice on your service; read `CHANGELOG.md` first, then apply it. Your volume is kept.

## Why Deploy Basic Memory on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Basic Memory on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
