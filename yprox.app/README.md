# yProx - App

A [Manala recipe](https://github.com/manala/manala-recipes) greatly inspired by [elao.app recipe](https://github.com/manala/manala-recipes/tree/master/elao.app) ❤️

---

* [Requirements](#requirements)
* [Overview](#overview)
* [Init](#init)
* [Quick start](#quick-start)
* [System](#system)
* [Integration](#integration)
    * [Github Actions](#github-actions)
    * [Common Integration Tasks](#common-integration-tasks)
* [Makefile](#makefile)
* [Tips, Tricks, and Tweaks](#tips-tricks-and-tweaks)

## Requirements

* [manala](https://manala.github.io/manala/)
* [VirtualBox 6.1.12+](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant 2.2.10+](https://www.vagrantup.com/downloads.html)
* [Vagrant Landrush 1.3.2+](https://github.com/vagrant-landrush/landrush)
* [Docker Desktop 2.2.0+](https://docs.docker.com/engine/install/)

## Overview

This recipe contains some helpful scripts in the context of a php/nodejs app, such as Makefile tasks in order to release and deploy your app.

## Init

```
$ cd [workspace]
$ manala init -i yprox.app --repository https://github.com/Yproximite/manala-recipes [project]
```

## Quick start

In a shell terminal, change directory to your app, and run the following commands:

```shell
cd /path/to/my/app
manala init --repository https://github.com/Yproximite/manala-recipes
Select the "yprox.app" recipe
```

Edit the `Makefile` at the root directory of your project and add the following lines at the beginning of the file:

```makefile
.SILENT:

-include .manala/Makefile
```

Then update the `.manala.yaml` file (see [the releases example](#releases) below) and then run the `manala up` command:

```shell
manala up
```

!!! Warning
    Don't forget to run the `manala up` command each time you update the 
    `.manala.yaml` file to actually apply your changes !!!

From now on, if you execute the `make help` command in your console, you should obtain the following output:

```shell
Usage: make [target]

Help:
  help This help

Docker:
  docker Run docker container

App:
```

## VM interaction

In your app directory.

Initialise your app:
```bash
make setup
```

Start VM:
```bash
make up
```

Stop VM:
```bash
make halt
```

VM shell:
```bash
make ssh
```


## System

Here is an example of a system configuration in `.manala.yaml`:

```yaml
##########
# System #
##########

system:
    version: 10
    hostname: localhost.your-app.fr
    #memory: 4096 # Optional
    #cpus: 2 # Optional
    nginx:
        configs:
            - template: nginx/gzip.j2
            - template: nginx/php_fpm_app.j2
            # App
            - file: app.conf
              config: |
                  server {
                      listen 443 ssl;
                      listen 4430 ssl;
                      listen 4431 ssl;

                      server_name ~.;
                      root /srv/app/public;

                      ssl_certificate /srv/app/var/localhost.your-app.fr+1.pem;
                      ssl_certificate_key /srv/app/var/localhost.your-app.fr+1-key.pem;

                      access_log /srv/log/nginx.access.log;
                      error_log /srv/log/nginx.error.log;

                      include conf.d/gzip;
                      location / {
                          try_files $uri /index.php$is_args$args;
                      }
                      location ~ ^/index\.php(/|$) {
                          include conf.d/php_fpm_app;
                          set $APP_ENV dev;
                          if ( $server_port = 4430 ) {
                              set $APP_ENV test;
                          }
                          if ( $server_port = 4431 ) {
                              set $APP_ENV prod;
                          }
                          fastcgi_param APP_ENV $APP_ENV;
                          internal;
                      }
                  }
    php:
        version: 7.4
        extensions:
            # Symfony
            - intl
            - curl
            - mbstring
            - xml
            # App
            - pgsql
        configs:
            - template: php/opcache.ini.j2
            - template: php/app.ini.j2
              config:
                  date.timezone: UTC
        #blackfire:
        #    agent:
        #        config:
        #            server_id: <Blackfire server_id> 
        #            server_token: <Blackfire server_token> 
        #    client:
        #        config:
        #            client_id: <Blackfire client_id> 
        #            client_token: <Blackfire client_token> 
    nodejs:
        version: 12
    postgresql:
        version: 12
    redis:
        version: '*'

    files:
        - path: /srv/app/var/log
          src: /srv/log
          state: link_directory
          force: true
        - path: /srv/app/var/cache
          src: /srv/cache
          state: link_directory
          force: true
```

## Integration

### Github Actions

The recipes generates a `Dockerfile` and a `docker-compose.yaml` file that can 
be used to provide a fully-fledged environnement according to your project needs.

The [Elao/manala-ci-action](https://github.com/Elao/manala-ci-action) rely on 
this to allow you running any CLI command in this environnement, 
using Github Action workflows.

### Common integration tasks

Add in your `Makefile`:

```makefile
###########
# Install #
###########

# ...

install-app@integration: export APP_ENV=test
install-app@integration:
	# Composer
	composer install --ansi --verbose --no-interaction --no-progress --prefer-dist --optimize-autoloader
	# Yarn
	yarn install --color=always --no-progress --frozen-lockfile
	yarn dev

	$(MAKE) init-db@integration
	
init-db@integration:
	bin/console doctrine:database:create --no-interaction
	bin/console doctrine:schema:update --force --no-interaction # to remove when migrations will be used
	# bin/console doctrine:migrations:migrate --no-interaction
	bin/console hautelook:fixtures:load --no-interaction
```

## Makefile

Makefile targets that are supposed to be runned via docker must be prefixed.

```makefile
foo: SHELL := $(or $(DOCKER_SHELL),$(SHELL))
foo:
	# Do something really foo...
```

## Tips, Tricks, and Tweaks

* [Vagrant root privilege requirement](https://www.vagrantup.com/docs/synced-folders/nfs.html#root-privilege-requirement)
* Debug ansible provisioning:

  ```shell
  ansible-galaxy collection install manala.roles --collections-path /vagrant/ansible/collections
  ```
* Update vagrant boxes
  ```
  vagrant box outdated --global
  vagrant box update --box bento/debian-10
  ```
