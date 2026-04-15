#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$ROOT_DIR/temp"

status_one() {
  local name="$1"
  local pid_file="$TEMP_DIR/${name}.pid"
  local log_file="$TEMP_DIR/${name}.out.log"

  if [[ ! -f "$pid_file" ]]; then
    echo "[$name] STOPPED | pid: - | log: $log_file"
    return 0
  fi

  local pid
  pid="$(tr -d '[:space:]' < "$pid_file" || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "[$name] RUNNING | pid: $pid | log: $log_file"
  else
    echo "[$name] STOPPED(stale pid) | pid: ${pid:-?} | log: $log_file"
  fi
}

status_one "wechatapp"
status_one "tgapp"
