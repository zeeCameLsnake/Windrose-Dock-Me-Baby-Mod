# Dock Me Baby

**⚠️ UPGRADING FROM v1.x?** Please read the [Upgrading from v1.x](#upgrading-from-v1x) section before installing!

A Lua mod for the game **Windrose** (powered by UE4SS) that acts as a "Valet Parking" system for your ship. 

Currently, ships often spawn at inconsistent or random points off the coast when teleporting home or calling them via 'K' or the wharf. This mod allows you to park your ship perfectly at your custom dock, save that exact position, and later recall the ship to that exact spot on demand.

## Features
* **Custom Docking Location:** Save the exact X, Y, Z coordinates and Yaw rotation of your ships.
* **Multi-Ship Support:** The mod stores coordinates under your character's name per ship, separated by the server's **World Seed**. You can have custom docks for your Frigate, Brig, etc. all at once, without overlapping coordinates when playing on different servers (unless they happen to share the exact same map seed!).
* **Fleet Support:** You can even save multiple ships of the *exact same type* (e.g., not only three Frigates, but also three -or as many as you like- *Bretheren Frigates*).  
  Since v2.0.0, every ship is tracked using its absolute native database GUID (`ShipId`). Just park them directly side-by-side, open the console, and type `setdock` for each one. The mod automatically assigns them to their exact parking spots upon recall without any mix-ups.
* **Persistent Saves:** Your custom dock locations are safely saved in a `.lua` dictionary file and persist across game restarts.
* **Anti-Cheat & Immersion:** To prevent players from abusing the valet parking to escape naval combat, you must be within 250 meters of a player-built Camp/Bonfire to use the recall command.
* **Safe Teleportation:** The mod safely teleports the player along with the ship if they are on board during the recall. You might fall off of the ship if it's current position is too close to the position defined in the save file. In this case, your character will be close to the ship so you can climb on it safely.


## Multiplayer Compatibility
**Fully compatible with Singleplayer, Co-op (Host Game), and Dedicated Servers!**
The mod uses a sophisticated RPC-hijacking technique to ensure that commands entered on a client's machine are securely executed on the host's or dedicated server. This allows seamless valet parking for you and your friends in any game mode.

**Note on Network Latency (Ping):**
The mod communicates with dedicated servers using carefully timed network pings (RPC sequences). If you have an exceptionally high ping (e.g., >200ms) or severe network jitter, the server might merge these packets (coalescing), causing the `dock` or `setdock` commands to be ignored. If nothing happens, simply try the command again.

## Upgrading from v1.x
**⚠️ Important Upgrade Notice:** Due to the new `WorldSeed` server segregation and `ShipId` tracking, the internal structure of the `DockMeBaby_SaveData.lua` has changed completely. **Old saved docks from v1.x will no longer work.** 

To make the transition as smooth as possible:
1. **Before updating**, load into your game and run the `dock` command one last time to ensure all your ships are perfectly parked at their old spots.
2. Close the game and **completely delete** your old `\ue4ss\Mods\DockMeBaby\` folder to ensure a clean slate and avoid leaving obsolete "ghost" data behind.
3. Install the new v2.0.0 version as described below.
4. In-game, stand on your ships and use the `setdock` command once more to register them in the new format!

## Installation
1. Install UE4SS into your Windrose `Binaries\Win64` folder.
2. Open `\ue4ss\UE4SS-settings.ini` and make sure the engine version is overridden to 5.6:
   ```ini
   [EngineVersionOverride]
   MajorVersion = 5
   MinorVersion = 6
   ```
3. Extract the `DockMeBaby` folder into your `\ue4ss\Mods\` directory.
   * Ensure the file path looks like this: `\Windrose\R5\Binaries\Win64\ue4ss\Mods\DockMeBaby\Scripts\main.lua`
   * Make sure `enabled.txt` is present in the `DockMeBaby` root folder.
   * **Crucial:** Ensure `ConsoleEnablerMod : 1` is set in the `mods.txt` inside your `\ue4ss\Mods\` directory.

### Multiplayer Installation

#### Co-op (Host Game)
For co-op sessions, the installation is different for the host and the joining friends:
*   **Joining Players (Clients) and host:** Install the mod into your normal game directory as described in the main installation steps above.
*   **Host only:** The host must install a *second copy* of UE4SS and the mod into the game's local server directory. This is typically located at: `[YourDrive]:\SteamLibrary\steamapps\common\Windrose\R5\Builds\WindowsServer\R5\Binaries\Win64\`. Install UE4SS here and then the mod into `\ue4ss\Mods\`.

#### Dedicated Server
The installation process for dedicated servers can vary greatly depending on your server provider, the operating system (Windows/Linux), and their specific setup (e.g., using Docker, Windrose+, etc.). The location for the `ue4ss/Mods` folder might be different.

Therefore, I cannot provide a single guide that works for everyone. Please consult your server provider's documentation or support for instructions on how to install UE4SS-based mods.

## Commands
Open the in-game developer console (usually **F10**) and use the following commands:

* `setdock` 
  Identifies the ship closest to you (it is recommended to stand on that ship to be absolutely sure) and saves its current position and rotation to `DockMeBaby_SaveData.lua` under your player name.
* `dock` 
  Reads your saved coordinates and instantly teleports all your saved ships back to their custom docks. Requires you to be within 25,000 units (approx. 250m) of a Camp/Bonfire.

## Note on Usage
Ensure you are very close to the ship you want to save when using `setdock` so the mod can accurately identify the correct vessel. When using `dock`, you must be close to a camp/bonfire.

### A Note on Cross-World Ship Summoning (Wharf)
In Windrose, ships are bound to your character, not the world. If you use the Wharf to summon a ship from an old world to a new one, it will keep its original `ShipId`.

**Edge Case:** If your new world happens to share the *exact same map seed* as the old one, using `dock` will recall the ship to its old coordinates from the previous world.

**Solution:** Simply use `setdock` once in the new world to set a new parking spot for the summoned ship.