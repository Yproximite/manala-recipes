FROM rg.fr-par.scw.cloud/yproximite/wordpress-base:7.4 as base

ARG PHP_INI_OPCACHE_ENABLE=1
ENV PHP_INI_OPCACHE_ENABLE PHP_INI_OPCACHE_ENABLE

COPY .docker/nginx.d /etc/nginx/conf.d/
COPY .docker/fpm.d /usr/local/etc/php-fpm.d/
COPY .docker/php.d /usr/local/etc/php/conf.d/

FROM base as development

ARG NODE_VERSION=10.24.1

WORKDIR /var/www/html

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node & Yarn
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && \. "$NVM_DIR/nvm.sh" \
    && nvm install ${NODE_VERSION}  \
    && nvm use v${NODE_VERSION} \
    && npm install --global yarn

FROM development as builder

COPY . .

RUN yarn && yarn build \
    && rm -rf node_modules

ARG COMPOSER_AUTH
RUN composer install

FROM base as production

COPY --from=builder /var/www/html /var/www/html

RUN chmod u+w /var/www/html/web/app/uploads && \
    chown -R www-data:www-data ./
