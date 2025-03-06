###> CHANNEL_CODE must be in lowercase ###
CHANNEL_CODE='code_channel'
THEME_NAME='themes/starter-theme'
CUSTOMER_SERVICE_NUMBER='01 56 96 96 96'
ROUTER_HOST={{ .app_name | toYaml }}.wip

###> bucket storage ###
AWS_S3_KEY=access_app
AWS_S3_SECRET=secret_app
AWS_S3_BUCKET=syl-{{ .app_name | toYaml }}
AWS_S3_REGION=us-east-1
AWS_S3_VERSION=2006-03-01
AWS_S3_ENDPOINT=http://${MINIO_HOST}:${MINIO_PORT}

###> symfony/framework-bundle ###
APP_ENV=dev
APP_DEBUG=1
APP_SECRET=EDITME
###< symfony/framework-bundle ###

###> doctrine/doctrine-bundle ###
# Format described at http://docs.doctrine-project.org/projects/doctrine-dbal/en/latest/reference/configuration.html#connecting-using-a-url
# For a sqlite database, use: "sqlite:///%kernel.project_dir%/var/data.db"
# Set "serverVersion" to your server version to avoid edge-case exceptions and extra database calls
# Hydrated by the symfony CLI
#DATABASE_URL=mysql://app@127.0.0.1:3306/sylius?serverVersion=5.7
###< doctrine/doctrine-bundle ###

###> symfony/messenger ###
SYLIUS_MESSENGER_TRANSPORT_MAIN_DSN=doctrine://default
SYLIUS_MESSENGER_TRANSPORT_MAIN_FAILED_DSN=doctrine://default?queue_name=main_failed
SYLIUS_MESSENGER_TRANSPORT_CATALOG_PROMOTION_REMOVAL_DSN=doctrine://default?queue_name=catalog_promotion_removal
SYLIUS_MESSENGER_TRANSPORT_CATALOG_PROMOTION_REMOVAL_FAILED_DSN=doctrine://default?queue_name=catalog_promotion_removal_failed
###< symfony/messenger ###

###> lexik/jwt-authentication-bundle ###
JWT_SECRET_KEY=%kernel.project_dir%/config/jwt/private.pem
JWT_PUBLIC_KEY=%kernel.project_dir%/config/jwt/public.pem
JWT_PASSPHRASE=e7c5fca1060bdf6ad23c33e4c236081f
###< lexik/jwt-authentication-bundle ###

###> snc/redis-bundle ###
# passwords that contain special characters (@, %, :, +) must be urlencoded
# Hydrated by the symfony CLI
#REDIS_URL=redis://localhost
###< snc/redis-bundle ###

###> symfony/lock ###
# Choose one of the stores below
# postgresql+advisory://db_user:db_password@localhost/db_name
LOCK_DSN=${REDIS_URL}
###< symfony/lock ###

###> knplabs/knp-snappy-bundle ###
WKHTMLTOPDF_PATH=/usr/local/bin/wkhtmltopdf
WKHTMLTOIMAGE_PATH=/usr/local/bin/wkhtmltoimage
###< knplabs/knp-snappy-bundle ###

###> friendsofsymfony/elastica-bundle ###
ELASTICSEARCH_URL=
ELASTICSEARCH_HOST=sylius-test.es.eu-west-3.aws.elastic-cloud.com
ELASTICSEARCH_PORT=9243
ELASTICSEARCH_USER=bob-sylius
ELASTICSEARCH_PASSWORD=hej!HUX5hwt0gdn1vwn
###< friendsofsymfony/elastica-bundle ###

SMTP_HOST=smtp.mailtrap.io
SMTP_ENCRYPTION=tls
SMTP_PORT=587
SMTP_AUTH=false
SMTP_USERNAME=4533f032e46b8f
SMTP_PASSWORD=b36033bc124cea

###> symfony/mailer ###
MAILER_DSN=null://null
###< symfony/mailer ###

###> sentry/sentry-symfony ###
SENTRY_DSN=
###< sentry/sentry-symfony ###

EMAIL_SENDER_NAME=${ROUTER_HOST}
EMAIL_SENDER_ADDRESS=no-reply@${ROUTER_HOST}
