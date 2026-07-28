#!/bin/bash
# local-install.sh - Local Maven Parent JDK17 Installation
# 
# This script handles local installation from a filesystem directory.
# Used for local testing and development.
#
# Usage:
#   ./local-install.sh [source-directory]
#
# Arguments:
#   source-directory: Path to mvn-parent-jdk17 repository root (default: parent of script dir)

set -e

# Redirect stdin from TTY if running via pipe
if [ ! -t 0 ] && ( : </dev/tty ) 2>/dev/null; then
    exec < /dev/tty
fi

# Determine source directory (this repo)
if [ -n "$1" ]; then
    SOURCE_DIR="$1"
else
    # Default: parent directory of this script
    SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

# Resolve to absolute path
SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
TARGET_DIR="$(pwd)"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      Maven Parent JDK17 - Local Installation            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "🔧 Using source files from: $SOURCE_DIR"
echo "📁 Installing to: $TARGET_DIR"
echo ""

# Verify source directory has required files
if [ ! -f "$SOURCE_DIR/pom.xml" ]; then
    echo "❌ Error: pom.xml not found in $SOURCE_DIR"
    echo "   Please provide a valid mvn-parent-jdk17 directory."
    exit 1
fi

# Prevent installing into source directory
if [ "$SOURCE_DIR" = "$TARGET_DIR" ]; then
    echo "❌ Error: Cannot install into source directory"
    echo "   Please run this script from your destination directory."
    exit 1
fi

echo "════════════════════════════════════════════════════════════"
echo "STEP 1: Locate mvn-parent Repository"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "mvn-parent-jdk17 requires an existing mvn-parent installation."
echo "Please provide the location of your mvn-parent repository."
echo ""

read -p "Use [local] filesystem path or [remote] git URL? (default: local): " SOURCE_MODE
SOURCE_MODE=${SOURCE_MODE:-local}

PARENT_SOURCE_DIR=""
TEMP_PARENT_DIR=""

# Cleanup function for temporary parent directory
cleanup() {
    if [ -n "$TEMP_PARENT_DIR" ] && [ -d "$TEMP_PARENT_DIR" ]; then
        echo "🧹 Cleaning up temporary parent directory..."
        rm -rf "$TEMP_PARENT_DIR"
    fi
}
trap cleanup EXIT

case "$SOURCE_MODE" in
    local)
        read -p "Enter absolute path to mvn-parent repository: " PARENT_SOURCE_DIR
        if [ -z "$PARENT_SOURCE_DIR" ]; then
            echo "❌ Error: mvn-parent path is required"
            exit 1
        fi
        # Resolve to absolute path
        PARENT_SOURCE_DIR="$(cd "$PARENT_SOURCE_DIR" && pwd)" || {
            echo "❌ Error: Directory not found: $PARENT_SOURCE_DIR"
            exit 1
        }
        ;;
    remote)
        read -p "Enter git repository URL for mvn-parent: " PARENT_REPO_URL
        if [ -z "$PARENT_REPO_URL" ]; then
            echo "❌ Error: mvn-parent repository URL is required"
            exit 1
        fi
        echo "📦 Cloning mvn-parent repository..."
        TEMP_PARENT_DIR=$(mktemp -d)
        git clone --depth 1 "$PARENT_REPO_URL" "$TEMP_PARENT_DIR" 2>/dev/null || {
            echo "❌ Error: Failed to clone repository: $PARENT_REPO_URL"
            exit 1
        }
        PARENT_SOURCE_DIR="$TEMP_PARENT_DIR"
        echo "✅ Cloned to: $TEMP_PARENT_DIR"
        ;;
    *)
        echo "❌ Error: Invalid source mode. Use 'local' or 'remote'."
        exit 1
        ;;
esac

# Verify parent directory has pom.xml
if [ ! -f "$PARENT_SOURCE_DIR/pom.xml" ]; then
    echo "❌ Error: pom.xml not found in mvn-parent repository"
    echo "   Path: $PARENT_SOURCE_DIR"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "STEP 2: Extract Parent Coordinates"
echo "════════════════════════════════════════════════════════════"
echo ""

# Function to extract POM values with fallback chain: Python → xmllint → sed
extract_pom_value() {
    local pom_file=$1
    local tag=$2
    local value=""
    
    # Try Python first (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        value=$(python3 - "$pom_file" "$tag" 2>/dev/null <<'PY'
import sys, xml.etree.ElementTree as ET
pom, tag = sys.argv[1], sys.argv[2]
try:
    ns = {"m": "http://maven.apache.org/POM/4.0.0"}
    root = ET.parse(pom).getroot()
    el = root.find(f"m:{tag}", ns)
    if el is not None and el.text: print(el.text.strip())
except: pass
PY
        )
    fi
    
    # Try xmllint if Python failed or not available
    if [ -z "$value" ] && command -v xmllint >/dev/null 2>&1; then
        value=$(xmllint --xpath "/*[local-name()='project']/*[local-name()='$tag']/text()" "$pom_file" 2>/dev/null | tr -d '\n')
    fi
    
    # Fallback to sed (least reliable but universally available)
    if [ -z "$value" ]; then
        value=$(sed -n "s|.*<$tag>\(.*\)</$tag>.*|\1|p" "$pom_file" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    
    echo "$value"
}

