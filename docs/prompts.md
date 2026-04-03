# Prompts LLM

## Vision general

El pipeline utiliza 3 prompts principales, todos configurados para devolver JSON estructurado (`response_format: json_object`). Cada prompt esta disenado para una tarea especifica dentro del workflow unificado `foronum_news_pipeline.json` (55 nodos, 5 fases).

---

## Prompt 1: Extraccion de Entidades + Clasificacion

**Usado en:** Fase 3 - Enrichment (nodo "Classify & Extract")
**Modelo:** gpt-4o-mini
**Temperatura:** 0.3

### Objetivo
Analizar una noticia numismatica, extraer entidades relevantes y clasificar si merece un articulo en Foronum.

### Estructura del prompt
```
Eres un analista de noticias numismaticas para Foronum...

NEWS TITLE: {titulo}
NEWS SOURCE: {fuente}
NEWS DATE: {fecha}
ARTICLE TEXT: {texto limpio, max 5000 chars}

REGLAS:
- Nuevas emisiones de monedas/billetes: score 80-100
- Resultados de subastas, anuncios de cecas, cambios de politica: 50-79
- Noticias financieras genericas que mencionan monedas: 0-39

OUTPUT JSON:
{
  "entities": { country, denomination, mint, piece_type, series, year_referenced, metal, event_type },
  "all_entities": [{type, value}],
  "score": 0-100,
  "classification": "high|medium|low|reject",
  "reasoning": "...",
  "seo_potential": 0-100,
  "suggested_angle": "..."
}
```

### Notas
- `score >= 40` continua al siguiente paso; por debajo se marca como `rejected` en `fn_news`
- gpt-4o-mini es suficiente para clasificacion (tarea relativamente simple)
- Temperatura 0.3 para consistencia en la clasificacion
- El texto de entrada se trunca a 5000 caracteres para controlar costes

---

## Prompt 2: Generacion de Articulo en Espanol

**Usado en:** Fase 4 - Generation (nodo "Generate ES Article")
**Modelo:** gpt-4o
**Temperatura:** 0.7

### Objetivo
Generar un articulo editorial en espanol con 2-4 enlaces internos de Foronum.

### Estructura del prompt
```
Eres el redactor editorial IA de Foronum (foronum.com)...

DIRECTRICES EDITORIALES:
- Tono informativo, riguroso, accesible
- 400-800 palabras
- Incluir exactamente 2-4 enlaces internos con anchor text natural
- NUNCA inventar URLs
- Articulo sustancialmente original vs fuente
- Sugerir imagen destacada

ENLACES INTERNOS DISPONIBLES PARA ESPANOL:
{lista de entity_type + entity_name + url}

CONTEXTO DE LA NOTICIA:
{titulo, fuente, entidades, resumen, texto}

OUTPUT JSON:
{
  "title": "max 70 chars, SEO",
  "slug": "URL-safe",
  "excerpt": "150-200 chars",
  "meta_description": "max 160 chars",
  "body_html": "HTML valido",
  "anchors_used": [{text, url, entity_type}],
  "featured_image_suggestion": "..."
}
```

### Notas
- gpt-4o para maxima calidad de redaccion
- Temperatura 0.7 para creatividad controlada
- El articulo ES sirve como referencia semantica para las traducciones
- Se genera primero porque el equipo editorial revisa en espanol
- Los enlaces internos se seleccionan de `fn_foronum_links` filtrados por idioma `es`

---

## Prompt 3: Re-generacion por Idioma

**Usado en:** Fase 4 - Generation (nodo "Generate Translation", loop x5)
**Modelo:** gpt-4o
**Temperatura:** 0.7

### Objetivo
Generar version en idioma target usando el articulo ES como referencia pero con URLs del idioma target.

### Estructura del prompt
```
You are the editorial AI writer for Foronum. Generate a {idioma} version...

IMPORTANT: This is NOT a literal translation. You must:
1. Rewrite naturally in {idioma}
2. Use the {idioma} internal links (NOT Spanish ones)
3. Adapt numismatic terminology
4. Maintain factual content
5. Include 2-4 internal links
6. Generate appropriate slug

REFERENCE ARTICLE (Spanish):
{titulo y body_html del articulo ES}

AVAILABLE INTERNAL LINKS FOR {IDIOMA}:
{enlaces del idioma target}

OUTPUT JSON:
{ title, slug, excerpt, meta_description, body_html, anchors_used, featured_image_alt }
```

### Notas
- NO es traduccion literal - es re-generacion en el idioma target
- Cada idioma usa sus propias URLs internas de Foronum
- El prompt esta en ingles porque los modelos LLM rinden mejor con instrucciones en ingles
- Se ejecuta 5 veces: `en`, `fr`, `de`, `it`, `pt`
- El articulo en espanol se pasa como referencia semantica, no como texto a traducir

---

## Consideraciones de coste

| Prompt | Modelo | Input tokens | Output tokens | Coste/llamada |
|--------|--------|-------------|---------------|---------------|
| Clasificacion | gpt-4o-mini | ~2,000 | ~400 | ~$0.001 |
| Generacion ES | gpt-4o | ~2,500 | ~2,000 | ~$0.026 |
| Traduccion (x5) | gpt-4o | ~3,500 | ~2,000 | ~$0.029 |

**Coste total por articulo (6 idiomas):** ~$0.17
**Coste estimado mensual (10 articulos/dia):** ~$54

---

## Ajustes recomendados

- **Presupuesto limitado:** Cambiar fase generation a gpt-4o-mini (coste x20 menor, calidad inferior en redaccion)
- **Calidad insuficiente:** Subir a Claude Sonnet 4 (coste x1.5 mayor, mejor redaccion en idiomas europeos)
- **Mas consistencia:** Bajar temperatura a 0.5 (menos variabilidad entre ejecuciones)
- **Mas creatividad:** Subir temperatura a 0.8 (mas variedad en estilo y angulo editorial)
