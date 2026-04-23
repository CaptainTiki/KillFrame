extends RefCounted

const CELL_SIZE_XZ_METERS: float = 1.0
const HEIGHT_STEP_METERS: float = 2.0
const INVALID_RAMP_DIR: int = -1

# ramp_dir points in the direction units travel to go up the ramp.
# The cell keeps the higher terrain height_level for that ramp tile.

enum RampDirection {
	NORTH,
	EAST,
	SOUTH,
	WEST,
}

enum BlockerType {
	NONE,
	ROCKS,
	DEBRIS,
	STRUCTURE,
}

enum SurfaceType {
	DIRT,
	BASE_PAD,
	ROUGH_GROUND,
	PLATEAU_ROCK,
}
