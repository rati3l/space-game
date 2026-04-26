# Roguelike Prototype Balance Notes

This document defines a simple numeric combat model for a turn-based roguelike that can scale to a large skill tree (300+ skills) without exploding power.

## 1) Baseline Player Stats (Level 1)

Use these as default values before skills/items:

- `max_hp = 28`
- `attack = 8`
- `defense = 6`
- `speed = 10` (turn order tie-breaker only in prototype)
- `crit_chance = 0.05` (5%)
- `crit_mult = 1.50`
- `accuracy = 0.92`
- `evasion = 0.05`
- `life_steal = 0.00`
- `block_chance = 0.00`

Per level player growth (applies every level-up, before skill picks):

- `max_hp += 5`
- `attack += 2`
- `defense += 1`
- `speed += 0.25` (or +1 every 4 levels to keep integers)

## 2) Baseline Monster Stats + Growth

For a monster with level `L`:

- `monster_hp(L) = round(22 + 7.0 * L + 1.4 * L^1.35)`
- `monster_attack(L) = round(5 + 1.9 * L + 0.35 * L^1.2)`
- `monster_defense(L) = round(3 + 1.3 * L + 0.18 * L^1.15)`
- `monster_accuracy(L) = min(0.97, 0.86 + 0.003 * L)`
- `monster_evasion(L) = min(0.25, 0.03 + 0.004 * L)`

Monster archetype multipliers (apply after formulas):

- `grunt`: hp `x1.00`, atk `x1.00`, def `x1.00`, xp `x1.00`
- `brute`: hp `x1.35`, atk `x1.15`, def `x1.10`, xp `x1.35`
- `skirmisher`: hp `x0.85`, atk `x1.20`, def `x0.85`, xp `x1.20`
- `elite`: hp `x1.80`, atk `x1.35`, def `x1.30`, xp `x2.20`

## 3) Damage + Mitigation Model

Use deterministic core with light variance:

1. Raw hit:
   - `raw = attacker_attack * skill_power`
   - Default basic attack `skill_power = 1.00`
2. Mitigation:
   - `mitigation = defense / (defense + 40.0)`
   - `post_def = raw * (1.0 - mitigation)`
3. Randomness:
   - `roll = randf_range(0.92, 1.08)`
   - `damage = floor(post_def * roll)`
4. Crit:
   - If crit, `damage = floor(damage * crit_mult)`
5. Clamp:
   - `damage = clamp(damage, 1, 9999)`

Why this works:

- `def/(def+40)` gives diminishing returns and never reaches immunity.
- At `def=40`, damage taken is ~50%.
- At `def=120`, damage taken is ~25% (still hittable).

Hit chance model:

- `hit_chance = clamp(attacker_accuracy - defender_evasion, 0.10, 0.98)`

## 4) XP Curve and Kill Rewards

### XP required to level

For current player level `L` (to reach `L+1`):

- `xp_to_next(L) = round(40 + 14 * L + 5 * L^1.6)`

Reference points:

- L1->2: `59`
- L5->6: `165`
- L10->11: `389`
- L20->21: `1124`
- L30->31: `2256`

### XP granted per kill

For monster level `M` and player level `P`:

- `base_xp = 18 + 6 * M + 2.2 * M^1.35`
- `delta = M - P`
- `level_factor = clamp(1.0 + 0.14 * delta, 0.35, 1.80)`
- `kill_xp = round(base_xp * level_factor * archetype_xp_mult)`

This keeps farming low-level enemies inefficient while rewarding risk.

## 5) Skill Tree Power Budget (300+ Skills)

Target aggregate throughput gain from skills (not levels):

- Every 10 levels, expected net power from skills: `+35%` to `+50%` total combat power.
- Total expected power by level 30 from skill picks: around `x2.8` to `x3.4` (including synergies).

Simple per-node budget tags:

- `minor`: ~`+4%` effective power (e.g., +3% attack, +2% hp, +3% status chance)
- `major`: ~`+9%` effective power
- `keystone`: `+15%` to `+22%` with a drawback or condition

Rule of thumb:

- 1 keystone ~= 2 majors ~= 4 minors in effective value.

## 6) Suggested Caps and Floors

Global safety limits:

- `crit_chance`: floor `0.00`, cap `0.60`
- `crit_mult`: floor `1.25`, cap `2.50`
- `evasion`: floor `0.00`, cap `0.45`
- `block_chance`: floor `0.00`, cap `0.40`
- `life_steal`: floor `0.00`, cap `0.25`
- `damage_reduction_total`: cap `0.75` after all sources
- `cooldown_reduction`: cap `0.50`
- `on_kill_heal`: cap `0.20 * max_hp`

Floors to avoid dead builds:

- Minimum hit chance after all modifiers: `10%`
- Minimum damage dealt on hit: `1`
- Minimum XP from valid kill: `1`

## 7) Expected TTK (Time to Kill) Targets

`TTK` = turns required for player to kill a same-level grunt with basic attacks and average gear/skills.

- Levels `1-5`: target `4-6` turns
- Levels `6-10`: target `5-7` turns
- Levels `11-20`: target `6-8` turns
- Levels `21-30`: target `7-9` turns

For elites, target roughly `1.8x` to `2.4x` grunt TTK.

Defensive target (survivability):

- Player should survive about `6-9` incoming same-level grunt hits without healing in most builds.

## 8) Anti-Snowball Controls

Use multiple soft brakes instead of one hard nerf:

1. **Level-gap XP damping** (already in kill XP formula)
   - Strongly reduces overfarming low-risk monsters.
2. **Recovery throttling**
   - If `current_hp/max_hp > 0.75`, healing effects are `x0.70`.
3. **Stacking penalty on repeated same-tag buffs**
   - First stack `100%`, second `70%`, third `45%`, then floor at `30%`.
4. **Elite pressure scaling**
   - Every 5 floors, increase elite spawn chance by `+3%` (cap +18%).
5. **Loss-protection but not full reset**
   - On death: keep `35%` of unspent XP progress and one recent skill pick token (prevents total collapse).

## 9) Reroll Economy Suggestion (Skill Choice)

Level-up grants 1 skill choice event:

- Offer `3` random skills from eligible pool.
- Player gets `1` free reroll each level-up.
- Extra rerolls cost `R`:
  - `R1 = 12` gold
  - `R2 = 20` gold
  - `R3 = 32` gold
  - Formula: `R(n) = round(8 + 4 * n^1.6)` for reroll number `n` this level-up.
- Hard cap rerolls per level-up: `3` paid rerolls.

Long-run tuning targets:

- Average player uses paid reroll every `2-3` levels.
- Reroll spend should consume about `18-25%` of total gold income over a run.

Bad-luck protection:

- Track recent offered tags (offense/defense/utility).
- Guarantee at least one non-duplicate tag in every offer after first reroll.

## 10) Minimal Godot Implementation Sketch

Keep implementation simple in `Game.gd` style:

- Add `level`, `xp`, `xp_to_next`, `attack`, `defense`, `accuracy`, `evasion`.
- Replace flat `PLAYER_DAMAGE` / `MONSTER_DAMAGE` with formula functions:
  - `compute_damage(attacker_stats, defender_stats, skill_power)`
  - `compute_hit(attacker_accuracy, defender_evasion)`
- On monster death:
  - `xp += kill_xp(monster_level, player_level, archetype_mult)`
  - While `xp >= xp_to_next`: level up, grant base stats, open skill choice.

This model is intentionally compact, tunable, and safe for a prototype while supporting deep skill trees.
