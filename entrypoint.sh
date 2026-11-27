#!/bin/sh
# Застосовує міграції перед запуском Django-сервера.
# База вже готова: docker-compose чекає healthcheck сервісу db.
set -e

python manage.py migrate --noinput

exec "$@"
