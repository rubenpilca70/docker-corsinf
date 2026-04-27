# PHP + SQL Server — Docker

Entorno PHP 8.2 con soporte nativo para SQL Server, servido por Nginx.  
Los archivos de la app viven en `src/corsinf/`.

---

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Docker Compose v2

---

## Estructura

```
EJEMPLO/
├── docker-compose.yml      # Servicios: nginx + php
├── Dockerfile              # PHP 8.2-fpm + ODBC 18 + sqlsrv + pdo_sqlsrv
├── nginx/
│   └── default.conf        # Configuración del servidor web
├── php/
│   ├── php.dev.ini         # PHP para desarrollo
│   └── php.prod.ini        # PHP para producción
└── src/
    └── corsinf/            # ← tus archivos PHP van aquí
        └── index.php
```

---

## Comandos Docker

### Construir y levantar

```bash
# Construir imágenes y levantar contenedores en segundo plano
docker compose up --build -d

# Levantar sin reconstruir la imagen (si no cambió el Dockerfile)
docker compose up -d

# Levantar y ver los logs en tiempo real (sin -d)
docker compose up --build
```

### Ver estado

```bash
# Ver contenedores activos del proyecto
docker compose ps

# Ver logs de todos los servicios
docker compose logs

# Ver logs en tiempo real
docker compose logs -f

# Ver logs solo de un servicio (nginx o php)
docker compose logs -f nginx
docker compose logs -f php
```

### Detener

```bash
# Detener contenedores sin eliminarlos (se pueden volver a levantar con up)
docker compose stop

# Detener un servicio específico
docker compose stop nginx
docker compose stop php
```

### Reiniciar

```bash
# Reiniciar todos los servicios
docker compose restart

# Reiniciar solo un servicio
docker compose restart php
docker compose restart nginx
```

### Eliminar

```bash
# Detener y eliminar contenedores (los volúmenes y la imagen se conservan)
docker compose down

# Eliminar contenedores + volúmenes anónimos
docker compose down -v

# Eliminar contenedores + imagen construida + volúmenes (limpieza total)
docker compose down -v --rmi local
```

### Ejecutar comandos dentro del contenedor

```bash
# Abrir una terminal bash dentro del contenedor PHP
docker compose exec php bash

# Ejecutar un comando puntual en PHP sin abrir terminal
docker compose exec php php -v
docker compose exec php php -m          # listar extensiones cargadas

# Verificar que sqlsrv está cargado
docker compose exec php php -r "echo extension_loaded('pdo_sqlsrv') ? 'OK' : 'FALTA';"

# Composer dentro del contenedor
docker compose exec php composer install
docker compose exec php composer require vendor/paquete
docker compose exec php composer update
```

### Reconstruir solo la imagen PHP

```bash
# Útil cuando cambias el Dockerfile o necesitas actualizar extensiones
docker compose build php
docker compose up -d
```

---

## Cambiar entre entornos (dev / prod)

Edita la línea del volumen en `docker-compose.yml`:

```yaml
# Desarrollo (por defecto) — errores visibles, OPcache flexible
- ./php/php.dev.ini:/usr/local/etc/php/conf.d/custom.ini:ro

# Producción — errores ocultos, OPcache máximo, funciones peligrosas deshabilitadas
- ./php/php.prod.ini:/usr/local/etc/php/conf.d/custom.ini:ro
```

Luego reinicia el contenedor PHP para aplicar el cambio:

```bash
docker compose restart php
```

---

## Limpieza general de Docker

```bash
# Eliminar todos los contenedores detenidos
docker container prune

# Eliminar imágenes sin uso
docker image prune

# Eliminar volúmenes sin uso
docker volume prune

# Limpieza total del sistema (contenedores, imágenes, redes, caché de build)
docker system prune -a
```

---

## Acceso

| Servicio | URL |
|----------|-----|
| Aplicación PHP | http://localhost:8080 |

---

## Conexión a SQL Server desde PHP

```php
$pdo = new PDO(
    "sqlsrv:Server=MI_SERVIDOR,1433;Database=MI_BASE",
    "usuario",
    "password"
);
```

> Si SQL Server está en tu máquina local usa `host.docker.internal` como servidor.
