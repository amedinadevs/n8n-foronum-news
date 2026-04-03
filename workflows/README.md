# Workflows n8n

Export JSON del workflow unificado del pipeline de noticias numismaticas.

## Workflow

| Archivo | Nombre | Trigger | Nodos | Funcion |
|---------|--------|---------|-------|---------|
| `foronum_news_pipeline.json` | Foronum News Pipeline | Cada 6h | 55 | Pipeline completo: cache, discovery, enrichment, generation, publication + notificacion |

## Fases del pipeline (dentro del workflow unico)

1. **Cache Refresh** - Refresca `fn_foronum_links` desde catalogo Foronum
2. **Discovery** - Escanea fuentes RSS/HTML, normaliza, dedup por hash
3. **Enrichment** - Descarga pagina, extrae entidades con LLM, clasifica, resuelve enlaces
4. **Generation** - Genera articulo ES + 5 traducciones, valida
5. **Publication + Notification** - INSERT directo en Foronum MySQL + email

## Importar en n8n

1. Abrir n8n > Workflows > Import from File
2. Importar `foronum_news_pipeline.json`
3. Abrir los nodos MySQL y seleccionar la credencial correcta
4. Configurar OPENAI_API_KEY en Settings > Environment Variables
5. Guardar el workflow
6. Ejecutar manualmente una vez para poblar la cache de enlaces
7. Activar el workflow

## Credenciales necesarias

- **Foronum MySQL**: conexion a la BD MySQL (pipeline + catalogo)
- **OpenAI API**: clave API para clasificacion y generacion (via HTTP Request + env var OPENAI_API_KEY)
- **SMTP Email**: servidor de correo para notificaciones

## Notas

- El workflow se exporta con `active: false` para no auto-activarse al importar
- Los IDs de credenciales son placeholders (`FORONUM_MYSQL_CREDENTIAL_ID`) que deben sustituirse
- Las queries MySQL se construyen en nodos Code con la funcion `esc()` (sin queries parametrizadas)
- Ver `docs/workflows.md` para documentacion detallada de cada fase
