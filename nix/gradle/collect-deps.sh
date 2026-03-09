#!/usr/bin/env bash
#
# Collect Gradle dependencies for offline Nix build
# Run this script in the dev shell (nix develop) to collect all Gradle deps
#
# Usage: ./nix/gradle/collect-deps.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/deps.json"

echo "=== Collecting Gradle dependencies for Nix build ==="

cd "$PROJECT_ROOT"

GRADLE_CACHE="${GRADLE_USER_HOME:-$HOME/.gradle}"
CACHES_DIR="$GRADLE_CACHE/caches"
MODULES_CACHE="$CACHES_DIR/modules-2/files-2.1"

if [ ! -d "$MODULES_CACHE" ]; then
    echo "ERROR: Gradle modules cache not found at $MODULES_CACHE"
    echo "Please run 'flutter build apk' first to populate the cache."
    exit 1
fi

echo "Using Gradle cache: $MODULES_CACHE"
echo ""

declare -A DEPS_MAP

get_repo_url() {
    local group="$1"
    local artifact="$2"
    local version="$3"
    local filename="$4"

    local group_path="${group//.//}"

    case "$group" in
        com.android.*|androidx.*|com.google.firebase.*|com.google.android.gms.*|com.google.mlkit.*|flutter_embedding_release)
            echo "https://dl.google.com/android/maven2/${group_path}/${artifact}/${version}/${filename}"
            ;;
        *)
            echo "https://repo1.maven.org/maven2/${group_path}/${artifact}/${version}/${filename}"
            ;;
    esac
}

while IFS= read -r -d '' group_dir; do
    while IFS= read -r -d '' artifact_dir; do
        while IFS= read -r -d '' version_dir; do
            while IFS= read -r -d '' hash_dir; do
                for file in "$hash_dir"/*; do
                    [ -f "$file" ] || continue

                    filename=$(basename "$file")
                    group=$(basename "$group_dir")
                    artifact=$(basename "$artifact_dir")
                    version=$(basename "$version_dir")

                    url=$(get_repo_url "$group" "$artifact" "$version" "$filename")

                    sha256=$(sha256sum "$file" | cut -d' ' -f1)

                    key="${group}:${artifact}:${version}:${filename}"
                    DEPS_MAP["$key"]="$sha256:$url"
                done
            done < <(find "$version_dir" -mindepth 1 -maxdepth 1 -type d -print0)
        done < <(find "$artifact_dir" -mindepth 1 -maxdepth 1 -type d -print0)
    done < <(find "$group_dir" -mindepth 1 -maxdepth 1 -type d -print0)
done < <(find "$MODULES_CACHE" -mindepth 1 -maxdepth 1 -type d -print0)

echo "Found ${#DEPS_MAP[@]} dependencies"

echo "[" > "$OUTPUT_FILE"
first=true
for key in "${!DEPS_MAP[@]}"; do
    value="${DEPS_MAP[$key]}"
    sha256="${value%%:*}"
    url="${value#*:}"

    IFS=':' read -r group artifact version filename <<< "$key"

    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$OUTPUT_FILE"
    fi

    cat >> "$OUTPUT_FILE" <<EOF
  {
    "group": "$group",
    "artifact": "$artifact",
    "version": "$version",
    "filename": "$filename",
    "url": "$url",
    "sha256": "$sha256"
  }
EOF
done
echo "]" >> "$OUTPUT_FILE"

echo ""
echo "Dependencies written to $OUTPUT_FILE"
