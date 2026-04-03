#!/usr/bin/env bash
set -euo pipefail
cd /opt/n8n
docker compose pull
docker compose up -d
