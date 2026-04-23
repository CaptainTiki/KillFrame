# Terrain Bake Plan

## Goal

Keep terrain authored in the editor with a `GridMap`, then bake gameplay terrain data into a `.tres` resource so runtime only loads and queries data instead of rescanning or generating terrain.

## Plan

1. Keep the `GridMap` as the authored visual terrain.
   - Paint terrain directly in the level under `TerrainManager`.
   - The `GridMap` remains the source for visuals and layout authoring.

2. Bake gameplay terrain into a level-specific `.tres` resource.
   - Add a manual `Bake Terrain Data` action on `TerrainManager`.
   - Baking scans the painted `GridMap` and saves a terrain data resource for that level.
   - Runtime reads the baked resource instead of rescanning the `GridMap`.

3. Use two resources.
   - `TerrainTileData`
     - `height`
     - `walkable`
     - `buildable`
     - `exit_mask`
     - optional `tile_kind` / `rotation` for debugging
   - `LevelTerrainData`
     - `origin`
     - `width`
     - `height`
     - cell map of `(x, z) -> TerrainTileData`

4. Store one tile record per occupied terrain cell.
   - Avoid multiple synced arrays for walkable/buildable/height.
   - One tile struct owns the gameplay data for that cell.

5. Derive traversal rules from terrain piece type plus rotation.
   - Floor cube: all 4 exits
   - Slope / corner pieces: exits based on rotation
   - `exit_mask` stores only `N/E/S/W`

6. Allow diagonal traversal at pathfinding time.
   - Diagonals are derived from the cardinal exits, not stored directly.
   - A diagonal move is valid only when the needed cardinal connections exist.
   - This gives us 8-direction movement without duplicating data.

7. Build pathfinding from baked terrain data.
   - Use A* over the baked cell graph.
   - `TerrainManager` should expose helpers for:
     - world position -> cell
     - cell -> world position
     - nearest walkable cell
     - path query

8. Route move clicks through terrain cells.
   - Mouse click hits the world.
   - Convert the hit to a terrain cell.
   - Snap or fall back to the nearest valid walkable cell if needed.
   - Units follow a path instead of moving in a straight line to the raw click position.

9. Keep `walkable` and `buildable` separate.
   - They may overlap for some tiles, but they are not the same gameplay concept.
   - Initial rule:
     - flat tiles: buildable
     - transition / slope tiles: walkable, not buildable

10. Runtime target.
    - Runtime only loads:
      - level scene
      - baked terrain data
    - No terrain generation, no scanner pipeline, and no editor-only rebuild logic at runtime.

## First Implementation Order

1. Create `TerrainTileData` and `LevelTerrainData`
2. Add bake button and save flow in `TerrainManager`
3. Generate `exit_mask` from tile type and rotation
4. Load baked terrain data at runtime
5. Add A* pathfinding
6. Hook move orders into path-following
7. Update placement to use `buildable`
