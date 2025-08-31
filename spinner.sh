#!/usr/bin/env bash

spinner() {
  local pid=$1         # PID of the background job
  local message="$2"   # message to display
  local delay=0.1
  local spin='|/-\'
  local i=0

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r[%c] %s" "${spin:i++%${#spin}:1}" "$message"
    sleep $delay
  done

  # when finished
  wait $pid
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    printf "\r[✔] %s\n" "$message"
  else
    printf "\r[✖] %s (failed)\n" "$message"
  fi

  return $exit_code
}

exit_ok() {
  sleep 2
  exit 0
}

exit_error() {
  sleep 2
  exit 1
}

exit_ok &
spinner $! "Calling function returning 0"

exit_error &
spinner $! "Calling function returning 1"
