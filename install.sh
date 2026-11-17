#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# p3ta-tricks — offline install script
# Sets up a fully self-contained offline pentest reference wiki.
# Run once before going dark. Tested on Arch/CachyOS, Debian/Kali/Ubuntu,
# Fedora/RHEL, and macOS (Homebrew).
#
# Usage:
#   chmod +x install.sh && ./install.sh
#   TOOLS_DIR=/path/to/tools ./install.sh   # custom tools location
#   ./install.sh --no-tools                 # skip tool deps, wiki only
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$(dirname "$SCRIPT_DIR")/p3ta-tricks-offline/tools}"
SKIP_TOOLS=0
VENV_DIR="$SCRIPT_DIR/.venv"

# ── Parse args ────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --no-tools) SKIP_TOOLS=1 ;;
    --help|-h)
      echo "Usage: $0 [--no-tools]"
      echo "  --no-tools   Only install wiki dependencies, skip pentest tool setup"
      exit 0 ;;
  esac
done

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

echo -e "${BOLD}"
echo "  ██████╗ ██████╗ ████████╗ █████╗       ████████╗██████╗ ██╗ ██████╗██╗  ██╗███████╗"
echo "  ██╔══██╗╚════██╗╚══██╔══╝██╔══██╗      ╚══██╔══╝██╔══██╗██║██╔════╝██║ ██╔╝██╔════╝"
echo "  ██████╔╝ █████╔╝    ██║   ███████║         ██║   ██████╔╝██║██║     █████╔╝ ███████╗"
echo "  ██╔═══╝  ╚═══██╗    ██║   ██╔══██║         ██║   ██╔══██╗██║██║     ██╔═██╗ ╚════██║"
echo "  ██║     ██████╔╝    ██║   ██║  ██║         ██║   ██║  ██║██║╚██████╗██║  ██╗███████║"
echo "  ╚═╝     ╚═════╝     ╚═╝   ╚═╝  ╚═╝         ╚═╝   ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝"
echo -e "${NC}"
echo "  Offline Install — $(date '+%Y-%m-%d')"
echo ""


# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Python 3.11+
# ─────────────────────────────────────────────────────────────────────────────
info "Checking Python..."
command -v python3 &>/dev/null || die "Python 3.9+ is required. Offline install will not contact a package manager."

PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
info "Python version: $PY_VER"
if python3 -c "import sys; sys.exit(0 if sys.version_info >= (3,9) else 1)" 2>/dev/null; then
  ok "Python $PY_VER is sufficient"
else
  die "Python 3.9+ required, found $PY_VER"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — pip
# ─────────────────────────────────────────────────────────────────────────────
python3 -m pip --version &>/dev/null 2>&1 || python3 -m ensurepip --upgrade &>/dev/null 2>&1 || \
  die "pip/ensurepip is required. Offline install will not contact a package manager."

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Create virtualenv and install wiki requirements
# ─────────────────────────────────────────────────────────────────────────────
info "Setting up Python virtual environment at $VENV_DIR ..."
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR" || die "Python venv support is required and must be installed before going offline."
  ok "Virtualenv created"
else
  ok "Virtualenv already exists"
fi

VENV_PIP="$VENV_DIR/bin/pip"
VENV_PY="$VENV_DIR/bin/python3"

info "Installing wiki requirements..."
[ -d "$SCRIPT_DIR/vendor" ] && [ -n "$(ls -A "$SCRIPT_DIR/vendor" 2>/dev/null)" ] || \
  die "vendor/ is missing; all Python packages must be bundled for offline installation."
info "Installing exclusively from bundled packages (network disabled)..."
PIP_NO_INDEX=1 "$VENV_PIP" install -r "$SCRIPT_DIR/requirements.txt" \
  --no-index --find-links "$SCRIPT_DIR/vendor/" \
  --find-links "$SCRIPT_DIR/vendor/wheels/" --quiet || \
  die "Bundled Python dependencies are incomplete; refusing to fall back to PyPI."
ok "Wiki requirements installed"

# Verify key imports
"$VENV_PY" -c "import flask, markdown, yaml, pygments" && ok "All Python imports verified" || die "Import check failed"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3.5 — Extract bundled archives (compiled binaries + exploit-db corpus)
#
# Compiled binaries and the exploit-db script corpus are NOT committed to git as
# raw files — antivirus quarantines/deletes them on clone or download. Instead
# they ship as password-protected, split 7-Zip archives disguised with a .txt
# extension (binaries.7z.001.txt … , exploitdb.7z.001.txt). They are only ever
# materialised here, at install time, on the operator's own machine.
#   - binaries.7z.*.txt    -> ./binaries/           (Compiled Binaries page)
#   - exploitdb.7z.001.txt -> ./sources/exploitdb/  (offline Exploit-DB lookups)
# Password defaults to "root"; override with ARCHIVE_PW=… if you re-pack them.
# ─────────────────────────────────────────────────────────────────────────────
info "Extracting bundled archives (binaries + exploit-db)..."

