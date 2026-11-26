# mac-storage-cleanup

A Claude skill that acts as your Mac storage manager. It scans the whole disk, explains what can be safely deleted and why, suggests what to move to an external drive, and only deletes what you approve. Files go to the Trash first.

## Install

**Claude Code:** copy the `mac-storage-cleanup` folder into `~/.claude/skills/`.

**Claude app:** download `mac-storage-cleanup` as a zip and upload it under Settings → Capabilities → Skills.

## Use

Ask something like "my Mac is full, free up 30 GB" or run `/mac-storage-cleanup`.

You get a report in four groups:
- **A:** safe to delete
- **B:** your call
- **C:** move to an external drive
- **Leave alone**

Nothing is deleted until you say which groups to run.

`scripts/scan.sh` is read-only and can be run on its own: `bash mac-storage-cleanup/scripts/scan.sh`.
