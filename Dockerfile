# Use the official PHP Apache image with PHP 7.4
FROM php:7.4-apache

# Set working directory
WORKDIR /var/www/html

ARG MYSQL_HOST
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_DATABASE
ENV MYSQL_HOST=$MYSQL_HOST
ENV MYSQL_USER=$MYSQL_USER
ENV MYSQL_PASSWORD=$MYSQL_PASSWORD
ENV MYSQL_DATABASE=$MYSQL_DATABASE

# Install necessary packages and PHP extensions, including libonig-dev
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    libxml2-dev \
    imagemagick \
    libmagickwand-dev \
    wget \
    unzip \
    zip \
    libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql zip intl \
    && docker-php-ext-install exif mbstring xml \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Download Omeka S version 4.1.1 and unzip into /var/www/html
RUN wget https://github.com/omeka/omeka-s/releases/download/v4.1.1/omeka-s-4.1.1.zip \
    && unzip omeka-s-4.1.1.zip -d /var/www/html/ \
    && rm omeka-s-4.1.1.zip

# Copy the entry point script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set ownership of files directory to www-data
RUN chown -R www-data:www-data /var/www/html/omeka-s/files \
    && chmod -R 755 /var/www/html/omeka-s/files

# Set the document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/omeka-s

# Create custom Apache VirtualHost configuration for Omeka S
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot ${APACHE_DOCUMENT_ROOT}\n\
    <Directory ${APACHE_DOCUMENT_ROOT}>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Expose port 80 for Apache
EXPOSE 80

# Set Database ini file and start Apache in the foreground
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
