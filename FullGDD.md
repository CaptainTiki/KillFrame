\# NETSHIELD: Firewall Protocol

\*\*Full Game Design Document\*\*



\*\*Version:\*\* 0.2 (Full Game Vision)  

\*\*Date:\*\* April 21, 2026  

\*\*Genre:\*\* Old-School Single-Player RTS with Deep Modular Creativity  

\*\*Art Style:\*\* Stylized Lowpoly 3D, Neon Digital Grid (Ready Player One / Tron / inside-the-computer aesthetic)  

\*\*Target Platform:\*\* PC (Godot or Unity)  

\*\*Scope Philosophy:\*\* Extremely limited art assets — everything is highly modular and reusable. Creativity comes from systems and player-designed units, not new models.



\---



\## 1. High Concept

You are the \*\*Firewall AI\*\* — the last line of defense inside a vast digital network. Each mission is a tactical battle fought on glowing server platforms floating in an endless sea of “Liquid Internet.”



The game is a \*\*pure old-school RTS\*\* at its core (select units → move → attack, nothing else).  

But it adds one massive layer of player creativity: a \*\*full modular “tinkertoy/LEGO” unit and building designer\*\*. You literally invent your own army and base layout every game, using a tiny shared pool of lowpoly pieces.



\*\*Core Fantasy:\*\*  

You are both the commander \*and\* the battlefield engineer. Deploy into a mission, root your core as the HQ, then design, build, and evolve your forces on the fly while defending the network from rival AIs and intrusions.



\*\*Tagline:\*\* “Design. Deploy. Defend.”



\---



\## 2. Core Gameplay Loop

1\. Load into your persistent \*\*3D Firewall Core Hub\*\* (navigable 3D base).  

2\. Walk around as your Engineer avatar, check story logs, spend meta resources, and choose a mission.  

3\. At the \*\*Deployment Ring\*\*, you are given a mission-specific starting resource pool (Crystals + Bits). You decide exactly what to deploy.  

4\. Mission starts: Engineer runs out of the ring → instantly transforms into your first HQ (free, instant, and your lifeline).  

5\. Harvest resources, design new units/buildings, expand, fight.  

6\. Complete objectives → return to Hub with \*\*Protocol Fragments\*\* for permanent upgrades and story progression.



\---



\## 3. Single-Player Campaign \& Hub

\- \*\*Persistent 3D Hub (Firewall Core)\*\*: A small but growing neon-lit digital room/base.  

&#x20; - Engineer avatar walks around (pure flavor — no combat).  

&#x20; - Interactive stations:  

&#x20;   - Holographic Mission Table (select next mission)  

&#x20;   - Research \& Module Unlock Console  

&#x20;   - Armory (view and manage saved unit designs)  

&#x20;   - Data Log Archive (story journals, lore)  

&#x20;   - Upgrade Terminal (spend Protocol Fragments)  

&#x20;   - Deployment Ring (the teleporter that starts every mission)



\- \*\*Campaign Structure\*\*: Linear with light branching. 8–12 missions that escalate in scale and introduce new modules/hulls. Story told through briefings, data logs, and in-mission events (defending key servers, stopping data breaches, corporate AI wars, glitch outbreaks, etc.).



\- \*\*Meta Progression\*\*: Protocol Fragments earned per mission (based on performance: speed, kills, nodes held, etc.). Spend them to unlock new hulls, locomotion types, modules, hub upgrades, and story branches.



\---



\## 4. Resources

\- \*\*Crystals\*\* – Primary “ore” resource. Static glowing crystal nodes on the map. Workers harvest automatically and return to any HQ.  

\- \*\*Bits\*\* – Secondary “vespene-style” resource.  

&#x20; - Static Bit Nodes (mineable geysers).  

&#x20; - Dropped by destroyed enemy units and buildings (small glowing data packets). Workers must physically run over and collect them — encourages aggressive worker play and scavenging.  

\- \*\*Protocol Fragments\*\* – Meta resource earned only at mission end. Spent exclusively in the Hub for permanent unlocks.



\- \*\*Supply / Population Cap\*\*: Built via \*\*Bandwidth Relay\*\* towers. Each one adds +10–12 pop cap. Cheap and fast to build.



\---



\## 5. Modular Designer (The Star Feature)

Accessed from any production building (HQ, Barracks, Factory, etc.). Full drag-and-drop interface with real-time 3D preview.



\### Unit Designer Flow

\- Choose \*\*Hull\*\* (Light / Medium / Heavy / Super-Heavy — 4 base meshes).  

\- Choose \*\*Locomotion\*\* (Wheels / Treads / Hovers / Legs — snaps to hull). Affects speed, weight limit, terrain handling.  

