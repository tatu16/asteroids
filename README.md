# Asteroids

Space shooter game built with Godot 4. Inspired by the classic arcade game with modern multiplayer support.

## Screenshots

| Main Menu | Gameplay |
|-----------|----------|
| ![Main Menu](assets/img/playmenu.png) | ![Gameplay](assets/img/game.png) |

## Features

- **Multiplayer** - Host or join lobbies via IP:PORT
- **Classic gameplay** - Shoot asteroids, avoid collisions, wrap-around screen
- **Enemy ships** - AI-controlled watchers that hunt players
- **Power-ups** - Collect upgrades for weapons and shields
- **Wave system** - Increasing difficulty with each wave

## Controls

| Action | Key |
|--------|-----|
| Movement | WASD |
| Shoot | Left Click |
| Ability | Right Click |

## Running
You can play Asteroids either by downloading a pre-built release or running it directly from the browser.

## Web version
**Note**: Some features may not work correctly in the web version. Multiplayer is not supported.
 - [Web Version](https://tatu16.github.io/loppuprojektipeli/)

## Download
You can download either the latest stable release or a nightly build.

### Stable Release
  1. Go to the Releases page.
  2. Download the latest release for your operating system.

### Nightly Build
  1. Go to GitHub Actions.
  2. Open the latest successful workflow run.
  3. Download the build artifact.
  - Note: Nightly builds may include unfinished features or bugs, but they also provide access to the latest changes and bug fixes before the next stable release.

### After downloading:
  1. Extract the downloaded archive.
  2. Run the game executable.
  - No Godot installation is required when using a pre-built release or nightly build.

### Run from Source
To run the project using Godot:
  1. Install Godot 4.
  2. Clone or download this repository.
  3. Open the project in Godot using project.godot.
  4. Run scenes/main_menu.tscn.

### Multiplayer
  - Host - Create a new multiplayer lobby.
  - Join - Connect to an existing lobby using its IP address and port (IP:PORT).

## Building
To build the game yourself:
  - Open the project in Godot 4.
  - Navigate to Project → Export.
  - Add an export preset for your target platform.
  - Click Export Project and choose where to save the build.
