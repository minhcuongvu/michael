#!/usr/bin/env bash
# copy_to_opencode_windows.sh - Copy skills from michael repo to opencode skills folder
# Run this after updating skills in the michael repo to sync them to opencode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skills"
DEST_DIR="/c/Users/Michael/.config/opencode/skills"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory $SOURCE_DIR not found"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Copying skills from $SOURCE_DIR to $DEST_DIR..."

# Copy each skill directory
for skill_dir in "$SOURCE_DIR"/*; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        dest_skill_dir="$DEST_DIR/$skill_name"
        
        echo "  Copying $skill_name..."
        mkdir -p "$dest_skill_dir"
        
        # Copy SKILL.md file
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            cp "$skill_dir/SKILL.md" "$dest_skill_dir/SKILL.md"
            echo "    ✓ $skill_name/SKILL.md"
        else
            echo "    ⚠ $skill_name/SKILL.md not found, skipping"
        fi
    fi
done

echo ""
echo "Done! Skills copied to $DEST_DIR"
echo ""
echo "Installed skills:"
ls -1 "$DEST_DIR"
