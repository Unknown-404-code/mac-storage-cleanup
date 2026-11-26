---
name: mac-storage-cleanup
description: Act as the user's Mac storage manager. Scan the whole disk, find what can safely be deleted (and why), what can move to an external drive, then clean up only what the user approves. Use this whenever the user says their Mac/disk/storage is full, wants to free up X GB, asks "what's taking up space", "clean my storage", "what can I delete", "what can I move to my external drive", or mentions low disk space, even if they don't say "cleanup".
---

# Mac storage cleanup

The user wants space back without breaking their daily work. Your job has two phases with a hard stop between them: **scan and report**, then **act only on what they approve**. Deleting nothing before approval matters because a lot of what looks like junk (projects, app data, a VM bundle) is irreplaceable or breaks an app.

## Phase 1: Scan (read-only)

1. Run `bash <skill-dir>/scripts/scan.sh` (takes a few minutes; run with a long timeout). It prints free space, the largest folders in home/Library/Applications/system, and the usual dev-tool hotspots.
2. If the Claude app storage tools exist (`mcp__ccd_host__get_storage_usage`, `mcp__ccd_host__clean_up_worktrees`), call `get_storage_usage` too. It reports the app's own worktrees and caches. Only offer `clean_up_worktrees` if it shows idle worktrees.
3. Drill into anything big the script surfaces that you don't yet understand (`du -sh <dir>/* | sort -rh | head`). Find which app or project owns it before you call it deletable.

### Known hotspots (checked on a real cleanup; sizes are typical)

| Where | What it is | Verdict |
|---|---|---|
| `/private/var/folders/*/*/X/com.google.Chrome.code_sign_clone` | Chrome bug leaving copies of itself (6 GB seen) | Safe; only while Chrome is quit (`pgrep -x "Google Chrome"`) |
| `xcrun simctl runtime list` | iOS simulator runtimes, ~8 GB each | Ask; old iOS versions and duplicate beta builds are usually redundant. Delete with `xcrun simctl runtime delete <id>`, then `xcrun simctl delete unavailable` |
| `/Library/Developer/CoreSimulator/Caches` | Simulator dyld caches | Safe, rebuilt; root-owned (runtime delete often clears it) |
| `~/Library/Arduino15/staging` | Downloaded installer archives of already-installed boards | Safe |
| `venv`, `.venv`, `node_modules`, `build` in projects | Dependencies | Safe; tell user to `pip install` / `npm install` again |
| `~/Library/Caches/*`, `~/.cache/uv` (`uv cache clean`), `~/.gradle/caches`, `~/.nuget/packages`, `~/Library/Developer/Xcode/DerivedData` | Caches | Safe, re-downloaded |
| `~/.vscode/extensions` with two versions of one extension | Old versions | Safe to drop the older |
| Leftover installer `.zip`/`.tar.*`/`.dmg` (e.g. `*/Update/*.zip`) | Installers | Safe |
| Game launchers (Steam, Riot, Epic) data | Game data | Ask; user may still play |
| Old coursework, old dated output folders, `Movies` | User files | Move to external, never delete |

### Don't be fooled / don't touch

- `/private/var/run` shows tens of GB: mounted simulator disk images, already counted. Not real.
- iCloud Drive (`~/Library/Mobile Documents`): `ls` shows full file sizes for files that are offloaded. Trust `du`, not `ls`.
- `~/Library/Application Support/Claude/vm_bundles` (~11 GB): the Claude app's VM. Don't delete by hand; it can break the app. The same goes for any app's main data folder.
- Keychains, Mail, Photos libraries, Messages, anything in `~/Documents` that's a project with source code.
- `du ~/.Trash` fails with "Operation not permitted" (macOS privacy). That's normal.

## Report format

Lead with current free space and the goal. Then four groups, each a table of size / what / why it's safe / what it belongs to:

- **A: Safe to delete.** Caches and things that rebuild themselves.
- **B: Deletable if you don't need it.** The user decides (runtimes, games, apps).
- **C: Move to external drive.** Old personal files that aren't part of daily work.
- **Leave alone.** Big items that look deletable but aren't, with the reason.

End with the A+B total against the goal. Say plainly what you didn't check. Ask which groups to run, and let them carve out exceptions ("A and B but leave Riot").

## Phase 2: Act on approval only

- Record `df -h /System/Volumes/Data` before you start.
- Move files with macOS's built-in `trash -v <paths...>` (in `/usr/bin/trash`), not `rm`, so mistakes can be recovered. For tool-managed caches, use the tool's own command (`uv cache clean`, `xcrun simctl runtime delete`). Those deletions are permanent, so say so.
- Do only exactly what was approved. If something needs `sudo`, give the user the command instead of asking for a password.
- Trashed files still take up space. Measure `df` again, report the real freed amount, and say how much more is sitting in the Trash.
- Emptying the Trash is permanent, and it also wipes whatever was already in there (you can't list it). Ask first. On a yes: `osascript -e 'tell application "Finder" to empty trash'`, then measure again.
- Finish with what will rebuild itself and what the user may notice (slower first build, reinstalling dependencies, apps downloading their data again).
