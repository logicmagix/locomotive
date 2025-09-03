#!/usr/bin/env bash
# === Locomotive Installer ===

set -euo pipefail

# === Logging ===
: > /tmp/locomotive-install.log
log() {
  echo "$@" | tee -a /tmp/locomotive-install.log
}

# === Header ===
cat <<'EOF'
================================================
    ░█░░░█▀█░█▀▀░█▀█░█▄█░█▀█░▀█▀░▀█▀░█░█░█▀▀    
    ░█░░░█░█░█░░░█░█░█░█░█░█░░█░░░█░░▀▄▀░█▀▀    
    ░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀    
================================================
Locomotive Installer
All aboard! Installing locomotive to ~/.local/bin and /usr/local/bin
============================================
EOF

# === Check for locomotive binary ===
if [[ ! -f "loco" ]]; then
  log "Error: File 'locomotive' not found in current directory"
  exit 1
fi

# === Install to ~/.local/bin ===
log "Laying tracks to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
if ! cp loco "$HOME/.local/bin/locomotive"; then
  log "Error: Failed to copy locomotive to ~/.local/bin/locomotive"
  exit 1
fi
chmod 755 "$HOME/.local/bin/locomotive"
log "Local installation complete! ~/.local/bin/locomotive is ready."

# === Ensure ~/.local/bin is in PATH ===
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  log "Note: ~/.local/bin is not in your PATH. Add it to your shell config (e.g., ~/.bashrc):"
  log "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# === Create /usr/local/bin wrapper ===
log "Building station at /usr/local/bin..."
WRAPPER="/usr/local/bin/locomotive"
WRAPPER_CONTENT="#!/usr/bin/env bash
# Locomotive wrapper
exec \"$HOME/.local/bin/locomotive\" \"\$@\""

if [[ -w "/usr/local/bin" ]]; then
  if echo "$WRAPPER_CONTENT" > "$WRAPPER"; then
    chmod 755 "$WRAPPER"
    log "System-wide wrapper installed at $WRAPPER"
  else
    log "Error: Failed to write wrapper to $WRAPPER"
    exit 1
  fi
else
  log "Need sudo to install wrapper to $WRAPPER"
  if sudo sh -c "echo '$WRAPPER_CONTENT' > '$WRAPPER' && chmod 755 '$WRAPPER'"; then
    log "System-wide wrapper installed at $WRAPPER with sudo"
  else
    log "Error: Failed to install wrapper to $WRAPPER with sudo"
    exit 1
  fi
fi

# === Create config directory ===
mkdir -p "$HOME/.config/locomotive"
log "Config station ready at ~/.config/locomotive for non_games.conf"

# === Final message ===
cat <<'EOF'
============================================
Installation complete!
================================================
                                      <<<<oooooo
                                     <<_________
 o  o  o  Choo Choo  o  o O  O         II    II 
____ ,_________ ,_____  ____    O      II    II 
...| |........| |.,.,.\_|[]|_'__Y    __II____II_
.I.|_|I.I.I.I.|_|.I.I.I.|__|_|II|}   I..........
=00==/00/==/00/=00--00==00--000\\==/==/==/==/==/
/==/==/==/==/==/==/==/==/==/==/==/==/==/==/==/==
                                                
================================================
Your train has arrived at the station.
Run 'locomotive' to start journey.
Check /tmp/locomotive-install.log for details.
All aboard!
============================================
EOF