# Extract parent coordinates
PARENT_GROUP_ID=$(extract_pom_value "$PARENT_SOURCE_DIR/pom.xml" "groupId")
PARENT_VERSION=$(extract_pom_value "$PARENT_SOURCE_DIR/pom.xml" "version")

if [ -z "$PARENT_GROUP_ID" ] || [ -z "$PARENT_VERSION" ]; then
    echo "❌ Error: Failed to extract groupId or version from parent pom.xml"
    exit 1
fi

PARENT_GROUP_ID=$(extract_pom_value "$PARENT_SOURCE_DIR/pom.xml" "groupId")
PARENT_VERSION=$(extract_pom_value "$PARENT_SOURCE_DIR/pom.xml" "version")

if [ -z "$PARENT_GROUP_ID" ] || [ -z "$PARENT_VERSION" ]; then
    echo "❌ Error: Failed to extract groupId or version from parent pom.xml"
    exit 1
fi

echo "✅ Extracted parent coordinates:"
echo "   GroupId: $PARENT_GROUP_ID"
echo "   Version: $PARENT_VERSION"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "STEP 3: Configure Module GroupId"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "The current module groupId is: io.xprevel.jdk17"
echo "Parent groupId is:             $PARENT_GROUP_ID"
echo ""
echo "If you use the same groupId as parent, it will be omitted"
echo "(inherited from parent POM automatically)."
echo ""

read -p "Enter module groupId [default: io.xprevel.jdk17]: " MODULE_GROUP_ID
MODULE_GROUP_ID=${MODULE_GROUP_ID:-io.xprevel.jdk17}

if [ "$MODULE_GROUP_ID" = "$PARENT_GROUP_ID" ]; then
    MODULE_GROUP_ID_ACTION="omit"
    echo "✅ Module groupId matches parent - will be omitted"
else
    MODULE_GROUP_ID_ACTION="set"
    echo "✅ Module groupId will be set to: $MODULE_GROUP_ID"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Configuration Summary"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Parent Repository:  $PARENT_SOURCE_DIR"
echo "  Parent GroupId:     $PARENT_GROUP_ID"
echo "  Parent Version:     $PARENT_VERSION"
echo "  Module GroupId:     $MODULE_GROUP_ID ($MODULE_GROUP_ID_ACTION)"
echo "  Install Directory:  $TARGET_DIR"
echo ""

read -p "Proceed with installation? (y/N): " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "STEP 4: Copy Files"
echo "════════════════════════════════════════════════════════════"
echo ""

# Copy core files
echo "📋 Copying project files..."
cp "$SOURCE_DIR/pom.xml" "$TARGET_DIR/pom.xml"
echo "   ✓ pom.xml"

cp "$SOURCE_DIR/.gitignore" "$TARGET_DIR/.gitignore" 2>/dev/null && echo "   ✓ .gitignore" || true
cp "$SOURCE_DIR/LICENSE" "$TARGET_DIR/LICENSE" 2>/dev/null && echo "   ✓ LICENSE" || true

# Copy .env file - try parent directory first, then ~/.m2
echo ""
echo "📋 Looking for .env file..."
ENV_COPIED=false

if [ -f "$PARENT_SOURCE_DIR/.env" ]; then
    cp "$PARENT_SOURCE_DIR/.env" "$TARGET_DIR/.env"
    echo "   ✓ .env (from mvn-parent repository)"
    ENV_COPIED=true
elif [ -f "$HOME/.m2/.env" ]; then
    cp "$HOME/.m2/.env" "$TARGET_DIR/.env"
    echo "   ✓ .env (from ~/.m2/.env)"
    ENV_COPIED=true
else
    echo "❌ Error: .env file not found"
    echo "   Looked in:"
    echo "   - $PARENT_SOURCE_DIR/.env"
    echo "   - $HOME/.m2/.env"
    echo ""
    echo "Please create a .env file in one of these locations."
    exit 1
fi

# Copy .mvn/maven.config from mvn-parent repository if available
echo ""
echo "📋 Looking for .mvn/maven.config..."
MAVEN_CONFIG_COPIED=false

if [ -f "$PARENT_SOURCE_DIR/.mvn/maven.config" ]; then
    mkdir -p "$TARGET_DIR/.mvn"
    cp "$PARENT_SOURCE_DIR/.mvn/maven.config" "$TARGET_DIR/.mvn/maven.config"
    echo "   ✓ .mvn/maven.config (from mvn-parent repository)"
    MAVEN_CONFIG_COPIED=true
