# Workflows

## Vision general

El pipeline consta de 1 workflow unificado de n8n (`foronum_news_pipeline.json`) con 55 nodos, organizado en 5 fases secuenciales. Se ejecuta cada 6 horas. Las fases se comunican via columnas `status` en MySQL (estado-maquina). Todas las queries MySQL se construyen en nodos Code con la funcion `esc()` (sin queries parametrizadas, sin capa PHP).

---

## Fase 1: Cache Refresh

**Funcion:** Refrescar cache de enlaces internos desde catalogo de Foronum.

### Nodos:
1. **Schedule Trigger** - disparo cada 6h (inicio del workflow completo)
2. **Get Foronum Coins** (MySQL)
3. **Get Foronum Banknotes** (MySQL)
4. **Get Foronum Series** (MySQL)
5. **Get Foronum Countries** (MySQL)
6. **Get Foronum Topics** (MySQL)
   - Los nodos 2-6 se ejecutan en paralelo
7. **Merge All Results**
8. **Clear Link Cache** - DELETE FROM `fn_foronum_links`
9. **Split In Batches** (100)
10. **Insert Links**
11. **Log Result**

### Tabla
`fn_foronum_links` (cache de enlaces internos)

### Referencia
`sql/foronum_mapping.sql`

> **NOTA:** Las queries SELECT deben adaptarse a las tablas reales del catalogo de Foronum.

---

## Fase 2: Discovery

**Funcion:** Escanear fuentes de noticias numismaticas y almacenar novedades en `fn_news`.

### Nodos:
1. **Get Active Sources** - SELECT fuentes activas de `fn_news_sources`
2. **Split In Batches** - iterar por fuente
3. **IF RSS or HTML** - bifurcar segun `scrape_type`
   - **RSS:** RSS Feed Read + Code normalizar
   - **HTML:** HTTP Request + HTML Extract + Code normalizar
4. **Merge** - combinar ambas ramas
5. **Generate URL Hash** - SHA-256 de cada URL para dedup
6. **Insert News** - INSERT IGNORE en `fn_news` con `status='discovered'`
7. **Update Source Timestamp** - actualizar `last_scraped_at`
8. **Log** - registrar en `fn_pipeline_log`

### Estados
- `fn_news.status` = `'discovered'`

### Fuentes configuradas
CoinWorld, Numismatic News, CoinsWeekly, CoinNews, US Mint

### Deduplicacion
Via `url_hash` UNIQUE constraint. Se genera un SHA-256 de la URL completa antes de insertar. Si el hash ya existe, el INSERT IGNORE descarta el duplicado silenciosamente.

---

## Fase 3: Enrichment

**Funcion:** Descargar pagina completa, extraer entidades con LLM, clasificar, resolver enlaces internos.

### Nodos:
1. **Get Discovered News** - SELECT `status='discovered'` LIMIT 10
2. **Has Results?** - IF hay items
3. **Split In Batches** (1 a 1)
4. **Fetch Full Page** - HTTP GET de la URL
5. **Store Raw HTML** - guardar en `raw_html`
6. **Clean HTML** - limpiar scripts/styles, extraer texto
7. **Build LLM Prompt** - prompt de extraccion de entidades + clasificacion
8. **Classify & Extract** - HTTP POST a OpenAI (gpt-4o-mini)
9. **Parse LLM Response** - parsear JSON
10. **IF Score >= 40** - bifurcar
    - **SI:** Update con entidades + enlaces -> Mark `status='enriched'` -> Find Matching Links -> Rank & Select Links -> Update Links
    - **NO:** Mark `status='rejected'`
11. **Log**

### Estados
- `fn_news`: `'discovered'` -> `'enriched'` / `'rejected'`

### Modelo LLM
gpt-4o-mini (clasificacion barata)

### Entidades extraidas
`country`, `denomination`, `mint`, `piece_type`, `series`, `year`, `metal`, `event_type`

### Links
2-4 por idioma, priorizados por `entity_type`

---

## Fase 4: Generation

**Funcion:** Generar articulo en espanol, re-generar en 5 idiomas, validar, almacenar.

### Subfases:

#### Fase 4A - Obtener items
1. **Get Enriched News** - SELECT `fn_news` WHERE `status='enriched'` LIMIT 5
2. **Has Items?** - IF
3. **Per Article** - Split In Batches
4. **Mark article_ready** - UPDATE `fn_news.status='article_ready'`

#### Fase 4B - Generar articulo ES
5. **Prepare ES Context** - ensamblar prompt con enlaces ES
6. **Generate ES Article** - HTTP POST a OpenAI (gpt-4o)
7. **Parse ES Article**

#### Fase 4C - Traducir a 5 idiomas
8. **Prepare Languages** - crear array `[en, fr, de, it, pt]`
9. **Per Language** - Split In Batches
10. **Build Translation Prompt** - prompt con enlaces del idioma target
11. **Generate Translation** - HTTP POST a OpenAI (gpt-4o)
12. **Parse Translation**

#### Fase 4D - Validar y almacenar
13. **Collect All Translations**
14. **Validate All** - titulo <70 chars, meta <160, body >=300 palabras, 2-4 enlaces, originalidad Jaccard <0.6
15. **IF Validation Passed**
    - **SI:** Insert Article (validated) -> Insert 6 Translations -> Mark fn_news `status='article_ready'`
    - **NO:** Insert Failed Article -> Mark fn_news `status='error'`
16. **Log**

### Estados
- `fn_news`: `'enriched'` -> `'article_ready'` / `'error'`
- `fn_articles`: `'validated'` / `'validation_failed'`

### Modelo LLM
gpt-4o (generacion de calidad)

### Validaciones
- Originalidad: similitud Jaccard < 0.6 respecto a la fuente original
- Longitud del cuerpo: >= 300 palabras
- Conteo de enlaces internos: entre 2 y 4
- Longitud de titulo: < 70 caracteres
- Longitud de meta description: < 160 caracteres

---

## Fase 5: Publication + Notification

**Funcion:** Publicar articulos validados directamente en MySQL de Foronum + enviar email.

### Nodos:
1. **Get Validated Articles** - SELECT `fn_articles` WHERE `status='validated'` LIMIT 3
2. **Has Articles?** - IF
3. **Split In Batches** (por articulo)
4. **Mark Publishing**
5. **Get Translations** - SELECT 6 traducciones de `fn_article_translations`
6. **Insert Foronum Post** - INSERT en tabla CMS de Foronum
7. **Get Post ID** - preparar inserts por idioma
8. **Per Language** - Split In Batches (por traduccion)
9. **Insert Foronum Translation** - INSERT en tabla traducciones CMS
10. **Get Translation IDs**
11. **Update Article Translation** - guardar `foronum_translation_id`
12. **Mark Published** - UPDATE `fn_articles.status='published'`, UPDATE `fn_news.status='published'`
13. **Build Email Body** - resumen HTML
14. **Send Email** - SMTP
15. **Log**

### Estados
- `fn_articles`: `'validated'` -> `'publishing'` -> `'published'` / `'failed'`
- `fn_news`: `'article_ready'` -> `'published'`

### Insercion
Directa a MySQL de Foronum (sin PHP intermedio). Las queries INSERT se construyen en nodos Code con `esc()`.

### Notificacion
Email SMTP al equipo editorial con resumen del articulo publicado.

> **NOTA:** Las queries INSERT de Foronum son ejemplos que deben adaptarse al CMS real. Revisar la estructura de tablas del CMS antes de configurar este workflow.
