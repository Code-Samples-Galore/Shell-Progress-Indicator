# ⏳ Shell Progress Indicators

This repository contains examples of progress indicators for shell scripts, including a **spinner** and a **progress bar**. These tools are useful for visualizing the progress of long-running tasks in Bash or Zsh.

## 📜 Features
- 🌀 **Spinner**: Displays a rotating spinner while a background task is running.
- 📊 **Progress Bar**: Shows a progress bar that updates as tasks complete.
- ✅ Compatible with Bash and Zsh on macOS and Linux.

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

### 📊 Progress Bar
The `progress_bar.sh` script supports running multiple commands with progress tracking.

```bash
./progress_bar.sh
```

Example output:
```
=== Continue on failure ===
[##########################] 100% (4/4)

All tasks complete. 3 succeeded, 1 failed.

=== Stop on failure ===
[########                  ] 50% (2/4)
Stopping early due to failure: abc C
```

## 📄 License

MIT License
