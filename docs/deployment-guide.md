# Guia de Despliegue

## Requisitos previos

- Docker y Docker Compose instalados
- Acceso a la base de datos MySQL de Foronum (lectura para catalogo, escritura para publicacion)
- Clave API de OpenAI
- Servidor SMTP para notificaciones (opcional)
- Git

## 1. Clonar el repositorio

```bash
git clone <url-del-repo> n8n-foronum
cd n8n-foronum
```

## 2. Configurar variables de entorno

```bash
cp deploy/.env.example deploy/.env
nano deploy/.env
```

Variables obligatorias:
- POSTGRES_PASSWORD: password para PostgreSQL de n8n
- N8N_ENCRYPTION_KEY: cadena aleatoria de 32+ caracteres
- MYSQL_ROOT_PASSWORD: password root de MySQL local
- MYSQL_PASSWORD: password del usuario foronum

Variables para produccion:
- N8N_HOST: dominio (ej: n8n.tudominio.com)
- N8N_PROTOCOL: https
- WEBHOOK_URL: URL completa del webhook
- N8N_BASIC_AUTH_ACTIVE: true (con usuario y password)

## 3. Levantar los servicios

```bash
cd deploy
docker compose up -d
```

Esto arranca:
- PostgreSQL 16 (n8n interno) en el puerto 5432
- MySQL 8.0 (pipeline + dev) en el puerto 3306
- n8n en el puerto 5678

El schema SQL se ejecuta automaticamente al crear el contenedor MySQL por primera vez (montado via /docker-entrypoint-initdb.d).

## 4. Verificar los servicios

```bash
docker compose ps
docker compose logs n8n --tail 50
```

Acceder a n8n: http://localhost:5678

## 5. Configurar credenciales en n8n

En la interfaz de n8n, crear las siguientes credenciales:

### MySQL (Foronum)
- Nombre: "Foronum MySQL"
- Host: mysql (para dev local) o el host real de Foronum
- Port: 3306
- Database: foronum_n8n (o la BD real)
- User: foronum
- Password: (de .env)

### OpenAI API
NOTA: El workflow usa HTTP Request directo a la API de OpenAI. La clave se pasa via $env.OPENAI_API_KEY. Configurar en n8n: Settings > Environment Variables > OPENAI_API_KEY.

### SMTP (para notificaciones)
- Nombre: "SMTP Email"
- Host, port, user, password del servidor SMTP

## 6. Importar el workflow

### Opcion A: Via interfaz de n8n
1. Ir a Workflows > Import from File
2. Importar `foronum_news_pipeline.json`
3. Abrir los nodos MySQL y seleccionar la credencial "Foronum MySQL"
4. Guardar el workflow

### Opcion B: Via script
```bash
chmod +x scripts/import_workflows.sh
./scripts/import_workflows.sh
```

## 7. Actualizar credenciales en el workflow

Despues de importar, el workflow tiene placeholder de credenciales (FORONUM_MYSQL_CREDENTIAL_ID). Hay que:
1. Abrir el workflow en n8n
2. Hacer click en cada nodo MySQL
3. Seleccionar la credencial "Foronum MySQL" del dropdown
4. Guardar el workflow

## 8. Adaptar queries a Foronum real

Si conectas a la BD real de Foronum:
1. Revisar sql/foronum_mapping.sql para entender las queries ejemplo
2. En la fase Cache Refresh: adaptar los 5 nodos SELECT a las tablas reales del catalogo
3. En la fase Publication: adaptar los INSERT a las tablas CMS reales

## 9. Ejecutar manualmente la primera vez

Antes de activar el workflow, ejecutarlo manualmente para verificar que funciona:
1. Abrir el workflow en n8n
2. Click "Execute Workflow"
3. Verificar que fn_foronum_links tiene datos (fase cache refresh)
4. Verificar que fn_news tiene items con `status='discovered'` (fase discovery)

## 10. Activar el workflow

Una vez verificado, activar el workflow. Se ejecutara automaticamente cada 6 horas.

## 11. Configurar reverse proxy (produccion)

Para Plesk/Nginx, usar deploy/plesk-nginx.conf como referencia.

Aspectos clave:
- Proxy pass a http://127.0.0.1:5678
- Headers X-Forwarded-For, X-Forwarded-Proto
- WebSocket upgrade para la interfaz de n8n
- Timeout largo (3600s) para ejecuciones largas

## 12. Backups

```bash
chmod +x scripts/backup_examples.sh
./scripts/backup_examples.sh
```

Esto respalda:
- Base de datos PostgreSQL de n8n
- Base de datos MySQL del pipeline

## Verificacion post-despliegue

Checklist:
- [ ] n8n accesible en el navegador
- [ ] Credencial MySQL conecta correctamente
- [ ] Workflow ejecutado manualmente con exito
- [ ] fn_foronum_links tiene datos
- [ ] fn_news tiene items con status 'discovered'
- [ ] API key de OpenAI configurada
- [ ] SMTP configurado (si se usa)
- [ ] Workflow activado
