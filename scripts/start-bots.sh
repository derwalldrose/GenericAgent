#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$ROOT_DIR/temp"
mkdir -p "$TEMP_DIR"

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

pid_matches_service() {
  local name="$1"
  local pid="$2"
  local pattern
  local args

  pattern="$(service_pattern "$name")"
  args="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  [[ -n "$args" ]] && grep -Eq -- "$pattern" <<<"$args"
}

start_one() {
  local name="$1"
  local pid_file="$TEMP_DIR/${name}.pid"
  local log_file="$TEMP_DIR/${name}.out.log"
  local new_pid adopted_pid tracked_pid

  if [[ -f "$pid_file" ]]; then
    tracked_pid="$(tr -d '[:space:]' < "$pid_file" || true)"
    if [[ -n "$tracked_pid" ]] && kill -0 "$tracked_pid" 2>/dev/null && pid_matches_service "$name" "$tracked_pid"; then
      echo "[$name] already running (pid=$tracked_pid)"
      echo "[$name] log: $log_file"
      return 0
    fi
    rm -f "$pid_file"
  fi

  adopted_pid="$(find_running_pid "$name")"
  if [[ -n "$adopted_pid" ]] && kill -0 "$adopted_pid" 2>/dev/null; then
    echo "$adopted_pid" > "$pid_file"
    echo "[$name] already running (adopted pid=$adopted_pid)"
    echo "[$name] log: $log_file"
    return 0
  fi

  echo "[$name] starting..."
  case "$name" in
    streamlit)
      nohup env STREAMLIT_BROWSER_GATHER_USAGE_STATS=false \
        uv run streamlit run "$ROOT_DIR/frontends/stapp.py" \
        --server.port 18631 \
        --server.address 0.0.0.0 \
        --server.headless true \
        >>"$log_file" 2>&1 < /dev/null &
      ;;
    tgapp)
      env GA_TG_LOG="$log_file" nohup uv run python "$ROOT_DIR/frontends/tgapp.py" >>"$log_file" 2>&1 < /dev/null &
      ;;
    wechatapp)
      env GA_WECHAT_LOG="$log_file" nohup uv run python "$ROOT_DIR/frontends/wechatapp.py" >>"$log_file" 2>&1 < /dev/null &
      ;;
    *)
      echo "unknown service: $name" >&2
      return 1
      ;;
  esac

  new_pid=$!
  sleep 2

  adopted_pid="$(find_running_pid "$name")"
  if [[ -n "$adopted_pid" ]] && kill -0 "$adopted_pid" 2>/dev/null; then
    echo "$adopted_pid" > "$pid_file"
    echo "[$name] started (pid=$adopted_pid)"
    echo "[$name] log: $log_file"
    return 0
  fi

  if kill -0 "$new_pid" 2>/dev/null; then
    echo "$new_pid" > "$pid_file"
    echo "[$name] started (pid=$new_pid)"
    echo "[$name] log: $log_file"
    return 0
  fi

  rm -f "$pid_file"
  echo "[$name] failed to stay running; check log: $log_file" >&2
  return 1
}

cd "$ROOT_DIR"
start_one "streamlit"
start_one "wechatapp"
start_one "tgapp"
