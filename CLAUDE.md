# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Two standalone shell scripts demonstrating terminal progress indicators. There is no build system, package manager, test framework, or CI. Each script is dual-purpose: a reusable function library at the top, and a self-running demo at the bottom guarded so the file can be sourced without side effects.

## Commands

There is no test runner. Verification means executing the scripts and reading the output.

```sh
./progress_bar.sh      # runs both demos (continue-on-failure, then stop-on-failure)
./spinner.sh           # runs both demos (success, then failure); takes ~4s by design
```

Behaviour differs on a terminal versus a pipe, so exercise both paths when changing output:

```sh
./progress_bar.sh | cat                              # non-TTY path: final frame only
script -qec './progress_bar.sh' /dev/null            # TTY path: in-place redraws
script -qec './progress_bar.sh' /dev/null | tr '\r' '\n'   # make each redraw its own line
```

`progress_bar.sh` must keep working under dash, which is `/bin/sh` on Debian/Ubuntu. Check it explicitly — bash will happily accept code that dash rejects:

```sh
dash ./progress_bar.sh
bash ./progress_bar.sh
```

`shellcheck` is not installed here; install it before relying on it.

## Shell compatibility contract

This is the constraint most likely to be violated, and it has already caused one total breakage.

- **`progress_bar.sh` is POSIX `sh`.** No arrays, no `local`, no `[[ ]]`, no `$'...'`. The demo passes commands via `set -- "cmd1" "cmd2"` and `"$@"` specifically because a bash `commands=(...)` array under the `#!/usr/bin/env sh` shebang made the entire script die with `Syntax error: "(" unexpected` on any dash system.
- **`spinner.sh` is bash** (`#!/usr/bin/env bash`) and may use `local`, `BASH_SOURCE`, `$'...'` and bash substring arithmetic.

Because POSIX `sh` has no `local`, every internal variable in `progress_bar.sh` is prefixed `_pb_` to avoid clobbering the caller's variables. `progress_bar_draw` uses `_pb_*` and `run_commands_with_progress` uses `_pb_run_*`, so the nested call does not overwrite the loop state. Keep new variables prefixed and non-colliding.

## Conventions that encode past bugs

- **Never interpolate a variable into a `printf` format string.** Pass it as an argument with `%s`. Command strings are user data; `printf "...: $cmd"` rendered `echo 100%s%s%d` as `echo 1000`.
- **Derive the bar fill from `current/total`, not from the rounded percentage.** Going via percent truncates twice and under-fills the bar (1/6 at width 60 drew 9 cells instead of 10).
- **Guard divisions by `total`.** `progress_bar_draw` returns 1 when `total <= 0` rather than dividing by zero.
- **Gate in-place redraws on `[ -t 1 ]`.** Without it, `\r` frames accumulate in pipes and CI logs. Non-TTY output shows only the final state; the spinner skips its loop entirely and goes straight to `wait`, which also avoids a `sleep` fork per frame.
- **Build bar strings with shell appends, not `printf ... | tr`.** The pipeline forked twice per redraw; the fork-free loop measured ~12x faster over 500 redraws.
- **Library functions must not sleep.** Pacing is opt-in via `PROGRESS_BAR_STEP_DELAY` (default `0`); the demo sets `0.2` only so the animation is visible.
- **Demo sections end with `exit 0`.** Both demos intentionally run a failing task, so propagating that exit code would falsely signal a broken script.

## Sourcing guards

Their mechanisms differ because of the shell contract above:

- `spinner.sh` uses `[ "${BASH_SOURCE[0]:-}" = "$0" ]`, so sourcing is silent with no extra setup.
- `progress_bar.sh` cannot use `BASH_SOURCE`, so callers must source it as `PROGRESS_BAR_DEMO=0 . ./progress_bar.sh`.

## README

`README.md` embeds literal program output. It previously drifted from reality — it showed a 26-cell bar for a 50-cell default and claimed the stop-on-failure run ended at `(2/4)` when the code prints `(3/4)`. When you change any output text, bar width, or counting behaviour, regenerate the blocks from a real run rather than editing them by hand, and re-run the usage snippets to confirm they still work.
