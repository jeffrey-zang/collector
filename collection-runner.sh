#!/bin/bash

LOG_FILE="/var/logs/collection-script.log"

echo "Starting supervisor, find logs in /var/logs/collection-script.log"

# redirect supervisor stdout/stderr
exec >>"$LOG_FILE" 2>&1

echo "=== Supervisor started at $(date) ==="

get_remote_version() {
  curl -f https://api.github.com/repos/jeffrey-zang/collection-script/releases/latest \
    | grep '"tag_name":' | cut -d '"' -f 4
}

get_latest_installed_version() {
  ls -1 /usr/local/bin/collection-script-* 2>/dev/null \
    | sed 's|.*/collection-script-||' \
    | sort -V \
    | tail -n 1
}

download_version() {
  ver="$1"
  echo "Downloading version $ver..."
  curl -fL \
    -o "/usr/local/bin/collection-script-$ver" \
    "https://github.com/jeffrey-zang/collection-script/releases/latest/download/collection-script-$ver"
  chmod +x "/usr/local/bin/collection-script-$ver"
}

run_child() {
  ver="$1"
  bin="/usr/local/bin/collection-script-$ver"
  
  # start child, discard its stdout/stderr
  "$bin" >/dev/null 2>&1 &
  echo $!
}

child_pid=""
running_version=""

while true; do
  echo "Checking for updates at $(date)..." 
  echo "Child PID: $child_pid"

  if [ -z "$running_version" ]; then
    running_version="$(get_latest_installed_version)"
  fi

  remote_version=$(get_remote_version)
  echo "Remote: $remote_version, Running: $running_version"

  if [ -z "$running_version" ] && [ -n "$remote_version" ]; then
    echo "No local version found, installing $remote_version"
    download_version "$remote_version"
    running_version="$remote_version"
  elif [ -n "$remote_version" ] && [ "$remote_version" != "$running_version" ]; then
    previous_version="$running_version"
    echo "Update detected: $previous_version -> $remote_version"
    download_version "$remote_version"

    if [ -n "$child_pid" ]; then
      echo "Stopping old child (PID $child_pid)..."
      kill "$child_pid" 2>/dev/null || true
      wait "$child_pid" 2>/dev/null || true
      echo "Old child exited"
      child_pid=""
    fi

    if [ -n "$previous_version" ] && [ "$previous_version" != "$remote_version" ]; then
      previous_bin="/usr/local/bin/collection-script-$previous_version"
      if [ -f "$previous_bin" ]; then
        echo "Removing old binary $previous_bin"
        rm -f "$previous_bin"
      fi
    fi

    running_version="$remote_version"
  fi

  if [ -z "$child_pid" ] || ! kill -0 "$child_pid" 2>/dev/null; then
    echo "Starting child $running_version..."
    child_pid=$(run_child "$running_version")
    echo "Child PID: $child_pid"
  fi

  sleep 10
done
