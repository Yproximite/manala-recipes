# yProx - WordPress (Docker)

A [Manala](https://manala.github.io/manala/) recipe for yProximité WordPress projects.

It provides:

* a Docker Compose environment for local development (web, MySQL, optional Redis),
* the `Dockerfile` used both locally and to build the deployed production image,
* the GitHub Actions workflows: CI, CD, Composer operations and Manala synchronization.

The generated `.env.example` follows the [Bedrock](https://roots.io/bedrock/) layout
(`web/app`, `WP_HOME` / `WP_SITEURL`, roots.io salts).

---

## Requirements

* [manala](https://manala.github.io/manala/)
* [Docker](https://docs.docker.com/engine/install/) with the [Compose plugin](https://docs.docker.com/compose/install/)
* [Ycli](https://github.com/Yproximite/ycli), which provides the `wordpress-network` network and the
  reverse proxy serving `*.wordpress.vm` hostnames
* Access to the yProximité Scaleway registry, where the `wordpress-base` image is pulled from
* A `~/.composer/auth.json` file: Compose mounts it read-only into the web container

## Init

```shell
cd [workspace]
manala init -i yprox.wordpress --repository https://github.com/Yproximite/manala-recipes.git [project]
```

On an existing project, run `manala init` in its directory and pick the `yprox.wordpress` recipe.

Then edit `.manala.yaml` and apply your changes:

```shell
manala up
```

**Run `manala up` every time you edit `.manala.yaml`, otherwise nothing is regenerated.**
`manala watch` keeps the project in sync while you work on the manifest.

## Configuration

Everything lives under the `system` key of `.manala.yaml`:

| Key | Accepted values | Effect |
| --- | --- | --- |
| `app_name` | kebab-case string, **required** | container names, `<app_name>.wordpress.vm` hostname, database name / user, S3 bucket, CD project |
| `timezone` | `Region/City`, defaults to `Etc/UTC` | `TZ` of the database and Redis containers |
| `php.version` | `7.4`, `8.2`, `8.4` | `wordpress-base` image tag, `PHP_VERSION` in CI |
| `node.version` | `"18"`, `"20"`, `"22"`, `"24"` | `NODE_VERSION` build argument (installed through nvm), `NODE_VERSION` in CI |
| `redis.version` | `~` or `'*'` | adds the Redis service to `docker-compose.yaml` |
| `run.postdeploy` | string or `~` | adds a `postdeploy` entry to the `Procfile` |

A typical manifest:

```yaml
manala:
    recipe: yprox.wordpress
    repository: https://github.com/Yproximite/manala-recipes.git

system:
    app_name: your-app
    timezone: Europe/Paris

    php:
        version: 8.4

    node:
        version: "22"

    redis:
        version: '*'

    run:
        postdeploy: ~
```

### Node version

Major versions are enough: `nvm` and `actions/setup-node` both resolve `22` to the latest 22.x. The
exact versions previously exposed by the recipe (`10.24.1`, `18.20.8`, `20.20.0`, `22.23.2`) are still
accepted, so existing projects keep synchronizing.

**Keep the quotes.** `version: "22"` is a string, `version: 22` is a YAML integer and gets rejected:

```
⨯ invalid type  expected=string given=integer
```

Two consequences of resolving a major at build time are worth knowing: two builds a few weeks apart
may not embed the same Node patch release, and the version must be one the `wordpress-base` image can
actually run.

### Keys with no effect

`php.extensions`, `node.extensions` and `redis.config` are accepted by the schema but no template
consumes them — filling them changes nothing. `node.version` cannot be set to `~` either, despite
`null` appearing in its enum.

## Generated files

`manala up` overwrites all of these; edit them in the recipe, never in the project.

| Path | Contents |
| --- | --- |
| `.docker/Dockerfile` | `base` → `development` → `builder` → `production` stages |
| `.docker/nginx.d/`, `.docker/fpm.d/`, `.docker/php.d/` | configuration snippets copied into the image |
| `docker-compose.yaml` | web, database and — when Redis is enabled — the Redis service |
| `Procfile` | processes run by the image: `nginx`, `php-fpm`, plus `postdeploy` |
| `.env.example` | template for the `.env` of the project |
| `.dockerignore` | build context exclusions |
| `.php-version` | the PHP version, for the local toolchain (phpenv, asdf) |
| `.nvmrc` | the Node major version, for `nvm use` |
| `.github/workflows/ci.yml`, `cd.yml`, `composer_operations.yml`, `manala_sync.yml` | see below |
| `.manala/Makefile` | the `manala` target |
| `.manala/postsync.sh` | see [Synchronization](#synchronization) |

`.docker/nginx.d/wordpress.conf` and `.docker/fpm.d/wordpress.conf` are shipped empty: they exist as
placeholders, and anything a project writes there is wiped on the next `manala up`.

`.github/dependabot.yml` sits in the recipe as a reference but is **not** part of the synchronized
files — copy it by hand into a project that needs it.

The root `Makefile` is the exception: manala creates it from `Makefile.dist` when it is missing, then
leaves it alone. It only includes `.manala/Makefile`, so project targets can be added to it safely.

## Synchronization

```shell
make manala
```

`manala up` alone is not enough. It can only write whole files, so it never touches `composer.json`
and `package.json`, whose contents the project also owns. `.manala/postsync.sh` covers that gap: it
realigns `require.php` and `engines.node` on the versions declared in `.manala.yaml`, then tries to
refresh the `composer.lock` content-hash.

That refresh is best effort. It needs a full dependency resolution, which fails on the projects
pinning package versions the repositories no longer serve. The script then leaves the lock alone and
warns: an outdated content-hash only makes `composer install` print a warning, it still installs.

The script needs `composer` and, for a project with a `package.json`, `jq` (`brew install jq`).

Run it after every `manala up`, not only when a version changes: a project declaring no `node:` block
in its `.manala.yaml` inherits the recipe default, so a plain recipe synchronization moves its
`Dockerfile` while leaving `engines.node` behind.

## Local environment

Create the `.env` file from the generated template, then fill in the salts
([roots.io/salts.html](https://roots.io/salts.html)), `MCLOUD_STORAGE_S3_SECRET` and, if the project
uses it, `WPMDB_LICENCE`:

```shell
cp .env.example .env
```

Build and start the containers:

```shell
docker compose up -d --build
```

The site is served at `http://<app_name>.wordpress.vm` through the Ycli proxy. Container ports are
published on random host ports; retrieve them when you need a direct access:

```shell
docker compose port wordpress-<app_name>-web 8080
docker compose port wordpress-<app_name>-database 3306
```

Useful details:

* the project directory is bind-mounted on `/var/www/html`, so Composer and Yarn can be run straight
  from the web container,
* the `development` stage installs Node through nvm: source it before using `yarn`
  (`. "$NVM_DIR/nvm.sh"`),
* OPcache is disabled locally (`PHP_INI_OPCACHE_ENABLE: 0`) and enabled in the production image,
* database credentials all default to `app_name`, on a `mysql:5.7` server whose data lives in a named
  volume,
* the Redis service uses `redis/redis-stack`, which also exposes its RedisInsight UI on port `8001`.

## GitHub Actions

### CI

Runs on pull requests and on pushes to `master`. Two independent jobs, each one skipped when the file
it needs is absent:

* **php** — needs `composer.json`: `composer validate`, then `php-cs-fixer` in dry-run mode, so
  `friendsofphp/php-cs-fixer` must be a dev dependency of the project.
* **javascript** — needs `package.json`: `yarn install`, `yarn lint`, `yarn build`, so both scripts
  must exist and a `yarn.lock` must be committed.

Each job reads its version from the generated `.php-version` and `.nvmrc`, so `ci.yml` holds no
manifest value and a version change no longer rewrites it.

Two auto-merge jobs then run once both are green:

* pull requests labelled `bifrost:composer_operation` opened by the `yprox` account,
* Dependabot pull requests, under this policy: development dependencies on any minor or patch,
  production and indirect dependencies only when the bump actually fixes an open security advisory,
  majors always by hand.

### CD

Triggered by a successful CI run on `master`, or manually. It delegates to
`Yproximite/actions/.github/workflows/wordpress_build.yml`, which builds the `production` stage and
rolls it out. Automatic deployment only happens when the repository variable `AUTODEPLOY` is set to
`true`; `workflow_dispatch` always deploys.

### Composer operations

Manual (or dispatched) `composer update` / `require` / `remove` on `master`, opening a pull request
that the auto-merge job above can pick up.

### Manala sync

Re-runs `manala up` on the project and opens a pull request with the result. Dispatched by this
repository when a recipe changes, or triggered by hand.

### Secrets and variables

| Name | Used by |
| --- | --- |
| `COMPOSER_AUTH` | CI, CD, Composer operations — private Packagist access |
| `GH_MANALA_SYNC_TOKEN` | Composer-operation auto-merge, Composer operations, Manala sync |
| `ACTION_DEPENDABOT_AUTO_MERGE_TOKEN` | Dependabot auto-merge — a PAT is required, the workflow token cannot approve a pull request |
| `SCW_CONTAINER_REGISTRY_TOKEN` | CD — pushing the image |
| `GH_ROLLOUT_TOKEN` | CD — triggering the rollout |
| `AUTODEPLOY` (variable) | CD — enables automatic deployment |
