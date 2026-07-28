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

set -e

# Redirect stdin from TTY if running via pipe (e.g., curl | bash)
if [ ! -t 0 ] && ( : </dev/tty ) 2>/dev/null; then
    exec < /dev/tty
fi

REPO_URL="https://github.com/sabirhussain/mvn-parent-jdk17"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      Maven Parent JDK17 - Remote Installation           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Clone repository to temp dir
TEMP_DIR=$(mktemp -d)
echo "📦 Downloading Maven Parent JDK17..."

git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null || {
    echo "❌ Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
}

echo "✅ Downloaded to: $TEMP_DIR"
echo ""

# Make local-install.sh executable
chmod +x "$TEMP_DIR/install/local-install.sh"

# Run local installation script
echo "🚀 Starting installation..."
echo ""

set +e
"$TEMP_DIR/install/local-install.sh" "$TEMP_DIR" "$@"
# Store exit code
INSTALL_EXIT_CODE=$?
set -e

# Cleanup temp directory
echo ""
echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Exit with same code as local-install.sh
exit $INSTALL_EXIT_CODE
