-- ============================================================
-- Foronum News Pipeline - Datos de ejemplo / Seed (v2)
-- Ejecutar DESPUES de schema.sql
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Fuentes de noticias
-- ------------------------------------------------------------
INSERT INTO fn_news_sources (name, base_url, feed_url, scrape_type, is_active, scrape_interval_minutes) VALUES
('CoinWorld', 'https://www.coinworld.com', NULL, 'html_list', 1, 360),
('Numismatic News', 'https://www.numismaticnews.net', 'https://www.numismaticnews.net/feed', 'rss', 1, 360),
('CoinsWeekly', 'https://coinsweekly.com', 'https://coinsweekly.com/feed/', 'rss', 1, 360),
('CoinNews', 'https://www.coinnews.net', 'https://www.coinnews.net/feed/', 'rss', 1, 360),
('US Mint', 'https://www.usmint.gov/news', NULL, 'html_list', 1, 720);

-- CSS selectors para US Mint (scraping HTML)
UPDATE fn_news_sources SET
    selector_title   = '.news-listing__title',
    selector_link    = '.news-listing__title a',
    selector_date    = '.news-listing__date',
    selector_summary = '.news-listing__summary',
    selector_body    = '.news-detail__body'
WHERE name = 'US Mint';

-- ------------------------------------------------------------
-- 2. Cache de enlaces internos de Foronum (ejemplo)
-- ------------------------------------------------------------

-- === exact_coin ===
INSERT INTO fn_foronum_links (entity_type, entity_id, entity_name, lang, url, slug, seo_priority, keywords_json) VALUES
('exact_coin', 101, 'Morgan Dollar', 'es', '/es/monedas/estados-unidos/morgan-dollar', 'morgan-dollar', 90, '["morgan", "dolar morgan", "silver dollar"]'),
('exact_coin', 101, 'Morgan Dollar', 'en', '/en/coins/united-states/morgan-dollar', 'morgan-dollar', 90, '["morgan", "morgan dollar", "silver dollar"]'),
('exact_coin', 101, 'Morgan Dollar', 'fr', '/fr/monnaies/etats-unis/morgan-dollar', 'morgan-dollar', 90, '["morgan", "dollar morgan"]'),
('exact_coin', 101, 'Morgan Dollar', 'de', '/de/muenzen/vereinigte-staaten/morgan-dollar', 'morgan-dollar', 90, '["morgan", "morgan dollar"]'),
('exact_coin', 101, 'Morgan Dollar', 'it', '/it/monete/stati-uniti/morgan-dollar', 'morgan-dollar', 90, '["morgan", "dollaro morgan"]'),
('exact_coin', 101, 'Morgan Dollar', 'pt', '/pt/moedas/estados-unidos/morgan-dollar', 'morgan-dollar', 90, '["morgan", "dolar morgan"]'),

('exact_coin', 102, 'Krugerrand', 'es', '/es/monedas/sudafrica/krugerrand', 'krugerrand', 85, '["krugerrand", "oro sudafricano"]'),
('exact_coin', 102, 'Krugerrand', 'en', '/en/coins/south-africa/krugerrand', 'krugerrand', 85, '["krugerrand", "south african gold"]'),
('exact_coin', 102, 'Krugerrand', 'fr', '/fr/monnaies/afrique-du-sud/krugerrand', 'krugerrand', 85, '["krugerrand", "or sud-africain"]'),
('exact_coin', 102, 'Krugerrand', 'de', '/de/muenzen/suedafrika/krugerrand', 'krugerrand', 85, '["krugerrand", "suedafrikanisches gold"]'),
('exact_coin', 102, 'Krugerrand', 'it', '/it/monete/sudafrica/krugerrand', 'krugerrand', 85, '["krugerrand", "oro sudafricano"]'),
('exact_coin', 102, 'Krugerrand', 'pt', '/pt/moedas/africa-do-sul/krugerrand', 'krugerrand', 85, '["krugerrand", "ouro sul-africano"]'),

