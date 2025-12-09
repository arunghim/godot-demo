# Godot Demo

Godot Demo is a playable action-RPG prototype built in Godot 4. This project demonstrates several core gameplay systems typically found in RPGs, focusing on item interaction, inventory management, player movement, combat mechanics, and world object interactions.  

The main goal was to learn Godot and GDScript while designing a modular, reusable gameplay system. This demo allows players to interact with the environment, collect and equip items, and damage objects in the world, creating a dynamic and interactive experience. The design is inspired by survival and RPG games like Valheim, aiming to simulate core mechanics in a small-scale prototype.

---

## Features
- **Item Pickup System:** Detects nearby items and allows the player to pick up the nearest item automatically.  
- **Inventory System:** Includes a hotbar, stackable items, and equipping mechanics. Supports both main-hand and off-hand items.  
- **Interactable Items:** Highlight when focused, indicating they can be picked up.  
- **Item Resource System:** Each item stores metadata including equipment type, stack size, weapon type, and damage values.  
- **Player Controller:** Smooth movement with sprinting, jumping, crouching, dodging, and camera rotation.  
- **Player Animations:** Action-based animations for walking, sprinting, crouching, jumping, attacking, dodging, and interacting.  
- **Combat System:** Players can attack objects or enemies using equipped items. Damage is applied only if the correct weapon type is used.  
- **World Object System:** Objects can take damage, check weapon type requirements, and spawn collectible drops when destroyed.  
- **Item Drop System:** Dynamically spawns items in the world upon object destruction. Items can be picked up again.  
- **Item Equipping System:** Fully functional equipment system for different item types and armor (though armor items were not created in this demo).  

---

## Gameplay Controls
| Action                    | Key / Input / Button          |
|---------------------------|-------------------------------|
| Interact / Pickup         | E                             |
| Open Inventory            | Tab                           |
| Jump                      | Space                         |
| Sprint                    | Shift                         |
| Crouch                    | Left Ctrl                     |
| Dodge                     | Left Alt                      |
| Move                      | W / A / S / D                 |
| Free Look / Camera        | Mouse Movement                |

---

## Known Bugs / Limitations
- Player momentum can occasionally feel slippery or unnatural.  
- Dropped items may spawn inside other objects or fall out of the map.  
- Inventory UI integration is functional but minimal.  
- Armor equipping is fully functional but no armor items were created.  
- Some minor edge cases may not have been tested.  

---

## Assets
- Player animation and model assets were from [here](https://quaternius.itch.io/universal-animation-library)  
- Tree models were from [here](https://brokenvector.itch.io/low-poly-tree-pack)  
- All other models and GDScript code were created manually by me

---

## Demo Video
[Godot Demo Video](https://github.com/user-attachments/assets/a6796c03-2f82-446d-a85a-c6f74ef0401f)