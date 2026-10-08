# ==========================================
# STAGE 1: Fetch and Extract Asset
# ==========================================
FROM debian:bookworm-slim AS builder

ARG VERSION=latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates jq tar && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN if [ "$VERSION" = "latest" ]; then \
      TAG_NAME=$(curl -sSL https://api.github.com/repos/gnacho/netpulse/releases/latest | jq -r .tag_name); \
    else \
      TAG_NAME="v${VERSION#v}"; \
    fi && \
    SEM_VER="${TAG_NAME#v}" && \
    FILENAME="netpulse_${SEM_VER}_linux_amd64.tar.gz" && \
    URL="https://github.com/gnacho/netpulse/releases/download/${TAG_NAME}/${FILENAME}" && \
    echo "Fetching: ${URL}" && \
    curl -fL -H "User-Agent: Mozilla/5.0" -o "$FILENAME" "$URL" && \
    tar -xzf "$FILENAME" netpulse && \
    chmod +x netpulse

# ==========================================
# STAGE 2: Minimal Runtime Container
# ==========================================
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /tmp/netpulse /usr/local/bin/netpulse

WORKDIR /data

EXPOSE 3000
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/netpulse"]