('exact_coin', 103, 'Walking Liberty Half Dollar', 'es', '/es/monedas/estados-unidos/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "medio dolar"]'),
('exact_coin', 103, 'Walking Liberty Half Dollar', 'en', '/en/coins/united-states/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "half dollar"]'),
('exact_coin', 103, 'Walking Liberty Half Dollar', 'fr', '/fr/monnaies/etats-unis/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "demi-dollar"]'),
('exact_coin', 103, 'Walking Liberty Half Dollar', 'de', '/de/muenzen/vereinigte-staaten/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "halber dollar"]'),
('exact_coin', 103, 'Walking Liberty Half Dollar', 'it', '/it/monete/stati-uniti/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "mezzo dollaro"]'),
('exact_coin', 103, 'Walking Liberty Half Dollar', 'pt', '/pt/moedas/estados-unidos/walking-liberty-half-dollar', 'walking-liberty-half-dollar', 80, '["walking liberty", "meio dolar"]');

-- === exact_banknote ===
INSERT INTO fn_foronum_links (entity_type, entity_id, entity_name, lang, url, slug, seo_priority, keywords_json) VALUES
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'es', '/es/billetes/estados-unidos/100-dolares-serie-2023', '100-dolares-serie-2023', 75, '["100 dolares", "billete 100"]'),
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'en', '/en/banknotes/united-states/100-dollar-bill-series-2023', '100-dollar-bill-series-2023', 75, '["100 dollar", "hundred dollar bill"]'),
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'fr', '/fr/billets/etats-unis/billet-100-dollars-serie-2023', 'billet-100-dollars-serie-2023', 75, '["100 dollars", "billet 100"]'),
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'de', '/de/banknoten/vereinigte-staaten/100-dollar-schein-serie-2023', '100-dollar-schein-serie-2023', 75, '["100 dollar", "hundert dollar schein"]'),
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'it', '/it/banconote/stati-uniti/banconota-100-dollari-serie-2023', 'banconota-100-dollari-serie-2023', 75, '["100 dollari", "banconota 100"]'),
('exact_banknote', 201, 'US 100 Dollar Bill Series 2023', 'pt', '/pt/notas/estados-unidos/nota-100-dolares-serie-2023', 'nota-100-dolares-serie-2023', 75, '["100 dolares", "nota 100"]');

-- === series ===
INSERT INTO fn_foronum_links (entity_type, entity_id, entity_name, lang, url, slug, seo_priority, keywords_json) VALUES
('series', 301, 'American Eagle', 'es', '/es/series/american-eagle', 'american-eagle', 85, '["american eagle", "aguila americana"]'),
('series', 301, 'American Eagle', 'en', '/en/series/american-eagle', 'american-eagle', 85, '["american eagle", "gold eagle", "silver eagle"]'),
('series', 301, 'American Eagle', 'fr', '/fr/series/american-eagle', 'american-eagle', 85, '["american eagle", "aigle americain"]'),
('series', 301, 'American Eagle', 'de', '/de/serien/american-eagle', 'american-eagle', 85, '["american eagle", "amerikanischer adler"]'),
('series', 301, 'American Eagle', 'it', '/it/serie/american-eagle', 'american-eagle', 85, '["american eagle", "aquila americana"]'),
('series', 301, 'American Eagle', 'pt', '/pt/series/american-eagle', 'american-eagle', 85, '["american eagle", "aguia americana"]'),

('series', 302, 'Maple Leaf', 'es', '/es/series/maple-leaf', 'maple-leaf', 80, '["maple leaf", "hoja de arce"]'),
('series', 302, 'Maple Leaf', 'en', '/en/series/maple-leaf', 'maple-leaf', 80, '["maple leaf", "canadian maple"]'),
('series', 302, 'Maple Leaf', 'fr', '/fr/series/maple-leaf', 'maple-leaf', 80, '["maple leaf", "feuille derable"]'),
('series', 302, 'Maple Leaf', 'de', '/de/serien/maple-leaf', 'maple-leaf', 80, '["maple leaf", "ahornblatt"]'),
('series', 302, 'Maple Leaf', 'it', '/it/serie/maple-leaf', 'maple-leaf', 80, '["maple leaf", "foglia dacero"]'),
('series', 302, 'Maple Leaf', 'pt', '/pt/series/maple-leaf', 'maple-leaf', 80, '["maple leaf", "folha de bordo"]'),

