#!/bin/bash
# install.sh - Remote Maven Parent JDK17 Installation
#
# This script handles remote installation via curl | bash
# Downloads the repository and delegates to local-install.sh
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sabirhussain/mvn-parent-jdk17/main/install/install.sh | bash
#   
# Or with bash -c for passing arguments:
#   bash <(curl -fsSL ...) [arguments for local-install.sh]

set -euo pipefail

# Enable debug/trace mode when DEBUG=1
[ "${DEBUG:-0}" = "1" ] && set -x

# Redirect stdin from TTY if running via pipe (e.g., curl | bash)
if [ ! -t 0 ] && ( : </dev/tty ) 2>/dev/null; then
    exec < /dev/tty
fi

# Allow override via environment variable for testing/forking
REPO_URL="${REPO_URL:-https://github.com/sabirhussain/mvn-parent-jdk17}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      Maven Parent JDK17 - Remote Installation           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Clone repository to temp dir
TEMP_DIR=$(mktemp -d)
# Always clean up temp dir on exit (handles SIGINT/SIGTERM as well as normal exit)
trap '[ -n "${TEMP_DIR:-}" ] && rm -rf "$TEMP_DIR"' EXIT

echo "📦 Downloading Maven Parent JDK17..."

_clone_err=$(mktemp)
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>"$_clone_err" || {
    echo "❌ Failed to clone repository"
    cat "$_clone_err" >&2
    rm -f "$_clone_err"
    exit 1
}
rm -f "$_clone_err"

echo "✅ Downloaded to: $TEMP_DIR"
echo ""

# Make local-install.sh executable
chmod +x "$TEMP_DIR/install/local-install.sh" || {
    echo "❌ Failed to make install script executable"
    exit 1
}

# Run local installation script
echo "🚀 Starting installation..."
echo ""

INSTALL_EXIT_CODE=0
"$TEMP_DIR/install/local-install.sh" "$TEMP_DIR" "$@" || INSTALL_EXIT_CODE=$?

# Cleanup temp directory (trap also handles this, but we want the user-visible message)
echo ""
echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
TEMP_DIR=""

# Exit with same code as local-install.sh
exit "$INSTALL_EXIT_CODE"
