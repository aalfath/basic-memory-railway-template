# Basic Memory on Railway: upstream image pinned by version and digest, plus a
# small Caddy front that requires a bearer token (upstream's HTTP MCP has no auth).
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM ghcr.io/basicmachines-co/basic-memory:1.0.0@sha256:cad49f5433bcd8592fea547907a2b967435b3fa60d0f81ebc4d558e2b5cb55a8

USER root
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh /usr/local/bin/caddy \
    && /usr/local/bin/caddy version

ENV PORT=8080 \
    BM_DATA_DIR=/data \
    BASIC_MEMORY_NO_PROMOS=1 \
    BASIC_MEMORY_LOGFIRE_ENABLED=false \
    BASIC_MEMORY_SEMANTIC_EMBEDDING_THREADS=1 \
    BASIC_MEMORY_SEMANTIC_EMBEDDING_PARALLEL=1 \
    BASIC_MEMORY_MATERIALIZATION_WORKERS=2 \
    BASIC_MEMORY_INDEX_PARSE_MAX_CONCURRENT=2 \
    BASIC_MEMORY_INDEX_ENTITY_MAX_CONCURRENT=2 \
    BASIC_MEMORY_INDEX_METADATA_UPDATE_MAX_CONCURRENT=2 \
    OMP_NUM_THREADS=1 \
    MALLOC_ARENA_MAX=1 \
    MALLOC_TRIM_THRESHOLD_=65536 \
    MALLOC_MMAP_THRESHOLD_=65536 \
    GOMAXPROCS=1

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/start.sh"]
