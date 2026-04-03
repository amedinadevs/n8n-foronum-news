# Entidades y Enlaces

## Tipos de entidad

| Tipo | Descripcion | Ejemplo | Prioridad SEO |
|------|-------------|---------|---------------|
| exact_coin | Moneda especifica | Morgan Dollar, Krugerrand | 1 (maxima) |
| exact_banknote | Billete especifico | US $100 Series 2023 | 2 |
| series | Serie de monedas | American Eagle, Maple Leaf, Britannia | 3 |
| country | Pais | Estados Unidos, Alemania, Reino Unido | 4 |
| topic | Tema general | Graduacion de monedas, Marcas de ceca | 5 (minima) |

## Prioridad de enlazado

Cuando WF2 resuelve enlaces internos, selecciona 2-4 enlaces por idioma siguiendo este orden de prioridad:

1. exact_coin / exact_banknote (prioridad maxima - enlace directo a la ficha)
2. series (pagina de la serie a la que pertenece)
3. country (pagina del pais)
4. topic (pagina tematica general)

Dentro de cada tipo, se ordena por seo_priority DESC (campo 0-100 en fn_foronum_links).

## Resolucion por idioma

Cada entidad tiene una URL diferente por idioma. La tabla fn_foronum_links almacena UNIQUE(entity_type, entity_id, lang).

Ejemplo para Morgan Dollar:
| Idioma | URL |
|--------|-----|
| es | /es/monedas/estados-unidos/morgan-dollar |
| en | /en/coins/united-states/morgan-dollar |
| fr | /fr/monnaies/etats-unis/morgan-dollar |
| de | /de/muenzen/vereinigte-staaten/morgan-dollar |
| it | /it/monete/stati-uniti/morgan-dollar |
| pt | /pt/moedas/estados-unidos/morgan-dollar |

## Matching de entidades

WF2 busca enlaces por dos vias:
1. Matching por nombre: LOWER(entity_name) LIKE '%search_term%'
2. Matching por keywords: JSON_SEARCH en keywords_json

keywords_json almacena sinonimos y variantes para cada entidad.

## Reglas

- Cada articulo solo usa URLs validas del idioma de salida
- Minimo 2, maximo 4 enlaces internos por articulo
- Anchor text natural (nunca "click aqui" o "ver mas")
- No repetir el mismo enlace en un articulo
- Preferir enlaces a fichas especificas sobre paginas genericas

## Cache de enlaces (WF5)

WF5 refresca diariamente la tabla fn_foronum_links desde las tablas de catalogo de Foronum. Las queries de ejemplo estan en sql/foronum_mapping.sql y deben adaptarse al esquema real.
