# n8n-foronum

Pipeline automatizado de noticias numismaticas para Foronum. Detecta novedades, enriquece con entidades, genera articulos SEO en 6 idiomas con enlaces internos reales, y publica directamente en la base de datos.

## Arquitectura

```
Schedule Trigger (cada 6h)
    |
    v
Fase 1: Cache Refresh --> fn_foronum_links <-- Catalogo Foronum
    |
    v
Fase 2: Discovery --> fn_news (status: discovered)
    |
    v
Fase 3: Enrichment --> fn_news (status: enriched / rejected)
    |
    v
Fase 4: Generation --> fn_articles + fn_article_translations
    |
    v
Fase 5: Publication + Notification --> MySQL Foronum + Email
```

**1 workflow unificado** (`foronum_news_pipeline.json`, 55 nodos) ejecutado cada 6 horas. Comunicacion entre fases via columnas `status` en MySQL. Sin capa PHP intermedia: insercion directa a la base de datos. Queries construidas en nodos Code con `esc()`.

## Componentes

- **n8n**: orquestacion del workflow unificado
- **PostgreSQL 16**: base de datos interna de n8n
- **MySQL 8.0**: pipeline (tablas `fn_*`) + catalogo y CMS de Foronum
- **OpenAI API**: gpt-4o-mini (clasificacion) + gpt-4o (generacion)
- **SMTP**: notificaciones por email

## Estructura del repositorio

```
workflows/           1 workflow JSON exportado de n8n
  foronum_news_pipeline.json
sql/
  schema.sql         6 tablas del pipeline (MySQL)
  seed_examples.sql  Fuentes + enlaces de ejemplo + datos test
  foronum_mapping.sql  Queries adaptables al esquema real de Foronum
  migrations/        Esquema versionado
docs/
  arquitectura.md    Arquitectura completa del sistema
  workflows.md       Detalle de cada fase del workflow y sus nodos
  prompts.md         Prompts LLM con razonamiento y costes
  entidades-y-enlaces.md  Tipos de entidad, prioridades, reglas SEO
  deployment-guide.md     Guia paso a paso de despliegue
  troubleshooting.md      Diagnostico y resolucion de problemas
deploy/
  docker-compose.yml  PostgreSQL + MySQL + n8n
  .env.example        Template de variables de entorno
  install.sh          Script de instalacion
  update.sh           Script de actualizacion
  plesk-nginx.conf    Config reverse proxy
scripts/
  import_workflows.sh  Importar workflow en n8n via CLI
  run_schema.sh        Ejecutar schema.sql en MySQL
  backup_examples.sh   Backup de bases de datos
```

## Inicio rapido

```bash
# 1. Clonar
git clone <url> n8n-foronum && cd n8n-foronum

# 2. Configurar
cp deploy/.env.example deploy/.env
# Editar deploy/.env con tus credenciales

# 3. Levantar
cd deploy && docker compose up -d

# 4. Acceder a n8n
open http://localhost:5678

# 5. Configurar credenciales MySQL y OpenAI en n8n

# 6. Importar foronum_news_pipeline.json

# 7. Ejecutar manualmente para poblar cache de enlaces y verificar

# 8. Activar el workflow
```

Ver [docs/deployment-guide.md](docs/deployment-guide.md) para instrucciones detalladas.

## Fases del pipeline

| Fase | Funcion | Modelo LLM |
|------|---------|------------|
| 1. Cache Refresh | Refresca cache de enlaces internos desde catalogo | - |
| 2. Discovery | Escanea RSS/HTML, dedup por hash | - |
| 3. Enrichment | Entidades + clasificacion + enlaces | gpt-4o-mini |
| 4. Generation | Genera ES + 5 idiomas, valida | gpt-4o |
| 5. Publication + Notification | INSERT en Foronum + email | - |

## Idiomas

es (espanol), en (ingles), fr (frances), de (aleman), it (italiano), pt (portugues)

## Fuentes de noticias

- [CoinWorld](https://www.coinworld.com) (RSS)
- [Numismatic News](https://www.numismaticnews.net) (RSS)
- [CoinsWeekly](https://coinsweekly.com) (RSS)
- [CoinNews](https://www.coinnews.net) (RSS)
- [US Mint](https://www.usmint.gov) (HTML scraping)

## Costes estimados

Estrategia hibrida (gpt-4o-mini clasificacion + gpt-4o generacion), 10 articulos/dia:

| Concepto | Coste mensual |
|----------|--------------|
| OpenAI API | ~$54 |
| Infraestructura (VPS) | variable |
| **Total** | **~$54/mes** |

Alternativa economica con gpt-4o-mini para todo: ~$3.40/mes

## Base de datos

6 tablas con prefijo `fn_`:

| Tabla | Funcion |
|-------|---------|
| fn_news_sources | Config de fuentes |
| fn_news | Noticias descubiertas + enriquecidas (status: discovered -> enriched -> rejected -> article_ready -> published -> error) |
| fn_foronum_links | Cache de enlaces internos |
| fn_articles | Articulos maestros (news_id referencia a fn_news) |
| fn_article_translations | Traducciones (6 por articulo) |
| fn_pipeline_log | Auditoria |

## Documentacion

- [Arquitectura](docs/arquitectura.md)
- [Workflows detallados](docs/workflows.md)
- [Prompts LLM](docs/prompts.md)
- [Entidades y enlaces](docs/entidades-y-enlaces.md)
- [Guia de despliegue](docs/deployment-guide.md)
- [Troubleshooting](docs/troubleshooting.md)

## Git: que subir y que no

**Si:** workflows JSON, documentacion, scripts, SQL, .env.example

**No:** .env real, credenciales, dumps de BD, backups, claves API

## Flujo de desarrollo

1. Disenar y probar en `n8n-dev`
2. Exportar workflow JSON a `workflows/`
3. Versionar cambios en Git
4. Revisar prompts, SQL y queries
5. Importar en `n8n-prod`
