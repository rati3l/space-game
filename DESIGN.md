# Roguelike Prototype Design (Implementation Spec)

## Core Loop
1. Enter floor -> clear rooms -> earn XP/gold/shards -> choose next room/reward.
2. Build power through level-ups (passive tree points) and item drops.
3. Reach floor boss every 5 floors; kill for large reward and checkpoint.
4. Death ends run; meta currency (optional later) can be added without changing formulas below.

Design target: 25-40 minute run, player level ~35-45 for average run, hard cap 50.

---

## Combat Stats

### Player Primary Stats
- `STR`: melee damage scaling, armor scaling.
- `DEX`: attack speed, evasion, crit chance scaling.
- `INT`: spell damage scaling, mana/energy scaling.
- `VIT`: max life.
- `WIL`: resource regen, ailment resistance.

### Derived Player Stats
- `MaxLife = 80 + 12*Level + 6*VIT + LifeFromGear + %LifeBonuses`
- `MaxMana = 40 + 6*Level + 5*INT + ManaFromGear + %ManaBonuses`
- `AttackPower = WeaponBase * (1 + 0.02*STR) * (1 + %IncreasedAttackDamage)`
- `SpellPower = SpellBase * (1 + 0.025*INT) * (1 + %IncreasedSpellDamage)`
- `AttackSpeed = WeaponAPS * (1 + 0.01*DEX + %IncreasedAttackSpeed)`
- `CritChance = clamp(BaseCrit + 0.0008*DEX + FlatCritBonus, 0.05, 0.75)`
- `CritMultiplier = 1.5 + CritMultiBonus` (default 150%)
- `Armor = GearArmor * (1 + 0.015*STR + %IncreasedArmor)`
- `Evasion = GearEvasion * (1 + 0.02*DEX + %IncreasedEvasion)`
- `Resist(Fire/Cold/Lightning) = clamp(BaseRes + GearRes + PassiveRes, -0.5, 0.75)`
- `ChaosRes = clamp(BaseChaosRes + GearChaosRes + PassiveChaosRes, -0.6, 0.6)`

### Monster Stats
Per monster archetype use multipliers:
- `HP = BaseHP(archetype) * FloorHPScale(floor) * Elite/BossMult`
- `Damage = BaseDmg(archetype) * FloorDmgScale(floor) * Elite/BossMult`
- `Armor/Evasion/Resists` by family (brute/high armor, scout/high evasion, caster/high elemental).

---

## Damage/Defense Formulas

### Hit Resolution
1. Accuracy check: `HitChance = clamp(Accuracy / (Accuracy + (Evasion*0.8)), 0.1, 0.95)`
2. If hit, crit roll from `CritChance`.
3. Base damage roll in weapon/spell range.
4. Apply additive increases, then multiplicative "more" modifiers.
5. Apply mitigation:
   - Physical via armor
   - Elemental/chaos via resist
6. Apply on-hit effects (leech, ailment, thorns, etc.).

### Mitigation
- Physical reduction:
  - `PhysDR = Armor / (Armor + 10 * IncomingPhysicalHit)`
  - `PostArmorDamage = IncomingPhysicalHit * (1 - PhysDR)`
  - Cap effective `PhysDR` at 85%.
- Elemental:
  - `PostResDamage = IncomingElemHit * (1 - Resist)`
- Chaos:
  - same as elemental but using `ChaosRes`.

### Final Damage
- `FinalHit = (Base * (1 + SumIncreased) * ProductMore) * CritFactor * EnemyTakenMultiplier`
- `CritFactor = CritMultiplier` on crit else `1.0`

### DPS Approximation (for balance tools)
- `ExpectedHit = AvgNonCrit * (1 - CritChance) + AvgNonCrit*CritMultiplier*CritChance`
- `SheetDPS = ExpectedHit * AttackSpeed` (or cast speed analog)

Balancing rationale:
- Armor strong vs many small hits, weak vs spikes (classic ARPG behavior).
- Resist caps force investment decisions.
- Multiplicative "more" is rare and mostly on keystones/notables.

---

## XP and Leveling

