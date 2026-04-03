# Arquitectura del Pipeline

## Objetivo
Automatizar la deteccion de noticias numismaticas, enriquecer con entidades, resolver enlaces internos SEO de Foronum, y generar articulos multidioma publicados directamente en la base de datos.

## Componentes

### n8n
Orquestacion mediante 1 workflow unificado de 55 nodos (`foronum_news_pipeline.json`). Se ejecuta cada 6 horas. Conecta directamente a MySQL de Foronum sin capa PHP intermedia.

### PostgreSQL 16
Base de datos interna de n8n (metadatos de workflows, ejecuciones, credenciales). NO almacena datos del pipeline.

### MySQL 8.0 (Foronum)
Base de datos principal. Almacena:
- Tablas del pipeline (prefijo fn_): fn_news_sources, fn_news, fn_foronum_links, fn_articles, fn_article_translations, fn_pipeline_log
- Tablas del catalogo de Foronum: monedas, billetes, series, paises, temas (con traducciones por idioma)
- Tablas CMS de Foronum: posts, traducciones de posts

### OpenAI API
Modelo gpt-4o-mini para clasificacion (fase enrichment). Modelo gpt-4o para generacion de articulos (fase generation). Llamadas via HTTP Request.

### SMTP
Notificaciones por email al equipo editorial (fase publication).

## Flujo del Pipeline

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
Fase 5: Publication + Notification --> Tablas CMS Foronum + Email
```

## Fases del workflow

| Fase | Nombre | Funcion |
|------|--------|---------|
| 1 | Cache Refresh | Refresca cache de enlaces internos desde catalogo |
| 2 | Discovery | Escanea RSS/HTML, normaliza, dedup por hash |
| 3 | Enrichment | Descarga pagina, extrae entidades con LLM, clasifica, resuelve enlaces |
| 4 | Generation | Genera ES + 5 idiomas, valida originalidad/enlaces/contenido |
| 5 | Publication + Notification | INSERT directo en Foronum, email de notificacion |

## Comunicacion entre fases
Via columnas `status` en MySQL (estado-maquina). Cada fase lee items en un estado y los transiciona al siguiente. Todo dentro de un unico workflow secuencial.

### Estados de fn_news
`discovered` -> `enriched` -> `article_ready` -> `published`
Alternativos: `rejected`, `error`

## Base de datos: 6 tablas

| Tabla | Funcion |
|-------|---------|
| fn_news_sources | Config de fuentes RSS/HTML |
| fn_news | Noticias descubiertas + enriquecidas (estados unificados) |
| fn_foronum_links | Cache de enlaces internos |
| fn_articles | Articulos maestros |
| fn_article_translations | Traducciones (6 por articulo) |
| fn_pipeline_log | Auditoria |

## Queries MySQL
Todas las queries se construyen en nodos Code usando la funcion `esc()` para escapar valores. No se usan queries parametrizadas ni capa PHP.

## Idiomas soportados
es, en, fr, de, it, pt

## Regla SEO clave
Nunca traducir slugs a mano. Resolver siempre la URL real por idioma desde la base de datos. Cada articulo solo usa URLs validas del idioma de salida.

## Seguridad
- Credenciales almacenadas en n8n (cifradas con N8N_ENCRYPTION_KEY)
- .env con passwords nunca se sube a Git
- MySQL con usuario dedicado y permisos minimos
