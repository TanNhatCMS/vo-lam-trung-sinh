# Dev image: chạy nguyên project Godot headless làm dedicated server (không cần export).
# Production sau này có thể chuyển sang export preset "Linux Server" (pck) cho image mỏng hơn.
#
# Build:   docker build -f deploy/Dockerfile -t vts-server:dev .
# Run:     docker run -d --name vts-server -p 9000:9000 vts-server:dev
# Compose: docker compose -f deploy/docker-compose.yml up -d --build

ARG GODOT_VERSION=4.7.2-stable
FROM debian:bookworm-slim
ARG GODOT_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip fontconfig \
 && rm -rf /var/lib/apt/lists/*

# Godot Linux binary (headless run). Đổi GODOT_VERSION khi nâng cấp engine.
RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
 && unzip -q /tmp/godot.zip -d /opt/godot \
 && mv /opt/godot/Godot_v*_linux.x86_64 /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm /tmp/godot.zip

WORKDIR /game
COPY game/ ./

ENV VTS_PORT=9000
EXPOSE 9000

# core/app.gd thấy cờ "--server" (hoặc chạy headless) sẽ chuyển sang scene server
CMD ["godot", "--headless", "--path", "/game", "--", "--server"]
