# FIGHTING FORCE (fightingforce)
AMARIS Development Specification

Engine: Godot 4.6
Platform: PC
Renderer: GL Compatibility
Resolution: 640×360 (2x → 1280×720 integer scale)
Genre: Tactical Turn-Based Strategy (SRPG)
Setting: Medieval High Fantasy (elves, dwarves, knights, mages)
Studio: AMARIS
Controller Required: Yes (Keyboard + Gamepad)

Reference:
- See /refImages/1.png for Shining Force 2-style UI + battle camera shift inspirations.

---

# AMARIS Studio Rules (Non-Negotiable)

- `project_status.json` is the single source of truth.
- CLAUDE.md defines structure + checkpoints only.
- Completion % must NOT be duplicated here.
- All gameplay systems must remain testable + deterministic.
- Debug flags default false in production.
- Never delete checklist items — mark N/A.

Launcher Contract:
- `game.config.json` must remain valid.
- `tests/run-tests.bat` must execute headless.
- ISO8601 minute precision timestamps.

AMATRIS MUST NOT:
- Parse markdown for metrics
- Modify CLAUDE.md automatically
- Rewrite game files silently

---

# Godot Execution Contract (MANDATORY)

Godot installed at:
Z:/godot

Claude MUST use:
Z:/godot/godot.exe

Never assume PATH.
Never use Downloads directory.
Never reinstall engine.

Headless boot:
Z:/godot/godot.exe --path . --headless --quit-after 1

Headless tests:
Z:/godot/godot.exe --path . --headless --script res://tests/run_tests.gd

If new scripts added:
Z:/godot/godot.exe --path . --headless --import

---

# Core Pillars (Shining Force 2-inspired)

1) Grid tactics: move → choose action → resolve → end turn
2) Persistent party roster: recruit units over time; keep favorites
3) RPG progression: unit XP, levels, stats, class promotions
4) Equipment: weapons/armor/accessories; inventory items
5) Battle presentation: when an attack happens, camera shifts to a "duel view"
   - Overworld grid pauses
   - Cinematic panel/scene shows attacker + defender
   - Plays weapon/magic SFX + hit VFX
   - Returns to tactical map after resolution
6) Controller-first UI everywhere

---

# Free 2D Asset Policy (Prototype → Replace Later)

Use ONLY free assets with permissive licenses (CC0 / CC-BY / public domain).
Store a small LICENSES folder + a credits file.

Recommended sources (choose a consistent style set):
- Kenney (CC0) for UI, icons, cursors, generic tiles
- OpenGameArt (varies) for medieval sprites, SFX, music
- itch.io free packs (verify license)
- Public domain / CC0 fonts for pixel UI

Asset Staging:
- placeholder → curated → final sweep
- Maintain `assets/_credits/credits.md` with links + license notes.

---

# Project Structure (Contract)

/ (repo root)
  game.config.json
  project_status.json
  CLAUDE.md
  /refImages/1.png
  /assets/
    /_credits/credits.md
    /tiles/
    /sprites/
      /units/
      /enemies/
      /effects/
    /ui/
    /audio/
      /music/
      /sfx/
  /scenes/
    /boot/
    /overworld/
    /battle/
    /ui/
  /scripts/
    /core/
    /battle/
    /overworld/
    /ui/
    /data/
  /data/
    /units/
    /items/
    /classes/
    /maps/
    /skills/
  /tests/
    run-tests.bat
    run_tests.gd
    test_results.json (generated)
    /cases/

---

# Architecture Summary

Autoloads (minimum):
- GameManager (mode, save/load hooks, debug flags)
- SceneManager (scene transitions + fade)
- InputManager (controller mapping + rebinding-ready)
- DataDB (loads .tres/.json data catalogs)
- AudioManager (music/sfx bus routing)
- SaveManager (slot-based saves, versioned)

Data Driven:
- Units, classes, items, skills, maps are data assets.
- Tactical logic must not depend on scene nodes for correctness.

Core Battle State Machine:
BOOT → INIT_BATTLE → PLAYER_PHASE → ENEMY_PHASE → RESOLVE → VICTORY/DEFEAT → OUTRO

---

# Battle System Requirements

Grid:
- Square grid (default) with tile types: grass, forest, hills, road, water, wall.
- Each tile provides:
  - movement cost
  - defense/evasion modifier
  - (optional) impassable flag per unit type

