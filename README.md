# Dock Me Baby

A Lua mod for the game **Windrose** (powered by UE4SS) that acts as a "Valet Parking" system for your ship. 

Currently, ships often spawn at inconsistent or random points off the coast when teleporting home. This mod allows you to park your ship perfectly at your custom dock, save that exact position, and later recall the ship to that exact spot on demand.

## Features
* **Custom Docking Location:** Save the exact X, Y, Z coordinates and Yaw rotation of your ships.
* **Multi-Ship Support:** The mod stores coordinates per player and per ship class. You can have custom docks for your Frigate, Brig, etc. all at once!
* **Fleet Support:** You can even save multiple ships of the *exact same type* (e.g., not only three Frigates, but also three *Bretheren Frigates*). Just park them side-by-side (at least 10 meters apart [for exact same types]) and type `setdock` for each one. The mod automatically assigns them to their respective parking spots upon recall.
* **Persistent Saves:** Your custom dock locations are safely saved in a `.lua` dictionary file and persist across game restarts.
* **Anti-Cheat & Immersion:** To prevent players from using the valet parking to escape naval combat, you must be within 250 meters of a player-built Camp (BuildingCenter) to use the recall command.
* **Safe Teleportation:** The mod safely teleports the player along with the ship if they are on board during the recall.

## Multiplayer Compatibility
**Currently Singleplayer ONLY.** 
Windrose's "Host Game" (Co-op) mode runs a hidden headless server in the background. Because UE4SS console commands execute strictly client-side, and the game currently lacks an in-game text chat to hook into for server commands, multiplayer valet parking is not supported at this time but definitively planned for future releases.


## Installation
1. Install UE4SS into your Windrose `Binaries\Win64` folder.
2. Open `\ue4ss\UE4SS-settings.ini` and make sure the engine version is overridden to 5.6:
   ```ini
   [EngineVersionOverride]
   MajorVersion = 5
   MinorVersion = 6
   ```
3. Extract the `DockMeBaby` folder into your `\ue4ss\Mods\` directory.
   * Ensure the file path looks like this: `\ue4ss\Mods\DockMeBaby\Scripts\main.lua`
   * Make sure `enabled.txt` is present in the `DockMeBaby` root folder.

## Commands
Open the in-game developer console (usually **F10**) and use the following commands:

* `setdock` 
  Identifies the ship closest to you and saves its current position and rotation to `DockMeBaby_SaveData.lua` under your player name.
* `dock` 
  Reads your saved coordinates and instantly teleports all your saved ships back to their custom docks. Requires you to be within 25,000 units (approx. 250m) of a Camp/BuildingCenter.

## Note on Usage
Ensure you are very close to the ship you want to save when using `setdock` so the mod can accurately identify the correct vessel. When using `dock`, you must be close to your base.