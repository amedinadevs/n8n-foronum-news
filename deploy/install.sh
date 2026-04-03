#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="/opt/n8n"
mkdir -p "$TARGET_DIR"
cp docker-compose.yml "$TARGET_DIR/"
if [ ! -f "$TARGET_DIR/.env" ]; then
  cp .env.example "$TARGET_DIR/.env"
  echo "Edita $TARGET_DIR/.env antes de arrancar en producción."
fi
cd "$TARGET_DIR"
docker compose up -d
