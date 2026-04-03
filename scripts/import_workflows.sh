#!/bin/bash
# ============================================================
# Importar workflow en n8n via CLI
# Ejecutar desde la raiz del repositorio
# ============================================================

set -e

N8N_CONTAINER="${N8N_CONTAINER:-n8n-app}"
WORKFLOWS_DIR="$(dirname "$0")/../workflows"

echo "=== Importando workflow de n8n ==="
echo "Contenedor: $N8N_CONTAINER"
echo "Directorio: $WORKFLOWS_DIR"
echo ""

WORKFLOW_FILE="foronum_news_pipeline.json"
filepath="$WORKFLOWS_DIR/$WORKFLOW_FILE"

if [ -f "$filepath" ]; then
    echo "Importando: $WORKFLOW_FILE"
    docker exec -i "$N8N_CONTAINER" n8n import:workflow --input=/dev/stdin < "$filepath"
    echo "  OK"
else
    echo "  ERROR: $filepath no encontrado"
    exit 1
fi

echo ""
echo "=== Importacion completada ==="
echo ""
echo "IMPORTANTE: Despues de importar:"
echo "1. Abre el workflow en n8n"
echo "2. Selecciona la credencial MySQL correcta en cada nodo"
echo "3. Configura OPENAI_API_KEY en Settings > Environment Variables"
echo "4. Guarda el workflow"
echo "5. Ejecuta manualmente para poblar la cache de enlaces"
echo "6. Activa el workflow"
