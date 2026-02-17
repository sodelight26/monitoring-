#!/usr/bin/env bash
set -euo pipefail

# --- Prevent env overrides that break contexts ---
unset DOCKER_HOST
unset DOCKER_CONTEXT

CONTEXT="${1:-office}"
COMPOSE_FILE="${2:-docker-compose.yml}"
OUT_DIR="${3:-dist}"
BUNDLE="${4:-monitoring-images}"

# Remote server (office)
REMOTE_SSH="${REMOTE_SSH:-takeitadmin@172.17.56.221}"
REMOTE_DIR="${REMOTE_DIR:-/opt/monitoring}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p "$OUT_DIR"

echo "== Build & Up local =="
docker compose -f "$COMPOSE_FILE" up -d --build

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

echo "== Check remote context '$CONTEXT' (optional) =="
if docker context inspect "$CONTEXT" >/dev/null 2>&1; then
  docker --context "$CONTEXT" info >/dev/null || true
else
  echo "WARN: Docker context '$CONTEXT' not found in this WSL environment."
  echo "      You can create it with:"
  echo "      docker context create $CONTEXT --docker \"host=ssh://$REMOTE_SSH\""
fi

echo "== Upload tar to server and load there (reliable) =="
scp "$TAR_PATH" "$REMOTE_SSH:/tmp/$BUNDLE.tar"
ssh "$REMOTE_SSH" "docker load -i /tmp/$BUNDLE.tar"

echo "== OPTIONAL: Deploy compose+configs on server and start stack =="
# Uncomment if you want auto deploy/run on server:
# ssh "$REMOTE_SSH" "mkdir -p '$REMOTE_DIR'"
# scp -r "$COMPOSE_FILE" configs "$REMOTE_SSH:$REMOTE_DIR/"
# ssh "$REMOTE_SSH" "cd '$REMOTE_DIR' && docker compose up -d && docker compose ps"

echo "DONE: $TAR_PATH"
