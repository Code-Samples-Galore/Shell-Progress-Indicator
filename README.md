# ⏳ Shell Progress Indicators

This repository contains examples of progress indicators for shell scripts, including a **spinner** and a **progress bar**. These tools are useful for visualizing the progress of long-running tasks.

## 📜 Features
- 🌀 **Spinner**: Displays a rotating spinner while a background task is running.
- 📊 **Progress Bar**: Shows a progress bar that updates as tasks complete.
- ✅ Both scripts run on macOS and Linux. `progress_bar.sh` is POSIX `sh` (dash, bash, zsh); `spinner.sh` requires bash.
- 🪵 Both detect whether stdout is a terminal and stay quiet in pipes and log files instead of filling them with redraw frames.

## 🚀 Usage

### 🌀 Spinner
The `spinner.sh` script runs a spinner while a background task executes.

```bash
./spinner.sh
```

Example output:
```
[✔] Calling function returning 0
[✖] Calling function returning 1 (failed)
```

Use it in your own script by sourcing the file and passing a background job's PID:

```bash
. ./spinner.sh

long_running_task &
spinner "$!" "Doing the thing"   # returns the job's exit code
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `SPINNER_DELAY` | `0.1` | Seconds between spinner frames |

### 📊 Progress Bar
The `progress_bar.sh` script supports running multiple commands with progress tracking.

```bash
./progress_bar.sh
```

Example output:
```
=== Continue on failure ===
[##################################################] 100% (4/4)

All tasks complete. 3 succeeded, 1 failed.

=== Stop on failure ===
[#####################################             ]  75% (3/4)
Stopping early due to failure: abc C

Stopped early after 3 of 4 tasks. 2 succeeded, 1 failed.
```

On a terminal the bar is redrawn in place after each command; the block above shows the final state of each run. The failing command is counted as attempted, which is why the stop-on-failure run ends at `(3/4)`.

Use the functions in your own script:

```sh
PROGRESS_BAR_DEMO=0 . ./progress_bar.sh

run_commands_with_progress "make build" "make test"        # returns non-zero if any failed
run_commands_with_progress --stop-on-failure "a" "b" "c"   # stop at the first failure

progress_bar_draw 3 10        # draw a single bar: 3 of 10, default width 50
progress_bar_draw 3 10 20     # ...with an explicit width
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `PROGRESS_BAR_STEP_DELAY` | `0` | Seconds to pause between commands. The demo sets `0.2` so the bar is visible. |
| `PROGRESS_BAR_DEMO` | `1` | Set to `0` to source the file for its functions without running the demo. |

Each command is run with `sh -c` and its output is discarded, so only success or failure is reported.

## 📄 License

MIT License
