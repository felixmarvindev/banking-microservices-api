#!/bin/bash
set -e

# Database initialization script for microservices
# This script creates all required databases if they don't exist

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create databases for each microservice
    SELECT 'CREATE DATABASE auth'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'auth')\gexec

    SELECT 'CREATE DATABASE account'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'account')\gexec

    SELECT 'CREATE DATABASE transaction'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'transaction')\gexec

    SELECT 'CREATE DATABASE loan'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'loan')\gexec

    SELECT 'CREATE DATABASE notification'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'notification')\gexec
EOSQL

echo "Databases created successfully!"
