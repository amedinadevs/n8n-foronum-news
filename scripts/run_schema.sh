#!/bin/bash
# ============================================================
# Ejecutar schema.sql y seed en MySQL
# Ejecutar desde la raiz del repositorio
# ============================================================

set -e

MYSQL_CONTAINER="${MYSQL_CONTAINER:-n8n-mysql}"
MYSQL_DB="${MYSQL_DATABASE:-foronum_n8n}"
MYSQL_USER="${MYSQL_USER:-foronum}"
SQL_DIR="$(dirname "$0")/../sql"

echo "=== Ejecutando schema SQL ==="
echo "Contenedor: $MYSQL_CONTAINER"
echo "Base de datos: $MYSQL_DB"
echo ""

# Esperar a que MySQL este listo
echo "Esperando a que MySQL este listo..."
for i in $(seq 1 30); do
    if docker exec "$MYSQL_CONTAINER" mysqladmin ping -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
        echo "MySQL listo."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: MySQL no respondio en 30 segundos"
        exit 1
    fi
    sleep 1
done

echo ""
echo "1/2 Ejecutando schema.sql..."
docker exec -i "$MYSQL_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$SQL_DIR/schema.sql"
echo "  OK"

echo ""
echo "2/2 Ejecutando seed_examples.sql..."
docker exec -i "$MYSQL_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$SQL_DIR/seed_examples.sql"
echo "  OK"

echo ""
echo "=== Schema y seed ejecutados correctamente ==="
echo ""
echo "Verificando tablas creadas:"
docker exec "$MYSQL_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "SHOW TABLES LIKE 'fn_%';"

echo ""
echo "Conteo de registros seed:"
docker exec "$MYSQL_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" -e "
SELECT 'fn_news_sources' AS tabla, COUNT(*) AS registros FROM fn_news_sources
UNION ALL
SELECT 'fn_foronum_links', COUNT(*) FROM fn_foronum_links
UNION ALL
SELECT 'fn_news', COUNT(*) FROM fn_news;"
