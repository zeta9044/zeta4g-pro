FROM ubuntu:24.04

LABEL org.opencontainers.image.title="Zeta4G Pro Edition"
LABEL org.opencontainers.image.description="GraphRAG database server with vector search, RAG pipeline, and LLM integration"
LABEL org.opencontainers.image.vendor="Zeta4Lab"
LABEL org.opencontainers.image.url="https://zeta4.net"
LABEL org.opencontainers.image.source="https://github.com/zeta9044/zeta4g-pro"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      libssl3t64 \
      curl \
      tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r zeta4g && \
    useradd -r -g zeta4g -m -d /home/zeta4g -s /bin/bash zeta4g && \
    mkdir -p /data && chown zeta4g:zeta4g /data

ARG BINARIES_DIR=binaries
COPY ${BINARIES_DIR}/zeta4gd ${BINARIES_DIR}/zeta4gs ${BINARIES_DIR}/zeta4g-admin ${BINARIES_DIR}/zeta4gctl ${BINARIES_DIR}/zeta4g-onto \
     ${BINARIES_DIR}/zeta4g-index ${BINARIES_DIR}/zeta4g-rag ${BINARIES_DIR}/zeta4g-model ${BINARIES_DIR}/zeta4g-vector ${BINARIES_DIR}/zeta4g-fulltext \
     /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/zeta4g*

VOLUME /data

EXPOSE 9043 9044 9045

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -sf http://localhost:9044/ || exit 1

USER zeta4g
WORKDIR /data

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
CMD ["start"]
