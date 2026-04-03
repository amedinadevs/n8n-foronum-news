# Troubleshooting

## Problemas comunes

### n8n no arranca
```bash
docker compose logs n8n --tail 100
```
Causas frecuentes:
- PostgreSQL no esta listo: verificar con `docker compose logs postgres`
- Puerto 5678 ocupado: cambiar N8N_PORT en .env
- N8N_ENCRYPTION_KEY cambiada: las credenciales no se descifran. Usar la clave original.

### MySQL no conecta desde n8n
- Verificar que el contenedor mysql esta corriendo: `docker compose ps`
- Host correcto: 'mysql' dentro de Docker, 'localhost' si n8n esta fuera
- Probar conexion: `docker exec -it n8n-mysql mysql -u foronum -p foronum_n8n`

### Fase Discovery no encuentra noticias
- Verificar fn_news_sources tiene fuentes activas: `SELECT * FROM fn_news_sources WHERE is_active = 1`
- Las fuentes RSS pueden cambiar su URL: verificar manualmente
- US Mint usa scraping HTML: los selectores CSS pueden cambiar con redisenos

### Fase Enrichment no clasifica correctamente
- Revisar la variable OPENAI_API_KEY en n8n
- Verificar que la API de OpenAI responde: revisar logs de ejecucion en n8n
- Si score es siempre bajo, revisar el clean_text: puede estar vacio o corrupto

### Fase Generation genera articulos con validacion fallida
- "too few internal links": fn_foronum_links puede estar vacio (verificar que la fase cache refresh funciono)
- "body too short": el LLM puede no estar generando suficiente contenido (aumentar max_tokens)
- "too similar to source": el LLM esta copiando demasiado (revisar prompt)

### Fase Publication falla al publicar
- Las queries INSERT son ejemplos: adaptarlas al esquema real de Foronum
- Verificar permisos MySQL: el usuario necesita INSERT en las tablas CMS

### Emails no se envian
- Verificar credencial SMTP en n8n
- Comprobar que NOTIFICATION_EMAIL esta configurado
- Revisar logs del nodo Send Email en la ejecucion

## Queries de diagnostico

### Ver estado general del pipeline
```sql
SELECT status, COUNT(*) FROM fn_news GROUP BY status;
SELECT status, COUNT(*) FROM fn_articles GROUP BY status;
```

### Ver errores recientes
```sql
SELECT * FROM fn_pipeline_log WHERE level = 'error' ORDER BY created_at DESC LIMIT 20;
```

### Ver items atascados (mas de 24h en un estado intermedio)
```sql
SELECT * FROM fn_news
WHERE status IN ('discovered', 'enriched', 'article_ready')
  AND updated_at < NOW() - INTERVAL 24 HOUR;
```

### Resetear items atascados
```sql
UPDATE fn_news SET status = 'discovered', error_message = NULL
WHERE status = 'discovered' AND updated_at < NOW() - INTERVAL 24 HOUR;

UPDATE fn_news SET status = 'enriched', error_message = NULL
WHERE status = 'article_ready' AND updated_at < NOW() - INTERVAL 24 HOUR;
```

## Limpieza de datos antiguos

```sql
-- Eliminar noticias rechazadas de mas de 30 dias
DELETE FROM fn_news WHERE status = 'rejected' AND created_at < NOW() - INTERVAL 30 DAY;

-- Eliminar logs de mas de 90 dias
DELETE FROM fn_pipeline_log WHERE created_at < NOW() - INTERVAL 90 DAY;

-- Eliminar HTML crudo de noticias ya procesadas (ahorra espacio)
UPDATE fn_news SET raw_html = NULL WHERE status IN ('published', 'rejected') AND created_at < NOW() - INTERVAL 7 DAY;
```

## Monitoreo

Consulta rapida de salud del pipeline (ejecutar periodicamente):
```sql
SELECT
  (SELECT COUNT(*) FROM fn_news WHERE status = 'discovered') AS pendientes_enrichment,
  (SELECT COUNT(*) FROM fn_news WHERE status = 'enriched') AS pendientes_generacion,
  (SELECT COUNT(*) FROM fn_news WHERE status = 'error') AS errores_news,
  (SELECT COUNT(*) FROM fn_articles WHERE status = 'validated') AS pendientes_publicacion,
  (SELECT COUNT(*) FROM fn_articles WHERE status = 'published' AND published_at > NOW() - INTERVAL 24 HOUR) AS publicados_24h,
  (SELECT COUNT(*) FROM fn_pipeline_log WHERE level = 'error' AND created_at > NOW() - INTERVAL 24 HOUR) AS errores_24h;
```