('series', 303, 'Britannia', 'es', '/es/series/britannia', 'britannia', 80, '["britannia", "moneda britanica"]'),
('series', 303, 'Britannia', 'en', '/en/series/britannia', 'britannia', 80, '["britannia", "british coin"]'),
('series', 303, 'Britannia', 'fr', '/fr/series/britannia', 'britannia', 80, '["britannia", "monnaie britannique"]'),
('series', 303, 'Britannia', 'de', '/de/serien/britannia', 'britannia', 80, '["britannia", "britische muenze"]'),
('series', 303, 'Britannia', 'it', '/it/serie/britannia', 'britannia', 80, '["britannia", "moneta britannica"]'),
('series', 303, 'Britannia', 'pt', '/pt/series/britannia', 'britannia', 80, '["britannia", "moeda britanica"]');

-- === country ===
INSERT INTO fn_foronum_links (entity_type, entity_id, entity_name, lang, url, slug, seo_priority, keywords_json) VALUES
('country', 401, 'Estados Unidos', 'es', '/es/paises/estados-unidos', 'estados-unidos', 70, '["estados unidos", "usa", "eeuu"]'),
('country', 401, 'United States', 'en', '/en/countries/united-states', 'united-states', 70, '["united states", "usa", "us"]'),
('country', 401, 'Etats-Unis', 'fr', '/fr/pays/etats-unis', 'etats-unis', 70, '["etats-unis", "usa"]'),
('country', 401, 'Vereinigte Staaten', 'de', '/de/laender/vereinigte-staaten', 'vereinigte-staaten', 70, '["vereinigte staaten", "usa"]'),
('country', 401, 'Stati Uniti', 'it', '/it/paesi/stati-uniti', 'stati-uniti', 70, '["stati uniti", "usa"]'),
('country', 401, 'Estados Unidos', 'pt', '/pt/paises/estados-unidos', 'estados-unidos', 70, '["estados unidos", "eua"]'),

('country', 402, 'Alemania', 'es', '/es/paises/alemania', 'alemania', 65, '["alemania", "germany"]'),
('country', 402, 'Germany', 'en', '/en/countries/germany', 'germany', 65, '["germany", "deutschland"]'),
('country', 402, 'Allemagne', 'fr', '/fr/pays/allemagne', 'allemagne', 65, '["allemagne"]'),
('country', 402, 'Deutschland', 'de', '/de/laender/deutschland', 'deutschland', 65, '["deutschland"]'),
('country', 402, 'Germania', 'it', '/it/paesi/germania', 'germania', 65, '["germania"]'),
('country', 402, 'Alemanha', 'pt', '/pt/paises/alemanha', 'alemanha', 65, '["alemanha"]'),

('country', 403, 'Reino Unido', 'es', '/es/paises/reino-unido', 'reino-unido', 65, '["reino unido", "uk", "gran bretana"]'),
('country', 403, 'United Kingdom', 'en', '/en/countries/united-kingdom', 'united-kingdom', 65, '["united kingdom", "uk", "britain"]'),
('country', 403, 'Royaume-Uni', 'fr', '/fr/pays/royaume-uni', 'royaume-uni', 65, '["royaume-uni", "uk"]'),
('country', 403, 'Vereinigtes Koenigreich', 'de', '/de/laender/vereinigtes-koenigreich', 'vereinigtes-koenigreich', 65, '["vereinigtes koenigreich", "uk"]'),
('country', 403, 'Regno Unito', 'it', '/it/paesi/regno-unito', 'regno-unito', 65, '["regno unito", "uk"]'),
('country', 403, 'Reino Unido', 'pt', '/pt/paises/reino-unido', 'reino-unido', 65, '["reino unido", "uk"]');

