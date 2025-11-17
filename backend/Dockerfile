# Running App 后端 Dockerfile
# 基于 PHP 8.0 + Apache

FROM php:8.0-apache

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制项目文件
COPY . /var/www/html

# 安装 PHP 依赖
RUN composer install --no-dev --optimize-autoloader

# 创建必要的目录并设置权限
RUN mkdir -p runtime uploads crash_logs \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 runtime uploads crash_logs

# 配置 Apache
RUN a2enmod rewrite \
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# 复制 Apache 虚拟主机配置
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf

# 暴露端口
EXPOSE 80

# 启动 Apache
CMD ["apache2-foreground"]
