FROM rg.fr-par.scw.cloud/yproximite/sylius-base:7.4 as base

COPY .docker/nginx.d /etc/nginx/conf.d/
COPY .docker/fpm.d /usr/local/etc/php-fpm.d/
COPY .docker/php.d /usr/local/etc/php/conf.d/

FROM base as builder

WORKDIR /var/www/html
ARG COMPOSER_AUTH

COPY . .

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node & Build
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install 10 && nvm use 10 \
    && npm install --global yarn \
    && yarn && yarn build \
    && rm -rf node_modules \
    && composer install

FROM base as production

COPY --from=builder /var/www/html /var/www/html

RUN chown -R www-data:www-data /var/www/html
