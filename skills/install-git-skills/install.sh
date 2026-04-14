#!/bin/bash

# Parse arguments
REPO=""
PATH_IN_REPO=""
NAME=""
ALLOW_RAW=""
DENY_RAW=""
GLOBAL=0

for ARG in "$@"; do
    case "$ARG" in
        --global)    GLOBAL=1 ;;
        --path=*)    PATH_IN_REPO="${ARG#--path=}" ;;
        --name=*)    NAME="${ARG#--name=}" ;;
        --allow=*)   ALLOW_RAW="${ARG#--allow=}" ;;
        --deny=*)    DENY_RAW="${ARG#--deny=}" ;;
        -*)          echo "Unknown option: $ARG"; exit 1 ;;
        *)           REPO="$ARG" ;;
    esac
done

if [ -z "$REPO" ]; then
    echo "Error: repo is required"
    echo "Usage: install.sh <owner/repo or URL> [--path=...] [--name=...] [--allow=...] [--deny=...] [--global]"
    exit 1
fi

if [ -n "$ALLOW_RAW" ] && [ -n "$DENY_RAW" ]; then
    echo "Error: --allow and --deny cannot both be set"
    exit 1
fi

# Derive name from repo if not provided
if [ -z "$NAME" ]; then
    # Strip protocol, trailing slashes and .git, take last two path segments as owner-repo
    CLEAN="${REPO%/}"
    CLEAN="${CLEAN%.git}"
    CLEAN="${CLEAN#*://}"   # remove https:// or similar
    CLEAN="${CLEAN#git@*:}" # remove git@host: prefix
    REPO_PART="${CLEAN##*/}"
    OWNER_PART="${CLEAN%/*}"
    OWNER_PART="${OWNER_PART##*/}"
    NAME="$OWNER_PART-$REPO_PART"
fi

# Default path to repo root
if [ -z "$PATH_IN_REPO" ]; then
    PATH_IN_REPO="."
fi

# Determine skills directory
if [ $GLOBAL -eq 1 ]; then
    SKILLS_DIR="$HOME/.claude/skills"
else
    SKILLS_DIR="$(pwd)/.claude/skills"
fi

META_FILE="$SKILLS_DIR/.$NAME.gs-meta"

if [ -f "$META_FILE" ]; then
    echo "Error: $META_FILE already exists — use update-git-skills to update it"
    exit 1
fi

# Write metadata file
{
    echo "repo=$REPO"
    echo "path=$PATH_IN_REPO"
    [ -n "$ALLOW_RAW" ] && echo "allow=$ALLOW_RAW"
    [ -n "$DENY_RAW" ]  && echo "deny=$DENY_RAW"
    echo "sha="
} > "$META_FILE"

echo "Created $META_FILE"

# Run updater for this source only
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$(dirname "$SCRIPT_DIR")/update-git-skills/update.sh"

if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "Error: update-git-skills/update.sh not found — run update-git-skills manually"
    exit 1
fi

EXTRA_ARGS=""
[ $GLOBAL -eq 1 ] && EXTRA_ARGS="--global"

bash "$UPDATE_SCRIPT" $EXTRA_ARGS --only="$NAME"
