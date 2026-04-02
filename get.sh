#!/bin/bash
# One-liner installer
# Usage: curl -fsSL https://raw.githubusercontent.com/robin-li/ccc-reset-self/main/get.sh | bash
set -e

REPO="https://github.com/robin-li/ccc-reset-self.git"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Downloading ccc-reset-self..."
git clone --depth 1 --quiet "$REPO" "$TMP_DIR"

echo ""
cd "$TMP_DIR"
bash install.sh
