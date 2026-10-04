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

`script -qec '<cmd>' /dev/null` is the Linux (util-linux) form. On macOS the same pty run is `script -q /dev/null <cmd>`, e.g. `script -q /dev/null ./progress_bar.sh`.

`progress_bar.sh` must keep working under dash, which is `/bin/sh` on Debian/Ubuntu, and both scripts must work under zsh. Check explicitly — bash accepts plenty that dash and zsh reject:

```sh
for sh in dash bash zsh; do "$sh" ./progress_bar.sh; done
for sh in bash zsh; do "$sh" ./spinner.sh; done
```

Also check the **sourced** path, since the demo guards and the shebang are bypassed there:

```sh
zsh -c 'PROGRESS_BAR_DEMO=0 . ./progress_bar.sh; progress_bar_draw 1 6 60'
zsh -c '. ./spinner.sh; sleep 1 & spinner "$!" test'
```

Note that a non-TTY spinner run **skips the animation loop entirely**, so piping it does not exercise the frame code at all. A zsh parse error there survived a full round of piped testing. Frame rendering must be checked through a pty:

```sh
script -qec 'zsh ./spinner.sh' /dev/null | tr '\r' '\n' | grep -oE '^\[[|/\\-]\]' | sort -u
```

If `dash`, `zsh` or `shellcheck` is missing on the machine, install it (`apt-get install -y zsh`, `brew install shellcheck`) rather than skipping that shell.

## Shell compatibility contract

This is the constraint most likely to be violated, and it has already caused one total breakage.

- **`progress_bar.sh` is POSIX `sh`.** No arrays, no `local`, no `[[ ]]`, no `$'...'`. The demo passes commands via `set -- "cmd1" "cmd2"` and `"$@"` specifically because a bash `commands=(...)` array under the `#!/usr/bin/env sh` shebang made the entire script die with `Syntax error: "(" unexpected` on any dash system.
- **`spinner.sh` is bash** (`#!/usr/bin/env bash`) but must also parse under zsh, since it is meant to be sourceable from a zsh shell. `local` and `$'...'` are fine in both. Substring offsets are **not**: write `${var:$((expr)):1}`, never `${var:expr:1}`. Bare `${spin:i++%${#spin}:1}` makes zsh read `:i` as a history modifier and abort with ``unrecognized modifier `i'``.

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

- `spinner.sh` detects execution-vs-sourcing automatically, so sourcing is silent with no extra setup. It needs two checks: bash exposes `BASH_SOURCE`, while zsh has no such variable and reports sourcing through `ZSH_EVAL_CONTEXT` (`toplevel` when executed, containing `:file` when sourced). With only the `BASH_SOURCE` check, `zsh ./spinner.sh` ran and printed nothing at all.
- `progress_bar.sh` cannot use either mechanism while staying POSIX, so callers must source it as `PROGRESS_BAR_DEMO=0 . ./progress_bar.sh`.

## README

`README.md` embeds literal program output. It previously drifted from reality — it showed a 26-cell bar for a 50-cell default and claimed the stop-on-failure run ended at `(2/4)` when the code prints `(3/4)`. When you change any output text, bar width, or counting behaviour, regenerate the blocks from a real run rather than editing them by hand, and re-run the usage snippets to confirm they still work.
