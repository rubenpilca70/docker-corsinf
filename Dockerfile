# Imagen base oficial de PHP con FPM (FastCGI Process Manager)
# FPM es necesario para que Nginx pueda delegar la ejecución de PHP
# php:8.2-fpm usa Debian 12 (Bookworm) como sistema base
# NOTA: sqlsrv >= 5.12 requiere PHP >= 8.3; se fija en 5.11.1 para mantener PHP 8.2
FROM php:8.2-fpm

# ── DEPENDENCIAS DEL SISTEMA ─────────────────────────────────────────────────
# Se instala todo en un solo RUN para reducir capas en la imagen Docker
RUN apt-get update && apt-get install -y \
    # Necesario para importar claves GPG de repositorios externos (Microsoft)
    gnupg2 \
    # Herramienta para descargar la clave y el repo de Microsoft
    curl \
    # Permite que apt use repositorios HTTPS (requerido para el repo de Microsoft)
    apt-transport-https \
    # Herramientas de desarrollo (útil para Composer y scripts)
    git \
    # Librería requerida por la extensión GD (manejo de imágenes PNG)
    libpng-dev \
    # Soporte para imágenes con tipografías TrueType en GD
    libfreetype6-dev \
    # Soporte para imágenes JPEG en GD
    libjpeg62-turbo-dev \
    # Requerida por la extensión mbstring (manejo de strings multibyte / UTF-8)
    libonig-dev \
    # Requerida por la extensión xml (SimpleXML, DOM, etc.)
    libxml2-dev \
    # Requerida por la extensión zip
    libzip-dev \
    # Cabeceras de desarrollo de unixODBC: necesarias para compilar sqlsrv y pdo_sqlsrv
    unixodbc-dev \
    # Compilador C++ y herramientas de build: requeridos para compilar sqlsrv/pdo_sqlsrv desde PECL
    g++ make autoconf \
    # Utilidades de compresión usadas por Composer y algunos paquetes
    zip unzip \
    \
    # ── MICROSOFT ODBC DRIVER 18 PARA SQL SERVER ────────────────────────────────
    # Paso 1: descarga la clave pública de Microsoft y la guarda en el keyring del sistema
    # gpg --dearmor convierte el formato ASCII armor a binario que apt entiende
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
       | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    \
    # Paso 2: agrega el repositorio de paquetes de Microsoft para Debian 12
    # signed-by indica que solo se aceptan paquetes firmados con la clave anterior
    && echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] \
       https://packages.microsoft.com/debian/12/prod bookworm main" \
       > /etc/apt/sources.list.d/mssql-release.list \
    \
    # Paso 3: actualiza apt para que reconozca el nuevo repositorio de Microsoft
    && apt-get update \
    \
    # Paso 4: instala el driver ODBC 18
    # ACCEPT_EULA=Y acepta automáticamente el EULA de Microsoft (requerido en modo no interactivo)
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    \
    # Limpia la caché de apt para reducir el tamaño final de la imagen
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── EXTENSIONES PHP ESTÁNDAR ─────────────────────────────────────────────────
# Configura GD antes de instalarla: indica qué formatos de imagen habilitar
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Instala extensiones PHP compiladas desde el código fuente
RUN docker-php-ext-install \
    # PDO: capa de abstracción de base de datos (requerida por pdo_sqlsrv)
    pdo \
    # Strings multibyte (UTF-8, internacionalización)
    mbstring \
    # Lee metadatos EXIF de imágenes (cámaras, fotos)
    exif \
    # Permite control de señales del proceso (útil en workers / colas)
    pcntl \
    # Aritmética de precisión arbitraria (criptografía, finanzas)
    bcmath \
    # Manipulación de imágenes (redimensionar, marca de agua, etc.)
    gd \
    # Soporte XML (DOMDocument, SimpleXML, XMLReader)
    xml \
    # Lectura y escritura de archivos ZIP
    zip \
    # OPcache: compila PHP a bytecode y lo guarda en memoria → menos CPU por petición
    opcache

# ── EXTENSIONES SQL SERVER VIA PECL ─────────────────────────────────────────
# PECL es el gestor de extensiones de PHP para librerías externas
# sqlsrv     → API nativa de SQL Server (funciones sqlsrv_*)
# pdo_sqlsrv → driver PDO para SQL Server (new PDO("sqlsrv:..."))
# Ambas usan el driver ODBC instalado anteriormente para comunicarse con SQL Server
#
# Se instalan por separado: instalarlas juntas en un solo "pecl install" puede
# provocar conflictos de compilación con exit code 1 en BuildKit
# Se fija la versión 5.11.1: es la última que soporta PHP 8.2
# (sqlsrv >= 5.12.0 exige PHP >= 8.3)
RUN pecl install sqlsrv-5.11.1 \
    && pecl install pdo_sqlsrv-5.11.1 \
    # Activa ambas extensiones en PHP (crea los archivos .ini necesarios en conf.d)
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

# ── COMPOSER ─────────────────────────────────────────────────────────────────
# Copia el binario de Composer desde su imagen oficial (multi-stage copy)
# Evita instalar Composer manualmente y garantiza la versión más reciente
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ── OPCACHE PARA DESARROLLO ───────────────────────────────────────────────────
# revalidate_freq=0 + validate_timestamps=1: OPcache revisa cambios en cada petición
# Esto permite editar archivos PHP y ver los cambios sin reiniciar el contenedor
RUN echo "opcache.enable=1"             >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/opcache.ini

# Directorio de trabajo dentro del contenedor
WORKDIR /var/www/html

# ── CÓDIGO DE LA APLICACIÓN ──────────────────────────────────────────────────
# Copia src/ dentro de la imagen para el MODO COPY (activo por defecto)
# Cuando docker-compose monta un volumen sobre /var/www/html este COPY queda
# sobreescrito en tiempo de ejecución → así funciona el MODO VOLUMEN (dev)
COPY src/ .

# Puerto que PHP-FPM escucha; Nginx se conecta a este puerto internamente
EXPOSE 9000

# Comando que se ejecuta al iniciar el contenedor
CMD ["php-fpm"]
