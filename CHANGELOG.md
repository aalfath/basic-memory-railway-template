# Changelog

## 1.0.0 (2026-11-23)

First release of the template.

- Basic Memory 1.0.0 (`ghcr.io/basicmachines-co/basic-memory:1.0.0@sha256:cad49f5433bcd8592fea547907a2b967435b3fa60d0f81ebc4d558e2b5cb55a8`), streamable-HTTP MCP at `/mcp`.
- Caddy 2.11.9 front with a generated bearer token (`MCP_BEARER_TOKEN`); `/healthz` for Railway's health check.
- All state on the `/data` volume: notes, SQLite index, config and the FastEmbed model cache.
- Fits 0.5 GB: FastEmbed on one thread, glibc arenas capped and freed memory trimmed.