SEVENZIP="$(command -v 7z || command -v 7za || command -v 7zz || true)"
[ -n "$SEVENZIP" ] || die "7z/7za/7zz is required. Offline install will not contact a package manager."

ARCHIVE_PW="${ARCHIVE_PW:-root}"

# extract_bundle <basename> <sentinel-relative-path>
#   Skips if <sentinel> already exists. 7z requires split volumes named
#   .7z.001/.002/… (without the AV-evading .txt), so we symlink them into a
#   temp dir first. Archives carry full paths, so we extract to $SCRIPT_DIR.
extract_bundle() {
  local base="$1" sentinel="$2"
  if [ -e "$SCRIPT_DIR/$sentinel" ]; then
    ok "$base already present ($sentinel) — skipping extraction"
    return 0
  fi
  shopt -s nullglob
  local parts=( "$SCRIPT_DIR/${base}".7z.*.txt )
  shopt -u nullglob
  if [ "${#parts[@]}" -eq 0 ]; then
    die "$base archive (${base}.7z.*.txt) is missing; repository is not self-contained"
  fi
  info "Extracting $base (${#parts[@]} volume(s))..."
  local tmp p name; tmp="$(mktemp -d)"
  for p in "${parts[@]}"; do
    name="$(basename "${p%.txt}")"
    ln -sf "$p" "$tmp/$name"
  done
  if "$SEVENZIP" x -p"$ARCHIVE_PW" -o"$SCRIPT_DIR" -y "$tmp/${base}.7z.001" >/dev/null 2>&1; then
    ok "$base extracted"
  else
    die "$base extraction failed (archive incomplete or wrong ARCHIVE_PW)"
  fi
  rm -rf "$tmp"
}

extract_bundle "exploitdb" "sources/exploitdb/exploits"
extract_bundle "binaries"  "binaries/.versions.json"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Verify all static assets are local (no CDN gaps)
# ─────────────────────────────────────────────────────────────────────────────
info "Verifying offline asset completeness..."

STATIC="$SCRIPT_DIR/static"
MISSING=0

check_file() {
  if [ ! -f "$1" ]; then
    warn "MISSING: $1"
    MISSING=$((MISSING+1))
  fi
}

# Critical JS
check_file "$STATIC/js/prism-bundle.min.js"
check_file "$STATIC/js/fuse.min.js"
check_file "$STATIC/js/app.js"
check_file "$STATIC/js/mermaid.min.js"

# CSS
check_file "$STATIC/css/style.css"

# Fonts
check_file "$STATIC/fonts/press-start-2p.css"
check_file "$STATIC/fonts/press-start-2p-latin.woff2"

# Adaptix C2 locally-hosted screenshots (required for offline)
ADAPTIX_IMG_COUNT=$(find "$STATIC/img/adaptix" -name "*.png" -o -name "*.jpg" 2>/dev/null | wc -l)
if [ "$ADAPTIX_IMG_COUNT" -lt 100 ]; then
  die "Only $ADAPTIX_IMG_COUNT bundled Adaptix images found (expected 190+); repository is incomplete"
else
  ok "$ADAPTIX_IMG_COUNT Adaptix screenshots cached locally"
fi

# Sliver C2 images
check_file "$SCRIPT_DIR/sources/sliver-docs/images/cursed-1.png"
check_file "$SCRIPT_DIR/sources/sliver-docs/images/dns-c2-1.png"

# CyberChef is required and bundled.
if [ ! -f "$STATIC/cyberchef/CyberChef_v11.0.0.html" ]; then
  die "Bundled CyberChef is missing from $STATIC/cyberchef/"
fi

if [ "$MISSING" -gt 0 ]; then
  die "$MISSING critical static files missing — check the repo is complete"
fi
ok "All critical static assets present"

# Third-party external images (download and locally host)
EXT_IMG_COUNT=$(find "$STATIC/img/external" -type f 2>/dev/null | wc -l)
if [ "$EXT_IMG_COUNT" -lt 100 ]; then
  die "Only $EXT_IMG_COUNT bundled external images found (expected 100+); refusing network recovery"
else
  ok "$EXT_IMG_COUNT external images already cached in static/img/external/"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — Verify processed content
# ─────────────────────────────────────────────────────────────────────────────
info "Checking content completeness..."
CONTENT_DIR="$SCRIPT_DIR/content/processed"
PAGE_COUNT=$(find "$CONTENT_DIR" -name "*.json" | wc -l)
NAV_COUNT=$(find "$SCRIPT_DIR/content/nav" -name "*.json" | wc -l)

if [ "$PAGE_COUNT" -lt 3000 ]; then
  die "Only $PAGE_COUNT processed pages found — offline content bundle is incomplete"
else
  ok "$PAGE_COUNT content pages found"
fi
ok "$NAV_COUNT nav files found"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — Tool dependencies (skip with --no-tools)
# ─────────────────────────────────────────────────────────────────────────────
if [ "$SKIP_TOOLS" -eq 1 ]; then
  warn "Skipping tool setup (--no-tools)"
