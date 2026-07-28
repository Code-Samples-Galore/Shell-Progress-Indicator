#!/usr/bin/env bash
#
# Spinner for shell scripts.
#
#   <background job> &
#   spinner $! "message"
#
# Returns the background job's exit code, so it can be tested by the caller.
#
# Environment:
#   SPINNER_DELAY  seconds between spinner frames (default 0.1)

spinner() {
  local pid=$1         # PID of the background job
  local message="$2"   # message to display
  local delay="${SPINNER_DELAY:-0.1}"
  local spin='|/-\'
  local i=0
  local cr="" clear_eol=""

  # Overwriting the line in place only works on a terminal. Piped to a file or
  # a CI log, every frame would be appended instead, burying the real output in
  # hundreds of spinner characters. There we stay quiet and just report the
  # result, which also saves a `sleep` fork per frame.
  if [ -t 1 ]; then
    cr=$'\r'
    clear_eol=$'\033[K'

    while kill -0 "$pid" 2>/dev/null; do
      printf "%s[%c] %s%s" "$cr" "${spin:i++%${#spin}:1}" "$message" "$clear_eol"
      sleep "$delay"
    done
  fi

  wait "$pid"
  local exit_code=$?

  if [ "$exit_code" -eq 0 ]; then
    printf "%s[✔] %s%s\n" "$cr" "$message" "$clear_eol"
  else
    printf "%s[✖] %s (failed)%s\n" "$cr" "$message" "$clear_eol"
  fi

  return "$exit_code"
}

# Only run the demo when executed directly, so the file can be sourced for the
# `spinner` function alone.
if [ "${BASH_SOURCE[0]:-}" = "$0" ]; then
  exit_ok() {
    sleep 2
    exit 0
  }

  exit_error() {
    sleep 2
    exit 1
  }

  exit_ok &
  spinner "$!" "Calling function returning 0"

  exit_error &
  spinner "$!" "Calling function returning 1"

  # The demo deliberately runs a job that fails, so a non-zero exit here would
  # be misleading.
  exit 0
fi