### XP Required per Level
For level `L` to `L+1` (1-49):
- `XPReq(L) = round(45 + 18*L + 5*L^2)`

Sample checkpoints:
- L1->2: 68
- L10->11: 725
- L20->21: 2485
- L30->31: 5245
- L40->41: 9005
- L49->50: 12928
- Total to level 50: ~232k

### XP Award per Kill
- `XPBase = MonsterBaseXP * FloorXPScale(floor) * RarityMult`
- `RarityMult: normal=1.0, magic=1.8, rare=3.2, boss=10`
- `FloorXPScale(f) = 1 + 0.14*(f-1) + 0.015*(f-1)^2`

Level difference penalty:
- `d = MonsterLevel - PlayerLevel`
- If `d >= -2`, multiplier = `1`
- Else multiplier = `max(0.1, 1 - 0.08 * ((-d)-2))`

Party/other modifiers omitted for prototype.

### Level Rewards
- +1 passive skill point every level.
- +5 Life and +2 Mana baseline every level (already represented through formulas).
- Every 10 levels: choice of 1 class-agnostic "Ascendancy-style" notable from 3 options (small list, see skill tree section).

---

## Skill Tree Structure (clusters, notable/keystone analogs)

Tree goals:
- PoE-like breadth, but implementable in prototype.
- 300+ passives generated from templates, not hand-authored one by one.
- 5 themed regions around center; each region supports 2 primary archetypes and hybrid bridges.

### Topology
- Total nodes: 324
  - 180 small nodes
  - 108 medium nodes
  - 30 notable nodes
  - 6 keystones
- Regions: `Might (STR)`, `Finesse (DEX)`, `Sorcery (INT)`, `Survival (VIT)`, `Control (WIL)`
- Center wheel contains generic sustain/offense and branching gateways.
- Edges contain high-specialization notables + keystones.

### Node Types
- **Small**: +6-12% increased stat or +8-20 flat utility.
- **Medium**: dual-stat efficiency nodes; stronger but more specific.
- **Notable**: build-defining bonuses with mild condition.
- **Keystone**: large upside + meaningful downside.

### Keystone Analogs (6 examples)
1. `Glass Cannon`: +40% more damage, -25% max life.
2. `Bulwark`: +30% armor and +20% block chance, -20% move speed.
3. `Perfect Focus`: spells cannot crit, +55% more non-crit spell damage.
4. `Blood Pact`: skills cost life instead of mana, +25% life leech from hit.
5. `Shadow Dance`: +35% evade chance, armor set to 0.
6. `Elemental Equilibrium`: hitting element gives enemies +20% res to that element, -25% to others for 4s.

### Notable Pattern
Each region has 6 local notables (30 total), examples:
- Might: `Crushing Blows` (+20% melee dmg, +10 STR, +15% stun duration)
- Finesse: `Needle Precision` (+2.5% base crit chance for attacks)
- Sorcery: `Arcwell` (+25% spell dmg, +1 mana/sec regen)
- Survival: `Lasting Shell` (+18% max life, +12% armor)
- Control: `Hex Engine` (+20% ailment chance, +30% ailment duration)

---

## 300-Skill Generation Scheme with Examples

Use data-driven generation to avoid manual authoring.

### Data Model
Each node record:
- `id`
- `type` (`small|medium|notable|keystone`)
- `region`
- `tags` (e.g. `attack`, `spell`, `fire`, `crit`, `defense`, `resource`)
- `stat_mods` (list of stat operations)
- `neighbors` (adjacency list for graph)
- `icon_key`
- `point_cost` (always 1 for prototype)

### Template Families
Build 18 small templates x 10 tuned variants = 180 small nodes:
- `+% melee damage`, `+% spell damage`, `+% attack speed`, `+% cast speed`
- `+% crit chance`, `+% crit multi`, `+% life`, `+% mana`
- `+% armor`, `+% evasion`, `+% resist all`, `+% single resist`
- `+flat accuracy`, `+resource regen`, `+ailment chance`, `+dot damage`
- `+block chance`, `+leech rate`

