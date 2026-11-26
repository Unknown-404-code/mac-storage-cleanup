#!/bin/bash
# Read-only disk usage scan for macOS. Deletes nothing.
top() { du -sh "$@" 2>/dev/null | sort -rh | head -"${N:-15}"; }
h() { echo; echo "== $1 =="; }

h "Free space";            df -h /System/Volumes/Data | tail -1
h "Home";                  top ~/* ~/.[!.]*
h "Library";               top ~/Library/*
h "Library deep";     N=25 top ~/Library/Application\ Support/* ~/Library/Caches/* ~/Library/Containers/* ~/Library/Group\ Containers/*
h "Applications";          top /Applications/*
h "System (var/run is mounted images, ignore)"; top /Library/* /opt/* /usr/local/* /private/var/* /Users/Shared
h "Developer";             top /Library/Developer/*/* ~/Library/Developer/*/*
h "Simulator runtimes";    xcrun simctl runtime list 2>/dev/null | grep -E "\(|Total"
h "Temp folders (user)";   top /private/var/folders/*/*/*/*
h "Dev caches";            top ~/.cache/* ~/.gradle/* ~/.nuget/* ~/.npm ~/.m2 ~/Library/Arduino15/* "$(brew --cache 2>/dev/null)"
h "Dependency/build folders >50MB (outside Library)"
find ~ -xdev -path ~/Library -prune -o \( -name node_modules -o -name venv -o -name .venv -o -name build -o -name target -o -name DerivedData \) -type d -prune -print 2>/dev/null \
  | while read -r d; do du -sm "$d" 2>/dev/null; done | awk '$1>50' | sort -rn | head -25
h "Duplicate VS Code extension versions"
ls ~/.vscode/extensions 2>/dev/null | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+.*//' | sort | uniq -c | awk '$1>1'
h "Single files >300MB on disk (excludes offloaded iCloud)"
find ~ -xdev -type f -size +300M -not -path "*/Library/Developer/*" -not -path "*/Mobile Documents/*" 2>/dev/null \
  | while read -r f; do du -sh "$f"; done | sort -rh | head -25
h "Local snapshots";       tmutil listlocalsnapshots / 2>/dev/null
