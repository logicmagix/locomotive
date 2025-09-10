#!/usr/bin/env bash

# Locomotive - A CLI Steam game launcher
# Copyright (C) 2025 Pavle Dzakula
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# shellcheck disable=SC2155

# === Truncate Log ===
: > /tmp/locomotive-debug.log
: > /tmp/locomotive-launch.log

# === Header ===
cat <<'EOF'
================================================
    ░█░░░█▀█░█▀▀░█▀█░█▄█░█▀█░▀█▀░▀█▀░█░█░█▀▀
    ░█░░░█░█░█░░░█░█░█░█░█░█░░█░░░█░░▀▄▀░█▀▀
    ░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀
================================================
EOF
echo "            == CLI STEAM LAUNCHER =="
echo "
          Press ENTER for Library menu.
             Enter game # to start.
        Enter 'add' to add non-game AppID.
                Enter q to quit.
================================================"
echo

# === Error handling ===
set -euo pipefail

# === Make unmatched globs vanish ===
shopt -s nullglob

# === Global menu structures ===
declare -ga titles=()
declare -gA ID=()
declare -ga STEAM_CMD=()
have() { command -v "$1" >/dev/null 2>&1; }

# === Choose native Steam or Flatpak ===
steam_cmd() {
  if have steam; then
    STEAM_CMD=(steam)
    echo "Using native Steam" >> /tmp/locomotive-debug.log
    return
  fi
  if have flatpak && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    STEAM_CMD=(flatpak run com.valvesoftware.Steam)
    echo "Using Flatpak Steam" >> /tmp/locomotive-debug.log
    return
  fi
  echo "Error: Steam not found (native or flatpak)" >&2
  exit 1
}

# === Determine Steam directory ===
get_steam_dir() {
  if have steam; then
    for p in "$HOME/.steam/steam" "$HOME/.local/share/Steam" ; do
      [[ -d "$p" ]] && { echo "$p"; return; }
    done
  fi
  if have flatpak; then
    for p in \
      "$HOME/.var/app/com.valvesoftware.Steam/data/Steam" \
      "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" \
      "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
    do
      [[ -d "$p" ]] && { echo "$p"; return; }
    done
  fi
  echo "Error: Unable to determine Steam directory" >&2
  exit 1
}

# === Determine paths ===
get_library_paths() {
  local vdf_file="$1/steamapps/libraryfolders.vdf"
  if [[ ! -f "$vdf_file" ]]; then
    echo "Error: libraryfolders.vdf not found at $vdf_file" >&2
    exit 1
  fi
  awk -F'"' '/"[Pp][Aa][Tt][Hh]"/ { if ($4 != "") print $4 }' "$vdf_file"
}
# === Add AppID to non_games.conf ===
add_non_game() {
  local appid="$1"
  local config_dir="$HOME/.config/locomotive"
  local config_file="$config_dir/non_games.conf"
  # Ensure the directory exists
  if ! mkdir -p "$config_dir" 2>>/tmp/locomotive-debug.log; then
    echo "Error: Failed to create directory $config_dir" >> /tmp/locomotive-debug.log
    return 1
  fi
  # === Ensure the file exists and is writable ===
  if [[ ! -f "$config_file" ]]; then
    if ! touch "$config_file" 2>>/tmp/locomotive-debug.log; then
      echo "Error: Failed to create $config_file" >> /tmp/locomotive-debug.log
      return 1
    fi
    if ! chmod u+rw "$config_file" 2>>/tmp/locomotive-debug.log; then
      echo "Error: Failed to set permissions on $config_file" >> /tmp/locomotive-debug.log
      return 1
    fi
  fi
  if [[ ! -w "$config_file" ]]; then
    echo "Error: $config_file is not writable" >> /tmp/locomotive-debug.log
    return 1
  fi
  # === Append AppID if not already present ===
  if ! grep -Fx "$appid" "$config_file" >/dev/null; then
    echo "$appid" >> "$config_file"
    echo "Added AppID $appid to $config_file" >> /tmp/locomotive-debug.log
  else
    echo "AppID $appid already in $config_file" >> /tmp/locomotive-debug.log
  fi
}

