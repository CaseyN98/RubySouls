# RubySouls

RubySouls is a modular 2D action‑RPG engine written in Ruby using the Gosu library.  
The project focuses on clean architecture, maintainability, and data‑driven content using Tiled JSON maps.
#vryell
#DawnBringer 
are responsible for the floor tiles/a few character sprites and items, thought I have made a few myself and plan on re working all of the pixel are once I get better. They can be found on itch and their packs are free. First map is for testing and map 2 is more of an attempt at a level. Though I have thought about random levels and loot.

## Technical Overview

### Engine Architecture
- **Entity‑Component‑Style** structure for player, enemies, items
- **Systems** for combat, physics, input, crafting, enemy AI
- **Camera** with smoothing, deadzone, and shake
- **UI Layer** separated into HUD, world UI, and menus

### Map Pipeline
- Maps created in **Tiled**
- Exported as **JSON**
- Supports:
  - Tile layers
  - Collision layers
  - Object layers (enemies, items, keys, doors, chests)
  - External TSX tilesets

### Gameplay Systems
- Real‑time combat with hit detection
- Enemy AI with behavior props
- Inventory + hotbar
- Crafting system with recipe database
- Item pickups and chests
- Door + key system
- Projectile system

### Graveyard System
On death, the game logs:
- Floor reached
- Kills
- Playtime
- Cause of death
- Timestamp

Stored in `saves/graveyard.json`.

## Running the Game

Install Gosu:
gem install gosu

Run:
ruby main.rb

## Folder Structure

src/
core/          → Game loop, camera, menu
entities/      → Player, Enemy, Item, Chest, Door
systems/       → Input, Physics, Combat, Crafting, EnemySystem
ui/            → HUD, Inventory, Graveyard
assets/
maps/          → JSON maps
tilesets/      → TSX + PNG tilesets
ect/           → Menu art, logo, misc

## License
MIT License