else
  info "Checking pentest tool dependencies..."

  TOOLS_PIP="$TOOLS_DIR/../venv/bin/pip" 2>/dev/null || TOOLS_PIP="$VENV_PIP"

  # Install Python attack tool requirements from tools directory
  if [ -d "$TOOLS_DIR" ]; then
    PYTHON_TOOLS=(
      BloodHound.py bloodyAD Certipy Coercer DonPAPI jwt_tool LaZagne
      ldapdomaindump ldeep lsassy mitm6 MSSqlPwner NetExec PKINITtools
      pyGoldenGMSA pypykatz pywhisker Responder ROADtools sccmhunter
      targetedKerberoast impacket-src
    )
    for tool in "${PYTHON_TOOLS[@]}"; do
      req="$TOOLS_DIR/$tool/requirements.txt"
      if [ -f "$req" ]; then
        info "  Installing deps for $tool..."
        PIP_NO_INDEX=1 "$VENV_PIP" install -r "$req" --no-index \
          --find-links "$SCRIPT_DIR/vendor/" --find-links "$SCRIPT_DIR/vendor/wheels/" --quiet || \
          die "Bundled packages cannot satisfy $tool requirements; refusing network fallback"
      fi
    done
    ok "Tool Python requirements processed"

    # Count available tools
    TOOL_COUNT=$(ls "$TOOLS_DIR" | wc -l)
    ok "$TOOL_COUNT tools found in $TOOLS_DIR"
  else
    warn "TOOLS_DIR not found at $TOOLS_DIR"
    warn "Set TOOLS_DIR env var or place tools at: $TOOLS_DIR"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7 — Generate start script
# ─────────────────────────────────────────────────────────────────────────────
START_SCRIPT="$SCRIPT_DIR/start-offline.sh"
cat > "$START_SCRIPT" << STARTSCRIPT
#!/usr/bin/env bash
# p3ta-tricks offline launcher — generated by install.sh
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
VENV_PY="\$SCRIPT_DIR/.venv/bin/python3"
TOOLS_DIR="\${TOOLS_DIR:-\$(dirname "\$SCRIPT_DIR")/p3ta-tricks-offline/tools}"
PORT="\${PORT:-5001}"
HOST="\${HOST:-127.0.0.1}"

# Validate venv
if [ ! -f "\$VENV_PY" ]; then
  echo "[!] Virtualenv not found. Run: ./install.sh"
  exit 1
fi

export OFFLINE_MODE=1
export TOOLS_DIR="\$TOOLS_DIR"

echo ""
echo "  ┌─────────────────────────────────────────────┐"
echo "  │   p3ta-tricks  —  OFFLINE MODE              │"
echo "  │   http://\${HOST}:\${PORT}                     │"
echo "  │   TOOLS_DIR: \$TOOLS_DIR"
echo "  └─────────────────────────────────────────────┘"
echo ""

cd "\$SCRIPT_DIR"

# Use gunicorn if available for stability, fall back to Flask dev server
if [ -f "\$SCRIPT_DIR/.venv/bin/gunicorn" ]; then
  exec "\$SCRIPT_DIR/.venv/bin/gunicorn" \
    --bind "\${HOST}:\${PORT}" \
    --workers 2 \
    --timeout 60 \
    --access-logfile - \
    app:app
else
  exec "\$VENV_PY" app.py
fi
STARTSCRIPT
chmod +x "$START_SCRIPT"
ok "Start script written to: $START_SCRIPT"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 8 — Network isolation test
# ─────────────────────────────────────────────────────────────────────────────
info "Scanning templates for external URL references..."

EXT_REFS=$(grep -rn "https://\|http://" "$SCRIPT_DIR/templates/" \
  | grep -v "github.com\|gitlab.com\|p3ta-tricks.com\|exploit-db.com\|nvd.nist.gov\|example\|placeholder\|YOUR_\|noopener\|rel=\|{{" \
  | grep -v "<!-\|/\*\|//\s" \
  | { grep "src=\|url(" || true; } \
  | wc -l)

if [ "$EXT_REFS" -gt 0 ]; then
  warn "$EXT_REFS potential external asset references found in templates:"
  grep -rn "https://\|http://" "$SCRIPT_DIR/templates/" \
    | grep -v "github.com\|gitlab.com\|p3ta-tricks.com\|exploit-db.com\|nvd.nist.gov\|example\|placeholder\|YOUR_\|noopener\|rel=\|{{" \
    | { grep "src=\|url(" || true; }
else
  ok "No external asset references found in templates"
fi

# ─────────────────────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Installation complete${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Start the offline wiki:"
echo -e "    ${BOLD}./start-offline.sh${NC}"
echo ""
echo "  Custom port / host:"
echo -e "    ${BOLD}PORT=8080 HOST=0.0.0.0 ./start-offline.sh${NC}"
echo ""
echo "  Custom tools directory:"
echo -e "    ${BOLD}TOOLS_DIR=/path/to/tools ./start-offline.sh${NC}"
echo ""
if [ "$SKIP_TOOLS" -eq 0 ] && [ -d "$TOOLS_DIR" ]; then
  echo "  Tools available: $TOOL_COUNT at $TOOLS_DIR"
  echo ""
fi
