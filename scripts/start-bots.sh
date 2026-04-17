#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$ROOT_DIR/temp"
mkdir -p "$TEMP_DIR"

find_running_pid() {
  local script_path="$1"
  pgrep -f "$script_path" | head -n1 || true
}

start_one() {
  local name="$1"
  local script_rel="$2"
  local pid_file="$TEMP_DIR/${name}.pid"
  local log_file="$TEMP_DIR/${name}.out.log"
  local script_path="$ROOT_DIR/$script_rel"

  if [[ -f "$pid_file" ]]; then
    local existing_pid
    existing_pid="$(tr -d '[:space:]' < "$pid_file" || true)"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
      echo "[$name] already running (pid=$existing_pid)"
      echo "[$name] log: $log_file"
      return 0
    fi
    rm -f "$pid_file"
  fi

  local adopted_pid
  adopted_pid="$(find_running_pid "$script_path")"
  if [[ -n "$adopted_pid" ]] && kill -0 "$adopted_pid" 2>/dev/null; then
    echo "$adopted_pid" > "$pid_file"
    echo "[$name] already running (adopted pid=$adopted_pid)"
    echo "[$name] log: $log_file"
    return 0
  fi

  echo "[$name] starting..."
  if [[ "$name" == "tgapp" ]]; then
    env GA_TG_LOG="$log_file" nohup uv run python "$script_path" >>"$log_file" 2>&1 < /dev/null &
  elif [[ "$name" == "wechatapp" ]]; then
    env GA_WECHAT_LOG="$log_file" nohup uv run python "$script_path" >>"$log_file" 2>&1 < /dev/null &
  else
    nohup uv run python "$script_path" >>"$log_file" 2>&1 < /dev/null &
  fi

  local new_pid=$!
  echo "$new_pid" > "$pid_file"
  sleep 1
  if kill -0 "$new_pid" 2>/dev/null; then
    echo "[$name] started (pid=$new_pid)"
    echo "[$name] log: $log_file"
  else
    rm -f "$pid_file"
    echo "[$name] failed to stay running; check log: $log_file" >&2
    return 1
  fi
}

cd "$ROOT_DIR"
start_one "wechatapp" "frontends/wechatapp.py"
start_one "tgapp" "frontends/tgapp.py"
