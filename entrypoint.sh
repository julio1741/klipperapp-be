#!/bin/bash
set -e

echo "== Esperando la base de datos... =="
# Este comando espera a que la base esté disponible (opcional si ya estás seguro)
# Puedes comentarlo si no es necesario
# ./bin/wait-for-it.sh "$DATABASE_HOST:$DATABASE_PORT" --timeout=30 --strict -- echo "Base lista"

echo "== Ejecutando migraciones =="
bundle exec rails db:migrate

echo "== Iniciando servidor Puma =="
exec bundle exec puma -C config/puma.rb