# === Build game library ===
build_games_list() {
  local steam_dir
  steam_dir="$(get_steam_dir)"
  echo "Steam directory: $steam_dir" >> /tmp/locomotive-debug.log
  titles=()
  ID=()
  local -a paths=()
  readarray -t paths < <(get_library_paths "$steam_dir")
  echo "Found ${#paths[@]} library paths" >> /tmp/locomotive-debug.log
  declare -A games_map=()
  local path app_dir manifest appid name
  # Known non-game AppIDs (Proton, Steam Linux Runtime, Steamworks Common, Source SDK)
  local -a non_games=(
    215
    1493710
    1391110
    1391112
    3658110
    961940
    858280
    1113280
    1054830
    1245040
    1420170
    1580130
    1887720
    2348590
    2805730
    1161040
    2180100
    1070560
    1628350
    1826330
  )
  local config_dir="$HOME/.config/locomotive"
  local config_file="$config_dir/non_games.conf"
  # === Ensure config directory exists ===
  if ! mkdir -p "$config_dir" 2>>/tmp/locomotive-debug.log; then
    echo "Error: Failed to create directory $config_dir" >> /tmp/locomotive-debug.log
    exit 1
  fi
  if [[ -f "$config_file" && -r "$config_file" ]]; then
    local -a extra=()
    mapfile -t extra < "$config_file"
    for appid in "${extra[@]}"; do
      if [[ "$appid" =~ ^[0-9]+$ ]]; then
        non_games+=("$appid")
      else
        echo "Warning: Invalid AppID '$appid' in $config_file, skipping" >> /tmp/locomotive-debug.log
      fi
    done
    echo "Loaded ${#extra[@]} AppIDs from $config_file" >> /tmp/locomotive-debug.log
  else
    echo "No $config_file found or not readable, creating empty file" >> /tmp/locomotive-debug.log
    if ! touch "$config_file" 2>>/tmp/locomotive-debug.log; then
      echo "Error: Failed to create $config_file" >> /tmp/locomotive-debug.log
      exit 1
    fi
    if ! chmod u+rw "$config_file" 2>>/tmp/locomotive-debug.log; then
      echo "Error: Failed to set permissions on $config_file" >> /tmp/locomotive-debug.log
      exit 1
    fi
  fi
  for path in "${paths[@]}"; do
    app_dir="$path/steamapps"
    [[ -d "$app_dir" ]] || continue
    echo "Processing app directory: $app_dir" >> /tmp/locomotive-debug.log
    for manifest in "$app_dir"/appmanifest_*.acf; do
      [[ -f "$manifest" ]] || continue
      appid="$(awk -F'"' '/"appid"/ {print $4; exit}' "$manifest")"
      name="$(awk -F'"' '/"name"/ {print $4; exit}' "$manifest")"
      echo "Found manifest: $manifest, AppID: $appid, Name: $name" >> /tmp/locomotive-debug.log
      if [[ -n "${appid:-}" && -n "${name:-}" ]]; then
        if [[ " ${non_games[*]} " =~ " ${appid} " || "$name" =~ [Ss][Tt][Ee][Aa][Mm][Ww][Oo][Rr][Kk][Ss] || "$name" =~ [Ss][Dd][Kk] ]];then
          echo "Filtering non-game AppID: $appid, Name: $name" >> /tmp/locomotive-debug.log
          add_non_game "$appid"
        else
          echo "Adding game: $name, AppID: $appid" >> /tmp/locomotive-debug.log
          games_map["$name"]="$appid"
        fi
      else
        echo "Skipping invalid manifest: $manifest (appid: $appid, name: $name)" >> /tmp/locomotive-debug.log
      fi
    done
  done
  # === Sort names alphabetically ===
  local -a sorted_names=()
  while IFS= read -r line; do
    sorted_names+=("$line")
  done < <(LC_ALL=C printf '%s\n' "${!games_map[@]}" | sort)
  # === Build titles and ID ===
  local i=1
  for name in "${sorted_names[@]}"; do
    titles+=("$i. $name")
    ID["$i"]="${games_map[$name]}"
    ((i++))
  done
  if [[ ${#titles[@]} -eq 0 ]]; then
    echo "Error: No installed games found after filtering" >&2
    exit 1
  fi
  echo "Built library with ${#titles[@]} entries" >> /tmp/locomotive-debug.log
}

# === Launch ===
launch() {
  local appid="$1"
  steam_cmd

  # Desired UI scale (fractional OK). Override by exporting L42_SCALE=... before running.
  local SCALE="${L42_SCALE:-1}"

  # GTK notes:
  # - GDK_SCALE is integer-only (1,2,3…)
  # - GDK_DPI_SCALE allows fractional scaling (1.25, 1.5, …)
  local GDK_SCALE_VAL="1"
  local GDK_DPI_VAL="$SCALE"
  local QT_SCALE_VAL="$SCALE"

  # Build the Steam URL and common args
  local url="steam://rungameid/${appid}"
  local common=(-silent)

  # Native Steam (non-Flatpak)
  if [[ "${STEAM_CMD[0]}" == "steam" ]]; then
    nohup env \
      GDK_SCALE="${GDK_SCALE_VAL}" \
      GDK_DPI_SCALE="${GDK_DPI_VAL}" \
      QT_SCALE_FACTOR="${QT_SCALE_VAL}" \
      "${STEAM_CMD[@]}" "${common[@]}" "${url}" \
      >/tmp/locomotive-launch.log 2>&1 &

  else
    # Flatpak: inject envs INSIDE the sandbox via --env flags
    local -a fp_prefix=()
    local -a fp_app_and_args=()

    if [[ "${STEAM_CMD[0]}" == "flatpak" && "${STEAM_CMD[1]}" == "run" ]]; then
      fp_prefix=("${STEAM_CMD[0]}" "${STEAM_CMD[1]}")
      fp_app_and_args=("${STEAM_CMD[@]:2}")
    else
      # Fallback: treat as prefix (rare custom wrappers)
      fp_prefix=("${STEAM_CMD[@]}")
      fp_app_and_args=()
    fi

    nohup "${fp_prefix[@]}" \
      --env=GDK_SCALE="${GDK_SCALE_VAL}" \
      --env=GDK_DPI_SCALE="${GDK_DPI_VAL}" \
      --env=QT_SCALE_FACTOR="${QT_SCALE_VAL}" \
      "${fp_app_and_args[@]}" \
      "${common[@]}" "${url}" \
      >/tmp/locomotive-launch.log 2>&1 &
  fi

  echo "Checking tickets... AppID is ${appid}"
  echo "Itinerary written to /tmp/locomotive-launch.log"
}


# === Menu (less) ===
display_menu() {
  {
    # === Library header ===
    cat <<'EOF'
================================================
                                      <<<<oooooo
                                     <<_________
         o o o Choo Choo o o O O       II    II
____ ,_________ ,_____ ____     O      II    II
...| |........| |.,.,.\_|[]|_'__Y    __II____II_
.I.|_|I.I.I.I.|_|.I.I.I.|__|_|II|}    I..........
=00==/00/==/00/=00--00==00--000\\==/==/==/==/==/
/==/==/==/==/==/==/==/==/==/==/==/==/==/==/==/==
                                               
================================================
EOF
    echo "           == GAME LIBRARY MENU =="
    echo "
   Browse your game library with less commands
              (SPACE/b or j/k).
        Enter q then game # to start
      Enter 'add' to add non-game AppID
             Enter q again to quit
================================================"
    echo
    for line in "${titles[@]}"; do printf '%s\n' "$line"; done
  } | less -R -X
}

# === Build the games list dynamically ===
build_games_list

# === Prompt for game selection ===
choice=""
while true; do
    read -rp "Choose a destination: " input
  echo "Input: '$input', Choice: '$choice'" >> /tmp/locomotive-debug.log
  if [[ -z "${input:-}" ]]; then
    display_menu
    choice=""  # Reset choice to allow menu display
    continue
  fi
  choice="$input"
  if [[ "$choice" =~ ^[qQ]$ ]]; then
    echo "Last stop. Goodbye!"
    exit 0
  elif [[ "$choice" == "add" ]]; then
    read -rp "Enter AppID to add to non_games.conf: " new_appid
    if [[ "$new_appid" =~ ^[0-9]+$ ]]; then
      add_non_game "$new_appid"
      echo "Added AppID $new_appid to $HOME/.config/locomotive/non_games.conf"
      build_games_list  # Rebuild list to reflect changes
    else
      echo "Invalid AppID, must be numeric" >&2
    fi
    choice=""  # Reset choice to allow menu display after add
    continue
  elif [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#titles[@]} )); then
    echo "Invalid selection, try again." >&2
    continue
  fi
  break
done

# === Get AppID ===
appid="${ID[$choice]:-}"
if [[ -z "$appid" ]]; then
  echo "No APPID found for selection $choice" >&2
  exit 1
fi

# === Debug log ===
{
  echo "Choice: $choice"
  echo "Raw title: ${titles[$((choice-1))]}"
  echo "Steam cmd: ${STEAM_CMD[*]}"
  echo "Steam dir: $(get_steam_dir)"
} >> /tmp/locomotive-debug.log

# === Get game name; strip leading number and dot ===
game_name="${titles[$((choice-1))]}"
game_name="${game_name#[0-9]*. }"
echo "Stripped game_name: $game_name" >> /tmp/locomotive-debug.log

# === Launch the game ===
launch "$appid"
echo "Locomotive steam engine is running.. Next stop: $game_name"
