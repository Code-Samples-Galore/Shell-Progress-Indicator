#!/usr/bin/env sh
#
# Progress bar helpers for shell scripts.
#
#   progress_bar_draw <current> <total> [width]
#   run_commands_with_progress [--stop-on-failure] <command>...
#
# Everything here is POSIX sh, so it runs under dash, bash and zsh alike.
#
# Environment:
#   PROGRESS_BAR_STEP_DELAY  seconds to pause between commands (default 0)
#   PROGRESS_BAR_DEMO        set to 0 to source this file without running the
#                            demo at the bottom

# Redraw the progress bar in place on the current line.
#
# Internal variables are prefixed with _pb_ because POSIX sh has no `local`:
# plain names like `current` and `total` would overwrite same-named variables
# in whatever function called us.
progress_bar_draw() {
  _pb_current=$1
  _pb_total=$2
  _pb_width=${3:-50}

  # Guard the divisions below; an empty work set has no bar to draw anyway.
  [ "$_pb_total" -gt 0 ] || return 1

  _pb_percent=$((_pb_current * 100 / _pb_total))
  # Derive the fill from current/total rather than from _pb_percent. Going via
  # the rounded percentage truncates twice and can leave the bar a cell short
  # of what the percentage claims (1/6 at width 60 drew 9 cells, not 10).
  _pb_filled=$((_pb_current * _pb_width / _pb_total))

  # Assembled with string appends instead of `printf ... | tr`, which forked a
  # subshell and a `tr` on every single redraw.
  _pb_bar=
  _pb_gap=
  _pb_i=0
  while [ "$_pb_i" -lt "$_pb_filled" ]; do
    _pb_bar="$_pb_bar#"
    _pb_i=$((_pb_i + 1))
  done
  while [ "$_pb_i" -lt "$_pb_width" ]; do
    _pb_gap="$_pb_gap "
    _pb_i=$((_pb_i + 1))
  done

  printf "\r[%s%s] %3d%% (%d/%d)" \
    "$_pb_bar" "$_pb_gap" "$_pb_percent" "$_pb_current" "$_pb_total"
}

# Run each argument as a shell command, drawing a progress bar as they finish.
# Returns non-zero if any command failed.
run_commands_with_progress() {
  _pb_stop=0
  if [ "${1:-}" = "--stop-on-failure" ]; then
    _pb_stop=1
    shift
  fi

  _pb_run_total=$#
  _pb_run_current=0
  _pb_run_failed=0
  _pb_stopped_early=0

  if [ "$_pb_run_total" -eq 0 ]; then
    printf "No commands to run.\n"
    return 0
  fi

  # Redrawing in place only works on a terminal. Piped to a file each redraw
  # would be appended instead of overwriting, so there we draw the final bar
  # once and leave the log readable.
  if [ -t 1 ]; then
    _pb_tty=1
  else
    _pb_tty=0
  fi

  for _pb_cmd in "$@"; do
    if ! sh -c "$_pb_cmd" >/dev/null 2>&1; then
      _pb_run_failed=$((_pb_run_failed + 1))
      [ "$_pb_stop" -eq 1 ] && _pb_stopped_early=1
    fi
    _pb_run_current=$((_pb_run_current + 1))

    if [ "$_pb_tty" -eq 1 ] || [ "$_pb_stopped_early" -eq 1 ] ||
      [ "$_pb_run_current" -eq "$_pb_run_total" ]; then
      progress_bar_draw "$_pb_run_current" "$_pb_run_total"
    fi

    if [ "$_pb_stopped_early" -eq 1 ]; then
      # Pass the command as an argument, not as the format string: one
      # containing % or \ would otherwise be mangled by printf.
      printf "\nStopping early due to failure: %s\n" "$_pb_cmd"
      break
    fi

    # Pacing is opt-in. A fixed sleep here used to add 0.2s per command to
    # every caller, purely so the demo below looked animated.
    if [ "${PROGRESS_BAR_STEP_DELAY:-0}" != "0" ]; then
      sleep "$PROGRESS_BAR_STEP_DELAY" 2>/dev/null || :
    fi
  done

  if [ "$_pb_stopped_early" -eq 1 ]; then
    printf "\nStopped early after %d of %d tasks. %d succeeded, %d failed.\n" \
      "$_pb_run_current" "$_pb_run_total" \
      "$((_pb_run_current - _pb_run_failed))" "$_pb_run_failed"
  else
    printf "\n\nAll tasks complete. %d succeeded, %d failed.\n" \
      "$((_pb_run_current - _pb_run_failed))" "$_pb_run_failed"
  fi

  [ "$_pb_run_failed" -eq 0 ]
}

if [ "${PROGRESS_BAR_DEMO:-1}" = "1" ]; then
  # Positional parameters rather than `commands=(...)`: arrays are a bash/zsh
  # extension, and using one under this `sh` shebang made the whole script die
  # with a syntax error on any system where /bin/sh is dash.
  set -- "echo A" "echo B" "abc C" "echo D"

  PROGRESS_BAR_STEP_DELAY=0.2

  printf "=== Continue on failure ===\n"
  run_commands_with_progress "$@"

  printf "\n=== Stop on failure ===\n"
  run_commands_with_progress --stop-on-failure "$@"

  # The demo deliberately runs a command that fails, so a non-zero exit here
  # would be misleading.
  exit 0
fi