Turn Order:
- Phase-based (player phase then enemy phase), Shining Force style.
- Optional later: agility-based individual turns (mark N/A for now).

Actions:
- Move (once)
- Attack (melee/ranged)
- Cast (support/offense)
- Item use
- Wait

Combat:
- Deterministic hit + damage formulas (seeded RNG permitted only if stored/replayable).
- Critical hits supported.
- Magic uses MP; physical uses weapon stats.

Cinematic "Duel View" (Shining Force attack camera):
- When an attack resolves:
  1) Snapshot involved unit visuals + facing
  2) Transition to BattleDuelScene overlay (fast fade/slide)
  3) Play attack animation + VFX + SFX
  4) Show damage numbers + status text
  5) Return to tactical map, update HP, check defeat
- Must be skippable (A) and reduced-motion friendly.

---

# Overworld / Campaign Loop (MVP)

Start Town → Talk/Shop/Recruit → Leave town → Tactical battle map → Rewards → Back to town/new area

Town Features (MVP):
- HQ / Tavern: recruit + party management
- Shop: buy/sell equipment + consumables
- Church/Healer: revive + cure
- Inventory management: equip items per unit

---

# Save System (Contract)

- Slot-based saves (slot_1.json etc.)
- Versioned schema with migration support
- Must persist:
  - party roster + unit stats + inventory + equipment
  - story flags + unlocked recruits
  - current location (town/map) + last battle state (if needed)

---

# Controller Contract (Non-Negotiable)

- Full navigation by D-pad/left stick
- A = confirm, B = back/cancel
- LB/RB = tab switching (unit lists, pages)
- Y = context/help in menus (optional)
- Visible hint bar in key screens
- Keyboard fallback allowed but controller required standard

---

# Debug Flags (Must exist, default false)

- DEBUG_BATTLE
- DEBUG_AI
- DEBUG_INPUT
- DEBUG_SAVE
- DEBUG_UI
- DEBUG_PATHFIND

---

# Testing Contract

`tests/run-tests.bat` must call headless tests.
`tests/run_tests.gd` must:
- Run fast deterministic unit tests (no rendering dependencies)
- Output `tests/test_results.json` (pass/fail + counts + timestamp)

Minimum test cases:
- Grid pathfinding (blocked tiles, cost correctness)
- Combat formula determinism (same seed → same results)
- Duel view trigger does not mutate combat math
- Save/load roundtrip preserves unit stats + inventory
- Controller mapping is present (basic sanity)

---

# Structured Development Checklist
AMARIS STANDARD — 110 Checkpoints (do not delete items; mark N/A)

## Macro Phase 1 — Repo & Compliance (1–12)
- [ ] 1. Repo standardized (folders + required files exist)
- [ ] 2. game.config.json valid + minimal fields
- [ ] 3. project_status.json valid schemaVersion=1
- [ ] 4. Godot 4.6 GL Compatibility set
- [ ] 5. Resolution 640×360 integer scaling configured
- [ ] 6. Controller required documented in config
- [ ] 7. Autoloads created + registered
- [ ] 8. Headless boot works
- [ ] 9. Headless import works
- [ ] 10. Headless tests runner wired
- [ ] 11. test_results.json emits
- [ ] 12. Credits file exists for all assets

## Macro Phase 2 — Tactical Grid Core (13–30)
- [ ] 13. TileMap/grid representation chosen + stable
- [ ] 14. Grid coordinate helpers + conversions
- [ ] 15. Tile data model: moveCost/defBonus/evasionBonus/flags
- [ ] 16. Unit data model: stats, movement, team, class, level
- [ ] 17. Grid occupancy map
- [ ] 18. Pathfinding (A*) on grid
- [ ] 19. Movement range preview
- [ ] 20. Valid move highlight + cursor
- [ ] 21. Unit select + action menu
- [ ] 22. Turn phase manager (player/enemy)
- [ ] 23. "Wait" ends unit turn
- [ ] 24. Enemy AI: move toward + attack if in range
- [ ] 25. Terrain modifiers applied to combat preview
- [ ] 26. Basic camera pan/zoom + clamp
- [ ] 27. Input: controller cursor movement
- [ ] 28. UI hint bar basic
- [ ] 29. Battle end conditions
- [ ] 30. Reward screen skeleton

