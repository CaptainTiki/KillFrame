\# NETSHIELD: Architecture Guide



\*\*Version:\*\* 0.1  

\*\*Date:\*\* April 21, 2026  

\*\*Engine:\*\* Godot 4.x (GDScript)  



This document defines how we structure the project to keep it simple, reusable, and easy to work with. Any additional Architecture patterns we want to use can go here for reference as we develop



\---



\## 1. Core Philosophy



\- \*\*Component-first, not inheritance-heavy\*\*  

&#x20; We prefer composing functionality by attaching small, focused scripts (as components) to nodes instead of deep inheritance trees. A unit is a Node3D with several component scripts rather than one massive `Unit.gd` that everything inherits from.



\- \*\*.tscn-first architecture\*\*  

&#x20; Where possible, we build things as saved scenes (.tscn) instead of instantiating and configuring nodes entirely in code. This makes the editor visual, easy to preview, and reusable.



\- \*\*Co-located files\*\*  

&#x20; Every scene and its main script live in the same folder. No giant flat folders or separate “scripts/” and “scenes/” directories.



\---



\## 2. Component-First Approach



Every major game object is a \*\*Node3D\*\* (or Node2D for UI) with small, single-responsibility component scripts attached.



\*\*Example pattern:\*\*

\- `Unit.tscn` (base scene)

&#x20; - Root: Node3D named “Unit”

&#x20; - Child: MeshInstance3D (visual)

&#x20; - Child: CollisionShape3D

&#x20; - Attached scripts:

&#x20;   - `health\_component.gd`

&#x20;   - `movement\_component.gd`

&#x20;   - `attack\_component.gd` (for units that can fight)



This lets us reuse the same components across Worker, Infantry, Small Vehicle, etc. without inheritance.



\---



\## 3. Scene-Based Architecture



We build and save as many things as possible as reusable .tscn scenes:



\- Individual units (Worker.tscn, RifleInfantry.tscn, SmallVehicle.tscn)

\- Buildings (HQ.tscn, BandwidthRelay.tscn, Barracks.tscn, etc.)

\- Map tiles (FlatPlatform\_32x32.tscn, Slope\_Up.tscn, Ramp.tscn, etc.)

\- Effects / visuals (DataPacketPickup.tscn, EngineerDeployEffect.tscn)

\- UI elements (ResourceCounter.tscn, DeploymentRing.tscn)



\*\*Key Rule:\*\*  

If something can be built visually in the editor and saved as a scene, we do it that way instead of spawning nodes from code.



\---



\## 4. File Structure (Co-located)



All scenes and their primary script stay together



\---



\## 5. Specific Examples Already Planned



\- \*\*Engineer → HQ transformation\*\*  

&#x20; Engineer is a simple scene (`engineer.tscn`) that plays a short animation then queues a free `HQ.tscn` to replace itself at the same position.



\- \*\*Units\*\*  

&#x20; Each unit is its own .tscn with the three components listed above attached.



\- \*\*Map\*\*  

&#x20; Built by placing large modular tile scenes in the editor (no procedural code for the prototype).