-- === topic ===
INSERT INTO fn_foronum_links (entity_type, entity_id, entity_name, lang, url, slug, seo_priority, keywords_json) VALUES
('topic', 501, 'Graduacion de monedas', 'es', '/es/temas/graduacion-de-monedas', 'graduacion-de-monedas', 60, '["graduacion", "grading", "ngc", "pcgs"]'),
('topic', 501, 'Coin Grading', 'en', '/en/topics/coin-grading', 'coin-grading', 60, '["grading", "ngc", "pcgs", "coin grade"]'),
('topic', 501, 'Classement des monnaies', 'fr', '/fr/sujets/classement-des-monnaies', 'classement-des-monnaies', 60, '["classement", "graduation", "ngc", "pcgs"]'),
('topic', 501, 'Muenzbewertung', 'de', '/de/themen/muenzbewertung', 'muenzbewertung', 60, '["bewertung", "grading", "ngc", "pcgs"]'),
('topic', 501, 'Classificazione delle monete', 'it', '/it/argomenti/classificazione-delle-monete', 'classificazione-delle-monete', 60, '["classificazione", "grading", "ngc", "pcgs"]'),
('topic', 501, 'Classificacao de moedas', 'pt', '/pt/temas/classificacao-de-moedas', 'classificacao-de-moedas', 60, '["classificacao", "grading", "ngc", "pcgs"]'),

('topic', 502, 'Marcas de ceca', 'es', '/es/temas/marcas-de-ceca', 'marcas-de-ceca', 55, '["marca de ceca", "mint mark", "ceca"]'),
('topic', 502, 'Mint Marks', 'en', '/en/topics/mint-marks', 'mint-marks', 55, '["mint mark", "mint", "mintage"]'),
('topic', 502, 'Marques datelier', 'fr', '/fr/sujets/marques-datelier', 'marques-datelier', 55, '["marque datelier", "atelier monetaire"]'),
('topic', 502, 'Muenzzeichen', 'de', '/de/themen/muenzzeichen', 'muenzzeichen', 55, '["muenzzeichen", "praegeanstalt"]'),
('topic', 502, 'Segni di zecca', 'it', '/it/argomenti/segni-di-zecca', 'segni-di-zecca', 55, '["segno di zecca", "zecca"]'),
('topic', 502, 'Marcas de casa da moeda', 'pt', '/pt/temas/marcas-de-casa-da-moeda', 'marcas-de-casa-da-moeda', 55, '["marca de casa da moeda", "casa da moeda"]');

-- ------------------------------------------------------------
-- 3. Noticias de prueba (tabla fn_news unificada)
-- ------------------------------------------------------------
INSERT INTO fn_news (source_id, title, url, url_hash, published_at, summary, status) VALUES
(2, 'US Mint Releases New 2026 American Eagle Gold Coin Design',
 'https://www.numismaticnews.net/us-coins/us-mint-2026-american-eagle-gold',
 SHA2('https://www.numismaticnews.net/us-coins/us-mint-2026-american-eagle-gold', 256),
 '2026-03-28 14:00:00',
 'The United States Mint has unveiled a new reverse design for the 2026 American Eagle gold bullion coin, featuring a modernized interpretation of the classic eagle motif.',
 'discovered'),

(3, 'Rare 1794 Flowing Hair Dollar Sells for Record $12.5 Million at Auction',
 'https://coinsweekly.com/rare-1794-flowing-hair-dollar-record-auction/',
 SHA2('https://coinsweekly.com/rare-1794-flowing-hair-dollar-record-auction/', 256),
 '2026-03-25 10:30:00',
 'A specimen of the legendary 1794 Flowing Hair Silver Dollar has broken auction records, selling for $12.5 million at a major numismatic auction in New York.',
 'discovered'),

(4, 'Royal Mint Announces New Britannia Bullion Series with Enhanced Security Features',
 'https://www.coinnews.net/2026/03/20/royal-mint-britannia-2026-security/',
 SHA2('https://www.coinnews.net/2026/03/20/royal-mint-britannia-2026-security/', 256),
 '2026-03-20 08:15:00',
 'The Royal Mint has announced an updated Britannia bullion coin series for 2026, incorporating new anti-counterfeiting technology and a refreshed design.',
 'discovered');
