# AFTERLIFE INC. — Godot vertical slice

A config-driven Godot 4 incremental game prototype based on the supplied architecture. Open `project.godot` in Godot 4.x and run the project.

Implemented: soul queue, manual judgment, three generators, geometric bulk buying and Buy Max, milestones, six upgrades, offline income (8-hour cap at 50%), Samsara prestige, localized strings, autosave, and versioned JSON saves. The playable vertical slice also includes a deterministic replayable peg-drop simulation, 30 fate cards with generated card art, a six-soul codex with generated visual entries, a 36-node constellation, three selectable deities with cosmetic data, special-shop rotation, local weekly records, and saved accessibility/UI-scale settings.

GodotSteam is intentionally behind the future platform-service boundary and is not required to run this local build.

## Project status

Completed locally: the first-soul playable flow (choose card → reveal rule → peg drop → settlement), fate alignment after reincarnation, card collection, soul codex/storage, constellation progression, deity wardrobe, special shop, weekly local records, and headless core tests.

Still pending: layered visual variants for deity cosmetics, card rarity and limited consumable behavior, audio, full key rebinding, balancing and save-migration coverage, error reporting, Steam Cloud, Steam leaderboards/anti-cheat, and Steam build packaging. Steam work requires GodotSteam, the Steam SDK, an App ID, and partner-site permissions.

## Controls

- Click **Judge** to process one soul.
- Expand departments using Buy 1, Buy 10, or Buy Max.
- At 1M lifetime Karma, reincarnate for permanent +10% production per Samsara.
