#!/usr/bin/env bash
set -euo pipefail

unset DOCKER_HOST
unset DOCKER_CONTEXT

CONTEXT="${1:-office}"
COMPOSE_FILE="${2:-docker-compose.yml}"
OUT_DIR="${3:-dist}"
BUNDLE="${4:-monitoring-images}"

REMOTE_SSH="${REMOTE_SSH:-takeitadmin@172.17.56.221}"
REMOTE_DIR="${REMOTE_DIR:-/opt/monitoring}"
REMOTE_NET="${REMOTE_NET:-monitor_net}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p "$OUT_DIR"

echo "== Build & Up local =="
docker compose -f "$COMPOSE_FILE" up -d --build --pull=never

echo "== Resolve images from compose =="
mapfile -t IMAGES < <(docker compose -f "$COMPOSE_FILE" config --images | awk 'NF' | sort -u)

printf "Images:\n"
printf " - %s\n" "${IMAGES[@]}"

TAR_PATH="$OUT_DIR/$BUNDLE.tar"
ZIP_PATH="$OUT_DIR/$BUNDLE.zip"

echo "== Save images -> $TAR_PATH =="
docker save -o "$TAR_PATH" "${IMAGES[@]}"

echo "== Zip bundle -> $ZIP_PATH =="
command -v zip >/dev/null 2>&1 && zip -j -9 "$ZIP_PATH" "$TAR_PATH" || true

echo "== Upload tar to server and load there =="
scp "$TAR_PATH" "$REMOTE_SSH:/tmp/$BUNDLE.tar"
ssh "$REMOTE_SSH" "docker load -i /tmp/$BUNDLE.tar"

echo "== Deploy compose to server =="
ssh "$REMOTE_SSH" "mkdir -p '$REMOTE_DIR'"
scp "$COMPOSE_FILE" "$REMOTE_SSH:$REMOTE_DIR/docker-compose.yml"

echo "== Ensure external network exists on server =="
ssh "$REMOTE_SSH" "docker network inspect '$REMOTE_NET' >/dev/null 2>&1 || docker network create '$REMOTE_NET'"

echo "== Up stack on server =="
ssh "$REMOTE_SSH" "cd '$REMOTE_DIR' && docker compose up -d"

echo "== Show status on server =="
ssh "$REMOTE_SSH" "cd '$REMOTE_DIR' && docker compose ps"

echo "DONE: deployed to $REMOTE_SSH:$REMOTE_DIR"
