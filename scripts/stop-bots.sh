#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$ROOT_DIR/temp"

service_pattern() {
  local name="$1"
  case "$name" in
    streamlit)
      printf '%s' 'streamlit run .*frontends/stapp\.py.*--server\.port(=| )18631.*--server\.address(=| )0\.0\.0\.0'
      ;;
    wechatapp)
      printf '%s' "$ROOT_DIR/frontends/wechatapp.py"
      ;;
    tgapp)
      printf '%s' "$ROOT_DIR/frontends/tgapp.py"
      ;;
    *)
      echo "unknown service: $name" >&2
      return 1
      ;;
  esac
}

find_running_pid() {
  local name="$1"
  local pattern
  pattern="$(service_pattern "$name")"
  pgrep -f -- "$pattern" | head -n1 || true
}

stop_one() {
  local name="$1"
  local pid_file="$TEMP_DIR/${name}.pid"
  local pattern running_pid

  pattern="$(service_pattern "$name")"
  running_pid="$(find_running_pid "$name")"

  if [[ -z "$running_pid" ]]; then
    rm -f "$pid_file"
    echo "[$name] not running"
    return 0
  fi

  echo "[$name] stopping pid=$running_pid"
  pkill -TERM -f -- "$pattern" 2>/dev/null || true

  for _ in $(seq 1 20); do
    if [[ -z "$(find_running_pid "$name")" ]]; then
      rm -f "$pid_file"
      echo "[$name] stopped"
      return 0
    fi
    sleep 1
  done

  echo "[$name] still alive after grace period, sending SIGKILL"
  pkill -KILL -f -- "$pattern" 2>/dev/null || true
  rm -f "$pid_file"
}

stop_one "streamlit"
stop_one "wechatapp"
stop_one "tgapp"
