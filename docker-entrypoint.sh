#!/bin/sh
set -e

if [ "$SELFSIGNED_CERTS" = 'true' ]; then
    wget https://raw.githubusercontent.com/Telecominfraproject/wlan-cloud-ucentral-deploy/main/docker-compose/certs/restapi-ca.pem -O /usr/local/share/ca-certificates/restapi-ca-selfsigned.pem
    update-ca-certificates
fi

if [[ "$TEMPLATE_CONFIG" = 'true' && ! -f "$UCENTRALFMS_CONFIG"/ucentralfms.properties ]]; then
  RESTAPI_HOST_ROOTCA=${RESTAPI_HOST_ROOTCA:-"\$UCENTRALFMS_ROOT/certs/restapi-ca.pem"} \
  RESTAPI_HOST_PORT=${RESTAPI_HOST_PORT:-"16004"} \
  RESTAPI_HOST_CERT=${RESTAPI_HOST_CERT:-"\$UCENTRALFMS_ROOT/certs/restapi-cert.pem"} \
  RESTAPI_HOST_KEY=${RESTAPI_HOST_KEY:-"\$UCENTRALFMS_ROOT/certs/restapi-key.pem"} \
  RESTAPI_HOST_KEY_PASSWORD=${RESTAPI_HOST_KEY_PASSWORD:-"mypassword"} \
  INTERNAL_RESTAPI_HOST_ROOTCA=${INTERNAL_RESTAPI_HOST_ROOTCA:-"\$UCENTRALFMS_ROOT/certs/restapi-ca.pem"} \
  INTERNAL_RESTAPI_HOST_PORT=${INTERNAL_RESTAPI_HOST_PORT:-"17004"} \
  INTERNAL_RESTAPI_HOST_CERT=${INTERNAL_RESTAPI_HOST_CERT:-"\$UCENTRALFMS_ROOT/certs/restapi-cert.pem"} \
  INTERNAL_RESTAPI_HOST_KEY=${INTERNAL_RESTAPI_HOST_KEY:-"\$UCENTRALFMS_ROOT/certs/restapi-key.pem"} \
  INTERNAL_RESTAPI_HOST_KEY_PASSWORD=${INTERNAL_RESTAPI_HOST_KEY_PASSWORD:-"mypassword"} \
  SERVICE_KEY=${SERVICE_KEY:-"\$UCENTRALFMS_ROOT/certs/restapi-key.pem"} \
  SERVICE_KEY_PASSWORD=${SERVICE_KEY_PASSWORD:-"mypassword"} \
  SYSTEM_DATA=${SYSTEM_DATA:-"\$UCENTRALFMS_ROOT/data"} \
  SYSTEM_URI_PRIVATE=${SYSTEM_URI_PRIVATE:-"https://localhost:17004"} \
  SYSTEM_URI_PUBLIC=${SYSTEM_URI_PUBLIC:-"https://localhost:16004"} \
  SYSTEM_URI_UI=${SYSTEM_URI_UI:-"http://localhost"} \
  S3_BUCKETNAME=${S3_BUCKETNAME:-"ucentral-ap-firmware"} \
  S3_REGION=${S3_REGION:-"us-east-1"} \
  S3_SECRET=${S3_SECRET:-"*******************************************"} \
  S3_KEY=${S3_KEY:-"*******************************************"} \
  S3_BUCKET_URI=${S3_BUCKET_URI:-"ucentral-ap-firmware.s3.amazonaws.com"} \
  KAFKA_ENABLE=${KAFKA_ENABLE:-"true"} \
  KAFKA_BROKERLIST=${KAFKA_BROKERLIST:-"localhost:9092"} \
  STORAGE_TYPE=${STORAGE_TYPE:-"sqlite"} \
  STORAGE_TYPE_POSTGRESQL_HOST=${STORAGE_TYPE_POSTGRESQL_HOST:-"localhost"} \
  STORAGE_TYPE_POSTGRESQL_USERNAME=${STORAGE_TYPE_POSTGRESQL_USERNAME:-"ucentralfms"} \
  STORAGE_TYPE_POSTGRESQL_PASSWORD=${STORAGE_TYPE_POSTGRESQL_PASSWORD:-"ucentralfms"} \
  STORAGE_TYPE_POSTGRESQL_DATABASE=${STORAGE_TYPE_POSTGRESQL_DATABASE:-"ucentralfms"} \
  STORAGE_TYPE_POSTGRESQL_PORT=${STORAGE_TYPE_POSTGRESQL_PORT:-"5432"} \
  STORAGE_TYPE_MYSQL_HOST=${STORAGE_TYPE_MYSQL_HOST:-"localhost"} \
  STORAGE_TYPE_MYSQL_USERNAME=${STORAGE_TYPE_MYSQL_USERNAME:-"ucentralfms"} \
  STORAGE_TYPE_MYSQL_PASSWORD=${STORAGE_TYPE_MYSQL_PASSWORD:-"ucentralfms"} \
  STORAGE_TYPE_MYSQL_DATABASE=${STORAGE_TYPE_MYSQL_DATABASE:-"ucentralfms"} \
  STORAGE_TYPE_MYSQL_PORT=${STORAGE_TYPE_MYSQL_PORT:-"3306"} \
  envsubst < $UCENTRALFMS_CONFIG/ucentralfms.properties.tmpl > $UCENTRALFMS_CONFIG/ucentralfms.properties
fi

if [ "$1" = '/ucentral/ucentralfms' -a "$(id -u)" = '0' ]; then
    if [ "$RUN_CHOWN" = 'true' ]; then
      chown -R "$UCENTRALFMS_USER": "$UCENTRALFMS_ROOT" "$UCENTRALFMS_CONFIG"
    fi
    exec su-exec "$UCENTRALFMS_USER" "$@"
fi

exec "$@"