Build 12 medium templates x 9 variants = 108 medium nodes:
- Hybrid pairs like:
  - `+12% melee dmg, +5% attack speed`
  - `+14% spell dmg, +10 INT`
  - `+10% life, +10% armor`
  - `+12% crit chance, +12% crit multi`
  - `+8% all res, +1 mana/sec`

Build 30 handcrafted notables + 6 handcrafted keystones.

Total: `180 + 108 + 30 + 6 = 324`.

### Generation Steps
1. Place 6 keystones at outer ring anchors.
2. Place 30 notables (6 per region).
3. Fill each region with medium nodes on major paths.
4. Fill remaining connectors with small nodes.
5. Validate graph:
   - All nodes reachable from start.
   - Average path to first notable <= 6 points.
   - At least 3 distinct routes to each keystone.

### Example Generated Nodes
- `might_small_07`: `+10% increased melee damage`
- `finesse_small_14`: `+12% increased evasion rating`
- `sorcery_medium_03`: `+14% spell damage, +8% cast speed`
- `survival_medium_08`: `+8% max life, +12% armor`
- `control_notable_02`: `+25% ailment effect, +15% damage vs affected enemies`

---

## Progression Pacing (Levels 1-50)

### Intended Power Milestones
- **L1-10**: establish core skill + resource sustain.
  - Time: 8-12 min
  - Passive points: 9
  - Expected tree state: first notable reached.
- **L11-20**: first specialization online.
  - Time: +8-10 min
  - Passive points: +10
  - Expected: one offense lane + one defense lane.
- **L21-35**: build identity spikes.
  - Time: +10-14 min
  - Passive points: +15
  - Expected: 2-3 notables, maybe 1 keystone.
- **L36-50**: capstone scaling and risk.
  - Time: +8-12 min
  - Passive points: +14
  - Expected: second region reach, 1-2 keystones total.

### Balance Targets
- Player TTK vs normal enemy: 1.5-3.0 sec.
- Elite: 4-8 sec.
- Boss: 45-90 sec.
- Incoming damage should force flask/positioning every 6-10 sec in combat at midgame.

---

## Monster Scaling

### Per Floor Baseline
Let floor index `f` start at 1.

- `MonsterLevel = f`
- `FloorHPScale(f) = 1 + 0.18*(f-1) + 0.02*(f-1)^2`
- `FloorDmgScale(f) = 1 + 0.12*(f-1) + 0.015*(f-1)^2`
- `FloorArmorScale(f) = 1 + 0.10*(f-1)`
- `FloorResScale(f) = min(0.45, 0.01*(f-1))` as added elemental resist

Rarity multipliers:
- Normal: `HP x1.0`, `DMG x1.0`
- Magic: `HP x1.6`, `DMG x1.25`
- Rare: `HP x2.8`, `DMG x1.6`
- Boss: `HP x8.0`, `DMG x2.1`

### Archetype Multipliers
- Brute: `HP x1.3`, `DMG x1.1`, `Armor x1.4`, `Evasion x0.7`
- Scout: `HP x0.85`, `DMG x0.9`, `Armor x0.8`, `Evasion x1.8`
- Caster: `HP x0.9`, `DMG x1.35`, `Armor x0.8`, `Resist x1.3`

Rationale: quadratic floor growth keeps later floors threatening without requiring huge absolute numbers early.

---

## UX Flow for Level-Up Choices

1. On level-up, pause combat and open tree overlay.
2. Highlight all currently allocatable nodes (connected and unspent).
3. Show compact delta preview on hover:
   - `DPS`, `EHP`, `resource sustain` estimate.
4. One-click allocate (or hold to confirm on controller).
5. If point unspent, remind at next room entrance with small toast.
6. Every 10 levels: modal with 3 random Ascendancy-style notable choices; pick one immediately.

Prototype UX constraints:
- No respec UI initially; allow debug key to refund all for testing.
- Use color coding by tag (offense red, defense blue, utility green, resource purple).

Implementation note: keep all stat mods additive/multiplicative via a central `StatAggregator` to avoid per-node special-case code.
