
![forager_demo_2](https://github.com/user-attachments/assets/38d94e7e-fe62-4dab-9e82-43b7a2d18198)


# Godot Online Multiplayer Forager Clone

This repository documents my personal learning project focused on building a multiplayer survival and crafting game using the **Godot Engine (4.4)** inspired by the game loop of the game Forager by HopFrog. My goal was to learn server-authoritative architecture and Godot Steam's networking capabilities. I built this project with an attempt on modular design.

### Server-Authoritative Networking
The biggest takeaway was the importance of a server-authoritative model. I learned that for systems where game state integrity is needed like inventory and crafting, the client should never trust its own data. For example, if two players try to pick up the same resource at the same moment, each client might think they succeeded, but only the server can decide who actually gets it and then update everyone consistently. 

Server authority also mitigates cheating in competitive multiplayer games where a player would benefit from sending its own state to the server (I jumped) rather than raw game input (I pressed spacebar). 

### File System Organization
At the beginning of the project, everything was arranged by file type. Scripts in one place, scenes in another, and assets grouped separately. That worked for a while, but as the project expanded and the number of .gd files increased, it became harder to keep track of which pieces belonged to which system. Switching to a structure organized around individual features made the layout far easier to navigate. Each system now keeps its scripts, scenes, and assets together. This feature-based folder structure should scale better as I continue, and makes the overall project feel more coherent.

* **State Management:** I implemented the `ServerManager` as the single source of truth, holding the authoritative `player_inventories` dictionary for all connected players.
* **RPCs for Action:** All client actions such as moving, gathering resources, crafting, or building are sent as **Remote Procedure Calls (RPCs)** to the server. The server then does three things:
    1.  Validates the action (checks ingredients)
    2.  Executes the change on its authoritative state.
    3.  Sends an RPC back to the client to update the local display (`add_item_to_inventory` / `remove_item_from_inventory`).
* **Movement Synchronization:** Player movement relies on the server's physics loop. The client syncs its input vector with the `MultiplayerSynchronizer`, and the server calculates and broadcasts the resulting position to all clients.

### 2. Modular Game Management Systems (Singletons)
I used Godot's **Autoload** feature to create globally accessible single-responsibility managers to seperate concerns:

* **`ServerManager`:** Handles the permanent and authoritative data, and registration of players.
* **`CraftingManager`:** Handles recipe lookups and handles the server-side logic for ingredient consumption and item creation
* **`BuildManager`:** Manages the building registry and handles the server-side placement of buildings after consuming materials.
* **`InventoryManager`:** This is purely a **client-side** manager responsible for holding the items received from the server and emitting the `inventory_changed` signal to update the UI

### 3. Resource Based Data Design
To keep the game data seperate from the code, I used Godot's **Resource** system:

* **Data Structures:** Custom resource scripts like `ItemData`, `BuildingData`, and `RecipeData` define the main assets.
* **Data Instances:** Instances like `wood.tres` and `basic_fabricator.tres` contain the actual values. This allows for easy data modification without touching the core logic scripts.

### 4. Third-Party Integration and Transport Layers
I explored using different multiplayer transport methods:

* **ENet/IP:** Simple peer-to-peer setup using local IP and port.
* **Steam Sockets:** Integration via the **Godot Steam** plugin to handle lobbies and connection management using Steam's internal ID system. This involved dynamically generating UI buttons to join discovered lobbies.

---

##  How to Run

1.  Open the project in **Godot Engine**.
2.  Set the main scene to `res://main/game.tscn`, if it's not already

### Networking Setup
* **To Host (ENet):** Run the project and click **"Host New Game"**.
* **To Join (ENet):** Open a second instance of the project and click **"Join as Client"**
* **To Use Steam Networking:** You need a steam client running in the background. Two instances on the same machine will not work, you need two Steam accounts on seperate machines, or else use a virtual machine.

## Controls

### Interaction
* **Harvest Resources:** Use `Spacebar` or `Mouse Button 1` (configured as the `interact` action) to harvest resources when you are near them, such as trees, rocks, and berries.

### Crafting
The only recipe currently implemented is the **Wooden Plank**. Press `C` (the `craft_test` action) to attempt to craft one Wooden Plank.
* **Requirement:** 2 Wood.

### Building
The only structure available is the **Basic Fabricator**.

1. Press `Q` (the `menu_bar_toggle` action) to open the menu bar.
2. Select **"Crafting Stations"** and click on the **"Basic Fabricator"** button.
3. Move the mouse to the desired location.
4. Press `E` (the `build` action) to place the Basic Fabricator.
