FROM rg.fr-par.scw.cloud/yproximite/sylius-base:8.2 as base

COPY .docker/nginx.d /etc/nginx/conf.d/
COPY .docker/fpm.d /usr/local/etc/php-fpm.d/
COPY .docker/php.d /usr/local/etc/php/conf.d/

FROM base as builder

WORKDIR /var/www/html
ARG COMPOSER_AUTH

COPY . .

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-scripts

RUN export NODE_VERSION=$(cat .nvmrc | xargs) && \
    export NVM_DIR=/root/.nvm && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash

RUN export NODE_VERSION=$(cat .nvmrc | xargs) && \
    export NVM_DIR=/root/.nvm && \. "$NVM_DIR/nvm.sh" && \
    npm install --global yarn \
    && yarn && yarn build \
    && rm -rf node_modules

FROM base as production

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=builder /var/www/html /var/www/html

RUN touch /var/www/html/.env && \
    mkdir -p /var/www/html/public/media/image && \
    chown -R www-data:www-data /var/www/html
