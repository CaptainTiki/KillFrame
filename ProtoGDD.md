# NETSHIELD: Firewall Protocol
**Game Design Document**

**Version:** 0.1 (Prototype + Full Vision)  
**Date:** April 21, 2026  
**Genre:** Old-School Single-Player RTS  
**Art Style:** Stylized Lowpoly 3D, Neon Digital Grid (Ready Player One / Tron inspired)

---

## 1. PROTOTYPE GAME DESIGN DOCUMENT

### 1.1 High Concept
You are the Firewall AI defending digital networks from rival programs and intrusions. Each mission takes place inside a server as a classic Command & Conquer style RTS. Simple, pure gameplay: select units, move, attack, build, expand, and destroy the enemy core.

No hero units, no special abilities — just old-school RTS fundamentals.

### 1.2 Core Gameplay Loop
1. Enter 3D Hub Base  
2. Choose mission via holographic interface  
3. Deploy starting force through the Deployment Ring  
4. Engineer deploys → transforms into first HQ (free and instant)  
5. Harvest resources, build base, produce units, expand  
6. Destroy enemy core to win  
7. Return to Hub with earned Protocol Fragments

### 1.3 Single Player Hub
- Small 3D navigable base (Firewall Core)  
- Player controls a simple Engineer avatar (non-combat, flavor only)  
- Interactive stations:  
  - Mission Selection Table  
  - Research & Upgrades Panel  
  - Story / Data Logs  
  - Deployment Ring (teleporter)

### 1.4 Resources
- **Crystals** – Primary resource. Harvested from static glowing crystal nodes by workers.  
- **Bits** – Secondary resource.  
  - Harvested from static Bit Nodes  
  - Dropped by destroyed enemy units and buildings (must be collected by workers)  
- **Protocol Fragments** – Meta progression resource. Earned at end of missions and spent in the Hub for permanent unlocks.

- **Supply:** Bandwidth Relay building (increases population cap)

### 1.5 Units (Static for Prototype)
- **Worker**  
  Medium-slow speed, low health, no attack. Cost: 10 Crystals  
- **Rifle Infantry**  
  Slightly faster than worker, med-low health, short-range low damage attack. Cost: 15 Crystals  
- **Small Vehicle (Scout)**  
  Medium-high speed, low health, medium-range attack. Cost: 25 Crystals (+ Bits later)

### 1.6 Buildings
- **HQ** – First one created instantly by Engineer transformation (free). Additional HQs are expensive and slow to build.  
- **Bandwidth Relay** – Supply building  
- **Barracks** – Produces infantry  
- **Vehicle Factory** – Produces vehicles  
- **Energy Relay** – Power/tech building (if needed)

### 1.7 Map Design
- Large modular grid tiles (flat platforms, slopes, ramps)  
- World border = "Liquid Internet" glowing plane with flowing shader + distance fog  
- Clean digital aesthetic with glowing grid lines

### 1.8 Win / Loss Conditions
- Win: Destroy enemy core  
- Loss: Main HQ destroyed

---