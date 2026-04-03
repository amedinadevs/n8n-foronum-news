-- ============================================================
-- Foronum News Pipeline - Schema SQL (v2 unificado)
-- Base de datos: MySQL 8.0+ (Foronum)
-- Prefijo: fn_ (Foronum News)
-- 6 tablas: fn_news_sources, fn_news, fn_foronum_links,
--           fn_articles, fn_article_translations, fn_pipeline_log
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. fn_news_sources: Configuracion de fuentes de noticias
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_news_sources (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name                    VARCHAR(100) NOT NULL,
    base_url                VARCHAR(500) NOT NULL,
    feed_url                VARCHAR(500) NULL COMMENT 'RSS/Atom feed URL si disponible',
    scrape_type             ENUM('rss', 'html_list', 'api') NOT NULL DEFAULT 'rss',
    selector_title          VARCHAR(255) NULL COMMENT 'CSS selector para titulo en scraping HTML',
    selector_link           VARCHAR(255) NULL COMMENT 'CSS selector para enlace del articulo',
    selector_date           VARCHAR(255) NULL COMMENT 'CSS selector para fecha',
    selector_summary        VARCHAR(255) NULL COMMENT 'CSS selector para resumen/extracto',
    selector_body           VARCHAR(255) NULL COMMENT 'CSS selector para cuerpo completo',
    is_active               TINYINT(1) NOT NULL DEFAULT 1,
    last_scraped_at         DATETIME NULL,
    scrape_interval_minutes INT UNSIGNED NOT NULL DEFAULT 360,
    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 2. fn_news: Noticias (discovery + enrichment unificados)
--    Reemplaza fn_news_raw + fn_news_enriched
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_news (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_id           INT UNSIGNED NOT NULL,

    -- Discovery
    title               VARCHAR(500) NOT NULL,
    url                 VARCHAR(1000) NOT NULL,
    url_hash            CHAR(64) NOT NULL COMMENT 'SHA-256 de la URL para deduplicacion',
    published_at        DATETIME NULL,
    summary             TEXT NULL,
    raw_html            MEDIUMTEXT NULL COMMENT 'HTML completo, rellenado en enrichment',

    -- Enrichment
    clean_text          MEDIUMTEXT NULL COMMENT 'Texto limpio extraido del HTML',
    entities_json       JSON NULL COMMENT '[{"type":"country","value":"USA"},...]',
    country             VARCHAR(100) NULL,
    denomination        VARCHAR(200) NULL,
    mint                VARCHAR(200) NULL,
    piece_type          ENUM('coin', 'banknote', 'medal', 'token', 'other') NULL,
    series              VARCHAR(200) NULL,
    year_referenced     VARCHAR(50) NULL,
    metal               VARCHAR(100) NULL,
    event_type          VARCHAR(200) NULL,
    llm_score           TINYINT UNSIGNED NULL COMMENT '0-100 puntuacion de interes',
    llm_classification  ENUM('high', 'medium', 'low', 'reject') NULL,
    llm_reasoning       TEXT NULL,
    seo_potential       TINYINT UNSIGNED NULL COMMENT '0-100 potencial SEO',
    resolved_links_json JSON NULL COMMENT '{"es":[...],"en":[...]}',
    link_count          TINYINT UNSIGNED NOT NULL DEFAULT 0,

    -- Status unificado
    status              ENUM('discovered', 'enriched', 'rejected', 'article_ready',
                            'published', 'error') NOT NULL DEFAULT 'discovered',
    error_message       TEXT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_url_hash (url_hash),
    INDEX idx_status (status),
    INDEX idx_source (source_id),
    INDEX idx_created (created_at),
    CONSTRAINT fk_news_source FOREIGN KEY (source_id) REFERENCES fn_news_sources(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 3. fn_foronum_links: Cache de enlaces internos de Foronum
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_foronum_links (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entity_type     ENUM('exact_coin', 'exact_banknote', 'series', 'country', 'topic') NOT NULL,
    entity_id       INT UNSIGNED NOT NULL COMMENT 'ID en las tablas originales de Foronum',
    entity_name     VARCHAR(500) NOT NULL COMMENT 'Nombre canonico para matching',
    lang            CHAR(2) NOT NULL,
    url             VARCHAR(1000) NOT NULL,
    slug            VARCHAR(500) NOT NULL,
    seo_priority    TINYINT UNSIGNED NOT NULL DEFAULT 50 COMMENT '0-100, mayor = preferir',
    keywords_json   JSON NULL COMMENT '["keyword1","keyword2"] para matching fuzzy',
    last_verified   DATETIME NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_entity_lang (entity_type, entity_id, lang),
    INDEX idx_entity_type_lang (entity_type, lang),
    INDEX idx_entity_name (entity_name(100)),
    INDEX idx_lang (lang),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 4. fn_articles: Articulos maestros
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_articles (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    news_id             BIGINT UNSIGNED NOT NULL COMMENT 'FK a fn_news',
    source_news_url     VARCHAR(1000) NOT NULL,

    status              ENUM('draft', 'validated', 'published', 'failed')
                        NOT NULL DEFAULT 'draft',
    validation_notes    TEXT NULL,
    originality_score   TINYINT UNSIGNED NULL COMMENT '0-100, mayor = mas original',

    -- Integracion Foronum
    foronum_post_id     INT UNSIGNED NULL,
    published_at        DATETIME NULL,

    -- Notificacion
    notification_sent       TINYINT(1) NOT NULL DEFAULT 0,
    notification_sent_at    DATETIME NULL,

    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_news_id (news_id),
    INDEX idx_status (status),
    INDEX idx_published (published_at),
    CONSTRAINT fk_article_news FOREIGN KEY (news_id) REFERENCES fn_news(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 5. fn_article_translations: Traducciones (6 por articulo)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_article_translations (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    article_id              BIGINT UNSIGNED NOT NULL,
    lang                    CHAR(2) NOT NULL,

    title                   VARCHAR(500) NOT NULL,
    slug                    VARCHAR(500) NOT NULL,
    excerpt                 VARCHAR(1000) NULL,
    meta_description        VARCHAR(320) NULL,
    body_html               MEDIUMTEXT NOT NULL,

    anchors_used_json       JSON NULL COMMENT '[{"text":"anchor","url":"...","entity_type":"..."}]',
    internal_link_count     TINYINT UNSIGNED NOT NULL DEFAULT 0,

    featured_image_url      VARCHAR(1000) NULL,
    featured_image_alt      VARCHAR(500) NULL,

    foronum_translation_id  INT UNSIGNED NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_article_lang (article_id, lang),
    INDEX idx_lang (lang),
    INDEX idx_slug (slug(100)),
    CONSTRAINT fk_translation_article FOREIGN KEY (article_id) REFERENCES fn_articles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- 6. fn_pipeline_log: Auditoria y debugging
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fn_pipeline_log (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    workflow_name   VARCHAR(100) NOT NULL,
    execution_id    VARCHAR(100) NULL,
    step            VARCHAR(50) NOT NULL,
    entity_type     VARCHAR(50) NULL,
    entity_id       BIGINT UNSIGNED NULL,
    level           ENUM('info', 'warn', 'error') NOT NULL DEFAULT 'info',
    message         TEXT NOT NULL,
    details_json    JSON NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_workflow (workflow_name),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_level (level),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
