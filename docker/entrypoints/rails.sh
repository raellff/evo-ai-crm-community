#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

# Ensure gems are installed and up-to-date
bundle check || bundle install

# Prepare the database (create if missing, run migrations).
# EVO-1999: gate RUN_MIGRATIONS (default 'true' = fail-safe) para que o serviço web
# sempre migre no boot, inclusive em orquestradores que ignoram o command/entrypoint
# do compose (CapRover). Defina RUN_MIGRATIONS=false nos *-sidekiq para evitar
# preparar o banco em duplicado (o db:prepare do web já cobre, via advisory lock).
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  echo "Preparing database (RUN_MIGRATIONS=${RUN_MIGRATIONS:-true})..."
  bundle exec rails db:prepare
else
  echo "Skipping database preparation (RUN_MIGRATIONS=${RUN_MIGRATIONS})."
fi

# Execute the main process of the container
exec "$@"
