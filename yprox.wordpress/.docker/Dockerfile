FROM rg.fr-par.scw.cloud/yproximite/wordpress-base:7.4 as base

COPY .docker/nginx.d /etc/nginx/conf.d/
COPY .docker/fpm.d /usr/local/etc/php-fpm.d/
COPY .docker/php.d /usr/local/etc/php/conf.d/

FROM base as builder

WORKDIR /var/www/html
ARG COMPOSER_AUTH

COPY . .

# Install node
COPY --from=node:10-alpine /usr/lib /usr/lib
COPY --from=node:10-alpine /usr/local/share /usr/local/share
COPY --from=node:10-alpine /usr/local/lib /usr/local/lib
COPY --from=node:10-alpine /usr/local/include /usr/local/include
COPY --from=node:10-alpine /usr/local/bin /usr/local/bin

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache --virtual .build-deps \
        yarn \
    && yarn && yarn build \
    && rm -rf node_modules \
    && composer install

FROM base as production

COPY --from=builder /var/www/html /var/www/html

RUN chmod u+w /var/www/html/web/app/uploads && \
    chown -R www-data:www-data ./
