# NoShow - App (Docker)

A [Manala recipe](https://github.com/manala/manala-recipes) for projects using the Laravel Sail CLI, PHP, Node.js, MySQL and Redis.

---

## Requirements

* [manala](https://manala.github.io/manala/)
* [Docker Desktop 2.2.0+](https://docs.docker.com/engine/install/), with [Docker Compose](https://docs.docker.com/compose/install/) **or** [Docker Compose v2 plugin](https://docs.docker.com/compose/cli-command/#install-on-linux)

## Init

```
$ cd [workspace]
$ manala init -i noshow.app-docker --repository https://github.com/Yproximite/manala-recipes.git [project]
```

## Configure PHP and Node.js versions

Since this recipe relies on having PHP and Node.js by yourself (with phpenv, ondrej's PPA, brew, nvm, etc...),
it's important to create two files `.php-version` and `.nvmrc` which will contains the PHP and Node.js versions to use for your project.

```shell
cd /path/to/my/app
echo 8.0 > .php-version # Use PHP 8.0
echo 14 > .nvmrc # Use Node.js 14
```

Those files will be used by:
- NVM when using `nvm use`
- GitHub Actions, thanks to [the action `setup-environment`](#github-actions)

**It is important to use `sail php` and not `php` directly for running commands, `sail` will wrap command to interact with Docker.**

## Quick start

In a shell terminal, change directory to your app, and run the following commands:

```shell
cd /path/to/my/app
manala init --repository https://github.com/Yproximite/manala-recipes.git
Select the "noshow.app-docker" recipe
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
    mysql:
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
            - run: sail php -v # PHP 8.0.3
            - run: node -v # Node.js 14.16.0
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
	$(sail) artisan cache:clear
	$(sail) yarn install
	$(sail) yarn dev

## Install application in integration environment
install-app@integration: export APP_ENV=test
install-app@integration:
	$(sail) composer install --ansi --no-interaction --no-progress --prefer-dist --optimize-autoloader
	$(sail) yarn install --color=always --no-progress --frozen-lockfile
	$(sail) yarn dev
	$(MAKE) init-db@integration

################
# Common tasks #
################

composer-install:
	$(sail) composer install --ansi --no-interaction

init-db:
	$(sail) artisan migrate:fresh --ansi --no-interaction
	$(sail) artisan db:seed --ansi --no-interaction

init-db@integration:
	$(sail) artisan --env testing migrate:fresh --ansi --no-interaction
	$(sail) artisan --env testing db:seed --ansi --no-interaction 
```

### Tooling

#### Dozzle
The project embed a tool ([Dozzle](https://github.com/amir20/dozzle)) to monitor in realtime logs from any container.
Once project has been launch (e.g. after `make up`) the tool is accessible at [http://localhost:9999](http://localhost:9999)
