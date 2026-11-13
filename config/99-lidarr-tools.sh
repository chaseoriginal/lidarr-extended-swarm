#!/usr/bin/with-contenv bash
# Lidarr Extended - persistent tool installer
# Runs on every container start via the linuxserver.io custom-cont-init.d mechanism.
# Ensures the tools the extended scripts need are present: beets (music matching
# and tag analysis), ffmpeg, flac, xq (XML jq wrapper for PlexNotify.bash).
#
# NOTE: this runs as root during s6 init, so `apk add` works. It must not
# abort the container: every step is best-effort and the script always exits 0.

# Short-circuit when everything is already installed. This keeps container
# start fast and makes the container independent of network reachability of
# the Alpine mirrors on a normal restart.
need_tools=0
for tool in beet ffmpeg flac xq xmlstarlet jq python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    need_tools=1
    echo "[lidarr-tools-init] MISSING: $tool"
  fi
done

# A present-but-broken beets counts as missing: it must be able to import.
if [ "$need_tools" -eq 0 ] && command -v beet >/dev/null 2>&1; then
  if ! beet --version >/dev/null 2>&1; then
    need_tools=1
    echo "[lidarr-tools-init] beet is present but does not run, will repair"
  fi
fi

if [ "$need_tools" -eq 0 ]; then
  echo "[lidarr-tools-init] All tools present, nothing to do."
  exit 0
fi

echo "[lidarr-tools-init] Installing missing packages..."

apk add --no-cache \
  python3 \
  py3-pip \
  ffmpeg \
  flac \
  xq \
  xmlstarlet \
  jq \
  beets \
  2>/dev/null || true

# Beets needs these for MusicBrainz matching; the apk beets package does not
# pull them all in. `packaging` is required by beets 2.11 at import time
# (beets.util.deprecation imports packaging.version), so without it the
# `beet` command dies with ModuleNotFoundError before doing anything.
# Note the pip name != import name for a couple of these:
#   acoustid is provided by the "pyacoustid" distribution
#   jellyfish is the "jellyfish" distribution
#   pyxDamerauLevenshtein is the "pyxdameraulevenshtein" distribution
# pip_install_name|import_name
for spec in \
  "packaging|packaging" \
  "mutagen|mutagen" \
  "requests|requests" \
  "pylast|pylast" \
  "beautifulsoup4|bs4" \
  "unidecode|unidecode" \
  "langdetect|langdetect" \
  "jellyfish|jellyfish" \
  "pyxdameraulevenshtein|pyxDamerauLevenshtein" \
  "pyacoustid|acoustid" \
  "confuse|confuse" \
  "r128gain|r128gain"
do
  pip_name="${spec%%|*}"
  import_name="${spec##*|}"
  if ! python3 -c "import $import_name" >/dev/null 2>&1; then
    echo "[lidarr-tools-init] Installing python package: $pip_name (imports as $import_name)"
    pip3 install --break-system-packages "$pip_name" >/dev/null 2>&1 \
      || pip3 install "$pip_name" >/dev/null 2>&1 \
      || echo "[lidarr-tools-init] WARN: could not install $pip_name"
  fi
done

# A beets that cannot import is worse than no beets at all: the arr-extended
# scripts would run and silently do nothing. Verify it actually executes.
if command -v beet >/dev/null 2>&1; then
  if beet --version >/dev/null 2>&1; then
    echo "[lidarr-tools-init] OK: beet (executable)"
  else
    echo "[lidarr-tools-init] WARN: beet is installed but fails to run"
    beet --version 2>&1 | tail -3
  fi
fi

for tool in xq xmlstarlet ffmpeg flac beet python3 jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "[lidarr-tools-init] OK: $tool"
  else
    echo "[lidarr-tools-init] MISSING: $tool"
  fi
done

echo "[lidarr-tools-init] Done."
exit 0
