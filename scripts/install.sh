#!/bin/bash

LOCAL=0
for ARG in "$@"; do
    case "$ARG" in
        --local) LOCAL=1 ;;
    esac
done

if [ $LOCAL -eq 1 ]; then
    TARGET="$(pwd)/.claude/skills"
else
    TARGET="$HOME/.claude/skills"
fi

mkdir -p "$TARGET"
curl -sL https://github.com/cytoph/agent-skills/archive/refs/heads/main.tar.gz \
    | tar -xz --strip-components=2 -C "$TARGET" agent-skills-main/skills/install-git-skills agent-skills-main/skills/update-git-skills

echo "install-git-skills and update-git-skills installed to $TARGET"
echo "Run /reload-plugins in Claude Code to pick up the skills."