## Macro Phase 3 — Combat & Items (31–55)
- [ ] 31. Weapon types (melee/ranged) data-driven
- [ ] 32. Hit chance formula implemented
- [ ] 33. Damage formula implemented
- [ ] 34. Critical hits implemented
- [ ] 35. Magic: MP + spell data model
- [ ] 36. Items: consumables data model
- [ ] 37. Inventory per unit + party shared storage
- [ ] 38. Equip/unequip system
- [ ] 39. Combat preview panel (hit/dmg)
- [ ] 40. Status effects framework (poison/slow) (MVP: one status)
- [ ] 41. Defeat handling + remove from field
- [ ] 42. Revive rules defined
- [ ] 43. XP award after battle
- [ ] 44. Level up + stat growth
- [ ] 45. Promotion/class change (stub OK)
- [ ] 46. Loot drops (stub OK)
- [ ] 47. Shop prices data
- [ ] 48. Item use in battle
- [ ] 49. Item use in town
- [ ] 50. Determinism tests for combat
- [ ] 51. No-dupe RNG usage (seeded access helper)
- [ ] 52. UI polish pass: action menu
- [ ] 53. UI polish pass: preview panel
- [ ] 54. SFX hooks for hit/miss/crit
- [ ] 55. Music hooks for battle

## Macro Phase 4 — Duel View Camera (56–75)
- [ ] 56. DuelViewScene created (overlay or separate scene)
- [ ] 57. Transition animation (fast, skippable)
- [ ] 58. Attacker/defender sprite staging
- [ ] 59. Facing + positioning logic
- [ ] 60. Weapon swing / projectile animation (placeholder)
- [ ] 61. Magic cast animation (placeholder)
- [ ] 62. Hit VFX + screen shake option (toggle)
- [ ] 63. Damage numbers display
- [ ] 64. Miss/crit text
- [ ] 65. HP update synchronized on return
- [ ] 66. KO handling returns correctly
- [ ] 67. Reduced-motion mode disables heavy effects
- [ ] 68. DuelView does not change combat math
- [ ] 69. DuelView tests: trigger + return state
- [ ] 70. Controller: A skip, B not allowed (avoid cancel desync)
- [ ] 71. Sound mix: swing/hit/crit
- [ ] 72. Battle camera returns to last cursor pos
- [ ] 73. Edge case: counterattack (optional; stub OK)
- [ ] 74. Edge case: ranged attacks camera framing
- [ ] 75. Edge case: spell AoE framing (later; mark N/A for MVP)

## Macro Phase 5 — Town Loop & Campaign (76–95)
- [ ] 76. Boot scene → title → new game → town
- [ ] 77. Town scene functional (tiles + collisions)
- [ ] 78. NPC dialogue system (simple)
- [ ] 79. Recruit flow (adds unit to roster)
- [ ] 80. HQ party management screen
- [ ] 81. Shop buy/sell screen
- [ ] 82. Healer screen (revive/cure)
- [ ] 83. World map / exit to battle trigger
- [ ] 84. Battle map 01 created
- [ ] 85. Victory returns to town
- [ ] 86. Story flags data (simple)
- [ ] 87. Save/load slot UI
- [ ] 88. Save schema versioning
- [ ] 89. Migration handler stub
- [ ] 90. Autosave after battle (optional)
- [ ] 91. Tests: save/load roundtrip
- [ ] 92. Audio: town theme
- [ ] 93. Audio: overworld theme (optional)
- [ ] 94. UI polish pass: town menus
- [ ] 95. Performance sanity (no spikes in scans)

## Macro Phase 6 — AMATRIS Integration & Polish (96–110)
- [ ] 96. project_status.json fields updated correctly
- [ ] 97. ISO8601 minute timestamps everywhere
- [ ] 98. tests/test_results.json generated + readable
- [ ] 99. Missing keys handled safely
- [ ] 100. Placeholder art pass consistent style
- [ ] 101. Placeholder VFX pass
- [ ] 102. Accessibility: font legibility at 640×360
- [ ] 103. Controller navigation audit: no dead ends
- [ ] 104. Crash-proof null checks in UI
- [ ] 105. Credits complete + licenses recorded
- [ ] 106. Build version visible in title/options UI
- [ ] 107. Basic settings menu (volume, rumble, reduced motion)
- [ ] 108. Headless tests pass reliably
- [ ] 109. Project marked compliant by AMATRIS table
- [ ] 110. Vertical slice playable: town → battle → reward → save

---

# Operating Mode

Proceed phase by phase.
No rushed refactors.
Preserve modular, testable architecture.
Update `project_status.json` after each macro-phase milestone and after tests pass.