else
    echo "⚠️ Warning: .mvn/maven.config not found in mvn-parent repository"
    echo "   Looked in: $PARENT_SOURCE_DIR/.mvn/maven.config"
    echo "   Continuing without .mvn/maven.config"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "STEP 5: Update POM with Parent Coordinates"
echo "════════════════════════════════════════════════════════════"
echo ""

# Function to update POM with fallback chain: Python → sed
update_pom_with_parent() {
    local pom_file=$1
    local parent_gid=$2
    local parent_ver=$3
    local action=$4
    local module_gid=$5
    
    # Try Python first (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$pom_file" "$parent_gid" "$parent_ver" "$action" "$module_gid" 2>/dev/null <<'PY' && return 0
import sys, xml.etree.ElementTree as ET
pom, p_gid, p_ver, action, m_gid = sys.argv[1:6]
ns = "http://maven.apache.org/POM/4.0.0"
ET.register_namespace("", ns)
q = lambda t: f"{{{ns}}}{t}"
try:
    tree = ET.parse(pom)
    root = tree.getroot()
    parent = root.find(q("parent"))
    if not parent: sys.exit(1)
    for el_name, val in [("groupId", p_gid), ("version", p_ver)]:
        el = parent.find(q(el_name))
        if el is None: el = ET.SubElement(parent, q(el_name))
        el.text = val
    m_gid_el = root.find(q("groupId"))
    if action == "omit":
        if m_gid_el is not None:
            root.remove(m_gid_el)
            print("   ✓ Removed module groupId (inherited from parent)")
    else:
        if m_gid_el is None:
            idx = list(root).index(parent)
            m_gid_el = ET.Element(q("groupId"))
            root.insert(idx + 1, m_gid_el)
        m_gid_el.text = m_gid
        print(f"   ✓ Set module groupId to: {m_gid}")
    print(f"   ✓ Updated parent groupId: {p_gid}")
    print(f"   ✓ Updated parent version: {p_ver}")
    tree.write(pom, encoding="utf-8", xml_declaration=True)
except: sys.exit(1)
PY
    fi
    
    # Fallback to sed (works for simple cases)
    echo "   ℹ Using sed fallback for POM update..."
    
    # Create a temporary awk script for more precise XML editing
    awk -v parent_gid="$parent_gid" -v parent_ver="$parent_ver" -v action="$action" -v module_gid="$module_gid" '
    BEGIN { in_parent=0; parent_done=0; skip_module_gid=0 }
    /<parent>/ { in_parent=1; print; next }
    /<\/parent>/ { in_parent=0; parent_done=1; print; next }
    in_parent && /<groupId>/ && !/<groupId>.*<\/groupId>/ {
        print "        <groupId>" parent_gid "</groupId>"
        next
    }
    in_parent && /<version>/ && !/<version>.*<\/version>/ {
        print "        <version>" parent_ver "</version>"
        next
    }
    !in_parent && parent_done && !skip_module_gid && /<groupId>/ {
        skip_module_gid=1
        if (action == "omit") {
            next
        } else {
            print "    <groupId>" module_gid "</groupId>"
            next
        }
    }
    { print }
    ' "$pom_file" > "$pom_file.tmp" && mv "$pom_file.tmp" "$pom_file"
    
    # Print status messages
    if [ "$action" = "omit" ]; then
        echo "   ✓ Removed module groupId (inherited from parent)"
    else
        echo "   ✓ Set module groupId to: $module_gid"
    fi
    
    echo "   ✓ Updated parent groupId: $parent_gid"
    echo "   ✓ Updated parent version: $parent_ver"
    
    rm -f "$pom_file.bak"
    return 0
}

update_pom_with_parent "$TARGET_DIR/pom.xml" "$PARENT_GROUP_ID" "$PARENT_VERSION" "$MODULE_GROUP_ID_ACTION" "$MODULE_GROUP_ID" || {
    echo "❌ Error: Failed to update pom.xml"
    exit 1
}

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Installation Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Files created in $TARGET_DIR:"
echo "  ✓ pom.xml"
echo "  ✓ .gitignore"
echo "  ✓ LICENSE"
echo "  ✓ .env"
if [ "$MAVEN_CONFIG_COPIED" = true ]; then
    echo "  ✓ .mvn/maven.config"
else
    echo "  ⚠ .mvn/maven.config (not copied; source file missing)"
fi
echo ""
echo "Parent POM coordinates:"
echo "  <parent>"
echo "    <groupId>$PARENT_GROUP_ID</groupId>"
echo "    <artifactId>mvn-parent</artifactId>"
echo "    <version>$PARENT_VERSION</version>"
echo "  </parent>"
echo ""
echo "Next steps:"
echo "  1. Review and customize pom.xml if needed"
echo "  2. Install to local Maven repository: mvn clean install"
echo "  3. Use in your JDK 17 projects as parent POM"
echo ""
