# Dock Me Baby

A Lua mod for the game **Windrose** (powered by UE4SS) that acts as a "Valet Parking" system for your ship. 

Currently, ships often spawn at inconsistent or random points off the coast when teleporting home. This mod allows you to park your ship perfectly at your custom dock, save that exact position, and later recall the ship to that exact spot on demand.

## Features
* **Custom Docking Location:** Save the exact X, Y, Z coordinates and Yaw rotation of your ship.
* **Persistent Saves:** Your custom dock location is saved in a `.json` file and persists across game restarts.
* **Safe Teleportation:** The mod safely teleports the player along with the ship if they are on board during the recall.

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
  Identifies your active ship and saves its current position and rotation to `DockMeBaby_Coords.json`.
* `dock` 
  Reads the saved coordinates and instantly teleports your ship back to its custom dock.
* `scanship` 
  (Debug) Scans the world and lists all potential ship classes in the UE4SS console.

## Note on Usage
This version currently saves a single ship configuration. Ensure you are on or very close to your ship when using `setdock` so the mod can accurately identify the correct vessel.