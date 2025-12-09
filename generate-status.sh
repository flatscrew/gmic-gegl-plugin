#!/usr/bin/env bash

CMDS=$(./build/gmic-parser --just_command | tr -d '\r')

echo "| G'MIC command  | Status | Notes |"
echo "|----------------|--------|-------|"

while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    echo "| \`$cmd\` | ❔ |  |"
done <<< "$CMDS"
