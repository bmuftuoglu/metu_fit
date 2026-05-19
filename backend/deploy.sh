#!/bin/bash
set -e

echo "=== MetuFit Deploy ==="
cd "$(dirname "$0")"

git pull origin main

cd backend
docker compose pull
docker compose up -d --build
docker compose exec api alembic upgrade head

echo "=== Deploy tamamlandi: $(date) ==="
docker compose ps
