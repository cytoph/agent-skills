#!/bin/bash

# Parse arguments
GLOBAL=0
ONLY_RAW=""

for ARG in "$@"; do
    case "$ARG" in
        --global) GLOBAL=1 ;;
        --only=*) ONLY_RAW="${ARG#--only=}" ;;
    esac
done

if [ $GLOBAL -eq 1 ]; then
    SKILLS_DIR="$HOME/.claude/skills"
else
    SKILLS_DIR="$(pwd)/.claude/skills"
fi

IFS=',' read -ra ONLY_LIST <<< "$ONLY_RAW"

UPDATED=0
SKIPPED=0
FAILED=0

for META_FILE in "$SKILLS_DIR"/.*.gs-meta; do
    [ -f "$META_FILE" ] || continue

    # Extract name: strip path, leading dot, and .gs-meta suffix
    NAME="${META_FILE##*/}"
    NAME="${NAME#.}"
    NAME="${NAME%.gs-meta}"

    # Apply --only filter
    if [ -n "$ONLY_RAW" ]; then
        MATCH=0
        for ENTRY in "${ONLY_LIST[@]}"; do
            ENTRY=$(echo "$ENTRY" | tr -d ' ')
            [ "$NAME" = "$ENTRY" ] && MATCH=1 && break
        done
        [ $MATCH -eq 0 ] && continue
    fi

    REPO=$(grep '^repo=' "$META_FILE" | cut -d'=' -f2-)
    PATH_IN_REPO=$(grep '^path=' "$META_FILE" | cut -d'=' -f2-)
    CURRENT_SHA=$(grep '^sha=' "$META_FILE" | cut -d'=' -f2-)
    ALLOW_RAW=$(grep '^allow=' "$META_FILE" | cut -d'=' -f2-)
    DENY_RAW=$(grep '^deny=' "$META_FILE" | cut -d'=' -f2-)

    if [ -z "$REPO" ] || [ -z "$PATH_IN_REPO" ]; then
        echo "[$NAME] Skipping: missing repo or path in metadata"
        FAILED=$((FAILED + 1))
        continue
    fi

    if [ -n "$ALLOW_RAW" ] && [ -n "$DENY_RAW" ]; then
        echo "[$NAME] Error: both allow and deny are set — only one is allowed; skipping"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Build clone URL: full URL passthrough, or GitHub shorthand
    if [[ "$REPO" == *"://"* ]] || [[ "$REPO" == "git@"* ]]; then
        CLONE_URL="$REPO"
    else
        CLONE_URL="https://github.com/$REPO"
    fi

    # Get latest SHA without cloning
    LATEST_SHA=$(git ls-remote "$CLONE_URL" refs/heads/main 2>/dev/null | cut -f1)

    if [ -z "$LATEST_SHA" ]; then
        echo "[$NAME] Error: could not fetch latest SHA from $CLONE_URL"
        FAILED=$((FAILED + 1))
        continue
    fi

    SHORT_LATEST=$(echo "$LATEST_SHA" | cut -c1-7)

    if [ "$CURRENT_SHA" = "$LATEST_SHA" ]; then
        echo "[$NAME] Already up to date ($SHORT_LATEST)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    if [ -n "$CURRENT_SHA" ]; then
        SHORT_CURRENT=$(echo "$CURRENT_SHA" | cut -c1-7)
        echo "[$NAME] Updating: $SHORT_CURRENT → $SHORT_LATEST"
    else
        echo "[$NAME] Installing: $SHORT_LATEST"
    fi

    # Clone: try with partial clone filter first, fall back to plain depth-1
    TEMP_DIR=$(mktemp -d)
    if ! git clone --depth 1 --filter=blob:none --no-checkout "$CLONE_URL" "$TEMP_DIR" 2>/dev/null; then
        rm -rf "$TEMP_DIR"
        TEMP_DIR=$(mktemp -d)
        if ! git clone --depth 1 --no-checkout "$CLONE_URL" "$TEMP_DIR" 2>/dev/null; then
            echo "[$NAME] Error: clone failed"
            rm -rf "$TEMP_DIR"
            FAILED=$((FAILED + 1))
            continue
        fi
    fi

    # Sparse checkout only the required path
    git -C "$TEMP_DIR" sparse-checkout set "$PATH_IN_REPO" 2>/dev/null
    git -C "$TEMP_DIR" checkout 2>/dev/null

    SOURCE="$TEMP_DIR/$PATH_IN_REPO"

    if [ ! -d "$SOURCE" ]; then
        echo "[$NAME] Error: path '$PATH_IN_REPO' not found in repo"
        rm -rf "$TEMP_DIR"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Build allow/deny sets
    IFS=',' read -ra ALLOW_LIST <<< "$ALLOW_RAW"
    IFS=',' read -ra DENY_LIST <<< "$DENY_RAW"

    # Copy skills, applying allow/deny filter per folder
    COPIED=0
    for ITEM in "$SOURCE"/*/; do
        [ -d "$ITEM" ] || continue
        FOLDER=$(basename "$ITEM")

        if [ -n "$ALLOW_RAW" ]; then
            MATCH=0
            for ENTRY in "${ALLOW_LIST[@]}"; do
                ENTRY=$(echo "$ENTRY" | tr -d ' ')
                [ "$FOLDER" = "$ENTRY" ] && MATCH=1 && break
            done
            [ $MATCH -eq 0 ] && continue
        elif [ -n "$DENY_RAW" ]; then
            MATCH=0
            for ENTRY in "${DENY_LIST[@]}"; do
                ENTRY=$(echo "$ENTRY" | tr -d ' ')
                [ "$FOLDER" = "$ENTRY" ] && MATCH=1 && break
            done
            [ $MATCH -eq 1 ] && continue
        fi

        cp -r "$ITEM" "$SKILLS_DIR/"
        COPIED=$((COPIED + 1))
    done

    # Update SHA in metadata file
    TEMP_META="$META_FILE.tmp"
    grep -v '^sha=' "$META_FILE" > "$TEMP_META"
    echo "sha=$LATEST_SHA" >> "$TEMP_META"
    mv "$TEMP_META" "$META_FILE"

    rm -rf "$TEMP_DIR"

    echo "[$NAME] Done ($COPIED folder(s) copied)"
    UPDATED=$((UPDATED + 1))
done

echo ""
echo "Summary: $UPDATED updated, $SKIPPED up to date, $FAILED failed"
[ $UPDATED -gt 0 ] && echo "Reload skills in your agent." || true
