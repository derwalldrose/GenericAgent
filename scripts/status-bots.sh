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

status_one() {
  local name="$1"
  local pid_file="$TEMP_DIR/${name}.pid"
  local log_file="$TEMP_DIR/${name}.out.log"
  local pid

  pid="$(find_running_pid "$name")"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    echo "$pid" > "$pid_file"
    echo "[$name] RUNNING | pid: $pid | log: $log_file"
    return 0
  fi

  rm -f "$pid_file"
  echo "[$name] STOPPED | pid: - | log: $log_file"
}

status_one "streamlit"
status_one "wechatapp"
status_one "tgapp"
