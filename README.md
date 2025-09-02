================================================

    ░█░░░█▀█░█▀▀░█▀█░█▄█░█▀█░▀█▀░▀█▀░█░█░█▀▀    
    ░█░░░█░█░█░░░█░█░█░█░█░█░░█░░░█░░▀▄▀░█▀▀    
    ░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀    

================================================

A command-line Steam launcher for Linux to browse and launch games with a interface.

## Features
- Browse Steam library using `less` (SPACE, b, j/k or arrow keys).
- Launch games by number, quit with `q`.
- Supports native Steam and Flatpak.
- Truncates logs for clean runs.
- Customizable non-game filtering via `~/.config/loco/non_games.conf`.
- Train-themed ASCII art and messages.
- Launch your favorites quickly with the command `loco` followed by your favorite games ID number e.g. loco 42.
- Game ID matches the games position in the library menu.

## Requirements
- **OS**: Linux
- **Tools**: `bash`, `awk`, `sort`, `less`
- **Steam**: Native or Flatpak (`com.valvesoftware.Steam`)

## Installation
- git clone https://github.com/logicmagix/loco
- cd ...loco/ and chmod +x install.sh
- Run ./install.sh

## Uninstallation
- chmod +x uninstall.sh from within the Locomotive repo
- ./uninstall.sh

## Usage
1. Run `loco`.
2. Press Enter to view the game library menu.
3. Navigate with SPACE/j (down), b/k (up), q (exit menu).
4. Enter a game number to launch or `q` to quit.
5. Press Enter to reuse the last selection or reopen the menu.

## Customization
- **Non-Game Filtering**: Add AppIDs of non-game entries (e.g., tools, DLCs) to `~/.config/loco/non_games.conf`, one integer per line. Example:
  ```bash
  echo "1234567" > ~/.config/loco/non_games.conf
  echo "7654321" >> ~/.config/loco/non_games.conf

## Screenshots

### Locomotive Interface
![Locomotive_Logo](Screenshots/Screenshot1.png)

### Locomotive Library
![Locomotive_Library](Screenshots/Screenshot2.png)

### Locomotive Launch
![Locomotive_Launch](Screenshots/Screenshot3.png)