\- Choose \*\*Powerplant\*\* (Small / Medium / Large / Overcharged). Sets total Power Points available.  

\- Drag \*\*Modules\*\* into available hardpoints (weapons, armor, shields, utility, mobility, etc.).  

&#x20; - Every module is 1–3 lowpoly pieces that snap to attach points.  

&#x20; - Live stat feedback (speed, armor, DPS, cost, build time, weight).  

&#x20; - Illegal combos are blocked with clear tooltips.



\- \*\*Save Design\*\* → Name it and store in global Armory.  

\- Load saved designs directly into production queues in any building.  

\- Visual status: Green = ready, Yellow = missing module, Red = locked.



\### Building Designer (Snap-Kit Bases)

\- Buildings are made from modular foundations + bays + turrets + power cores.  

\- Drag-and-drop modules onto a grid to create unique factories, barracks, defensive setups.  

\- Different combinations automatically grant different bonuses or unlock new production options.



\*\*Key Rule\*\*: If an enemy destroys one of your module-unlock buildings (Weapons Lab, Armor Forge, etc.), any designs using those modules become unavailable until you rebuild it. Creates real strategic tension.



\*\*Balance Levers\*\*:

\- Weight \& Power hard caps.  

\- Diminishing returns on stacking too many of the same module.  

\- Higher-tier modules cost more resources and take longer to build.



\---



\## 6. Units \& Buildings (All Modular in Full Game)

All units and buildings start from the shared lowpoly pool. Differentiation comes from player-designed combinations and faction doctrines (small passive bonuses per faction — still zero new art).



\*\*Example Starting Units (static versions exist for early missions)\*\*:

\- Worker, Rifle Infantry, Small Vehicle (as defined in prototype).



Later everything becomes fully modular.



\*\*Buildings\*\*:

\- HQ (first one free via Engineer transformation; extras are expensive).  

\- Bandwidth Relay (supply).  

\- Modular production buildings (Barracks, Vehicle Factory, etc.).  

\- Defensive turrets and utility structures built from the same snap-kit system.



\---



\## 7. Map Design \& World

\- \*\*Modular Grid Tiles\*\*: Large 16×16 or 32×32 lowpoly tiles (flat platforms, gentle slopes, steep ramps, raised highways). Only 8–12 tile types total.  

\- \*\*World Border\*\*: Massive “Liquid Internet” plane with flowing emissive shader, binary particles, and gentle waves. Stretches hundreds of units beyond playable area.  

\- \*\*Distance Fog\*\*: Neon-colored haze that hides edges and creates an infinite digital-void feel.  

\- Maps feel like floating server platforms in raw data space.



\---



\## 8. Combat \& Depth Systems (Still Pure Old-School)

Units only move and attack — depth comes from:

\- \*\*Resonance Bonuses\*\*: Certain unit combinations near each other gain small passive buffs (visualized with subtle selection glows).  

\- \*\*Echo System\*\*: Destroyed units/buildings leave temporary “echo” ghosts that can be harvested for bonus Bits or used as light cover.  

\- \*\*Terrain Interaction\*\*: Slopes, height advantage, destructible cover pieces (made from modular kit).  

\- \*\*Suppression\*\*: Sustained fire applies stacking “pinned” debuff.



\---



\## 9. Win / Loss \& Mission Variety

\- Primary win: Destroy enemy core.  

\- Alternative victory conditions: Hold central Internet Node for X minutes, control 70% of data highways, etc.  

\- Loss: Your main HQ (the one created by the Engineer) is destroyed.



Missions include optional side objectives that reward extra Protocol Fragments.



\---



\## 10. Design Pillars \& Constraints

\- \*\*Old-School Purity\*\*: No alternate fires, no cooldown abilities, no hero units.  

\- \*\*Lowpoly \& Limited Assets\*\*: Max \~40–50 unique meshes for the entire game. Everything reuses the same pieces via snapping and recoloring.  

\- \*\*Single-Player Focus\*\*: No multiplayer. Deep, replayable campaign with meaningful progression.  

\- \*\*Emergent Creativity\*\*: The modular designer and snap-kit bases create near-infinite variety from tiny art assets.  

\- \*\*Accessibility\*\*: Clear visuals, readable silhouettes, simple controls.



\---



\## 11. Next Steps After Prototype

1\. Finish vertical prototype slice (first mission fully playable with static units).  

2\. Test core RTS feel.  

3\. Add modular designer once base gameplay is rock-solid.  

4\. Expand campaign, add resonance/echo systems, more modules, etc.



\---



\*\*This document is living.\*\* We will revise it constantly as we build and playtest.  

