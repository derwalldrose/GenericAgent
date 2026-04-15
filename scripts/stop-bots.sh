#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$ROOT_DIR/temp"

stop_one() {
  local name="$1"
  local pid_file="$TEMP_DIR/${name}.pid"

  if [[ ! -f "$pid_file" ]]; then
    echo "[$name] not running (no pid file)"
    return 0
  fi

  local pid
  pid="$(tr -d '[:space:]' < "$pid_file" || true)"
  if [[ -z "$pid" ]]; then
    rm -f "$pid_file"
    echo "[$name] stale pid file removed"
    return 0
  fi

  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$pid_file"
    echo "[$name] not running (stale pid $pid removed)"
    return 0
  fi

  echo "[$name] stopping pid=$pid"
  kill "$pid" 2>/dev/null || true
  for _ in $(seq 1 20); do
    if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$pid_file"
      echo "[$name] stopped"
      return 0
    fi
    sleep 1
  done

  echo "[$name] still alive after grace period, sending SIGKILL"
  kill -9 "$pid" 2>/dev/null || true
  rm -f "$pid_file"
}

stop_one "wechatapp"
stop_one "tgapp"
