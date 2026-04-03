-- ============================================================
-- Foronum Mapping - Queries de ejemplo
-- ============================================================
-- IMPORTANTE: Estas queries son EJEMPLOS que deben adaptarse
-- a las tablas reales del CMS de Foronum. Los nombres de tablas
-- y columnas son ilustrativos.
-- ============================================================

-- ============================================================
-- A. QUERIES PARA WF5: Leer catalogo de Foronum -> fn_foronum_links
-- ============================================================

-- A1. Leer monedas con sus traducciones por idioma
-- Adaptar: foronum_coins, foronum_coins_translations
SELECT
    c.id                    AS entity_id,
    'exact_coin'            AS entity_type,
    ct.name                 AS entity_name,
    ct.lang                 AS lang,
    CONCAT('/', ct.lang, '/monedas/', ct.slug) AS url,
    ct.slug                 AS slug,
    COALESCE(c.seo_priority, 50) AS seo_priority
FROM foronum_coins c
JOIN foronum_coins_translations ct ON c.id = ct.coin_id
WHERE c.is_active = 1
  AND ct.lang IN ('es','en','fr','de','it','pt');

-- A2. Leer billetes con sus traducciones
-- Adaptar: foronum_banknotes, foronum_banknotes_translations
SELECT
    b.id                    AS entity_id,
    'exact_banknote'        AS entity_type,
    bt.name                 AS entity_name,
    bt.lang                 AS lang,
    CONCAT('/', bt.lang, '/billetes/', bt.slug) AS url,
    bt.slug                 AS slug,
    COALESCE(b.seo_priority, 50) AS seo_priority
FROM foronum_banknotes b
JOIN foronum_banknotes_translations bt ON b.id = bt.banknote_id
WHERE b.is_active = 1
  AND bt.lang IN ('es','en','fr','de','it','pt');

-- A3. Leer series
-- Adaptar: foronum_series, foronum_series_translations
SELECT
    s.id                    AS entity_id,
    'series'                AS entity_type,
    st.name                 AS entity_name,
    st.lang                 AS lang,
    CONCAT('/', st.lang, '/series/', st.slug) AS url,
    st.slug                 AS slug,
    COALESCE(s.seo_priority, 50) AS seo_priority
FROM foronum_series s
JOIN foronum_series_translations st ON s.id = st.series_id
WHERE s.is_active = 1
  AND st.lang IN ('es','en','fr','de','it','pt');

-- A4. Leer paises
-- Adaptar: foronum_countries, foronum_countries_translations
SELECT
    co.id                   AS entity_id,
    'country'               AS entity_type,
    cot.name                AS entity_name,
    cot.lang                AS lang,
    CONCAT('/', cot.lang, '/paises/', cot.slug) AS url,
    cot.slug                AS slug,
    COALESCE(co.seo_priority, 50) AS seo_priority
FROM foronum_countries co
JOIN foronum_countries_translations cot ON co.id = cot.country_id
WHERE co.is_active = 1
  AND cot.lang IN ('es','en','fr','de','it','pt');

-- A5. Leer temas/topics
-- Adaptar: foronum_topics, foronum_topics_translations
SELECT
    t.id                    AS entity_id,
    'topic'                 AS entity_type,
    tt.name                 AS entity_name,
    tt.lang                 AS lang,
    CONCAT('/', tt.lang, '/temas/', tt.slug) AS url,
    tt.slug                 AS slug,
    COALESCE(t.seo_priority, 50) AS seo_priority
FROM foronum_topics t
JOIN foronum_topics_translations tt ON t.id = tt.topic_id
WHERE t.is_active = 1
  AND tt.lang IN ('es','en','fr','de','it','pt');


-- ============================================================
-- B. QUERIES PARA WF4: Publicar articulo en Foronum
-- ============================================================

-- B1. Insertar post maestro en Foronum
-- Adaptar: foronum_posts (o articles, news, etc.)
INSERT INTO foronum_posts (
    type,
    status,
    author_id,
    category_id,
    source_url,
    created_at,
    updated_at
) VALUES (
    'news_article',
    'published',
    :bot_user_id,           -- ID del usuario bot/automatico en Foronum
    :category_id,           -- Categoria de noticias numismaticas
    :source_news_url,       -- URL original de la noticia
    NOW(),
    NOW()
);
-- Guardar LAST_INSERT_ID() como foronum_post_id

-- B2. Insertar traducciones del post (una por idioma)
-- Adaptar: foronum_posts_translations
INSERT INTO foronum_posts_translations (
    post_id,
    lang,
    title,
    slug,
    excerpt,
    meta_description,
    body,
    featured_image_url,
    featured_image_alt,
    status,
    created_at,
    updated_at
) VALUES (
    :foronum_post_id,       -- ID del post recien creado
    :lang,                  -- 'es', 'en', 'fr', etc.
    :title,
    :slug,
    :excerpt,
    :meta_description,
    :body_html,
    :featured_image_url,
    :featured_image_alt,
    'published',
    NOW(),
    NOW()
);
-- Guardar LAST_INSERT_ID() como foronum_translation_id


-- ============================================================
-- C. QUERIES PARA WF2: Buscar enlaces en cache
-- ============================================================

-- C1. Buscar por nombre de entidad y tipo (matching exacto)
SELECT entity_type, entity_id, entity_name, lang, url, slug, seo_priority
FROM fn_foronum_links
WHERE entity_type = :entity_type
  AND LOWER(entity_name) LIKE CONCAT('%', LOWER(:search_term), '%')
  AND is_active = 1
ORDER BY seo_priority DESC;

-- C2. Buscar por keywords (matching fuzzy via JSON)
SELECT entity_type, entity_id, entity_name, lang, url, slug, seo_priority
FROM fn_foronum_links
WHERE is_active = 1
  AND JSON_SEARCH(LOWER(keywords_json), 'one', CONCAT('%', LOWER(:search_term), '%')) IS NOT NULL
ORDER BY seo_priority DESC;

-- C3. Obtener todos los enlaces de un idioma especifico para un entity_id
SELECT entity_type, entity_name, url, slug, seo_priority
FROM fn_foronum_links
WHERE entity_id = :entity_id
  AND entity_type = :entity_type
  AND lang = :lang
  AND is_active = 1;


-- ============================================================
-- D. TABLA DE MAPEO DE CAMPOS
-- ============================================================
-- fn_article_translations     ->  foronum_posts_translations
-- -------------------------------------------------------
-- title                       ->  title
-- slug                        ->  slug
-- excerpt                     ->  excerpt
-- meta_description            ->  meta_description
-- body_html                   ->  body
-- featured_image_url          ->  featured_image_url
-- featured_image_alt          ->  featured_image_alt
-- lang                        ->  lang
-- -------------------------------------------------------
