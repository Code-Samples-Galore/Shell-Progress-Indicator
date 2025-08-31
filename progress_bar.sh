#!/usr/bin/env sh

progress_bar_draw() {
  current=$1
  total=$2
  width=${3:-50}  # default width 50

  percent=$((current * 100 / total))
  done=$((percent * width / 100))
  todo=$((width - done))

  bar=$(printf "%${done}s" | tr ' ' '#')
  spaces=$(printf "%${todo}s")
  printf "\r[%s%s] %3d%% (%d/%d)" "$bar" "$spaces" "$percent" "$current" "$total"
}

run_commands_with_progress() {
  stop_on_failure=0

  # Parse options
  if [ "$1" = "--stop-on-failure" ]; then
    stop_on_failure=1
    shift
  fi

  total=$#
  current=0
  failed=0

  for cmd in "$@"; do
    if sh -c "$cmd" >/dev/null 2>&1; then
      :
    else
      failed=$((failed + 1))
      if [ "$stop_on_failure" -eq 1 ]; then
        current=$((current + 1))
        progress_bar_draw "$current" "$total"
        printf "\nStopping early due to failure: $cmd"
        break
      fi
    fi
    current=$((current + 1))
    progress_bar_draw "$current" "$total"
    sleep 0.2
  done

  printf "\n\nAll tasks complete. $((current - failed)) succeeded, $failed failed.\n"
}

commands=(
  "echo A"
  "echo B"
  "abc C"
  "echo D"
)

printf "=== Continue on failure ===\n"
run_commands_with_progress "${commands[@]}"

printf "\n=== Stop on failure ===\n"
run_commands_with_progress --stop-on-failure "${commands[@]}"
