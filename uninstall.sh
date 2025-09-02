#!/usr/bin/env bash
# === Locomotive Uninstaller ===
# Removes loco from ~/.local/bin and /usr/local/bin

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
Locomotive Uninstaller
All aboard for departure! Removing loco from ~/.local/bin and /usr/local/bin
============================================
EOF

# === Remove ~/.local/bin/loco ===
log "Clearing tracks at ~/.local/bin/locomotive..."
if [[ -f "$HOME/.local/bin/locomotive" ]]; then
  if rm "$HOME/.local/bin/locomotive"; then
    log "Removed $HOME/.local/bin/locomotive"
  else
    log "Error: Failed to remove $HOME/.local/bin/locomotive"
    exit 1
  fi
else
  log "Note: $HOME/.local/bin/locomotive not found, skipping"
fi

# === Remove /usr/local/bin/loco wrapper ===
log "Dismantling station at /usr/local/bin/locomotive..."
WRAPPER="/usr/local/bin/locomotive"
if [[ -f "$WRAPPER" ]]; then
  if [[ -w "$WRAPPER" ]]; then
    if rm "$WRAPPER"; then
      log "Removed $WRAPPER"
    else
      log "Error: Failed to remove $WRAPPER"
      exit 1
    fi
  else
    log "Need sudo to remove $WRAPPER"
    if sudo rm "$WRAPPER"; then
      log "Removed $WRAPPER with sudo"
    else
      log "Error: Failed to remove $WRAPPER with sudo"
      exit 1
    fi
  fi
else
  log "Note: $WRAPPER not found, skipping"
fi

# === Check config directory ===
log "Checking config station at ~/.config/locomotive..."
if [[ -d "$HOME/.config/locomotive" ]]; then
  if [[ -z "$(ls -A "$HOME/.config/locomotive")" ]]; then
    if rmdir "$HOME/.config/locomotive"; then
      log "Removed empty config directory $HOME/.config/locomotive"
    else
      log "Warning: Failed to remove empty $HOME/.config/locomotive"
    fi
  else
    log "Note: $HOME/.config/locomotive contains files (e.g., non_games.conf), leaving intact"
  fi
else
  log "Note: $HOME/.config/locomotive not found, skipping"
fi

# === Final message ===
cat <<'EOF'
============================================
Locomotive uninstalled!
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
The train has left the station.
Check /tmp/locomotive-install.log for details.
Thank you for riding!
============================================
EOF
