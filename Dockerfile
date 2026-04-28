FROM php:8.2-fpm

# Todo en un solo RUN: compilar + purgar + limpiar queda en una sola capa.
# Si fueran RUN separados, los archivos borrados en capas posteriores
# seguirían pesando en la imagen final.
RUN set -eux \
    # ── Dependencias del sistema ──────────────────────────────────────────────
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        gnupg2 curl apt-transport-https ca-certificates \
        # Compilador y build tools (se purgan al final)
        g++ make autoconf \
        # Headers -dev para compilar extensiones PHP
        libpng-dev libfreetype6-dev libjpeg62-turbo-dev \
        libonig-dev libxml2-dev libzip-dev unixodbc-dev \
    \
    # ── Microsoft ODBC Driver 18 ──────────────────────────────────────────────
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
       | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] \
       https://packages.microsoft.com/debian/12/prod bookworm main" \
       > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    \
    # ── Extensiones PHP estándar ──────────────────────────────────────────────
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo mbstring exif pcntl bcmath gd xml zip opcache \
    \
    # ── Drivers SQL Server (5.11.1 = última versión compatible con PHP 8.2) ──
    && pecl install sqlsrv-5.11.1 \
    && pecl install pdo_sqlsrv-5.11.1 \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    \
    # ── Limpieza ──────────────────────────────────────────────────────────────
    # Se purga SOLO el compilador (g++ arrastra gcc, cpp, binutils → ~400 MB).
    # Los paquetes -dev se conservan: sus dependencias de runtime (libpng16-16,
    # libfreetype6, etc.) quedan protegidas de apt autoremove mientras existan.
    && apt-get purge -y g++ make autoconf \
    && apt-get autoremove -y \
    && pecl clear-cache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer desde su imagen oficial (no requiere instalar nada extra)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# MODO COPY (activo): archivos baked en la imagen
# MODO VOLUMEN (dev): si docker-compose monta ./src aquí este COPY queda sobreescrito
COPY src/ .

EXPOSE 9000
CMD ["php-fpm"]
