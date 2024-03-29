# yProx - Sylius (Docker)

A [Manala recipe](https://github.com/manala/manala-recipes) for sylius projects.

---

## Requirements

* [manala](https://manala.github.io/manala/)
* [Docker Desktop 2.2.0+](https://docs.docker.com/engine/install/), with [Docker Compose](https://docs.docker.com/compose/install/) **or** [Docker Compose v2 plugin](https://docs.docker.com/compose/cli-command/#install-on-linux)
* [Ycli](https://github.com/Yproximite/ycli) must be installed by yourself on your machine

## Init

```
$ cd [workspace]
$ manala init -i yprox.sylius --repository https://github.com/Yproximite/manala-recipes.git [project]
```

## Quick start

In a shell terminal, change directory to your app, and run the following commands:

```shell
cd /path/to/my/app
manala init --repository https://github.com/Yproximite/manala-recipes.git
Select the "yprox.sylius" recipe
```

Edit the `Makefile` at the root directory of your project and add the following lines at the beginning of the file:

```makefile
-include .manala/Makefile

# This function will be called at the end of "make setup"
define setup
	# For example:
	# $(MAKE) install-app
	# $(MAKE) init-db@test
endef

# This function will be called at the end of "make setup@integration"
define setup_integration
	# For example:
	# $(MAKE) install-app@integration
endef
```

Then update the `.manala.yaml` file (see [the releases example](#releases) below) and then run the `manala up` command:

```shell
manala up
```

**Don't forget to run the `manala up` command each time you update the `.manala.yaml` file to actually apply your changes**

From now on, if you execute the `make help` command in your console, you should obtain the following output:

```shell
Usage: make [target] 	

Help:   
  help This help 	

Environment:   
  setup              Setup the development environment   
  setup@integration  Setup the integration environment   
  up                 Start the development environment   
  halt               Stop the development environment   
  destroy            Destroy the development environment 	

Project:
  install-app:             Install application
  install-app@integration: Install application in integration environment
```

## Docker interaction

Initialise Docker Compose containers and your app:
```bash
make setup
```

Start Docker Compose containers:
```bash
make up
```

Stop Docker Compose containers:
```bash
make halt
```

Stop and remove Docker Compose containers:
```shell
make destroy
```

## System

Here is an example of a system configuration in `.manala.yaml`:

```yaml
##########
# System #
##########

system:
    app_name: your-app
    postgresql:
        version: 12
    redis:
        version: '*'
```

## Integration

### GitHub Actions

Since this recipe generates a `docker-compose.yaml` file, it can 
be used to provide a fully-fledged environnement according to your project needs on GitHub Actions.

```yaml
name: CI

on:
    pull_request:
        types: [opened, synchronize, reopened, ready_for_review]

env:
    TZ: UTC

jobs:
    php:
        runs-on: ubuntu-latest
        steps:
            - uses: actions/checkout@v2
            
            # The code of this local action can be found below
            - uses: ./.github/actions/setup-environment

            - uses: shivammathur/setup-php@v2
              with:
                  php-version: ${{ env.PHP_VERSION }} # PHP_VERSION comes from setup-environment local action
                  coverage: none
                  extensions: iconv, intl
                  ini-values: date.timezone=${{ env.TZ }}
                  tools: symfony

            - uses: actions/setup-node@v2
              with:
                  node-version: ${{ env.NODE_VERSION }} # NODE_VERSION comes from setup-environment local action

            - uses: actions/cache@v2
              with:
                  path: ${{ env.COMPOSER_CACHE_DIR }}
                  key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
                  restore-keys: ${{ runner.os }}-composer-

            - uses: actions/cache@v2
              with:
                  path: ${{ env.YARN_CACHE_DIR }}
                  key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
                  restore-keys: ${{ runner.os }}-yarn-

            # Will setup the Symfony CLI and build Docker Compose containers
            # No need to create DATABASE_URL or REDIS_URL environment variables, they will be
            # automatically injected to PHP/Symfony thanks to the Symfony CLI's Docker Integration
            - run: make setup@integration

            # Check versions
            - run: symfony php -v # PHP 8.0.3
            - run: node -v # Node.js 14.16.0

            # Run some tests... remember to use "symfony php" and not "php"
            - run: symfony console cache:clear
            - run: symfony console lint:twig templates
            - run: symfony console lint:yaml config --parse-tags
            - run: symfony console lint:xliff translations

```

This is the code of local action `setup-environment`:
```yaml
# .github/actions/setup-environment/action.yml
name: Setup environment
description: Setup environment
runs:
    using: 'composite'
    steps:
        - run: echo "PHP_VERSION=$(cat .php-version | xargs)" >> $GITHUB_ENV
          shell: bash

        - run: echo "NODE_VERSION=$(cat .nvmrc | xargs)" >> $GITHUB_ENV
          shell: bash

        # Composer cache
        - id: composer-cache
          run: echo "::set-output name=dir::$(composer global config cache-files-dir)"
          shell: bash

        - run: echo "COMPOSER_CACHE_DIR=${{ steps.composer-cache.outputs.dir }}" >> $GITHUB_ENV
          shell: bash

        # Yarn cache
        - id: yarn-cache-dir
          run: echo "::set-output name=dir::$(yarn cache dir)"
          shell: bash

        - run: echo "YARN_CACHE_DIR=${{ steps.yarn-cache-dir.outputs.dir }}" >> $GITHUB_ENV
          shell: bash
```

### Common integration tasks

Add in your `Makefile`:

```makefile
# ...

# This function will be called during "make setup"
define setup
    $(MAKE) install-app
    $(MAKE) init-db@test
endef

# This function will be called during "make setup@integration"
define setup_integration
    $(MAKE) install-app@integration
endef

###########
# Install #
###########

## Install application
install-app: composer-install init-db
install-app:
	$(symfony) console cache:clear
	yarn install
	yarn dev

## Install application in integration environment
install-app@integration: export APP_ENV=test
install-app@integration:
	$(composer) install --ansi --no-interaction --no-progress --prefer-dist --optimize-autoloader
	yarn install --color=always --no-progress --frozen-lockfile
	yarn dev
	$(MAKE) init-db@integration

################
# Common tasks #
################

composer-install:
	$(composer) install --ansi --no-interaction

init-db:
	$(symfony) console doctrine:database:drop --force --if-exists --no-interaction
	$(symfony) console doctrine:database:create --no-interaction
	$(symfony) console doctrine:schema:update --force --no-interaction # to remove when we will use migrations
	# $(symfony) console doctrine:migrations:migrate --no-interaction
	$(symfony) console hautelook:fixtures:load --no-interaction

init-db@test: export APP_ENV=test
init-db@test: init-db

init-db@integration: export APP_ENV=test
init-db@integration:
	$(symfony) console doctrine:database:create --if-not-exists --no-interaction
	$(symfony) console doctrine:schema:update --force --no-interaction # to remove when we will use migrations
	# $(symfony) console doctrine:migrations:migrate --no-interaction
	$(symfony) console hautelook:fixtures:load --no-interaction

reload-db@test: export APP_ENV=test
reload-db@test:
	$(symfony) console hautelook:fixtures:load --purge-with-truncate --no-interaction
```

### ElasticSearch usage

#### System configuration
> __ElasticSearch require some configuration in order start.__ 

You have to increase the `vm.max_map_count` up to `262144` either by running : `sysctl -w vm.max_map_count=262144` or by updating `/etc/sysctl.conf`.
Setting value with `sysctl` command will not persist after a reboot.

#### Plugins
You can install any plugin you need by providing them in the `plugins` field.
```yaml
# .manala.yml

system:
  app_name: your-app
  
  elascticsearch:
    version: 6.22.8
    plugins:
      - a-plugin
      - b-plugin 
```
> Since all elasticsearch data are stored in a persistent volume, if you remove a plugin from this list and just re-run a `make up` the plugin will not be removed.
> In order to do so, you have to delete the volume (the hard way) or manually remove the plugin in the container itself with `./bin/elasticsearch-plugin remove <plugin>`

### Tools

#### Admin UI for database

- If you use PostgreSQL, run `make run-phppgadmin` to run a local [PhpPgAdmin](https://github.com/phppgadmin/phppgadmin) instance
- If using MariaDB, run `make run-phpmyadmin` to run a local [PhpMyAdmin](https://github.com/phpmyadmin/phpmyadmin) instance

#### Admin UI for Redis

Run `make run-phpredisadmin` to run a local [PhpRedisAdmin](https://github.com/erikdubbelboer/phpRedisAdmin) instance.

#### Admin UI for Mongo

You can use `Compass` a GUI for MongoDB, install it from here : [Compass](https://www.mongodb.com/try/download/compass).
Once installed, retrieve Mongo Docker exposed port with `docker ps --filter "name=mongo"` and use this port in the connection string.

#### Kibana for ElasticSearch

Run `make run-kibana` to run a local [Kibana](https://github.com/elastic/kibana) instance.
