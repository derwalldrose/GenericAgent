#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[restart] stopping bots..."
bash "$ROOT_DIR/scripts/stop-bots.sh"

echo "[restart] starting bots..."
bash "$ROOT_DIR/scripts/start-bots.sh"

echo "[restart] current status:"
bash "$ROOT_DIR/scripts/status-bots.sh"
