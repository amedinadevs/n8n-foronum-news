#!/usr/bin/env bash
set -euo pipefail

DATE=$(date +%F_%H-%M-%S)
mkdir -p backups

# Backup PostgreSQL interno de n8n
# Ajusta nombres de contenedor y credenciales según tu entorno.
docker exec n8n-postgres pg_dump -U n8n n8n > "backups/n8n_postgres_${DATE}.sql"

# Opcional: copia de workflows exportados ya versionados en Git
cp -R workflows "backups/workflows_${DATE}"

echo "Backup generado en backups/"
