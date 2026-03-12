extends Node

const RunWorldGenerator = preload("res://systems/worldgen/run_world_generator.gd")

signal mode_changed(mode_name: String)
signal status_changed(message: String)
signal connection_ready()
signal client_connect_failed()
signal client_disconnected()
signal session_phase_changed(phase: String)
signal boat_blueprint_changed(snapshot: Dictionary)
signal peer_snapshot_changed(snapshot: Dictionary)
signal hangar_avatar_state_changed(snapshot: Dictionary)
signal run_avatar_state_changed(snapshot: Dictionary)
signal reaction_state_changed(snapshot: Dictionary)
signal run_seed_changed(seed: int)
signal helm_changed(driver_peer_id: int)
signal boat_state_changed(state: Dictionary)
signal hazard_state_changed(hazards: Array)
signal station_state_changed(stations: Dictionary)
signal loot_state_changed(loot_targets: Array)
signal run_state_changed(state: Dictionary)
signal progression_state_changed(snapshot: Dictionary)

enum Mode {
	OFFLINE,
	CLIENT,
	SERVER,
}

const SESSION_PHASE_HANGAR := "hangar"
const SESSION_PHASE_RUN := "run"
const STATION_ORDER := ["helm", "drive", "brace", "grapple", "repair"]
const STATION_CLAIMABLE_ORDER := ["helm", "drive", "grapple"]
const STATION_LAYOUT := {
	"helm": {
		"label": "Helm",
		"position": Vector3(0.0, 0.92, -1.4),
	},
	"drive": {
		"label": "Drive Console",
		"position": Vector3(-0.15, 0.92, -0.25),
	},
	"brace": {
		"label": "Brace Station",
		"position": Vector3(-0.95, 0.92, 0.1),
	},
	"grapple": {
		"label": "Grapple Crane",
		"position": Vector3(0.95, 0.92, 0.45),
	},
	"repair": {
		"label": "Repair Bench",
		"position": Vector3(-0.95, 0.92, 1.05),
	},
}
const HANGAR_TOOLBELT := [
	{
		"id": "build",
		"label": "Build",
		"icon": "reinforced-hull",
		"hint": "Place the selected part into the aimed cell.",
	},
	{
		"id": "remove",
		"label": "Remove",
		"icon": "salvage",
		"hint": "Scrap the targeted block from the shared blueprint.",
	},
	{
		"id": "yard",
		"label": "Workshop",
		"icon": "gold",
		"hint": "Review your stash, donate to the host workshop, and craft new boat options.",
	},
]
const RUN_TOOLBELT := [
	{
		"id": "helm",
		"label": "Helm",
		"icon": "helm",
		"hint": "Claim the wheel when you are inside the helm zone.",
	},
	{
		"id": "drive",
		"label": "Drive",
		"icon": "twin-engine",
		"hint": "Work the propulsion package so helm intent turns into real thrust.",
	},
	{
		"id": "brace",
		"label": "Brace",
		"icon": "brace",
		"hint": "Brace anywhere on deck to resist impacts and surges.",
	},
	{
		"id": "grapple",
		"label": "Grapple",
		"icon": "salvage",
		"hint": "Work the crane to recover salvage, rescue lines, and cache pulls.",
	},
	{
		"id": "repair",
		"label": "Repair",
		"icon": "repair-kit",
		"hint": "Patch nearby damaged hull sections using shared kits.",
	},
	{
		"id": "recover",
		"label": "Recover",
		"icon": "extraction",
		"hint": "Climb back aboard from a ladder or stern line when overboard.",
	},
]
const BUILDER_CELL_SIZE := 1.25
const BUILDER_WORLD_ORIGIN := Vector3(0.0, 0.1, 0.0)
const BUILDER_BOUNDS_MIN := Vector3i(-5, 0, -6)
const BUILDER_BOUNDS_MAX := Vector3i(5, 4, 6)
const HANGAR_BUILD_RANGE := 5.25
const HANGAR_SPAWN_POINTS := [
	Vector3(-3.6, 0.55, 6.8),
	Vector3(-1.2, 0.55, 6.4),
	Vector3(1.2, 0.55, 6.4),
	Vector3(3.6, 0.55, 6.8),
]
const RUN_DECK_SPAWN_POINTS := [
	Vector3(0.0, 0.92, 1.35),
	Vector3(-1.0, 0.92, 1.05),
	Vector3(1.0, 0.92, 1.05),
	Vector3(0.0, 0.92, 2.0),
]
const RUN_DECK_BOUNDS_MIN := Vector3(-1.18, 0.72, -1.92)
const RUN_DECK_BOUNDS_MAX := Vector3(1.18, 1.28, 2.08)
const RUN_HELM_ZONE_RADIUS := 1.15
const RUN_HELM_RELEASE_RADIUS := 1.55
const RUN_DRIVE_ZONE_RADIUS := 1.0
const RUN_DRIVE_RELEASE_RADIUS := 1.32
const RUN_GRAPPLE_ZONE_RADIUS := 0.92
const RUN_GRAPPLE_RELEASE_RADIUS := 1.18
const RUN_REPAIR_RANGE := 1.32
const RUN_REPAIR_HEAL_RADIUS := 1.2
const PROPULSION_FAMILY_RAFT_PADDLES := "raft_paddles"
const PROPULSION_FAMILY_SAIL_RIG := "sail_rig"
const PROPULSION_FAMILY_STEAM_TUG := "steam_tug"
const PROPULSION_FAMILY_TWIN_ENGINE := "twin_engine"
const PROPULSION_FAULT_STATE_STABLE := "stable"
const PROPULSION_FAULT_STATE_LABORING := "laboring"
const PROPULSION_FAULT_STATE_OVERHEATED := "overheated"
const PROPULSION_FAULT_STATE_OVERPRESSURE := "overpressure"
const PROPULSION_FAULT_STATE_DESYNC := "desync"
const PROPULSION_FAULT_STATE_CRIPPLED := "crippled"
const PROPULSION_SUPPORT_ACTION_SECONDS := 2.4
const PROPULSION_SECONDARY_ACTION_SECONDS := 1.8
const PROPULSION_FAULT_RECOVERY_RATE := 0.16
const PROPULSION_DAMAGE_RECOVERY_RATE := 1.1
const PROPULSION_DAMAGE_COLLISION_UNBRACED := 11.0
const PROPULSION_DAMAGE_COLLISION_BRACED := 5.0
const PROPULSION_DAMAGE_SQUALL_UNBRACED := 6.0
const PROPULSION_DAMAGE_SQUALL_BRACED := 2.5
const PROPULSION_DAMAGE_BACKLASH := 8.0
const PROPULSION_DAMAGE_DETACHMENT := 12.0
const PROPULSION_MANUAL_PADDLE_STAMINA_COST := 12.0
const PROPULSION_RUDDER_RESPONSE_BASE := 0.72
const PROPULSION_BURST_SPEED_MULTIPLIER := 1.15
const RUN_PRESSURE_PHASE_CALM := "calm"
const RUN_PRESSURE_PHASE_STRAINED := "strained"
const RUN_PRESSURE_PHASE_CRITICAL := "critical"
const RUN_PRESSURE_PHASE_CASCADE := "cascade"
const RUN_PRESSURE_PHASE_COLLAPSE := "collapse"
const MATERIAL_ORDER := [
	"scrap_metal",
	"treated_planks",
	"rigging",
	"machined_parts",
	"boiler_parts",
	"shock_insulation",
]
const MATERIAL_LABELS := {
	"scrap_metal": "Scrap Metal",
	"treated_planks": "Treated Planks",
	"rigging": "Rigging",
	"machined_parts": "Machined Parts",
	"boiler_parts": "Boiler Parts",
	"shock_insulation": "Shock Insulation",
}
const MATERIAL_ICON_IDS := {
	"scrap_metal": "reinforced-hull",
	"treated_planks": "cargo",
	"rigging": "stabilizer",
	"machined_parts": "twin-engine",
	"boiler_parts": "repair-kit",
	"shock_insulation": "brace",
	"gold": "gold",
	"schematic": "salvage",
}
const BUILDER_OVERLAY_ORDER := [
	"none",
	"pathing",
	"recovery",
	"repair",
	"propulsion",
	"redundancy",
	"safety",
]
const BUILDER_BLOCK_ORDER := [
	"core",
	"hull",
	"deck_plate",
	"keel_hull",
	"reinforced_hull",
	"reinforced_prow",
	"light_crane",
	"heavy_winch",
	"harpoon_crane",
	"ladder_rig",
	"guard_rail",
	"rescue_net",
	"engine",
	"sail_rig",
	"twin_engine",
	"auxiliary_kicker",
	"high_pressure_boiler",
	"cargo",
	"utility",
	"utility_bay",
	"repair_bay",
	"brace_frame",
	"stabilizer",
	"outtrigger_beam",
	"armored_housing",
	"shock_bulkhead",
	"catamaran_beam",
	"structure",
]
const BUILDER_BLOCK_LIBRARY := {
	"core": {
		"label": "Core",
		"description": "The shared heart of the boat. Losing the main core chunk is a bad day.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "hull",
		"color": Color(0.84, 0.30, 0.24),
		"size": Vector3(1.05, 1.05, 1.05),
		"max_hp": 34.0,
		"weight": 3.0,
		"buoyancy": 5.5,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.08,
		"hull": 1.0,
		"drag": 0.7,
		"stability": 4.0,
		"safety": 4.0,
		"redundancy": 3.0,
		"walkable": true,
	},
	"hull": {
		"label": "Hull",
		"description": "Basic float support for everyday builds.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "hull",
		"color": Color(0.54, 0.35, 0.20),
		"size": Vector3(1.2, 0.8, 1.2),
		"max_hp": 24.0,
		"weight": 2.1,
		"buoyancy": 5.2,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.03,
		"hull": 1.0,
		"drag": 0.9,
		"stability": 2.6,
		"safety": 1.4,
		"redundancy": 1.0,
		"walkable": true,
	},
	"deck_plate": {
		"label": "Deck Plate",
		"description": "Cheap walkable plating that improves routeing across awkward hulls.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "structure",
		"color": Color(0.63, 0.67, 0.71),
		"size": Vector3(1.18, 0.38, 1.18),
		"max_hp": 14.0,
		"weight": 1.0,
		"buoyancy": 0.9,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.02,
		"hull": 0.42,
		"drag": 0.15,
		"stability": 1.0,
		"safety": 2.0,
		"redundancy": 1.0,
		"walkable": true,
	},
	"keel_hull": {
		"label": "Keel Hull",
		"description": "A centerline hull section that tracks cleanly and boosts turn control on lean builds.",
		"unlockable": true,
		"unlock_tier": 1,
		"unlock_cost_gold": 60,
		"unlock_cost_salvage": 0,
		"category": "hull",
		"color": Color(0.46, 0.31, 0.18),
		"size": Vector3(1.04, 0.92, 1.28),
		"max_hp": 28.0,
		"weight": 2.4,
		"buoyancy": 5.8,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.05,
		"hull": 1.2,
		"drag": 0.75,
		"stability": 3.0,
		"safety": 1.8,
		"redundancy": 1.1,
		"walkable": true,
	},
	"reinforced_hull": {
		"label": "Reinforced Hull",
		"description": "Heavier plating for crews that want more hull and buoyancy margin.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 55,
		"unlock_cost_salvage": 1,
		"category": "hull",
		"color": Color(0.42, 0.30, 0.18),
		"size": Vector3(1.28, 0.9, 1.28),
		"max_hp": 34.0,
		"weight": 3.1,
		"buoyancy": 6.6,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.05,
		"hull": 1.55,
		"drag": 1.15,
		"stability": 3.6,
		"safety": 2.6,
		"redundancy": 1.3,
		"walkable": true,
		"propulsion_cover": 0.2,
	},
	"reinforced_prow": {
		"label": "Reinforced Prow",
		"description": "Forward armor for impact-heavy routes that protects the machine from bad entries.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 110,
		"unlock_cost_salvage": 1,
		"category": "hull",
		"color": Color(0.50, 0.34, 0.19),
		"size": Vector3(1.08, 0.98, 1.08),
		"max_hp": 36.0,
		"weight": 3.0,
		"buoyancy": 3.4,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.08,
		"hull": 1.7,
		"drag": 0.9,
		"stability": 2.0,
		"safety": 2.8,
		"redundancy": 1.4,
		"walkable": true,
		"propulsion_cover": 0.12,
	},
	"light_crane": {
		"label": "Light Crane",
		"description": "Starter salvage station. Keeps a basic grapple available on any legal hull.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "salvage",
		"color": Color(0.77, 0.56, 0.18),
		"size": Vector3(0.92, 1.18, 0.92),
		"max_hp": 20.0,
		"weight": 2.0,
		"buoyancy": 1.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.04,
		"hull": 0.42,
		"drag": 0.25,
		"stability": 1.0,
		"safety": 1.0,
		"redundancy": 0.6,
		"walkable": true,
		"salvage_station": true,
		"salvage_rating": 1.0,
		"station_role": "grapple",
	},
	"heavy_winch": {
		"label": "Heavy Winch",
		"description": "A safer heavy salvage rig that cuts backlash and stabilizes violent pulls.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 130,
		"unlock_cost_salvage": 2,
		"category": "salvage",
		"color": Color(0.66, 0.49, 0.16),
		"size": Vector3(1.06, 1.18, 1.04),
		"max_hp": 24.0,
		"weight": 3.2,
		"buoyancy": 1.3,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.08,
		"hull": 0.56,
		"drag": 0.35,
		"stability": 2.0,
		"safety": 1.6,
		"redundancy": 0.8,
		"walkable": true,
		"salvage_station": true,
		"salvage_rating": 1.35,
		"salvage_backlash_multiplier": 0.72,
		"station_role": "grapple",
	},
	"harpoon_crane": {
		"label": "Harpoon Crane",
		"description": "Longer reach salvage gear with a sharper ceiling and rougher punishment when misplayed.",
		"unlockable": true,
		"unlock_tier": 3,
		"unlock_cost_gold": 170,
		"unlock_cost_salvage": 3,
		"category": "salvage",
		"color": Color(0.72, 0.44, 0.16),
		"size": Vector3(0.96, 1.24, 0.96),
		"max_hp": 19.0,
		"weight": 2.7,
		"buoyancy": 0.9,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.03,
		"hull": 0.38,
		"drag": 0.32,
		"stability": 0.8,
		"safety": 0.8,
		"redundancy": 0.5,
		"walkable": true,
		"salvage_station": true,
		"salvage_rating": 1.55,
		"salvage_backlash_multiplier": 1.12,
		"station_role": "grapple",
	},
	"ladder_rig": {
		"label": "Ladder Rig",
		"description": "Side recovery access that makes overboard rescues less punishing and easier to reach.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "recovery",
		"color": Color(0.30, 0.72, 0.62),
		"size": Vector3(0.72, 1.06, 0.46),
		"max_hp": 14.0,
		"weight": 0.8,
		"buoyancy": 0.6,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.02,
		"hull": 0.18,
		"drag": 0.08,
		"stability": 0.8,
		"safety": 6.0,
		"redundancy": 0.7,
		"walkable": false,
		"recovery_access": 1.0,
		"recovery_type": "side",
	},
	"guard_rail": {
		"label": "Guard Rail",
		"description": "Light edge protection that improves crew safety on exposed decks.",
		"unlockable": true,
		"unlock_tier": 1,
		"unlock_cost_gold": 50,
		"unlock_cost_salvage": 0,
		"category": "recovery",
		"color": Color(0.64, 0.72, 0.78),
		"size": Vector3(1.0, 0.54, 0.18),
		"max_hp": 10.0,
		"weight": 0.5,
		"buoyancy": 0.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.01,
		"hull": 0.12,
		"drag": 0.05,
		"stability": 0.4,
		"safety": 8.0,
		"redundancy": 0.4,
		"walkable": false,
	},
	"rescue_net": {
		"label": "Rescue Net",
		"description": "A stern catch net that widens recovery windows and calms late-run rescue pressure.",
		"unlockable": true,
		"unlock_tier": 3,
		"unlock_cost_gold": 160,
		"unlock_cost_salvage": 2,
		"category": "recovery",
		"color": Color(0.22, 0.66, 0.54),
		"size": Vector3(1.18, 0.54, 0.42),
		"max_hp": 14.0,
		"weight": 1.1,
		"buoyancy": 0.5,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.04,
		"hull": 0.2,
		"drag": 0.05,
		"stability": 0.6,
		"safety": 9.0,
		"redundancy": 0.8,
		"walkable": false,
		"recovery_access": 1.4,
		"recovery_type": "stern",
	},
	"engine": {
		"label": "Engine",
		"description": "Reliable starter thrust for the main hull.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "propulsion",
		"color": Color(0.27, 0.34, 0.38),
		"size": Vector3(1.0, 0.9, 1.2),
		"max_hp": 18.0,
		"weight": 2.5,
		"buoyancy": 1.8,
		"thrust": 1.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.0,
		"hull": 0.35,
		"propulsion_family": PROPULSION_FAMILY_STEAM_TUG,
		"drag": 0.7,
		"stability": 0.2,
		"safety": -1.2,
		"redundancy": 0.4,
		"propulsion_component": true,
		"walkable": true,
	},
	"sail_rig": {
		"label": "Sail Rig",
		"description": "Wind-hungry canvas that trades raw response for efficient cruising.",
		"unlockable": true,
		"unlock_tier": 1,
		"unlock_cost_gold": 68,
		"unlock_cost_salvage": 1,
		"category": "propulsion",
		"color": Color(0.86, 0.84, 0.72),
		"size": Vector3(0.9, 1.8, 0.9),
		"max_hp": 16.0,
		"weight": 1.4,
		"buoyancy": 0.6,
		"thrust": 1.2,
		"cargo": 0,
		"repair": 0,
		"brace": -0.03,
		"hull": 0.22,
		"propulsion_family": PROPULSION_FAMILY_SAIL_RIG,
		"drag": 0.18,
		"stability": -1.0,
		"safety": -0.8,
		"redundancy": 0.3,
		"propulsion_component": true,
		"walkable": true,
	},
	"twin_engine": {
		"label": "Twin Engine",
		"description": "A louder, faster drive block that trades sturdiness for speed.",
		"unlockable": true,
		"unlock_tier": 3,
		"unlock_cost_gold": 70,
		"unlock_cost_salvage": 3,
		"category": "propulsion",
		"color": Color(0.20, 0.25, 0.29),
		"size": Vector3(1.18, 0.96, 1.26),
		"max_hp": 16.0,
		"weight": 3.3,
		"buoyancy": 1.6,
		"thrust": 1.75,
		"cargo": 0,
		"repair": 0,
		"brace": -0.02,
		"hull": 0.3,
		"propulsion_family": PROPULSION_FAMILY_TWIN_ENGINE,
		"drag": 0.88,
		"stability": -0.4,
		"safety": -1.8,
		"redundancy": 0.5,
		"propulsion_component": true,
		"walkable": true,
	},
	"auxiliary_kicker": {
		"label": "Auxiliary Kicker",
		"description": "A light backup drive that improves recovery from faults and makes hybrid hulls easier to save.",
		"unlockable": true,
		"unlock_tier": 4,
		"unlock_cost_gold": 210,
		"unlock_cost_salvage": 4,
		"category": "propulsion",
		"color": Color(0.25, 0.31, 0.35),
		"size": Vector3(0.72, 0.76, 0.86),
		"max_hp": 14.0,
		"weight": 1.4,
		"buoyancy": 0.8,
		"thrust": 0.35,
		"cargo": 0,
		"repair": 0,
		"brace": 0.0,
		"hull": 0.18,
		"drag": 0.26,
		"stability": 0.1,
		"safety": -0.4,
		"redundancy": 0.9,
		"propulsion_component": true,
		"walkable": true,
	},
	"high_pressure_boiler": {
		"label": "High-Pressure Boiler",
		"description": "An ambitious steam package with stronger peak output and a much nastier fault profile.",
		"unlockable": true,
		"unlock_tier": 4,
		"unlock_cost_gold": 280,
		"unlock_cost_salvage": 5,
		"category": "propulsion",
		"color": Color(0.33, 0.36, 0.38),
		"size": Vector3(1.18, 1.18, 1.18),
		"max_hp": 18.0,
		"weight": 3.6,
		"buoyancy": 1.2,
		"thrust": 1.35,
		"cargo": 0,
		"repair": 0,
		"brace": -0.02,
		"hull": 0.34,
		"drag": 0.82,
		"stability": 0.0,
		"safety": -1.6,
		"redundancy": 0.4,
		"propulsion_component": true,
		"walkable": true,
		"propulsion_family": PROPULSION_FAMILY_STEAM_TUG,
	},
	"cargo": {
		"label": "Cargo",
		"description": "Adds space for salvage at the cost of extra weight.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "cargo",
		"color": Color(0.82, 0.62, 0.22),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 16.0,
		"weight": 1.8,
		"buoyancy": 1.6,
		"thrust": 0.0,
		"cargo": 2,
		"repair": 0,
		"brace": 0.0,
		"hull": 0.3,
		"drag": 0.95,
		"stability": -1.6,
		"safety": -3.6,
		"redundancy": 0.4,
		"walkable": true,
	},
	"utility": {
		"label": "Utility",
		"description": "General-purpose support gear for patch kits and brace help.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "support",
		"color": Color(0.24, 0.62, 0.50),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 20.0,
		"weight": 1.6,
		"buoyancy": 1.9,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 1,
		"brace": 0.18,
		"hull": 0.5,
		"drag": 0.22,
		"stability": 1.0,
		"safety": 3.0,
		"redundancy": 0.9,
		"repair_zone": 0.45,
		"brace_zone": 0.3,
		"walkable": true,
	},
	"utility_bay": {
		"label": "Utility Bay",
		"description": "Improves deck logistics, routeing, and crew recovery without specializing too hard.",
		"unlockable": true,
		"unlock_tier": 1,
		"unlock_cost_gold": 80,
		"unlock_cost_salvage": 0,
		"category": "support",
		"color": Color(0.22, 0.70, 0.56),
		"size": Vector3(1.02, 1.0, 1.02),
		"max_hp": 20.0,
		"weight": 1.7,
		"buoyancy": 1.9,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 1,
		"brace": 0.12,
		"hull": 0.48,
		"drag": 0.2,
		"stability": 1.2,
		"safety": 4.0,
		"redundancy": 1.2,
		"repair_zone": 0.5,
		"brace_zone": 0.2,
		"walkable": true,
	},
	"repair_bay": {
		"label": "Repair Bay",
		"description": "A real patch zone that expands repair reach and shortens long damage-control runs.",
		"unlockable": true,
		"unlock_tier": 1,
		"unlock_cost_gold": 70,
		"unlock_cost_salvage": 0,
		"category": "support",
		"color": Color(0.20, 0.58, 0.48),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 18.0,
		"weight": 1.8,
		"buoyancy": 1.6,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 2,
		"brace": 0.06,
		"hull": 0.44,
		"drag": 0.2,
		"stability": 0.8,
		"safety": 2.4,
		"redundancy": 1.0,
		"repair_zone": 0.9,
		"walkable": true,
	},
	"brace_frame": {
		"label": "Brace Frame",
		"description": "Shock hardware that calms impacts and makes universal brace actions more forgiving.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 100,
		"unlock_cost_salvage": 1,
		"category": "support",
		"color": Color(0.19, 0.56, 0.70),
		"size": Vector3(0.94, 1.02, 0.94),
		"max_hp": 20.0,
		"weight": 1.9,
		"buoyancy": 1.5,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.28,
		"hull": 0.46,
		"drag": 0.18,
		"stability": 1.5,
		"safety": 3.4,
		"redundancy": 0.9,
		"brace_zone": 0.85,
		"walkable": true,
	},
	"stabilizer": {
		"label": "Stabilizer",
		"description": "Support rigging that improves brace strength and repair capacity.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 62,
		"unlock_cost_salvage": 2,
		"category": "support",
		"color": Color(0.19, 0.52, 0.63),
		"size": Vector3(1.0, 1.12, 1.0),
		"max_hp": 24.0,
		"weight": 1.9,
		"buoyancy": 2.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 2,
		"brace": 0.34,
		"hull": 0.62,
		"drag": 0.28,
		"stability": 4.6,
		"safety": 4.4,
		"redundancy": 1.0,
		"repair_zone": 0.55,
		"brace_zone": 0.5,
		"walkable": true,
	},
	"outtrigger_beam": {
		"label": "Outrigger Beam",
		"description": "A width-hungry stability arm that makes storms and overboard mistakes far less cruel.",
		"unlockable": true,
		"unlock_tier": 2,
		"unlock_cost_gold": 120,
		"unlock_cost_salvage": 1,
		"category": "support",
		"color": Color(0.16, 0.50, 0.62),
		"size": Vector3(1.28, 0.46, 1.0),
		"max_hp": 18.0,
		"weight": 1.6,
		"buoyancy": 2.8,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.08,
		"hull": 0.36,
		"drag": 0.42,
		"stability": 6.5,
		"safety": 4.0,
		"redundancy": 0.8,
		"walkable": true,
	},
	"armored_housing": {
		"label": "Armored Housing",
		"description": "Protective machinery casing that turns exposed drives into something crews can trust.",
		"unlockable": true,
		"unlock_tier": 3,
		"unlock_cost_gold": 180,
		"unlock_cost_salvage": 3,
		"category": "support",
		"color": Color(0.36, 0.40, 0.42),
		"size": Vector3(1.0, 1.02, 1.0),
		"max_hp": 26.0,
		"weight": 2.5,
		"buoyancy": 1.0,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.02,
		"hull": 0.8,
		"drag": 0.24,
		"stability": 1.0,
		"safety": 1.6,
		"redundancy": 1.4,
		"propulsion_armor": 1.0,
		"propulsion_cover": 1.0,
		"walkable": true,
	},
	"shock_bulkhead": {
		"label": "Shock Bulkhead",
		"description": "Damage spread control for hulls that expect to take repeated punishment and keep sailing.",
		"unlockable": true,
		"unlock_tier": 4,
		"unlock_cost_gold": 250,
		"unlock_cost_salvage": 5,
		"category": "support",
		"color": Color(0.40, 0.44, 0.47),
		"size": Vector3(1.08, 1.08, 1.08),
		"max_hp": 30.0,
		"weight": 2.9,
		"buoyancy": 1.4,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.1,
		"hull": 0.9,
		"drag": 0.22,
		"stability": 2.4,
		"safety": 2.2,
		"redundancy": 2.2,
		"walkable": true,
	},
	"catamaran_beam": {
		"label": "Catamaran Beam",
		"description": "Split-hull scaffolding that rewards wide creative layouts with serious stability.",
		"unlockable": true,
		"unlock_tier": 4,
		"unlock_cost_gold": 240,
		"unlock_cost_salvage": 4,
		"category": "support",
		"color": Color(0.24, 0.48, 0.58),
		"size": Vector3(1.34, 0.42, 0.92),
		"max_hp": 18.0,
		"weight": 1.4,
		"buoyancy": 1.8,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.06,
		"hull": 0.4,
		"drag": 0.34,
		"stability": 5.0,
		"safety": 3.6,
		"redundancy": 1.4,
		"walkable": true,
	},
	"structure": {
		"label": "Structure",
		"description": "Cheap scaffold material for shape, walkways, and goofy ideas.",
		"unlockable": false,
		"unlock_tier": 0,
		"unlock_cost_gold": 0,
		"unlock_cost_salvage": 0,
		"category": "structure",
		"color": Color(0.68, 0.74, 0.78),
		"size": Vector3(1.0, 1.0, 1.0),
		"max_hp": 14.0,
		"weight": 1.2,
		"buoyancy": 1.1,
		"thrust": 0.0,
		"cargo": 0,
		"repair": 0,
		"brace": 0.06,
		"hull": 0.5,
		"drag": 0.2,
		"stability": 0.8,
		"safety": 1.2,
		"redundancy": 0.8,
		"walkable": true,
	},
}
const BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION := 2
const BUILDER_ARCHETYPE_PRESETS := {
	"work_barge": {
		"label": "Work Barge",
		"description": "Wide steam hauler with forgiving repair coverage, heavy salvage, and lots of cargo.",
		"propulsion_family": PROPULSION_FAMILY_STEAM_TUG,
		"target_crew": 3,
		"required_blocks": ["engine", "cargo", "light_crane", "ladder_rig", "repair_bay"],
	},
	"storm_cutter": {
		"label": "Storm Cutter",
		"description": "Narrow fast hull with high response and a sharper punishment curve when the crew slips.",
		"propulsion_family": PROPULSION_FAMILY_TWIN_ENGINE,
		"target_crew": 3,
		"required_blocks": ["twin_engine", "reinforced_prow", "brace_frame", "guard_rail"],
	},
	"rescue_tug": {
		"label": "Rescue Tug",
		"description": "Stable deck-first boat that trades haul size for recovery access and crew safety.",
		"propulsion_family": PROPULSION_FAMILY_RAFT_PADDLES,
		"target_crew": 3,
		"required_blocks": ["ladder_rig", "rescue_net", "utility_bay", "stabilizer"],
	},
	"sail_runner": {
		"label": "Sail Runner",
		"description": "Wind-driven splitter that rewards route planning and hates bad storm angles.",
		"propulsion_family": PROPULSION_FAMILY_SAIL_RIG,
		"target_crew": 2,
		"required_blocks": ["sail_rig", "keel_hull", "light_crane", "guard_rail"],
	},
	"catamaran_hybrid": {
		"label": "Catamaran Hybrid",
		"description": "Wide split-hull specialist that mixes sail efficiency with emergency powered recovery.",
		"propulsion_family": PROPULSION_FAMILY_SAIL_RIG,
		"target_crew": 4,
		"required_blocks": ["catamaran_beam", "sail_rig", "auxiliary_kicker", "harpoon_crane", "ladder_rig"],
	},
}
const RUNTIME_BLOCK_SPACING := BUILDER_CELL_SIZE
const RUNTIME_DAMAGE_CLUSTER_RADIUS := 1.9
const RUNTIME_DAMAGE_CLUSTER_WEIGHTS := [1.0, 0.6, 0.45, 0.3, 0.2]
const RUNTIME_SINK_SPEED := 0.95
const RUNTIME_SINK_DRIFT_SPEED := 0.42
const RUNTIME_SINK_LIFETIME := 8.0
const REACTION_BUMP_SPEED_THRESHOLD := 5.4
const REACTION_BUMP_COLLISION_RADIUS := 0.92
const REACTION_BUMP_PAIR_COOLDOWN := 0.68
const REACTION_BUMP_ACTIVE_SECONDS := 0.15
const REACTION_BUMP_RECOVERY_SECONDS := 0.34
const REACTION_BUMP_KNOCKBACK := 4.4
const REACTION_IMPACT_ACTIVE_SECONDS := 0.24
const REACTION_IMPACT_RECOVERY_SECONDS := 0.46
const REACTION_IMPACT_KNOCKBACK := 5.8
const REACTION_HOOK_ACTIVE_SECONDS := 0.42
const REACTION_HOOK_RECOVERY_SECONDS := 0.38
const RUN_AVATAR_MODE_DECK := "deck"
const RUN_AVATAR_MODE_OVERBOARD := "overboard"
const RUN_AVATAR_MODE_DOWNED := "downed"
const RUN_AVATAR_MOVE_SPEED := 4.9
const RUN_SWIM_MOVE_SPEED := 2.6
const RUN_AVATAR_STAND_HEIGHT := 0.52
const RUN_DECK_SURFACE_MARGIN := 0.08
const RUN_DECK_SURFACE_SNAP_DISTANCE := 0.62
const RUN_OVERBOARD_PROBE_DISTANCE := 1.05
const RUN_OVERBOARD_WATER_HEIGHT := 0.18
const RUN_OVERBOARD_SWIM_RADIUS := 8.8
const RUN_OVERBOARD_RECOVERY_RANGE := 1.15
const RUN_OVERBOARD_DIRECT_REBOARD_RANGE := 0.72
const RUN_OVERBOARD_DIRECT_REBOARD_MAX_HEIGHT := 1.42
const RUN_OVERBOARD_DIRECT_REBOARD_WORLD_DISTANCE := 1.9
const RUN_OVERBOARD_EDGE_MARGIN := 0.24
const RUN_OVERBOARD_MIN_STRENGTH := 0.54
const AVATAR_MAX_HEALTH := 100.0
const AVATAR_MAX_STAMINA := 100.0
const AVATAR_WOUNDED_THRESHOLD := 60.0
const AVATAR_CRITICAL_THRESHOLD := 30.0
const AVATAR_HEALTH_REGEN_DELAY := 8.0
const AVATAR_HEALTH_REGEN_RATE := 6.0
const AVATAR_HEALTH_REGEN_CAP := 60.0
const AVATAR_STAMINA_REGEN_DELAY := 0.8
const AVATAR_STAMINA_REGEN_DECK := 20.0
const AVATAR_STAMINA_REGEN_OVERBOARD := 5.0
const AVATAR_STAMINA_EXHAUSTED_RECOVERY_THRESHOLD := 20.0
const AVATAR_SPRINT_STAMINA_DRAIN := 16.0
const AVATAR_SWIM_BURST_STAMINA_DRAIN := 22.0
const AVATAR_BRACE_STAMINA_COST := 18.0
const AVATAR_REPAIR_STAMINA_COST := 24.0
const AVATAR_ASSIST_STAMINA_COST := 15.0
const AVATAR_DOWNED_SELF_RECOVERY_SECONDS := 6.0
const AVATAR_ASSIST_RALLY_RANGE := 1.25
const AVATAR_OVERBOARD_ENTRY_DAMAGE := 12.0
const AVATAR_OVERBOARD_ATTRITION_DELAY := 3.0
const AVATAR_OVERBOARD_ATTRITION_INTERVAL := 2.5
const AVATAR_OVERBOARD_ATTRITION_DAMAGE := 4.0
const AVATAR_IMPACT_DAMAGE_UNBRACED := 8.0
const AVATAR_IMPACT_DAMAGE_BRACED := 2.0
const AVATAR_IMPACT_EXPOSED_BONUS := 8.0
const AVATAR_SALVAGE_BACKLASH_PRIMARY_DAMAGE := 18.0
const AVATAR_SALVAGE_BACKLASH_SPLASH_DAMAGE := 4.0
const AVATAR_RALLY_HEALTH := 40.0
const AVATAR_RALLY_STAMINA := 35.0
const RUN_RECOVERY_POINTS := [
	{
		"id": "port_ladder",
		"label": "Port Ladder",
		"water_position": Vector3(-1.74, RUN_OVERBOARD_WATER_HEIGHT, 0.62),
		"deck_position": Vector3(-1.02, 0.92, 0.74),
	},
	{
		"id": "starboard_ladder",
		"label": "Starboard Ladder",
		"water_position": Vector3(1.74, RUN_OVERBOARD_WATER_HEIGHT, 0.62),
		"deck_position": Vector3(1.02, 0.92, 0.74),
	},
	{
		"id": "stern_line",
		"label": "Stern Line",
		"water_position": Vector3(0.0, RUN_OVERBOARD_WATER_HEIGHT, 2.62),
		"deck_position": Vector3(0.0, 0.92, 1.96),
	},
]
const DISCONNECT_BROADCAST_DELAY_SECONDS := 0.12

const SEA_SURFACE_Y := -0.12
const BOAT_ACCELERATION := 8.0
const BOAT_DECELERATION := 10.0
const BOAT_TOP_SPEED := 14.0
const BOAT_TURN_SPEED := 1.9
const BOAT_BROADCAST_INTERVAL := 0.05
const BOAT_COLLISION_RADIUS := 1.8
const BOAT_MAX_INTEGRITY := 100.0
const BRACE_ACTIVE_SECONDS := 0.9
const BRACE_COOLDOWN_SECONDS := 2.25
const COLLISION_DAMAGE_UNBRACED := 18.0
const COLLISION_DAMAGE_BRACED := 7.0
const GRAPPLE_RANGE := 7.8
const SALVAGE_MAX_SPEED := 1.55
const SALVAGE_BACKLASH_DAMAGE := 6.0
const SALVAGE_BACKLASH_BREACHES := 1
const RESCUE_MAX_SPEED := 1.25
const RESCUE_DURATION := 1.85
const RESCUE_PATCH_KIT_GRANT := 1
const RESCUE_GOLD_BONUS_MIN := 22
const RESCUE_GOLD_BONUS_MAX := 34
const RESCUE_SALVAGE_BONUS_MIN := 1
const RESCUE_SALVAGE_BONUS_MAX := 2
const BREACH_SPEED_PENALTY := 0.16
const MAX_BREACH_STACKS := 4
const HULL_LEAK_DAMAGE_PER_BREACH := 0.55
const BOAT_HEAVE_SPRING := 10.5
const BOAT_HEAVE_DAMPING := 6.8
const BOAT_PITCH_SPRING := 8.4
const BOAT_PITCH_DAMPING := 6.0
const BOAT_ROLL_SPRING := 9.1
const BOAT_ROLL_DAMPING := 6.4
const REPAIR_COOLDOWN_SECONDS := 1.35
const REPAIR_HULL_RECOVERY := 12.0
const REPAIR_SUPPLIES_START := 3
const REPAIR_SUPPLIES_MAX := 4
const EXTRACTION_DURATION := 1.6
const EXTRACTION_RADIUS := 3.7
const EXTRACTION_MAX_SPEED := 2.25
const RESUPPLY_CACHE_RADIUS := 4.4
const RESUPPLY_CACHE_MAX_SPEED := 8.0
const RESUPPLY_CACHE_SUPPLY_GRANT := 1
const RESUPPLY_CACHE_GOLD_BONUS := 18
const RESUPPLY_CACHE_SALVAGE_BONUS := 1
const SQUALL_PULSE_DAMAGE_MIN := 3.4
const SQUALL_PULSE_DAMAGE_MAX := 5.6
const SQUALL_DRAG_MIN := 0.6
const SQUALL_DRAG_MAX := 0.82
const SQUALL_PULSE_INTERVAL_MIN := 2.1
const SQUALL_PULSE_INTERVAL_MAX := 2.9
const REWARD_GOLD_PER_CARGO := 12
const REWARD_SALVAGE_PER_CARGO := 0

var mode: int = Mode.OFFLINE
var current_host: String = GameConfig.DEFAULT_HOST
var current_port: int = GameConfig.DEFAULT_PORT
var local_player_name: String = GameConfig.DEFAULT_PLAYER_NAME
var run_seed: int = GameConfig.DEFAULT_RUN_SEED
var session_phase := SESSION_PHASE_HANGAR
var boat_blueprint: Dictionary = {}
var peer_snapshot: Dictionary = {}
var hangar_avatar_state: Dictionary = {}
var run_avatar_state: Dictionary = {}
var reaction_state: Dictionary = {}
var status_message := "Offline"
var driver_peer_id := 0
var boat_state: Dictionary = {}
var hazard_state: Array = []
var station_state: Dictionary = {}
var loot_state: Array = []
var run_state: Dictionary = {}
var progression_state: Dictionary = {}

var _peer_inputs: Dictionary = {}
var _boat_broadcast_accumulator := 0.0
var _run_state_broadcast_accumulator := 0.0
var _next_hazard_id: int = 1
var _next_loot_id: int = 1
var _next_runtime_chunk_id: int = 1
var _next_reaction_id: int = 1
var _next_run_instance_id: int = 1
var _hangar_bump_pair_cooldowns: Dictionary = {}
var _disconnect_broadcast_scheduled := false
var _client_bootstrap_complete := false
var _last_applied_local_result_run_instance_id := -1

const OFFLINE_LOCAL_PEER_ID := 1

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	shutdown()

func start_server(listen_port: int = GameConfig.DEFAULT_PORT, seed: int = GameConfig.DEFAULT_RUN_SEED) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error: int = peer.create_server(listen_port, GameConfig.MAX_PLAYERS)
	if error != OK:
		_set_status("Server failed to start (code %s)." % str(error))
		return error

	multiplayer.multiplayer_peer = peer
	mode = Mode.SERVER
	current_host = "0.0.0.0"
	current_port = listen_port
	run_seed = seed
	session_phase = SESSION_PHASE_HANGAR
	_client_bootstrap_complete = false
	peer_snapshot = {
		1: {
			"name": "Dedicated Server",
			"status": "hosting",
		},
	}
	_reset_progression_runtime()
	_reset_hangar_avatar_state()
	_reset_run_avatar_state()
	_reset_reaction_runtime()
	_reset_blueprint_runtime()
	_reset_run_runtime()

	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_all_runtime_state()
	_set_status("Server listening on port %d." % current_port)
	return OK

func start_client(host: String, connect_port: int, player_name: String) -> int:
	shutdown()

	var peer := ENetMultiplayerPeer.new()
	var error: int = peer.create_client(host, connect_port)
	if error != OK:
		_set_status("Could not start a client connection to %s:%d (code %s)." % [host, connect_port, str(error)])
		emit_signal("client_connect_failed")
		return error

	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	current_host = host
	current_port = connect_port
	local_player_name = player_name if not player_name.is_empty() else GameConfig.DEFAULT_PLAYER_NAME
	_client_bootstrap_complete = false
	emit_signal("mode_changed", _mode_name())
	_set_status("Connecting to %s:%d..." % [current_host, current_port])
	return OK

func shutdown() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	mode = Mode.OFFLINE
	session_phase = SESSION_PHASE_HANGAR
	boat_blueprint = _decorate_blueprint(DockState.get_boat_blueprint())
	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())
	peer_snapshot = {}
	hangar_avatar_state = {}
	reaction_state = {}
	status_message = "Offline"
	_client_bootstrap_complete = false
	_disconnect_broadcast_scheduled = false
	_reset_reaction_runtime()
	_reset_run_runtime()
	_ensure_offline_local_state()
	emit_signal("mode_changed", _mode_name())
	emit_signal("run_seed_changed", run_seed)
	_emit_all_runtime_state()

func get_mode_name() -> String:
	return _mode_name()

func get_session_phase() -> String:
	return session_phase

func get_local_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return OFFLINE_LOCAL_PEER_ID
	return multiplayer.get_unique_id()

func _has_runtime_authority() -> bool:
	return multiplayer.multiplayer_peer == null or multiplayer.is_server()

func _has_network_server() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()

func get_builder_bounds_min() -> Vector3i:
	return BUILDER_BOUNDS_MIN

func get_builder_bounds_max() -> Vector3i:
	return BUILDER_BOUNDS_MAX

func get_builder_cell_size() -> float:
	return BUILDER_CELL_SIZE

func get_builder_world_origin() -> Vector3:
	return BUILDER_WORLD_ORIGIN

func get_hangar_build_range() -> float:
	return HANGAR_BUILD_RANGE

func get_builder_block_ids() -> Array:
	var unlocked_lookup := _get_unlocked_block_lookup()
	var block_ids: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		if not unlocked_lookup.has(block_id):
			continue
		block_ids.append(block_id)
	return block_ids

func get_builder_block_definition(block_type: String) -> Dictionary:
	var block_id := block_type.strip_edges().to_lower()
	var definition: Dictionary = BUILDER_BLOCK_LIBRARY.get(block_id, BUILDER_BLOCK_LIBRARY["structure"])
	var decorated := definition.duplicate(true)
	decorated["family"] = str(decorated.get("family", _normalize_block_family(block_id, decorated)))
	decorated["occupancy_cells"] = _normalize_definition_cells(decorated.get("occupancy_cells", [[0, 0, 0]]))
	decorated["cg_bias"] = _normalize_definition_vector3(decorated.get("cg_bias", Vector3.ZERO))
	decorated["buoyancy_bias"] = _normalize_definition_vector3(decorated.get("buoyancy_bias", Vector3.ZERO))
	var recipe := _build_block_recipe(block_id, decorated)
	decorated["recipe_materials"] = recipe.get("materials", {})
	decorated["recipe_gold"] = int(recipe.get("gold", 0))
	decorated["required_schematic"] = str(recipe.get("required_schematic", ""))
	return decorated

func get_progression_state() -> Dictionary:
	return progression_state.duplicate(true)

func get_builder_store_entries() -> Array:
	var store_entries: Array = []
	var unlocked_lookup := _get_unlocked_block_lookup()
	var workshop_gold := int(progression_state.get("workshop_gold", progression_state.get("total_gold", 0)))
	var workshop_stock := _normalize_material_dict_ui(progression_state.get("workshop_stock", {}))
	var host_known_schematics := _normalize_schematic_list_ui(progression_state.get("host_known_schematics", []))
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		if not bool(block_def.get("unlockable", false)):
			continue
		var recipe_gold := int(block_def.get("recipe_gold", 0))
		var recipe_materials := _normalize_material_dict_ui(block_def.get("recipe_materials", {}))
		var required_schematic := str(block_def.get("required_schematic", ""))
		var unlocked := unlocked_lookup.has(block_id)
		var missing_gold := maxi(0, recipe_gold - workshop_gold)
		var missing_materials := _get_missing_material_costs(workshop_stock, recipe_materials)
		var schematic_known := required_schematic.is_empty() or host_known_schematics.has(required_schematic)
		var affordable := unlocked or (missing_gold <= 0 and missing_materials.is_empty() and schematic_known)
		store_entries.append({
			"block_id": block_id,
			"label": str(block_def.get("label", block_id.capitalize())),
			"description": str(block_def.get("description", "")),
			"category": str(block_def.get("category", "structure")),
			"unlock_tier": int(block_def.get("unlock_tier", 0)),
			"unlock_cost_gold": recipe_gold,
			"unlock_cost_salvage": 0,
			"unlocked": unlocked,
			"affordable": affordable,
			"recipe_gold": recipe_gold,
			"recipe_materials": recipe_materials,
			"required_schematic": required_schematic,
			"schematic_known": schematic_known,
			"missing_gold": missing_gold,
			"missing_materials": missing_materials,
			"definition": block_def.duplicate(true),
		})
	return store_entries

func get_toolbelt_entries(phase_name: String = session_phase) -> Array:
	if phase_name == SESSION_PHASE_RUN:
		return RUN_TOOLBELT.duplicate(true)
	return HANGAR_TOOLBELT.duplicate(true)

func get_hangar_inventory_snapshot(active_tool_id: String = "") -> Dictionary:
	var snapshot := progression_state.duplicate(true)
	if snapshot.is_empty():
		snapshot = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())
	var local_profile := DockState.get_local_profile_snapshot()
	var blueprint_manifest: Array = []
	var block_counts: Dictionary = {}
	for block_variant in Array(boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_id := str(block.get("type", "structure"))
		block_counts[block_id] = int(block_counts.get(block_id, 0)) + 1
	for block_id_variant in block_counts.keys():
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		blueprint_manifest.append(_make_inventory_entry(
			str(block_def.get("label", block_id.capitalize())),
			int(block_counts.get(block_id, 0)),
			_get_inventory_icon_for_block(block_id),
			"Mounted on the shared blueprint."
		))
	blueprint_manifest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("label", "")) < str(b.get("label", ""))
	)
	var unlocked_labels := PackedStringArray()
	for block_id_variant in Array(snapshot.get("unlocked_blocks", [])):
		var block_id := str(block_id_variant)
		var block_def := get_builder_block_definition(block_id)
		unlocked_labels.append(str(block_def.get("label", block_id.capitalize())))
	unlocked_labels.sort()
	var local_stash_manifest := _build_resource_manifest(
		int(local_profile.get("total_gold", 0)),
		Dictionary(local_profile.get("stash_items", {})),
		"Personal stash"
	)
	var workshop_manifest := _build_resource_manifest(
		int(snapshot.get("workshop_gold", 0)),
		Dictionary(snapshot.get("workshop_stock", {})),
		"Host workshop"
	)
	return {
		"gold": int(local_profile.get("total_gold", 0)),
		"salvage": DockState.get_total_salvage(),
		"toolbelt_manifest": _build_toolbelt_manifest(SESSION_PHASE_HANGAR, active_tool_id),
		"unlocked_parts": unlocked_labels,
		"blueprint_manifest": blueprint_manifest,
		"local_stash_manifest": local_stash_manifest,
		"workshop_manifest": workshop_manifest,
		"local_known_schematics": _normalize_schematic_list_ui(local_profile.get("known_schematics", [])),
		"host_known_schematics": _normalize_schematic_list_ui(snapshot.get("host_known_schematics", [])),
		"repair_debt": Dictionary(snapshot.get("repair_debt", {})).duplicate(true),
		"store_entries": get_builder_store_entries(),
		"stats": get_blueprint_stats(),
	}

func get_run_inventory_snapshot(active_tool_id: String = "") -> Dictionary:
	var bonus_manifest: Array = []
	for entry_variant in Array(run_state.get("bonus_manifest", [])):
		bonus_manifest.append(Dictionary(entry_variant).duplicate(true))
	return {
		"toolbelt_manifest": _build_toolbelt_manifest(SESSION_PHASE_RUN, active_tool_id),
		"cargo_manifest": Array(run_state.get("cargo_manifest", [])).duplicate(true),
		"secured_manifest": Array(run_state.get("secured_manifest", [])).duplicate(true),
		"item_manifest": _build_material_manifest_entries(Dictionary(run_state.get("run_item_bank", {}))),
		"schematic_manifest": _build_schematic_manifest_entries(Array(run_state.get("run_schematic_bank", []))),
		"bonus_manifest": bonus_manifest,
		"cargo_count": int(run_state.get("cargo_count", 0)),
		"cargo_capacity": int(run_state.get("cargo_capacity", int(boat_state.get("cargo_capacity", 0)))),
		"cargo_lost_to_sea": int(run_state.get("cargo_lost_to_sea", 0)),
		"patch_kits": int(run_state.get("repair_supplies", 0)),
		"patch_kits_max": int(run_state.get("repair_supplies_max", 0)),
		"bonus_gold_bank": int(run_state.get("bonus_gold_bank", 0)),
		"bonus_salvage_bank": 0,
		"reward_items": Dictionary(run_state.get("reward_items", {})).duplicate(true),
		"reward_schematics": Array(run_state.get("reward_schematics", [])).duplicate(true),
		"loot_lost_items": Dictionary(run_state.get("loot_lost_items", {})).duplicate(true),
	}

func _build_block_recipe(block_id: String, block_def: Dictionary) -> Dictionary:
	var tier := int(block_def.get("unlock_tier", 0))
	var recipe := {
		"gold": maxi(0, int(block_def.get("unlock_cost_gold", 0))),
		"materials": {},
		"required_schematic": block_id if tier >= 2 and bool(block_def.get("unlockable", false)) else "",
	}
	match block_id:
		"keel_hull":
			recipe["materials"] = {"scrap_metal": 2, "treated_planks": 1}
		"reinforced_hull":
			recipe["materials"] = {"scrap_metal": 4, "treated_planks": 1}
		"reinforced_prow":
			recipe["materials"] = {"scrap_metal": 4, "machined_parts": 1}
		"heavy_winch":
			recipe["materials"] = {"scrap_metal": 2, "machined_parts": 3}
		"harpoon_crane":
			recipe["materials"] = {"scrap_metal": 2, "machined_parts": 4, "rigging": 1}
		"guard_rail":
			recipe["materials"] = {"treated_planks": 1, "rigging": 1}
		"rescue_net":
			recipe["materials"] = {"treated_planks": 2, "rigging": 2}
		"repair_bay":
			recipe["materials"] = {"scrap_metal": 1, "machined_parts": 2}
		"utility_bay":
			recipe["materials"] = {"scrap_metal": 1, "machined_parts": 2}
		"brace_frame":
			recipe["materials"] = {"scrap_metal": 1, "rigging": 2}
		"stabilizer":
			recipe["materials"] = {"treated_planks": 1, "rigging": 1}
		"outtrigger_beam":
			recipe["materials"] = {"treated_planks": 2, "rigging": 2}
		"catamaran_beam":
			recipe["materials"] = {"treated_planks": 2, "rigging": 2, "shock_insulation": 1}
		"armored_housing":
			recipe["materials"] = {"scrap_metal": 2, "machined_parts": 2, "shock_insulation": 1}
		"shock_bulkhead":
			recipe["materials"] = {"scrap_metal": 2, "shock_insulation": 2}
		"sail_rig":
			recipe["materials"] = {"treated_planks": 1, "rigging": 3}
		"engine":
			recipe["materials"] = {"scrap_metal": 1, "machined_parts": 2}
		"twin_engine":
			recipe["materials"] = {"machined_parts": 4, "shock_insulation": 1}
		"auxiliary_kicker":
			recipe["materials"] = {"machined_parts": 2, "rigging": 1}
		"high_pressure_boiler":
			recipe["materials"] = {"machined_parts": 3, "boiler_parts": 3, "shock_insulation": 1}
		"cargo":
			recipe["materials"] = {"scrap_metal": 1, "treated_planks": 1}
		"utility":
			recipe["materials"] = {"scrap_metal": 1, "machined_parts": 1}
		_:
			if tier <= 0 or not bool(block_def.get("unlockable", false)):
				recipe["materials"] = {}
			else:
				var fallback_materials := {"scrap_metal": tier + 1}
				if tier >= 1:
					fallback_materials["treated_planks"] = maxi(0, tier - 1)
				if str(block_def.get("category", "")) == "propulsion":
					fallback_materials["machined_parts"] = maxi(1, tier + 1)
				recipe["materials"] = fallback_materials
	return {
		"gold": maxi(0, int(recipe.get("gold", 0))),
		"materials": _normalize_material_dict_ui(recipe.get("materials", {})),
		"required_schematic": str(recipe.get("required_schematic", "")),
	}

func _normalize_material_dict_ui(values: Variant) -> Dictionary:
	var normalized := {}
	for material_id_variant in MATERIAL_ORDER:
		normalized[str(material_id_variant)] = 0
	if typeof(values) != TYPE_DICTIONARY:
		return normalized
	var source := Dictionary(values)
	for key_variant in source.keys():
		var material_id := str(key_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		normalized[material_id] = maxi(0, int(source.get(key_variant, 0)))
	return normalized

func _normalize_schematic_list_ui(values: Variant) -> Array:
	var schematics: Array = []
	var seen := {}
	if typeof(values) != TYPE_ARRAY:
		return schematics
	for value in values:
		var schematic_id := str(value).strip_edges().to_lower()
		if schematic_id.is_empty() or seen.has(schematic_id):
			continue
		seen[schematic_id] = true
		schematics.append(schematic_id)
	schematics.sort()
	return schematics

func _get_missing_material_costs(stock_values: Variant, cost_values: Variant) -> Dictionary:
	var stock := _normalize_material_dict_ui(stock_values)
	var costs := _normalize_material_dict_ui(cost_values)
	var missing := {}
	for material_id_variant in costs.keys():
		var material_id := str(material_id_variant)
		var delta := maxi(0, int(costs.get(material_id, 0)) - int(stock.get(material_id, 0)))
		if delta > 0:
			missing[material_id] = delta
	return missing

func _build_resource_manifest(gold_amount: int, material_values: Variant, detail_prefix: String) -> Array:
	var manifest: Array = []
	if gold_amount > 0:
		manifest.append(_make_inventory_entry("Gold", gold_amount, "gold", "%s currency." % detail_prefix))
	for material_id_variant in MATERIAL_ORDER:
		var material_id := str(material_id_variant)
		var quantity := int(_normalize_material_dict_ui(material_values).get(material_id, 0))
		if quantity <= 0:
			continue
		manifest.append(_make_inventory_entry(
			str(MATERIAL_LABELS.get(material_id, material_id.capitalize())),
			quantity,
			str(MATERIAL_ICON_IDS.get(material_id, "cargo")),
			"%s resource." % detail_prefix
		))
	return manifest

func _build_material_manifest_entries(material_values: Variant) -> Array:
	var manifest: Array = []
	for material_id_variant in MATERIAL_ORDER:
		var material_id := str(material_id_variant)
		var quantity := int(_normalize_material_dict_ui(material_values).get(material_id, 0))
		if quantity <= 0:
			continue
		manifest.append(_make_inventory_entry(
			str(MATERIAL_LABELS.get(material_id, material_id.capitalize())),
			quantity,
			str(MATERIAL_ICON_IDS.get(material_id, "cargo")),
			"Packed into the current haul."
		))
	return manifest

func _build_schematic_manifest_entries(values: Variant) -> Array:
	var manifest: Array = []
	for schematic_id_variant in _normalize_schematic_list_ui(values):
		var schematic_id := str(schematic_id_variant)
		var block_def := get_builder_block_definition(schematic_id)
		manifest.append(_make_inventory_entry(
			"%s Schematic" % str(block_def.get("label", schematic_id.capitalize())),
			1,
			str(MATERIAL_ICON_IDS.get("schematic", "salvage")),
			"Recovered as permanent workshop knowledge on extraction."
		))
	return manifest

func _build_toolbelt_manifest(phase_name: String, active_tool_id: String = "") -> Array:
	var manifest: Array = []
	for tool_variant in get_toolbelt_entries(phase_name):
		var tool: Dictionary = tool_variant
		var entry := _make_inventory_entry(
			str(tool.get("label", "Tool")),
			1,
			str(tool.get("icon", "cargo")),
			str(tool.get("hint", ""))
		)
		entry["equipped"] = str(tool.get("id", "")) == active_tool_id
		manifest.append(entry)
	return manifest

func _get_inventory_icon_for_block(block_id: String) -> String:
	match block_id.strip_edges().to_lower():
		"core", "hull", "deck_plate", "keel_hull", "reinforced_hull", "reinforced_prow", "structure", "shock_bulkhead":
			return "reinforced-hull"
		"engine", "sail_rig", "twin_engine", "auxiliary_kicker", "high_pressure_boiler", "armored_housing":
			return "twin-engine"
		"light_crane", "heavy_winch", "harpoon_crane":
			return "salvage"
		"cargo":
			return "cargo"
		"utility", "utility_bay", "repair_bay", "brace_frame":
			return "repair-kit"
		"stabilizer", "outtrigger_beam", "catamaran_beam", "guard_rail", "ladder_rig", "rescue_net":
			return "stabilizer"
		_:
			return "cargo"

func _make_inventory_entry(label: String, quantity: int, icon_id: String, detail: String = "") -> Dictionary:
	return {
		"label": label,
		"quantity": maxi(1, quantity),
		"icon_id": icon_id,
		"detail": detail,
	}

func _append_inventory_entry(state_key: String, label: String, quantity: int, icon_id: String, detail: String = "") -> void:
	if quantity <= 0:
		return
	var manifest: Array = Array(run_state.get(state_key, [])).duplicate(true)
	for entry_index in range(manifest.size()):
		var entry: Dictionary = manifest[entry_index]
		if str(entry.get("label", "")) != label:
			continue
		if str(entry.get("detail", "")) != detail:
			continue
		entry["quantity"] = int(entry.get("quantity", 0)) + quantity
		manifest[entry_index] = entry
		run_state[state_key] = manifest
		return
	manifest.append(_make_inventory_entry(label, quantity, icon_id, detail))
	run_state[state_key] = manifest

func _append_run_materials(material_values: Variant) -> void:
	run_state["run_item_bank"] = _merge_material_dicts_ui(run_state.get("run_item_bank", {}), material_values)

func _append_run_schematics(values: Variant) -> void:
	run_state["run_schematic_bank"] = _merge_schematic_lists_ui(run_state.get("run_schematic_bank", []), values)

func _merge_material_dicts_ui(base_values: Variant, added_values: Variant) -> Dictionary:
	var merged := _normalize_material_dict_ui(base_values)
	var added := _normalize_material_dict_ui(added_values)
	for material_id_variant in added.keys():
		var material_id := str(material_id_variant)
		merged[material_id] = int(merged.get(material_id, 0)) + int(added.get(material_id, 0))
	return merged

func _sum_material_dict_ui(values: Variant) -> int:
	var total := 0
	for quantity_variant in _normalize_material_dict_ui(values).values():
		total += int(quantity_variant)
	return total

func _merge_schematic_lists_ui(base_values: Variant, added_values: Variant) -> Array:
	var merged_lookup := {}
	var merged: Array = []
	for value in _normalize_schematic_list_ui(base_values):
		var schematic_id := str(value)
		merged_lookup[schematic_id] = true
		merged.append(schematic_id)
	for value in _normalize_schematic_list_ui(added_values):
		var schematic_id := str(value)
		if merged_lookup.has(schematic_id):
			continue
		merged_lookup[schematic_id] = true
		merged.append(schematic_id)
	merged.sort()
	return merged

func _build_material_detail(material_values: Variant, gold_bonus: int = 0, patch_kits: int = 0, schematic_values: Variant = []) -> String:
	var tokens := PackedStringArray()
	if gold_bonus > 0:
		tokens.append("%dg" % gold_bonus)
	for material_id_variant in MATERIAL_ORDER:
		var material_id := str(material_id_variant)
		var quantity := int(_normalize_material_dict_ui(material_values).get(material_id, 0))
		if quantity <= 0:
			continue
		tokens.append("%s x%d" % [str(MATERIAL_LABELS.get(material_id, material_id.capitalize())), quantity])
	if patch_kits > 0:
		tokens.append("Patch Kits x%d" % patch_kits)
	var schematic_list := _normalize_schematic_list_ui(schematic_values)
	if not schematic_list.is_empty():
		var schematic_labels := PackedStringArray()
		for schematic_id_variant in schematic_list:
			var schematic_id := str(schematic_id_variant)
			var block_def := get_builder_block_definition(schematic_id)
			schematic_labels.append(str(block_def.get("label", schematic_id.capitalize())))
		tokens.append("Schematics: %s" % ", ".join(schematic_labels))
	if tokens.is_empty():
		return "No notable haul."
	return " | ".join(tokens)

func _spill_inventory_quantity(state_key: String, quantity: int) -> void:
	if quantity <= 0:
		return
	var manifest: Array = Array(run_state.get(state_key, [])).duplicate(true)
	var remaining := quantity
	for entry_index in range(manifest.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var entry: Dictionary = manifest[entry_index]
		var entry_quantity := int(entry.get("quantity", 0))
		if entry_quantity <= remaining:
			remaining -= entry_quantity
			manifest.remove_at(entry_index)
			continue
		entry["quantity"] = entry_quantity - remaining
		remaining = 0
		manifest[entry_index] = entry
	run_state[state_key] = manifest

func get_hangar_avatar_state() -> Dictionary:
	return hangar_avatar_state.duplicate(true)

func get_run_avatar_state() -> Dictionary:
	return run_avatar_state.duplicate(true)

func get_reaction_state() -> Dictionary:
	return reaction_state.duplicate(true)

func get_peer_reaction_state(peer_id: int) -> Dictionary:
	return Dictionary(reaction_state.get(peer_id, {})).duplicate(true)

func get_blueprint_stats() -> Dictionary:
	return Dictionary(boat_blueprint.get("stats", {})).duplicate(true)

func get_blueprint_warnings() -> Array:
	return Array(boat_blueprint.get("warnings", [])).duplicate(true)

func get_builder_overlay_modes() -> Array:
	return BUILDER_OVERLAY_ORDER.duplicate(true)

func get_blueprint_overlay_cells() -> Dictionary:
	return Dictionary(get_blueprint_stats().get("overlay_cells", {})).duplicate(true)

func get_builder_archetype_presets() -> Dictionary:
	return BUILDER_ARCHETYPE_PRESETS.duplicate(true)

func get_propulsion_family_label(family: String) -> String:
	match family.strip_edges().to_lower():
		PROPULSION_FAMILY_SAIL_RIG:
			return "Sail Rig"
		PROPULSION_FAMILY_STEAM_TUG:
			return "Steam Tug"
		PROPULSION_FAMILY_TWIN_ENGINE:
			return "Twin Engine"
		_:
			return "Raft Paddles"

func get_propulsion_fault_label(fault_state: String) -> String:
	match fault_state.strip_edges().to_lower():
		PROPULSION_FAULT_STATE_LABORING:
			return "Laboring"
		PROPULSION_FAULT_STATE_OVERHEATED:
			return "Overheated"
		PROPULSION_FAULT_STATE_OVERPRESSURE:
			return "Overpressure"
		PROPULSION_FAULT_STATE_DESYNC:
			return "Desynced"
		PROPULSION_FAULT_STATE_CRIPPLED:
			return "Crippled"
		_:
			return "Stable"

func get_biome_sea_profile(biome_id: String) -> Dictionary:
	match biome_id:
		RunWorldGenerator.BIOME_REEF_WATERS:
			return {
				"wave_amp": 0.18,
				"wave_speed": 0.92,
				"chop_strength": 0.24,
				"cross_weight": 0.28,
				"background": Color(0.26, 0.58, 0.63),
				"fog_density": 0.0,
				"deep_color": Color(0.04, 0.20, 0.25),
				"shallow_color": Color(0.12, 0.49, 0.46),
				"foam_color": Color(0.76, 0.93, 0.88),
				"horizon_color": Color(0.28, 0.54, 0.56),
				"sun_energy": 0.95,
				"sun_color": Color(0.96, 0.94, 0.85),
				"sky_energy": 0.62,
				"reflection_strength": 0.44,
				"glint_strength": 0.26,
				"clarity": 0.72,
			}
		RunWorldGenerator.BIOME_FOG_BANK:
			return {
				"wave_amp": 0.21,
				"wave_speed": 0.84,
				"chop_strength": 0.14,
				"cross_weight": 0.24,
				"background": Color(0.36, 0.42, 0.48),
				"fog_density": 0.028,
				"deep_color": Color(0.06, 0.11, 0.15),
				"shallow_color": Color(0.11, 0.22, 0.28),
				"foam_color": Color(0.76, 0.82, 0.88),
				"horizon_color": Color(0.34, 0.40, 0.46),
				"sun_energy": 0.56,
				"sun_color": Color(0.82, 0.86, 0.90),
				"sky_energy": 0.32,
				"reflection_strength": 0.24,
				"glint_strength": 0.14,
				"clarity": 0.34,
			}
		RunWorldGenerator.BIOME_STORM_BELT:
			return {
				"wave_amp": 0.42,
				"wave_speed": 1.18,
				"chop_strength": 0.52,
				"cross_weight": 0.44,
				"background": Color(0.15, 0.19, 0.25),
				"fog_density": 0.021,
				"deep_color": Color(0.03, 0.08, 0.12),
				"shallow_color": Color(0.06, 0.16, 0.21),
				"foam_color": Color(0.86, 0.92, 0.97),
				"horizon_color": Color(0.18, 0.25, 0.31),
				"sun_energy": 0.36,
				"sun_color": Color(0.60, 0.66, 0.76),
				"sky_energy": 0.22,
				"reflection_strength": 0.42,
				"glint_strength": 0.40,
				"clarity": 0.24,
			}
		RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			return {
				"wave_amp": 0.30,
				"wave_speed": 0.98,
				"chop_strength": 0.26,
				"cross_weight": 0.31,
				"background": Color(0.24, 0.29, 0.33),
				"fog_density": 0.009,
				"deep_color": Color(0.05, 0.10, 0.12),
				"shallow_color": Color(0.08, 0.20, 0.20),
				"foam_color": Color(0.72, 0.82, 0.84),
				"horizon_color": Color(0.20, 0.26, 0.29),
				"sun_energy": 0.52,
				"sun_color": Color(0.78, 0.78, 0.72),
				"sky_energy": 0.30,
				"reflection_strength": 0.34,
				"glint_strength": 0.18,
				"clarity": 0.28,
			}
		_:
			return {
				"wave_amp": 0.28,
				"wave_speed": 0.96,
				"chop_strength": 0.18,
				"cross_weight": 0.24,
				"background": Color(0.23, 0.57, 0.73),
				"fog_density": 0.002,
				"deep_color": Color(0.02, 0.14, 0.25),
				"shallow_color": Color(0.08, 0.39, 0.49),
				"foam_color": Color(0.92, 0.97, 0.99),
				"horizon_color": Color(0.47, 0.72, 0.82),
				"sun_energy": 0.98,
				"sun_color": Color(1.0, 0.94, 0.80),
				"sky_energy": 0.76,
				"reflection_strength": 0.70,
				"glint_strength": 0.48,
				"clarity": 0.82,
			}

func _sample_directional_wave(world_xz: Vector2, direction: Vector2, frequency: float, phase: float) -> float:
	return sin(world_xz.dot(direction.normalized()) * frequency + phase)

func _sample_wave_group_envelope(world_xz: Vector2, time: float, primary_direction: Vector2, secondary_direction: Vector2, strength: float) -> float:
	var primary_group := sin(world_xz.dot(primary_direction.normalized()) * 0.006 + time * 0.18)
	var secondary_group := cos(world_xz.dot(secondary_direction.normalized()) * 0.004 - time * 0.11)
	return 0.86 + strength * (primary_group * 0.18 + secondary_group * 0.12 + 0.22)

func sample_wave_height(world_position: Vector3, time_seconds: float = -1.0) -> float:
	var descriptor := get_chunk_descriptor(get_world_chunk_coord(world_position))
	var profile := get_biome_sea_profile(str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN)))
	var hazard_level := clampf(float(descriptor.get("hazard_level", 0.35)), 0.0, 1.0)
	var time := time_seconds if time_seconds >= 0.0 else float(run_state.get("elapsed_time", 0.0))
	var world_xz := Vector2(world_position.x, world_position.z)
	var wave_speed := float(profile.get("wave_speed", 1.0))
	var wave_amplitude := float(profile.get("wave_amp", 0.24)) * (0.86 + hazard_level * 0.74)
	var chop_strength := float(profile.get("chop_strength", 0.18))
	var cross_weight := float(profile.get("cross_weight", 0.26))
	var wind_angle := 0.34 + sin(time * 0.029) * 0.18 + hazard_level * 0.12
	var wind_direction := Vector2.RIGHT.rotated(wind_angle)
	var swell_direction := wind_direction.rotated(-0.56 + cos(time * 0.021) * 0.10)
	var cross_direction := wind_direction.rotated(1.08 + sin(time * 0.017) * 0.08)
	var drift_direction := wind_direction.rotated(-1.42)
	var swell_group := _sample_wave_group_envelope(world_xz, time, swell_direction, cross_direction, 0.24 + hazard_level * 0.18)
	var swell_a := _sample_directional_wave(world_xz, swell_direction, 0.030, time * (0.56 * wave_speed))
	var swell_b := _sample_directional_wave(world_xz, wind_direction, 0.041, time * (0.92 * wave_speed) + 0.80)
	var long_swell := _sample_directional_wave(world_xz, drift_direction, 0.018, time * (0.34 * wave_speed) - 1.20)
	var cross := _sample_directional_wave(world_xz, cross_direction, 0.024, time * (0.48 * wave_speed) + 1.60)
	var chop_carrier := _sample_directional_wave(world_xz, wind_direction, 0.18, time * (1.75 * wave_speed))
	var chop_cross := _sample_directional_wave(world_xz, cross_direction, 0.22, -time * (1.38 * wave_speed) + 0.70)
	var gust_envelope := 0.74 + 0.26 * (sin(time * 0.31 + world_xz.dot(wind_direction) * 0.008) * 0.5 + 0.5)
	var wind_chop := chop_carrier * chop_cross * chop_strength * gust_envelope
	var cap_ripple := _sample_directional_wave(world_xz, wind_direction.rotated(0.22), 0.31, time * (2.38 * wave_speed) + 1.40) * (0.05 + hazard_level * 0.08)
	return (
		(swell_a * 0.36 + swell_b * 0.28 + long_swell * 0.24 + cross * cross_weight * 0.42) * wave_amplitude * swell_group
		+ wind_chop * wave_amplitude
		+ cap_ripple * wave_amplitude
	)

func get_wave_surface_height(world_position: Vector3, time_seconds: float = -1.0) -> float:
	return SEA_SURFACE_Y + sample_wave_height(world_position, time_seconds)

func sample_boat_wave_pose(
	world_position: Vector3,
	rotation_y: float,
	hull_length: float = 4.4,
	hull_beam: float = 2.7,
	time_seconds: float = -1.0
) -> Dictionary:
	var forward := -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	var right := Vector3.RIGHT.rotated(Vector3.UP, rotation_y)
	var bow_distance := maxf(1.0, hull_length * 0.55)
	var stern_distance := maxf(0.9, hull_length * 0.45)
	var side_distance := maxf(0.7, hull_beam * 0.5)
	var bow_sample := sample_wave_height(world_position + forward * bow_distance, time_seconds)
	var stern_sample := sample_wave_height(world_position - forward * stern_distance, time_seconds)
	var port_sample := sample_wave_height(world_position - right * side_distance, time_seconds)
	var starboard_sample := sample_wave_height(world_position + right * side_distance, time_seconds)
	var center_height := sample_wave_height(world_position, time_seconds)
	return {
		"height": center_height,
		"surface_y": SEA_SURFACE_Y + center_height,
		"pitch": clampf(atan2(bow_sample - stern_sample, bow_distance + stern_distance), -0.24, 0.24),
		"roll": clampf(atan2(starboard_sample - port_sample, side_distance * 2.0), -0.30, 0.30),
	}

func _get_runtime_hull_dimensions_from_stats(stats: Dictionary) -> Dictionary:
	var span_length := maxi(1, int(stats.get("span_length", 4)))
	var span_width := maxi(1, int(stats.get("span_width", 2)))
	return {
		"hull_length": clampf(2.4 + float(span_length) * 0.42, 3.2, 6.8),
		"hull_beam": clampf(1.35 + float(span_width) * 0.36, 1.9, 4.6),
	}

func _get_propulsion_station_label(family: String) -> String:
	match family.strip_edges().to_lower():
		PROPULSION_FAMILY_SAIL_RIG:
			return "Trim Deck"
		PROPULSION_FAMILY_STEAM_TUG:
			return "Engine Console"
		PROPULSION_FAMILY_TWIN_ENGINE:
			return "Engineering Panel"
		_:
			return "Paddle Bench"

func _get_propulsion_family_defaults(family: String) -> Dictionary:
	match family.strip_edges().to_lower():
		PROPULSION_FAMILY_SAIL_RIG:
			return {
				"label": "Sail Rig",
				"automation_floor": 0.7,
				"manual_ceiling": 1.0,
				"burst_ceiling": 1.14,
				"drive_rating": 5.1,
				"workload_base": 38.0,
			}
		PROPULSION_FAMILY_STEAM_TUG:
			return {
				"label": "Steam Tug",
				"automation_floor": 0.78,
				"manual_ceiling": 1.0,
				"burst_ceiling": 1.12,
				"drive_rating": 5.4,
				"workload_base": 45.0,
			}
		PROPULSION_FAMILY_TWIN_ENGINE:
			return {
				"label": "Twin Engine",
				"automation_floor": 0.82,
				"manual_ceiling": 1.0,
				"burst_ceiling": 1.15,
				"drive_rating": 6.8,
				"workload_base": 54.0,
			}
		_:
			return {
				"label": "Raft Paddles",
				"automation_floor": 0.55,
				"manual_ceiling": 1.0,
				"burst_ceiling": 1.12,
				"drive_rating": 2.9,
				"workload_base": 60.0,
			}

func _get_propulsion_family_from_counts(block_counts: Dictionary) -> String:
	if int(block_counts.get("twin_engine", 0)) > 0:
		return PROPULSION_FAMILY_TWIN_ENGINE
	if int(block_counts.get("engine", 0)) > 0 or int(block_counts.get("high_pressure_boiler", 0)) > 0:
		return PROPULSION_FAMILY_STEAM_TUG
	if int(block_counts.get("sail_rig", 0)) > 0:
		return PROPULSION_FAMILY_SAIL_RIG
	return PROPULSION_FAMILY_RAFT_PADDLES

func _get_speed_order_label(throttle_intent: float) -> String:
	if throttle_intent <= -0.2:
		return "Reverse"
	if throttle_intent < 0.15:
		return "Stop"
	if throttle_intent < 0.45:
		return "Slow"
	if throttle_intent < 0.8:
		return "Cruise"
	return "Full"

func _extract_block_layout_cell(block: Dictionary) -> Array:
	if block.has("cell"):
		return _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
	if block.has("id"):
		var blueprint_block := _get_blueprint_block_by_id(int(block.get("id", 0)))
		if not blueprint_block.is_empty():
			return _normalize_blueprint_cell(blueprint_block.get("cell", [0, 0, 0]))
	var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
	return [
		int(round(local_position.x / RUNTIME_BLOCK_SPACING)),
		int(round(local_position.y / RUNTIME_BLOCK_SPACING)),
		int(round(local_position.z / RUNTIME_BLOCK_SPACING)),
	]

func _get_definition_float(block_def: Dictionary, key: String, default_value: float = 0.0) -> float:
	return float(block_def.get(key, default_value))

func _get_definition_bool(block_def: Dictionary, key: String, default_value: bool = false) -> bool:
	return bool(block_def.get(key, default_value))

func _get_definition_vector3(block_def: Dictionary, key: String, default_value: Vector3 = Vector3.ZERO) -> Vector3:
	return _normalize_definition_vector3(block_def.get(key, default_value))

func _normalize_definition_vector3(value: Variant) -> Vector3:
	if value is Vector3:
		return value as Vector3
	if typeof(value) == TYPE_ARRAY and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if typeof(value) == TYPE_DICTIONARY:
		return Vector3(
			float(value.get("x", 0.0)),
			float(value.get("y", 0.0)),
			float(value.get("z", 0.0))
		)
	return Vector3.ZERO

func _normalize_definition_cells(value: Variant) -> Array:
	var normalized: Array = []
	if typeof(value) == TYPE_ARRAY:
		for cell_variant in value:
			normalized.append(_normalize_blueprint_cell(cell_variant))
	if normalized.is_empty():
		normalized.append([0, 0, 0])
	return normalized

func _normalize_block_family(block_id: String, block_def: Dictionary) -> String:
	if _get_definition_bool(block_def, "propulsion_component", false) or _get_definition_float(block_def, "thrust", 0.0) > 0.0:
		return "propulsion"
	if int(block_def.get("cargo", 0)) > 0:
		return "cargo"
	if _get_definition_float(block_def, "recovery_access", 0.0) > 0.0:
		return "recovery"
	var category := str(block_def.get("category", "utility"))
	match category:
		"hull":
			return "hull"
		"structure":
			return "deck"
		"recovery":
			return "recovery"
		"cargo":
			return "cargo"
		"propulsion":
			return "propulsion"
		_:
			if block_id.contains("engine") or block_id.contains("boiler") or block_id.contains("sail"):
				return "propulsion"
			return "utility"

func _vector3_to_cell_array(value: Vector3) -> Array:
	return [roundi(value.x), roundi(value.y), roundi(value.z)]

func _get_cells_weighted_center(cells: Array) -> Array:
	if cells.is_empty():
		return [0, 0, 0]
	var accumulator := Vector3.ZERO
	for cell_variant in cells:
		var cell := _normalize_blueprint_cell(cell_variant)
		accumulator += Vector3(float(cell[0]), float(cell[1]), float(cell[2]))
	accumulator /= float(cells.size())
	return [roundi(accumulator.x), roundi(accumulator.y), roundi(accumulator.z)]

func _find_nearest_cell_to_center(cells: Array, center_cell_value: Variant) -> Array:
	if cells.is_empty():
		return _normalize_blueprint_cell(center_cell_value)
	var center := _normalize_blueprint_cell(center_cell_value)
	var nearest_cell := _normalize_blueprint_cell(cells[0])
	var nearest_distance := INF
	for cell_variant in cells:
		var cell := _normalize_blueprint_cell(cell_variant)
		var distance := Vector3(float(cell[0] - center[0]), float(cell[1] - center[1]), float(cell[2] - center[2])).length_squared()
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_cell = cell
	return nearest_cell

func _compute_cell_distance_map(start_cell_value: Variant, cells_by_key: Dictionary) -> Dictionary:
	var start_cell := _normalize_blueprint_cell(start_cell_value)
	var start_key := _cell_to_key(start_cell)
	if not cells_by_key.has(start_key):
		return {}
	var distance_map := {
		start_key: 0,
	}
	var queue: Array = [start_cell]
	while not queue.is_empty():
		var cell := _normalize_blueprint_cell(queue.pop_front())
		var current_key := _cell_to_key(cell)
		var current_distance := int(distance_map.get(current_key, 0))
		for neighbor_variant in _get_adjacent_cells(cell):
			var neighbor := _normalize_blueprint_cell(neighbor_variant)
			var neighbor_key := _cell_to_key(neighbor)
			if not cells_by_key.has(neighbor_key) or distance_map.has(neighbor_key):
				continue
			distance_map[neighbor_key] = current_distance + 1
			queue.append(neighbor)
	return distance_map

func _mark_route_cells(route_lookup: Dictionary, distance_map: Dictionary, start_cell_value: Variant, target_cell_value: Variant, cells_by_key: Dictionary) -> void:
	var start_cell := _normalize_blueprint_cell(start_cell_value)
	var target_cell := _normalize_blueprint_cell(target_cell_value)
	var start_key := _cell_to_key(start_cell)
	var current_key := _cell_to_key(target_cell)
	if not distance_map.has(start_key) or not distance_map.has(current_key):
		return
	var current_cell := target_cell
	route_lookup[current_key] = true
	while current_key != start_key:
		var current_distance := int(distance_map.get(current_key, 0))
		var stepped := false
		for neighbor_variant in _get_adjacent_cells(current_cell):
			var neighbor := _normalize_blueprint_cell(neighbor_variant)
			var neighbor_key := _cell_to_key(neighbor)
			if not cells_by_key.has(neighbor_key):
				continue
			if int(distance_map.get(neighbor_key, -1)) != current_distance - 1:
				continue
			route_lookup[neighbor_key] = true
			current_cell = neighbor
			current_key = neighbor_key
			stepped = true
			break
		if not stepped:
			break

func _derive_recovery_points_from_blocks(blocks: Array) -> Array:
	var targets: Array = []
	var ladder_index := 0
	var stern_index := 0
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := get_builder_block_definition(block_type)
		var recovery_access := _get_definition_float(block_def, "recovery_access", 0.0)
		if recovery_access <= 0.0:
			continue
		var cell := _extract_block_layout_cell(block)
		var local_base := _block_cell_to_local_position(cell)
		var recovery_type := str(block_def.get("recovery_type", "side"))
		var label := "Recovery"
		var water_position := local_base
		var deck_position := local_base + Vector3(0.0, 0.92, 0.0)
		if recovery_type == "stern":
			stern_index += 1
			label = "Stern Net" if stern_index == 1 else "Stern Net %d" % stern_index
			water_position += Vector3(0.0, RUN_OVERBOARD_WATER_HEIGHT, 1.58)
			deck_position += Vector3(0.0, 0.0, 0.84)
		else:
			ladder_index += 1
			var side_sign := -1.0 if int(cell[0]) <= 0 else 1.0
			label = "Port Ladder" if side_sign < 0.0 else "Starboard Ladder"
			if ladder_index > 2:
				label += " %d" % ladder_index
			water_position += Vector3(1.52 * side_sign, RUN_OVERBOARD_WATER_HEIGHT, 0.18)
			deck_position += Vector3(0.86 * side_sign, 0.0, 0.18)
		targets.append({
			"id": "%s_%d" % [block_type, targets.size()],
			"label": label,
			"water_position": water_position,
			"deck_position": deck_position,
		})
	if targets.is_empty():
		return RUN_RECOVERY_POINTS.duplicate(true)
	return targets

func _compute_boat_stats_for_blocks(blocks: Array) -> Dictionary:
	var block_counts := {}
	var total_weight := 0.0
	var total_buoyancy := 0.0
	var total_thrust := 0.0
	var total_cargo := 0
	var total_repair := 0
	var total_brace := 0.0
	var total_hull := 0.0
	var total_drag := 0.0
	var total_stability := 0.0
	var total_safety := 0.0
	var total_repair_zone := 0.0
	var total_brace_zone := 0.0
	var total_recovery_access := 0.0
	var total_propulsion_armor := 0.0
	var total_redundancy := 0.0
	var engine_count := 0
	var cells_by_key := {}
	var block_types_by_key := {}
	var block_defs_by_key := {}
	var all_cells: Array = []
	var walkable_cells: Array = []
	var propulsion_cells: Array = []
	var salvage_cells: Array = []
	var recovery_cells: Array = []
	var repair_cells: Array = []
	var brace_cells: Array = []
	var core_cells: Array = []
	var min_cell := Vector3i(0, 0, 0)
	var max_cell := Vector3i(0, 0, 0)
	var first_cell := true
	var hydro_samples: Array = []
	var lowest_hull_y := INF
	var center_of_mass_accumulator := Vector3.ZERO
	var center_of_buoyancy_accumulator := Vector3.ZERO
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", ""))
		if block_type.is_empty() and block.has("id"):
			block_type = str(_get_blueprint_block_by_id(int(block.get("id", 0))).get("type", "structure"))
		if block_type.is_empty():
			block_type = "structure"
		var block_def := get_builder_block_definition(block_type)
		var cell := _extract_block_layout_cell(block)
		var cell_key := _cell_to_key(cell)
		cells_by_key[cell_key] = block_type
		block_types_by_key[cell_key] = block_type
		block_defs_by_key[cell_key] = block_def
		all_cells.append(cell)
		if _get_definition_bool(block_def, "walkable", true):
			walkable_cells.append(cell)
		var cell_vec := _cell_to_vector3i(cell)
		if first_cell:
			min_cell = cell_vec
			max_cell = cell_vec
			first_cell = false
		else:
			min_cell = Vector3i(mini(min_cell.x, cell_vec.x), mini(min_cell.y, cell_vec.y), mini(min_cell.z, cell_vec.z))
			max_cell = Vector3i(maxi(max_cell.x, cell_vec.x), maxi(max_cell.y, cell_vec.y), maxi(max_cell.z, cell_vec.z))
		block_counts[block_type] = int(block_counts.get(block_type, 0)) + 1
		var family_name := str(block_def.get("family", "utility"))
		var weight := float(block_def.get("weight", 1.0))
		var buoyancy := float(block_def.get("buoyancy", 1.0))
		var cell_center := Vector3(float(cell[0]), float(cell[1]), float(cell[2]))
		var cg_center := cell_center + _get_definition_vector3(block_def, "cg_bias", Vector3.ZERO)
		var buoyancy_center := cell_center + _get_definition_vector3(block_def, "buoyancy_bias", Vector3.ZERO)
		total_weight += weight
		total_buoyancy += buoyancy
		total_thrust += float(block_def.get("thrust", 0.0))
		total_cargo += int(block_def.get("cargo", 0))
		total_repair += int(block_def.get("repair", 0))
		total_brace += float(block_def.get("brace", 0.0))
		total_hull += float(block_def.get("hull", 0.0))
		total_drag += _get_definition_float(block_def, "drag", 0.3)
		total_stability += _get_definition_float(block_def, "stability", 0.0)
		total_safety += _get_definition_float(block_def, "safety", 0.0)
		total_repair_zone += _get_definition_float(block_def, "repair_zone", 0.0)
		total_brace_zone += _get_definition_float(block_def, "brace_zone", 0.0)
		total_recovery_access += _get_definition_float(block_def, "recovery_access", 0.0)
		total_propulsion_armor += _get_definition_float(block_def, "propulsion_armor", 0.0)
		total_redundancy += _get_definition_float(block_def, "redundancy", 0.0)
		center_of_mass_accumulator += cg_center * weight
		center_of_buoyancy_accumulator += buoyancy_center * maxf(0.0, buoyancy)
		if family_name == "hull":
			lowest_hull_y = minf(lowest_hull_y, cg_center.y)
		hydro_samples.append({
			"cell": cell,
			"family": family_name,
			"weight": weight,
			"buoyancy": buoyancy,
			"cg_center": cg_center,
			"buoyancy_center": buoyancy_center,
			"stability": _get_definition_float(block_def, "stability", 0.0),
		})
		if block_type == "core":
			core_cells.append(cell)
		if _get_definition_bool(block_def, "salvage_station", false):
			salvage_cells.append(cell)
		if _get_definition_float(block_def, "recovery_access", 0.0) > 0.0:
			recovery_cells.append(cell)
		if int(block_def.get("repair", 0)) > 0 or _get_definition_float(block_def, "repair_zone", 0.0) > 0.0:
			repair_cells.append(cell)
		if float(block_def.get("brace", 0.0)) > 0.0 or _get_definition_float(block_def, "brace_zone", 0.0) > 0.0:
			brace_cells.append(cell)
		if _get_definition_bool(block_def, "propulsion_component", false) or float(block_def.get("thrust", 0.0)) > 0.0:
			engine_count += 1
			propulsion_cells.append(cell)

	var main_block_count := blocks.size()
	if walkable_cells.is_empty():
		walkable_cells = all_cells.duplicate(true)
	var width_span := max_cell.x - min_cell.x + 1 if not first_cell else 0
	var height_span := max_cell.y - min_cell.y + 1 if not first_cell else 0
	var length_span := max_cell.z - min_cell.z + 1 if not first_cell else 0
	var exposed_propulsion_faces := 0
	var protected_propulsion_faces := 0
	var armored_propulsion_faces := 0
	var single_neighbor_count := 0
	var multi_neighbor_count := 0
	var lateral_neighbors := [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]
	for cell_variant in propulsion_cells:
		var propulsion_cell := _cell_to_vector3i(cell_variant)
		for offset_variant in lateral_neighbors:
			var offset: Vector3i = offset_variant
			var neighbor_key := _cell_to_key([
				propulsion_cell.x + offset.x,
				propulsion_cell.y + offset.y,
				propulsion_cell.z + offset.z,
			])
			if cells_by_key.has(neighbor_key):
				protected_propulsion_faces += 1
				var neighbor_def: Dictionary = block_defs_by_key.get(neighbor_key, {})
				if _get_definition_float(neighbor_def, "propulsion_cover", 0.0) > 0.0 or _get_definition_float(neighbor_def, "propulsion_armor", 0.0) > 0.0:
					armored_propulsion_faces += 1
			else:
				exposed_propulsion_faces += 1
	for cell_variant in all_cells:
		var cell := _normalize_blueprint_cell(cell_variant)
		var neighbor_count := 0
		for neighbor_variant in _get_adjacent_cells(cell):
			var neighbor_key := _cell_to_key(neighbor_variant)
			if cells_by_key.has(neighbor_key):
				neighbor_count += 1
		if neighbor_count <= 1:
			single_neighbor_count += 1
		elif neighbor_count >= 3:
			multi_neighbor_count += 1

	var family := _get_propulsion_family_from_counts(block_counts)
	var defaults := _get_propulsion_family_defaults(family)
	var reserve_buoyancy := total_buoyancy - total_weight
	var buoyancy_margin := reserve_buoyancy
	var center_of_mass := center_of_mass_accumulator / maxf(0.001, total_weight)
	var center_of_buoyancy := center_of_buoyancy_accumulator / maxf(0.001, total_buoyancy)
	if is_inf(lowest_hull_y):
		lowest_hull_y = center_of_mass.y
	if first_cell:
		lowest_hull_y = 0.0
	var low_support_band := lowest_hull_y + 0.75
	var port_mass := 0.0
	var starboard_mass := 0.0
	var bow_mass := 0.0
	var stern_mass := 0.0
	var low_support_score := 0.0
	var top_heavy_moment := 0.0
	var beam_buoyancy_moment := 0.0
	var length_buoyancy_moment := 0.0
	for sample_variant in hydro_samples:
		var sample: Dictionary = sample_variant
		var sample_weight := float(sample.get("weight", 0.0))
		var sample_buoyancy := maxf(0.0, float(sample.get("buoyancy", 0.0)))
		var cg_center: Vector3 = sample.get("cg_center", Vector3.ZERO)
		var buoyancy_center: Vector3 = sample.get("buoyancy_center", Vector3.ZERO)
		var sample_family := str(sample.get("family", "utility"))
		var relative_x := cg_center.x - center_of_buoyancy.x
		var relative_z := cg_center.z - center_of_buoyancy.z
		if relative_x < 0.0:
			port_mass += sample_weight
		elif relative_x > 0.0:
			starboard_mass += sample_weight
		if relative_z < 0.0:
			bow_mass += sample_weight
		elif relative_z > 0.0:
			stern_mass += sample_weight
		beam_buoyancy_moment += absf(buoyancy_center.x - center_of_mass.x) * sample_buoyancy
		length_buoyancy_moment += absf(buoyancy_center.z - center_of_mass.z) * sample_buoyancy
		if cg_center.y <= low_support_band and (sample_family == "hull" or sample_family == "deck"):
			low_support_score += sample_buoyancy + float(sample.get("stability", 0.0))
		var top_offset := maxf(0.0, cg_center.y - (lowest_hull_y + 1.0))
		if top_offset > 0.0:
			var family_multiplier := 1.0
			if sample_family == "propulsion" or sample_family == "utility":
				family_multiplier = 1.18
			top_heavy_moment += sample_weight * top_offset * family_multiplier
	var draft_ratio := clampf(total_weight / maxf(1.0, total_buoyancy), 0.0, 1.35)
	var heel_bias := clampf((starboard_mass - port_mass) / maxf(1.0, total_weight), -1.0, 1.0)
	var trim_bias := clampf((stern_mass - bow_mass) / maxf(1.0, total_weight), -1.0, 1.0)
	var asymmetry_penalty := clampf((absf(heel_bias) + absf(trim_bias)) * 0.5, 0.0, 1.0)
	var excess_mass_penalty := maxf(0.0, total_weight - total_buoyancy * 0.82)
	var beam_factor := maxf(0.0, float(width_span) - 1.0)
	var length_factor := maxf(0.0, float(length_span) - 1.0)
	var height_penalty := maxf(0.0, float(height_span) - 1.0)
	var top_heavy_penalty := clampf(
		top_heavy_moment * 16.0 / maxf(1.0, total_weight)
		+ height_penalty * 7.2
		- low_support_score * 0.34,
		0.0,
		100.0
	)
	var roll_resistance := clampf(
		24.0
		+ beam_factor * 11.0
		+ beam_buoyancy_moment * 1.8
		+ low_support_score * 1.1
		+ total_stability * 2.6
		+ reserve_buoyancy * 2.4
		- absf(heel_bias) * 34.0
		- top_heavy_penalty * 0.72,
		0.0,
		100.0
	)
	var pitch_resistance := clampf(
		24.0
		+ length_factor * 9.0
		+ length_buoyancy_moment * 1.5
		+ total_stability * 2.1
		+ reserve_buoyancy * 1.8
		- absf(trim_bias) * 30.0
		- height_penalty * 4.0
		- top_heavy_penalty * 0.35,
		0.0,
		100.0
	)
	var freeboard_rating := clampf(
		46.0
		+ reserve_buoyancy * 8.0
		+ beam_factor * 3.6
		- draft_ratio * 38.0
		- top_heavy_penalty * 0.34,
		0.0,
		100.0
	)
	var hydrostatic_class := "stable"
	if reserve_buoyancy < -0.75 or draft_ratio > 1.04:
		hydrostatic_class = "sinking"
	elif reserve_buoyancy < 1.0 or freeboard_rating < 28.0 or roll_resistance < 32.0:
		hydrostatic_class = "unstable"
	elif reserve_buoyancy < 2.5 or freeboard_rating < 46.0 or roll_resistance < 46.0 or absf(trim_bias) > 0.18 or absf(heel_bias) > 0.18:
		hydrostatic_class = "touchy"
	var center_cell := _get_cells_weighted_center(all_cells)
	var spawn_cell := _find_nearest_cell_to_center(core_cells if not core_cells.is_empty() else walkable_cells, center_cell)
	var helm_anchor := _find_nearest_cell_to_center(
		walkable_cells,
		[center_cell[0], center_cell[1], min_cell.z]
	)
	var drive_anchor := _find_nearest_cell_to_center(
		propulsion_cells if not propulsion_cells.is_empty() else walkable_cells,
		[center_cell[0], center_cell[1], center_cell[2] - 1]
	)
	var salvage_anchor := _find_nearest_cell_to_center(
		salvage_cells if not salvage_cells.is_empty() else walkable_cells,
		[max_cell.x, center_cell[1], center_cell[2]]
	)
	var repair_anchor := _find_nearest_cell_to_center(
		repair_cells if not repair_cells.is_empty() else walkable_cells,
		[min_cell.x, center_cell[1], max_cell.z]
	)
	var brace_anchor := _find_nearest_cell_to_center(
		brace_cells if not brace_cells.is_empty() else walkable_cells,
		[min_cell.x, center_cell[1], center_cell[2]]
	)
	var route_distance_map := _compute_cell_distance_map(spawn_cell, cells_by_key)
	var route_lookup := {}
	var station_routes := {
		"helm": -1,
		"drive": -1,
		"grapple": -1,
		"repair": -1,
		"recovery": -1,
	}
	var route_targets := {
		"helm": helm_anchor,
		"drive": drive_anchor,
		"grapple": salvage_anchor,
		"repair": repair_anchor,
	}
	for route_id_variant in route_targets.keys():
		var route_id := str(route_id_variant)
		var route_target := _normalize_blueprint_cell(route_targets[route_id])
		var route_key := _cell_to_key(route_target)
		if route_distance_map.has(route_key):
			station_routes[route_id] = int(route_distance_map.get(route_key, -1))
			_mark_route_cells(route_lookup, route_distance_map, spawn_cell, route_target, cells_by_key)
	var best_recovery_distance := INF
	for recovery_cell_variant in recovery_cells:
		var recovery_cell := _normalize_blueprint_cell(recovery_cell_variant)
		var recovery_key := _cell_to_key(recovery_cell)
		if not route_distance_map.has(recovery_key):
			continue
		best_recovery_distance = minf(best_recovery_distance, float(route_distance_map.get(recovery_key, INF)))
		_mark_route_cells(route_lookup, route_distance_map, spawn_cell, recovery_cell, cells_by_key)
	if best_recovery_distance < INF:
		station_routes["recovery"] = int(best_recovery_distance)
	var required_routes := 3
	var reachable_routes := 0
	for route_id in ["helm", "drive", "repair"]:
		if int(station_routes.get(route_id, -1)) >= 0:
			reachable_routes += 1
	if not salvage_cells.is_empty():
		required_routes += 1
		if int(station_routes.get("grapple", -1)) >= 0:
			reachable_routes += 1
	if not recovery_cells.is_empty():
		required_routes += 1
		if int(station_routes.get("recovery", -1)) >= 0:
			reachable_routes += 1
	var route_ratio := float(reachable_routes) / maxf(1.0, float(required_routes))
	var average_route_steps := 0.0
	var average_route_sources := 0.0
	for route_id in station_routes.keys():
		var distance := int(station_routes.get(route_id, -1))
		if distance < 0:
			continue
		average_route_steps += float(distance)
		average_route_sources += 1.0
	if average_route_sources > 0.0:
		average_route_steps /= average_route_sources
	var salvage_rating := 0.0
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var block_def := get_builder_block_definition(str(block.get("type", "structure")))
		salvage_rating += _get_definition_float(block_def, "salvage_rating", 0.0)
	var damage_redundancy := clampf(
		26.0
		+ total_redundancy * 9.0
		+ float(multi_neighbor_count) * 3.4
		+ float(recovery_cells.size()) * 8.0
		+ float(salvage_cells.size()) * 6.0
		- float(single_neighbor_count) * 2.8
		- float(exposed_propulsion_faces) * 1.8,
		5.0,
		100.0
	)
	var pathing_score := clampf(
		24.0
		+ route_ratio * 42.0
		+ float(route_lookup.size()) * 1.8
		+ float(walkable_cells.size()) * 0.9
		- average_route_steps * 2.8
		- maxf(0.0, float(height_span) - 1.0) * 5.0,
		8.0,
		100.0
	)
	var draft_penalty := maxf(0.0, draft_ratio - 0.72) * 18.0
	var trim_penalty := absf(trim_bias) * 12.0
	var heel_penalty := absf(heel_bias) * 9.0
	var top_speed := float(defaults.get("drive_rating", 3.0)) + total_thrust * 2.1 + reserve_buoyancy * 0.06 - excess_mass_penalty * 0.18
	top_speed += roll_resistance * 0.012
	top_speed -= total_drag * 0.18
	top_speed -= float(total_cargo) * 0.16
	top_speed -= draft_penalty * 0.20
	top_speed -= trim_penalty * 0.14
	top_speed -= top_heavy_penalty * 0.025
	var min_speed := 2.2
	var max_speed := 5.4
	match family:
		PROPULSION_FAMILY_SAIL_RIG:
			min_speed = 3.8
			max_speed = 7.8
		PROPULSION_FAMILY_STEAM_TUG:
			min_speed = 3.6
			max_speed = 7.2
		PROPULSION_FAMILY_TWIN_ENGINE:
			min_speed = 4.6
			max_speed = 8.6
	top_speed = clampf(top_speed, min_speed, max_speed)
	var acceleration := clampf(
		28.0
		+ total_thrust * 18.0
		+ float(engine_count) * 7.0
		- total_weight * 1.30
		+ maxf(0.0, reserve_buoyancy) * 1.8
		- total_drag * 1.7
		- draft_penalty * 1.8
		- trim_penalty * 1.4
		- heel_penalty * 0.6,
		10.0,
		95.0
	)
	var turn_authority := clampf(
		60.0
		+ roll_resistance * 0.45
		+ pitch_resistance * 0.10
		+ total_brace * 18.0
		+ total_brace_zone * 10.0
		- length_factor * 4.4
		- total_weight * 0.70
		- float(total_cargo) * 3.0
		- draft_penalty * 0.9
		- trim_penalty * 1.4
		- heel_penalty * 1.1
		+ (6.0 if family == PROPULSION_FAMILY_RAFT_PADDLES else 0.0)
		- (4.0 if family == PROPULSION_FAMILY_SAIL_RIG else 0.0)
		+ (8.0 if family == PROPULSION_FAMILY_TWIN_ENGINE else 0.0),
		15.0,
		95.0
	)
	var storm_stability := clampf(
		18.0
		+ roll_resistance * 0.72
		+ freeboard_rating * 0.24
		+ total_brace * 24.0
		+ reserve_buoyancy * 2.8
		- float(total_cargo) * 2.5
		- float(exposed_propulsion_faces) * 2.5
		- absf(heel_bias) * 28.0
		- top_heavy_penalty * 0.34,
		10.0,
		100.0
	)
	var crew_safety := clampf(
		24.0
		+ total_safety
		+ storm_stability * 0.25
		+ float(total_repair) * 12.0
		+ total_recovery_access * 10.0
		+ total_brace * 12.0
		- float(total_cargo) * 4.0
		- float(exposed_propulsion_faces) * 3.0
		- height_penalty * 4.5
		- absf(heel_bias) * 22.0
		- top_heavy_penalty * 0.18,
		5.0,
		100.0
	)
	var repair_coverage := clampf(
		24.0
		+ float(total_repair) * 18.0
		+ total_repair_zone * 20.0
		+ total_brace_zone * 4.0
		+ float(main_block_count) * 1.4
		+ route_ratio * 12.0
		- float(maxi(1, width_span * length_span)) * 1.6,
		10.0,
		100.0
	)
	var propulsion_health_rating := clampf(
		38.0
		+ float(block_counts.get("reinforced_hull", 0)) * 10.0
		+ float(block_counts.get("reinforced_prow", 0)) * 6.0
		+ float(block_counts.get("hull", 0)) * 2.0
		+ float(block_counts.get("utility", 0)) * 6.0
		+ total_propulsion_armor * 18.0
		+ float(protected_propulsion_faces) * 5.0
		+ float(armored_propulsion_faces) * 7.0
		- float(exposed_propulsion_faces) * 7.0
		- float(block_counts.get("twin_engine", 0)) * 4.0
		- asymmetry_penalty * 10.0,
		18.0,
		100.0
	)
	var propulsion_exposure_rating := clampf(
		100.0 - float(exposed_propulsion_faces) * 13.0 + float(armored_propulsion_faces) * 8.0 + total_propulsion_armor * 10.0,
		0.0,
		100.0
	)
	var recovery_access_rating := clampf(
		20.0 + total_recovery_access * 22.0 + float(recovery_cells.size()) * 8.0 + total_safety * 0.24 - maxf(0.0, float(length_span) - 3.0) * 4.0,
		0.0,
		100.0
	)
	var workload := float(defaults.get("workload_base", 50.0))
	workload += float(total_cargo) * 4.0
	workload += maxf(0.0, float(length_span) - 3.0) * 3.5
	workload += maxf(0.0, float(height_span) - 1.0) * 4.0
	workload += maxf(0.0, 1.0 - route_ratio) * 12.0
	workload -= total_repair_zone * 2.0
	workload -= total_brace_zone * 1.8
	workload -= total_recovery_access * 1.5
	workload = clampf(workload, 12.0, 100.0)
	var recommended_crew := clampi(int(ceil(workload / 25.0)), 1, 4)
	var overlay_cells := {}
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := get_builder_block_definition(block_type)
		var cell := _extract_block_layout_cell(block)
		var cell_key := _cell_to_key(cell)
		var neighbor_count := 0
		for neighbor_variant in _get_adjacent_cells(cell):
			if cells_by_key.has(_cell_to_key(neighbor_variant)):
				neighbor_count += 1
		var repair_influence := 0.0
		for source_variant in repair_cells:
			var source := _normalize_blueprint_cell(source_variant)
			var distance := Vector3(float(cell[0] - source[0]), float(cell[1] - source[1]), float(cell[2] - source[2])).length()
			repair_influence = maxf(repair_influence, clampf(1.0 - distance / 4.5, 0.0, 1.0))
		var recovery_influence := 0.0
		for source_variant in recovery_cells:
			var source := _normalize_blueprint_cell(source_variant)
			var distance := Vector3(float(cell[0] - source[0]), float(cell[1] - source[1]), float(cell[2] - source[2])).length()
			recovery_influence = maxf(recovery_influence, clampf(1.0 - distance / 5.0, 0.0, 1.0))
		var route_influence := 1.0 if route_lookup.has(cell_key) else clampf(0.28 + float(neighbor_count) * 0.1, 0.0, 0.72)
		var exposure_influence := 0.0
		if propulsion_cells.has(cell):
			var local_exposed_faces := 0
			for offset_variant in lateral_neighbors:
				var offset: Vector3i = offset_variant
				var neighbor_key := _cell_to_key([cell[0] + offset.x, cell[1] + offset.y, cell[2] + offset.z])
				if not cells_by_key.has(neighbor_key):
					local_exposed_faces += 1
			exposure_influence = clampf(float(local_exposed_faces) / 4.0, 0.0, 1.0)
		var safety_influence := clampf(
			(_get_definition_float(block_def, "safety", 0.0) + _get_definition_float(block_def, "stability", 0.0) * 0.5 + _get_definition_float(block_def, "recovery_access", 0.0) * 3.0) / 12.0,
			0.0,
			1.0
		)
		overlay_cells[cell_key] = {
			"cell": cell,
			"type": block_type,
			"label": str(block_def.get("label", block_type.capitalize())),
			"pathing": route_influence,
			"recovery": recovery_influence,
			"repair": repair_influence,
			"propulsion": exposure_influence,
			"redundancy": clampf((float(neighbor_count) + _get_definition_float(block_def, "redundancy", 0.0)) / 5.0, 0.0, 1.0),
			"safety": safety_influence,
		}
	var station_anchor_cells := {
		"spawn": spawn_cell,
		"helm": helm_anchor,
		"drive": drive_anchor,
		"grapple": salvage_anchor,
		"repair": repair_anchor,
		"brace": brace_anchor,
	}
	var recovery_points := _derive_recovery_points_from_blocks(blocks)
	var has_salvage_station := not salvage_cells.is_empty()
	var has_recovery_access := not recovery_cells.is_empty()
	var required_roles_ok := has_salvage_station and has_recovery_access and route_ratio >= 0.75 and int(station_routes.get("helm", -1)) >= 0 and int(station_routes.get("drive", -1)) >= 0 and int(station_routes.get("repair", -1)) >= 0
	return {
		"block_counts": block_counts,
		"block_count": main_block_count,
		"main_chunk_blocks": main_block_count,
		"weight": total_weight,
		"buoyancy": total_buoyancy,
		"buoyancy_margin": buoyancy_margin,
		"reserve_buoyancy": reserve_buoyancy,
		"center_of_mass_cell": _vector3_to_cell_array(center_of_mass),
		"center_of_buoyancy_cell": _vector3_to_cell_array(center_of_buoyancy),
		"draft_ratio": draft_ratio,
		"roll_resistance": roll_resistance,
		"pitch_resistance": pitch_resistance,
		"heel_bias": heel_bias,
		"trim_bias": trim_bias,
		"freeboard_rating": freeboard_rating,
		"top_heavy_penalty": top_heavy_penalty,
		"hydrostatic_class": hydrostatic_class,
		"top_speed": top_speed,
		"acceleration": acceleration,
		"turn_authority": turn_authority,
		"storm_stability": storm_stability,
		"crew_safety": crew_safety,
		"repair_coverage": repair_coverage,
		"propulsion_health_rating": propulsion_health_rating,
		"propulsion_exposure_rating": propulsion_exposure_rating,
		"propulsion_family": family,
		"propulsion_label": str(defaults.get("label", get_propulsion_family_label(family))),
		"automation_floor": float(defaults.get("automation_floor", 0.65)),
		"manual_ceiling": float(defaults.get("manual_ceiling", 1.0)),
		"burst_ceiling": float(defaults.get("burst_ceiling", 1.1)),
		"workload": workload,
		"recommended_crew": recommended_crew,
		"engine_count": engine_count,
		"propulsion_count": engine_count,
		"salvage_station_count": salvage_cells.size(),
		"salvage_rating": salvage_rating,
		"recovery_access_count": recovery_cells.size(),
		"recovery_access_rating": recovery_access_rating,
		"pathing_score": pathing_score,
		"damage_redundancy": damage_redundancy,
		"max_hull_integrity": clampf(38.0 + total_hull * 18.0 + float(main_block_count) * 1.8, 20.0, 240.0),
		"cargo_capacity": maxi(1, 1 + total_cargo),
		"repair_capacity": maxi(1, mini(REPAIR_SUPPLIES_MAX + 3, REPAIR_SUPPLIES_START + total_repair)),
		"brace_multiplier": clampf(1.0 + total_brace, 1.0, 2.3),
		"span_width": width_span,
		"span_height": height_span,
		"span_length": length_span,
		"exposed_propulsion_faces": exposed_propulsion_faces,
		"protected_propulsion_faces": protected_propulsion_faces,
		"armored_propulsion_faces": armored_propulsion_faces,
		"asymmetry_penalty": asymmetry_penalty,
		"station_routes": station_routes,
		"station_anchor_cells": station_anchor_cells,
		"route_ratio": route_ratio,
		"average_route_steps": average_route_steps,
		"required_roles_ok": required_roles_ok,
		"has_salvage_station": has_salvage_station,
		"has_recovery_access": has_recovery_access,
		"overlay_cells": overlay_cells,
		"recovery_points": recovery_points,
	}

func _build_blueprint_warnings_from_stats(stats: Dictionary, loose_block_count: int) -> Array:
	var warnings: Array = []
	if loose_block_count > 0:
		warnings.append("Loose chunk")
	var reserve_buoyancy := float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0)))
	var draft_ratio := float(stats.get("draft_ratio", 0.0))
	var freeboard_rating := float(stats.get("freeboard_rating", 100.0))
	var top_heavy_penalty := float(stats.get("top_heavy_penalty", 0.0))
	var heel_bias := float(stats.get("heel_bias", 0.0))
	var trim_bias := float(stats.get("trim_bias", 0.0))
	if reserve_buoyancy < 0.0:
		warnings.append("Overweight")
	elif freeboard_rating < 40.0 or draft_ratio > 0.92:
		warnings.append("Low freeboard")
	if top_heavy_penalty >= 26.0:
		warnings.append("Top-heavy")
	if heel_bias <= -0.12:
		warnings.append("Port heavy")
	elif heel_bias >= 0.12:
		warnings.append("Starboard heavy")
	if trim_bias <= -0.12:
		warnings.append("Bow heavy")
	elif trim_bias >= 0.12:
		warnings.append("Stern heavy")
	if not bool(stats.get("has_salvage_station", false)):
		warnings.append("No salvage station is mounted. This hull can launch, but it cannot work wrecks until you add a crane or winch.")
	if not bool(stats.get("has_recovery_access", false)):
		warnings.append("No ladder or rescue net is mounted. Overboard incidents will become much riskier.")
	if not bool(stats.get("required_roles_ok", false)):
		warnings.append("Core deck routes are weak. Spawn-to-station pathing is stretched or blocked for one of the required jobs.")
	if int(stats.get("cargo_capacity", 0)) <= 1:
		warnings.append("Cargo space is minimal. Add cargo blocks to haul more salvage per run.")
	if float(stats.get("crew_safety", 100.0)) < 42.0:
		warnings.append("Crew safety is poor. Expect more overboard pressure and harsher deck hits.")
	if float(stats.get("propulsion_health_rating", 100.0)) < 45.0:
		warnings.append("Propulsion is exposed. Collisions and squalls will cripple speed faster.")
	if float(stats.get("propulsion_exposure_rating", 100.0)) < 40.0:
		warnings.append("Propulsion faces are too exposed. Add armor or hull around the drive before pushing rough water.")
	if float(stats.get("workload", 0.0)) >= 70.0:
		warnings.append("Crew workload is high. This hull wants a full crew to reach its ceiling.")
	if float(stats.get("repair_coverage", 0.0)) < 42.0:
		warnings.append("Repair coverage is thin. Damage control will force longer deck runs.")
	if float(stats.get("recovery_access_rating", 0.0)) < 45.0:
		warnings.append("Recovery coverage is narrow. One bad splash-out could force a long swim back to the hull.")
	if float(stats.get("damage_redundancy", 0.0)) < 42.0:
		warnings.append("Damage redundancy is weak. A single bad detachment may take a whole job offline.")
	if float(stats.get("pathing_score", 0.0)) < 45.0:
		warnings.append("Deck routeing is awkward. Station travel time will punish the crew under pressure.")
	if str(stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES)) == PROPULSION_FAMILY_RAFT_PADDLES:
		warnings.append("No engine blocks mounted. The crew will rely on raft paddles and manual labor for speed.")
	elif str(stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES)) == PROPULSION_FAMILY_SAIL_RIG:
		warnings.append("This hull depends on sail trim. Expect wide speed swings when the wind angle turns against you.")
	return warnings

func get_driver_name() -> String:
	if driver_peer_id <= 0:
		return "Unclaimed"

	var peer_data: Dictionary = peer_snapshot.get(driver_peer_id, {})
	return str(peer_data.get("name", "Peer %d" % driver_peer_id))

func get_player_peer_ids() -> Array:
	var peer_ids: Array = []
	if _has_network_server():
		for peer_id in multiplayer.get_peers():
			var peer_data: Dictionary = peer_snapshot.get(peer_id, {})
			if str(peer_data.get("status", "")) == "hosting":
				continue
			peer_ids.append(peer_id)
		peer_ids.sort()
		return peer_ids

	for peer_id in peer_snapshot.keys():
		var peer_data: Dictionary = peer_snapshot[peer_id]
		if str(peer_data.get("status", "")) == "hosting":
			continue
		peer_ids.append(peer_id)
	peer_ids.sort()
	return peer_ids

func _get_sorted_station_ids() -> Array:
	if station_state.is_empty():
		return STATION_ORDER.duplicate()
	var sorted_ids: Array = []
	for station_id_variant in station_state.keys():
		sorted_ids.append(str(station_id_variant))
	sorted_ids.sort_custom(func(a: String, b: String) -> bool:
		var a_order := int(station_state.get(a, {}).get("sort_order", 999))
		var b_order := int(station_state.get(b, {}).get("sort_order", 999))
		if a_order == b_order:
			return a < b
		return a_order < b_order
	)
	return sorted_ids

func get_station_ids() -> Array:
	return _get_sorted_station_ids()

func get_claimable_station_ids() -> Array:
	var claimable_ids: Array = []
	for station_id_variant in _get_sorted_station_ids():
		var station_id := str(station_id_variant)
		var station_data: Dictionary = station_state.get(station_id, {})
		if not bool(station_data.get("claimable", false)):
			continue
		if not bool(station_data.get("active", true)):
			continue
		claimable_ids.append(station_id)
	return claimable_ids

func get_station_label(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	return str(station_data.get("label", station_id.capitalize()))

func get_station_prompt(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	return str(station_data.get("prompt", ""))

func get_station_category(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	return str(station_data.get("category", ""))

func get_station_position(station_id: String) -> Vector3:
	var station_data: Dictionary = station_state.get(station_id, {})
	return station_data.get("position", Vector3.ZERO)

func get_run_recovery_points() -> Array:
	return Array(run_state.get("recovery_points", RUN_RECOVERY_POINTS)).duplicate(true)

func get_run_peer_repair_range(peer_id: int) -> float:
	return float(_get_peer_repair_profile(peer_id).get("range", RUN_REPAIR_RANGE))

func get_station_occupant_name(station_id: String) -> String:
	var station_data: Dictionary = station_state.get(station_id, {})
	var occupant_peer_id := int(station_data.get("occupant_peer_id", 0))
	if occupant_peer_id <= 0:
		return "Open"

	var peer_data: Dictionary = peer_snapshot.get(occupant_peer_id, {})
	return str(peer_data.get("name", "Peer %d" % occupant_peer_id))

func get_peer_station_id(peer_id: int) -> String:
	for station_id in _get_sorted_station_ids():
		var station_data: Dictionary = station_state.get(station_id, {})
		if int(station_data.get("occupant_peer_id", 0)) == peer_id:
			return station_id
	return ""

func _station_anchor_to_position(anchor_cell_value: Variant, x_offset: float = 0.0, z_offset: float = 0.0) -> Vector3:
	var anchor_cell := _normalize_blueprint_cell(anchor_cell_value)
	var local_position := _block_cell_to_local_position(anchor_cell)
	return Vector3(local_position.x + x_offset, maxf(0.92, local_position.y + 0.92), local_position.z + z_offset)

func _make_station_entry(
	station_id: String,
	label: String,
	position: Vector3,
	category: String,
	sort_order: int,
	claimable: bool = false,
	claim_radius: float = 0.0,
	release_radius: float = 0.0,
	family_role: String = "",
	burst_action: String = "",
	prompt: String = "",
	active: bool = true
) -> Dictionary:
	return {
		"id": station_id,
		"label": label,
		"position": position,
		"category": category,
		"claimable": claimable,
		"claim_radius": claim_radius,
		"release_radius": release_radius,
		"family_role": family_role,
		"burst_action": burst_action,
		"prompt": prompt,
		"active": active,
		"occupant_peer_id": 0,
		"sort_order": sort_order,
	}

func _build_station_state_from_stats(stats: Dictionary) -> Dictionary:
	var anchors := Dictionary(stats.get("station_anchor_cells", {}))
	var propulsion_family := str(stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	var station_entries := {}
	var helm_position := _station_anchor_to_position(anchors.get("helm", [0, 0, -1]), 0.0, -0.18)
	var drive_position := _station_anchor_to_position(anchors.get("drive", [0, 0, -1]), -0.1, 0.05)
	var grapple_position := _station_anchor_to_position(anchors.get("grapple", [1, 0, 0]), 0.24, 0.12)
	var brace_position := _station_anchor_to_position(anchors.get("brace", [-1, 0, 0]), -0.18, 0.18)
	var repair_position := _station_anchor_to_position(anchors.get("repair", [-1, 0, 1]), -0.16, 0.08)
	var salvage_active := bool(stats.get("has_salvage_station", false))
	station_entries["helm"] = _make_station_entry(
		"helm",
		"Helm",
		helm_position,
		"persistent",
		0,
		true,
		RUN_HELM_ZONE_RADIUS,
		RUN_HELM_RELEASE_RADIUS,
		"helm",
		"",
		"Claim the helm to set heading and speed orders."
	)
	station_entries["drive"] = _make_station_entry(
		"drive",
		_get_propulsion_station_label(propulsion_family),
		drive_position,
		"persistent",
		1,
		true,
		RUN_DRIVE_ZONE_RADIUS,
		RUN_DRIVE_RELEASE_RADIUS,
		"drive",
		"",
		"Claim the propulsion station to turn helm intent into real thrust."
	)
	station_entries["grapple"] = _make_station_entry(
		"grapple",
		"Grapple Crane" if salvage_active else "Grapple Offline",
		grapple_position,
		"persistent",
		2,
		salvage_active,
		RUN_GRAPPLE_ZONE_RADIUS,
		RUN_GRAPPLE_RELEASE_RADIUS,
		"grapple",
		"",
		"Work the salvage station once the boat is inside the target ring.",
		salvage_active
	)
	station_entries["brace"] = _make_station_entry(
		"brace",
		"Brace Anywhere",
		brace_position,
		"deck_action",
		3,
		false,
		0.0,
		0.0,
		"brace",
		"brace",
		"Brace anywhere on deck when impacts or squalls are about to land."
	)
	station_entries["repair"] = _make_station_entry(
		"repair",
		"Patch Nearby Hull",
		repair_position,
		"deck_action",
		4,
		false,
		0.0,
		0.0,
		"repair",
		"repair",
		"Patch nearby hull sections from the deck while patch kits last."
	)
	match propulsion_family:
		PROPULSION_FAMILY_SAIL_RIG:
			station_entries["trim"] = _make_station_entry(
				"trim",
				"Trim Lines",
				drive_position + Vector3(-0.8, 0.0, 0.18),
				"burst",
				5,
				false,
				0.0,
				0.0,
				"propulsion",
				"trim",
				"Press G at the drive station to pull the sail into the wind."
			)
			station_entries["reef"] = _make_station_entry(
				"reef",
				"Reef Point",
				drive_position + Vector3(0.78, 0.0, 0.24),
				"burst",
				6,
				false,
				0.0,
				0.0,
				"propulsion",
				"reef",
				"Press R at the drive station to reef when a bad angle or storm starts stealing drive."
			)
		PROPULSION_FAMILY_STEAM_TUG:
			station_entries["boiler"] = _make_station_entry(
				"boiler",
				"Boiler Feed",
				drive_position + Vector3(-0.74, 0.0, 0.16),
				"burst",
				5,
				false,
				0.0,
				0.0,
				"propulsion",
				"stoke",
				"Press G at the drive station to stoke pressure and sharpen response."
			)
			station_entries["vent"] = _make_station_entry(
				"vent",
				"Vent Valve",
				drive_position + Vector3(0.72, 0.0, 0.2),
				"burst",
				6,
				false,
				0.0,
				0.0,
				"propulsion",
				"vent",
				"Press R at the drive station to dump heat and clear overpressure."
			)
		PROPULSION_FAMILY_TWIN_ENGINE:
			station_entries["cool_port"] = _make_station_entry(
				"cool_port",
				"Port Cooling",
				drive_position + Vector3(-0.84, 0.0, 0.18),
				"burst",
				5,
				false,
				0.0,
				0.0,
				"propulsion",
				"cool_port",
				"Press R at the drive station to bleed engine heat before desync spreads."
			)
			station_entries["cool_starboard"] = _make_station_entry(
				"cool_starboard",
				"Starboard Cooling",
				drive_position + Vector3(0.84, 0.0, 0.18),
				"burst",
				6,
				false,
				0.0,
				0.0,
				"propulsion",
				"cool_starboard",
				"Press G at the drive station to keep the pair in sync and keep acceleration sharp."
			)
		_:
			station_entries["paddle_port"] = _make_station_entry(
				"paddle_port",
				"Port Stroke",
				drive_position + Vector3(-0.82, 0.0, 0.16),
				"burst",
				5,
				false,
				0.0,
				0.0,
				"propulsion",
				"stroke_port",
				"Raft paddles respond best when someone keeps the port side digging."
			)
			station_entries["paddle_starboard"] = _make_station_entry(
				"paddle_starboard",
				"Starboard Stroke",
				drive_position + Vector3(0.82, 0.0, 0.16),
				"burst",
				6,
				false,
				0.0,
				0.0,
				"propulsion",
				"stroke_starboard",
				"Backwater and burst strokes keep paddle hulls from yawing off line."
			)
	var recovery_points := Array(stats.get("recovery_points", []))
	var recovery_sort_order := 10
	for target_variant in recovery_points:
		var target: Dictionary = target_variant
		station_entries[str(target.get("id", "recovery_%d" % recovery_sort_order))] = _make_station_entry(
			str(target.get("id", "recovery_%d" % recovery_sort_order)),
			str(target.get("label", "Recovery")),
			target.get("deck_position", Vector3.ZERO),
			"recovery",
			recovery_sort_order,
			false,
			0.0,
			0.0,
			"recovery",
			"recover",
			"Overboard crew can grab this recovery point to climb back aboard.",
			bool(stats.get("has_recovery_access", false))
		)
		recovery_sort_order += 1
	return station_entries

func _apply_station_state_from_stats(stats: Dictionary) -> void:
	var previous_station_state := station_state.duplicate(true)
	var next_station_state := _build_station_state_from_stats(stats)
	for station_id_variant in next_station_state.keys():
		var station_id := str(station_id_variant)
		var next_station: Dictionary = next_station_state[station_id]
		if previous_station_state.has(station_id):
			var previous_station: Dictionary = previous_station_state.get(station_id, {})
			var occupant_peer_id := int(previous_station.get("occupant_peer_id", 0))
			if occupant_peer_id > 0 and bool(next_station.get("claimable", false)) and bool(next_station.get("active", true)):
				next_station["occupant_peer_id"] = occupant_peer_id
		next_station_state[station_id] = next_station
	station_state = next_station_state
	if driver_peer_id > 0 and get_peer_station_id(driver_peer_id) != "helm":
		_set_driver(0, false)

func request_driver_control() -> void:
	request_station_claim("helm")

func request_station_claim(station_id: String) -> void:
	if multiplayer.multiplayer_peer == null:
		_claim_station(OFFLINE_LOCAL_PEER_ID, station_id)
		return
	if multiplayer.is_server():
		_claim_station(multiplayer.get_unique_id(), station_id)
		return

	server_request_station_claim.rpc_id(1, station_id)

func request_station_release() -> void:
	if multiplayer.multiplayer_peer == null:
		_release_station(OFFLINE_LOCAL_PEER_ID)
		return
	if multiplayer.is_server():
		_release_station(multiplayer.get_unique_id())
		return

	server_request_station_release.rpc_id(1)

func request_unlock_builder_block(block_type: String) -> void:
	var normalized_block_type := block_type.strip_edges().to_lower()
	if normalized_block_type.is_empty():
		return
	if multiplayer.multiplayer_peer == null:
		_unlock_builder_block(OFFLINE_LOCAL_PEER_ID, normalized_block_type)
		return
	if multiplayer.is_server():
		_unlock_builder_block(multiplayer.get_unique_id(), normalized_block_type)
		return

	server_request_unlock_builder_block.rpc_id(1, normalized_block_type)

func request_donate_workshop_resource(resource_id: String, quantity: int) -> bool:
	var normalized_resource_id := resource_id.strip_edges().to_lower()
	var amount := maxi(0, quantity)
	if normalized_resource_id.is_empty() or amount <= 0:
		return false
	if not DockState.remove_local_resource(normalized_resource_id, amount):
		return false
	if multiplayer.multiplayer_peer == null:
		_donate_workshop_resource(OFFLINE_LOCAL_PEER_ID, normalized_resource_id, amount)
		return true
	if multiplayer.is_server():
		_donate_workshop_resource(multiplayer.get_unique_id(), normalized_resource_id, amount)
		return true
	server_request_donate_workshop_resource.rpc_id(1, normalized_resource_id, amount)
	return true

func request_brace() -> void:
	if multiplayer.is_server():
		_begin_brace(multiplayer.get_unique_id())
		return

	server_request_brace.rpc_id(1)

func request_grapple() -> void:
	if multiplayer.is_server():
		_process_grapple(multiplayer.get_unique_id())
		return

	server_request_grapple.rpc_id(1)

func request_repair() -> void:
	if multiplayer.is_server():
		_process_repair(multiplayer.get_unique_id())
		return

	server_request_repair.rpc_id(1)

func request_propulsion_primary() -> void:
	if multiplayer.is_server():
		_process_propulsion_primary(multiplayer.get_unique_id())
		return

	server_request_propulsion_primary.rpc_id(1)

func request_propulsion_secondary() -> void:
	if multiplayer.is_server():
		_process_propulsion_secondary(multiplayer.get_unique_id())
		return

	server_request_propulsion_secondary.rpc_id(1)

func request_overboard_recovery() -> void:
	if multiplayer.is_server():
		_attempt_overboard_recovery(multiplayer.get_unique_id())
		return

	server_request_overboard_recovery.rpc_id(1)

func request_assist_rally(target_peer_id: int) -> void:
	if target_peer_id <= 0:
		return
	if multiplayer.is_server():
		_attempt_assist_rally(multiplayer.get_unique_id(), target_peer_id)
		return

	server_request_assist_rally.rpc_id(1, target_peer_id)

func request_debug_overboard() -> void:
	if multiplayer.is_server():
		_force_peer_overboard_for_debug(multiplayer.get_unique_id())
		return

	server_request_debug_overboard.rpc_id(1)

func request_local_overboard_transition(world_position: Vector3, velocity: Vector3, facing_y: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	var sanitized_world_position := _sanitize_overboard_world_position(world_position)
	var sanitized_velocity := velocity.limit_length(6.8)
	if multiplayer.is_server():
		_request_peer_overboard_transition(multiplayer.get_unique_id(), sanitized_world_position, sanitized_velocity, facing_y)
		return

	server_request_local_overboard_transition.rpc_id(1, sanitized_world_position, sanitized_velocity, facing_y)

func request_place_blueprint_block(cell_value: Variant, block_type: String, rotation_steps: int) -> void:
	var cell := _normalize_blueprint_cell(cell_value)
	var normalized_type := block_type.strip_edges().to_lower()
	var normalized_rotation := wrapi(rotation_steps, 0, 4)
	if multiplayer.multiplayer_peer == null:
		_place_blueprint_block(OFFLINE_LOCAL_PEER_ID, cell, normalized_type, normalized_rotation)
		return
	if multiplayer.is_server():
		_place_blueprint_block(multiplayer.get_unique_id(), cell, normalized_type, normalized_rotation)
		return

	server_request_place_blueprint_block.rpc_id(1, cell, normalized_type, normalized_rotation)

func request_remove_blueprint_block(cell_value: Variant) -> void:
	var cell := _normalize_blueprint_cell(cell_value)
	if multiplayer.multiplayer_peer == null:
		_remove_blueprint_block(OFFLINE_LOCAL_PEER_ID, cell)
		return
	if multiplayer.is_server():
		_remove_blueprint_block(multiplayer.get_unique_id(), cell)
		return

	server_request_remove_blueprint_block.rpc_id(1, cell)

func request_reset_blueprint() -> void:
	if multiplayer.multiplayer_peer == null:
		_reset_blueprint_for_peer(OFFLINE_LOCAL_PEER_ID)
		return
	if multiplayer.is_server():
		_reset_blueprint_for_peer(multiplayer.get_unique_id())
		return

	server_request_reset_blueprint.rpc_id(1)

func request_launch_run() -> void:
	if multiplayer.multiplayer_peer == null:
		_launch_run_session(OFFLINE_LOCAL_PEER_ID)
		return
	if multiplayer.is_server():
		_launch_run_session(multiplayer.get_unique_id())
		return

	server_request_launch_run.rpc_id(1)

func request_return_to_hangar() -> void:
	if multiplayer.multiplayer_peer == null:
		_return_to_hangar_session(OFFLINE_LOCAL_PEER_ID)
		return
	if multiplayer.is_server():
		_return_to_hangar_session(multiplayer.get_unique_id())
		return

	server_request_return_to_hangar.rpc_id(1)

func send_local_hangar_avatar_state(position: Vector3, velocity: Vector3, facing_y: float, grounded: bool) -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if multiplayer.multiplayer_peer == null:
		_receive_hangar_avatar_state(
			OFFLINE_LOCAL_PEER_ID,
			position,
			velocity,
			facing_y,
			grounded,
			"",
			0,
			[0, 0, 0],
			[0, 0, 0],
			false,
			"hidden"
		)
		return
	if multiplayer.is_server():
		_receive_hangar_avatar_state(
			multiplayer.get_unique_id(),
			position,
			velocity,
			facing_y,
			grounded,
			"",
			0,
			[0, 0, 0],
			[0, 0, 0],
			false,
			"hidden"
		)
		return
	server_receive_hangar_avatar_state.rpc_id(
		1,
		position,
		velocity,
		facing_y,
		grounded,
		"",
		0,
		[0, 0, 0],
		[0, 0, 0],
		false,
		"hidden"
	)

func send_local_hangar_avatar_presence(
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	var normalized_target_cell := _normalize_blueprint_cell(target_cell_value)
	var normalized_remove_cell := _normalize_blueprint_cell(remove_cell_value)
	if multiplayer.multiplayer_peer == null:
		_receive_hangar_avatar_state(
			OFFLINE_LOCAL_PEER_ID,
			position,
			velocity,
			facing_y,
			grounded,
			selected_block_id,
			rotation_steps,
			normalized_target_cell,
			normalized_remove_cell,
			has_target,
			target_feedback_state
		)
		return
	if multiplayer.is_server():
		_receive_hangar_avatar_state(
			multiplayer.get_unique_id(),
			position,
			velocity,
			facing_y,
			grounded,
			selected_block_id,
			rotation_steps,
			normalized_target_cell,
			normalized_remove_cell,
			has_target,
			target_feedback_state
		)
		return
	server_receive_hangar_avatar_state.rpc_id(
		1,
		position,
		velocity,
		facing_y,
		grounded,
		selected_block_id,
		rotation_steps,
		normalized_target_cell,
		normalized_remove_cell,
		has_target,
		target_feedback_state
	)

func send_local_run_avatar_state(deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, avatar_mode: String = RUN_AVATAR_MODE_DECK) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if multiplayer.is_server():
		_receive_run_avatar_state(multiplayer.get_unique_id(), deck_position, world_position, velocity, facing_y, grounded, avatar_mode)
		return
	server_receive_run_avatar_state.rpc_id(1, deck_position, world_position, velocity, facing_y, grounded, avatar_mode)

func send_local_boat_input(throttle: float, steer: float) -> void:
	var clamped_throttle := clampf(throttle, -1.0, 1.0)
	var clamped_steer := clampf(steer, -1.0, 1.0)
	if multiplayer.is_server():
		_receive_boat_input(multiplayer.get_unique_id(), clamped_throttle, clamped_steer)
		return

	server_receive_boat_input.rpc_id(1, clamped_throttle, clamped_steer)

func _get_drive_station_occupant_peer_id() -> int:
	return int(station_state.get("drive", {}).get("occupant_peer_id", 0))

func _apply_propulsion_damage(amount: float, severity_boost: float = 0.0, fault_state: String = PROPULSION_FAULT_STATE_LABORING) -> bool:
	if amount <= 0.0:
		return false
	var protection_rating := clampf(float(boat_state.get("propulsion_health_rating", 100.0)), 18.0, 100.0)
	var exposure_rating := clampf(float(boat_state.get("propulsion_exposure_rating", protection_rating)), 0.0, 100.0)
	var damage_multiplier := clampf(1.12 - protection_rating / 165.0 - exposure_rating / 260.0, 0.52, 1.3)
	amount *= damage_multiplier
	var max_health := maxf(1.0, float(boat_state.get("propulsion_health_rating", 100.0)))
	var current_health := clampf(float(boat_state.get("propulsion_health", max_health)), 0.0, max_health)
	var next_health := clampf(current_health - amount, 0.0, max_health)
	var current_severity := clampf(float(boat_state.get("fault_severity", 0.0)), 0.0, 1.0)
	var next_severity := clampf(maxf(current_severity, severity_boost), 0.0, 1.0)
	boat_state["propulsion_health"] = next_health
	boat_state["fault_severity"] = next_severity
	if next_health <= max_health * 0.2:
		boat_state["fault_state"] = PROPULSION_FAULT_STATE_CRIPPLED
	elif next_severity > 0.0:
		boat_state["fault_state"] = fault_state
	return not is_equal_approx(current_health, next_health) or not is_equal_approx(current_severity, next_severity)

func _process_propulsion_primary(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	if get_peer_station_id(peer_id) != "drive":
		return
	var family := str(boat_state.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	if family == PROPULSION_FAMILY_RAFT_PADDLES and not _spend_peer_stamina(peer_id, PROPULSION_MANUAL_PADDLE_STAMINA_COST, true):
		_set_status("%s is too winded to dig the paddles in." % _get_peer_name(peer_id))
		return
	boat_state["propulsion_support_timer"] = PROPULSION_SUPPORT_ACTION_SECONDS
	boat_state["propulsion_support_boost"] = clampf(float(boat_state.get("propulsion_support_boost", 0.0)) + 0.55, 0.0, 1.0)
	boat_state["fault_severity"] = maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - 0.08)
	match family:
		PROPULSION_FAMILY_SAIL_RIG:
			boat_state["propulsion_trim"] = clampf(float(boat_state.get("propulsion_trim", 1.0)) + 0.18, 0.0, 1.1)
			boat_state["propulsion_sync"] = clampf(float(boat_state.get("propulsion_sync", 0.0)) + 0.12, 0.0, 1.15)
			_set_status("%s trimmed the sail." % _get_peer_name(peer_id))
		PROPULSION_FAMILY_STEAM_TUG:
			boat_state["propulsion_pressure"] = clampf(float(boat_state.get("propulsion_pressure", 0.0)) + 0.14, 0.0, 1.15)
			boat_state["propulsion_side_bias"] = move_toward(float(boat_state.get("propulsion_side_bias", 0.0)), 0.0, 0.22)
			_set_status("%s stoked the boiler." % _get_peer_name(peer_id))
		PROPULSION_FAMILY_TWIN_ENGINE:
			boat_state["propulsion_sync"] = clampf(float(boat_state.get("propulsion_sync", 0.0)) + 0.16, 0.0, 1.2)
			boat_state["propulsion_side_bias"] = clampf(float(boat_state.get("propulsion_side_bias", 0.0)) + float(boat_state.get("rudder_input", 0.0)) * 0.18, -1.0, 1.0)
			_set_status("%s tuned the engines." % _get_peer_name(peer_id))
		_:
			boat_state["propulsion_sync"] = clampf(float(boat_state.get("propulsion_sync", 0.0)) + 0.12, 0.0, 1.15)
			boat_state["propulsion_side_bias"] = clampf(float(boat_state.get("propulsion_side_bias", 0.0)) + float(boat_state.get("rudder_input", 0.0)) * 0.34, -1.0, 1.0)
			_set_status("%s dug the paddles in." % _get_peer_name(peer_id))
	_broadcast_boat_state()

func _process_propulsion_secondary(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	if get_peer_station_id(peer_id) != "drive":
		return
	var family := str(boat_state.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	boat_state["propulsion_secondary_timer"] = PROPULSION_SECONDARY_ACTION_SECONDS
	match family:
		PROPULSION_FAMILY_SAIL_RIG:
			boat_state["propulsion_trim"] = clampf(float(boat_state.get("propulsion_trim", 1.0)) - 0.16, 0.45, 1.0)
			boat_state["fault_severity"] = maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - 0.1)
			_set_status("%s reefed the sail." % _get_peer_name(peer_id))
		PROPULSION_FAMILY_STEAM_TUG:
			boat_state["propulsion_heat"] = maxf(0.0, float(boat_state.get("propulsion_heat", 0.0)) - 0.28)
			boat_state["propulsion_pressure"] = maxf(0.0, float(boat_state.get("propulsion_pressure", 0.0)) - 0.2)
			boat_state["propulsion_side_bias"] = move_toward(float(boat_state.get("propulsion_side_bias", 0.0)), 0.0, 0.3)
			boat_state["fault_severity"] = maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - 0.2)
			if str(boat_state.get("fault_state", PROPULSION_FAULT_STATE_STABLE)) == PROPULSION_FAULT_STATE_OVERPRESSURE:
				boat_state["fault_state"] = PROPULSION_FAULT_STATE_STABLE
			_set_status("%s vented the boiler." % _get_peer_name(peer_id))
		PROPULSION_FAMILY_TWIN_ENGINE:
			boat_state["propulsion_heat"] = maxf(0.0, float(boat_state.get("propulsion_heat", 0.0)) - 0.32)
			boat_state["propulsion_side_bias"] = clampf(float(boat_state.get("propulsion_side_bias", 0.0)) - float(boat_state.get("rudder_input", 0.0)) * 0.22, -1.0, 1.0)
			boat_state["fault_severity"] = maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - 0.18)
			if str(boat_state.get("fault_state", PROPULSION_FAULT_STATE_STABLE)) == PROPULSION_FAULT_STATE_OVERHEATED:
				boat_state["fault_state"] = PROPULSION_FAULT_STATE_STABLE
			_set_status("%s bled heat out of the engines." % _get_peer_name(peer_id))
		_:
			boat_state["speed"] = move_toward(float(boat_state.get("speed", 0.0)), 0.0, BOAT_DECELERATION * 0.55)
			boat_state["propulsion_side_bias"] = clampf(float(boat_state.get("propulsion_side_bias", 0.0)) - signf(float(boat_state.get("speed", 0.0))) * 0.42, -1.0, 1.0)
			boat_state["fault_severity"] = maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - 0.08)
			_set_status("%s backwatered to scrub speed." % _get_peer_name(peer_id))
	_broadcast_boat_state()

func _step_propulsion_state(delta: float, throttle_intent: float, steer_intent: float, top_speed_limit: float) -> Dictionary:
	var family := str(boat_state.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	var automation_floor := clampf(float(boat_state.get("automation_floor", 0.65)), 0.2, 1.0)
	var manual_ceiling := maxf(automation_floor, float(boat_state.get("manual_ceiling", 1.0)))
	var burst_ceiling := maxf(manual_ceiling, float(boat_state.get("burst_ceiling", PROPULSION_BURST_SPEED_MULTIPLIER)))
	var support_timer := maxf(0.0, float(boat_state.get("propulsion_support_timer", 0.0)) - delta)
	var secondary_timer := maxf(0.0, float(boat_state.get("propulsion_secondary_timer", 0.0)) - delta)
	var support_boost := maxf(0.0, float(boat_state.get("propulsion_support_boost", 0.0)) - delta * 0.24)
	var fault_severity := clampf(maxf(0.0, float(boat_state.get("fault_severity", 0.0)) - PROPULSION_FAULT_RECOVERY_RATE * delta), 0.0, 1.0)
	var propulsion_health_rating := maxf(1.0, float(boat_state.get("propulsion_health_rating", 100.0)))
	var propulsion_health := clampf(float(boat_state.get("propulsion_health", propulsion_health_rating)), 0.0, propulsion_health_rating)
	var propulsion_health_factor := clampf(propulsion_health / propulsion_health_rating, 0.22, 1.0)
	var drive_occupied := _get_drive_station_occupant_peer_id() > 0
	var occupant_bonus := 0.08 if drive_occupied else 0.0
	var throttle_demand := absf(throttle_intent)
	var propulsion_heat := clampf(float(boat_state.get("propulsion_heat", 0.0)), 0.0, 1.3)
	var propulsion_pressure := clampf(float(boat_state.get("propulsion_pressure", 0.0)), 0.0, 1.2)
	var propulsion_trim := clampf(float(boat_state.get("propulsion_trim", 1.0)), 0.0, 1.1)
	var propulsion_sync := clampf(float(boat_state.get("propulsion_sync", automation_floor)), 0.0, 1.2)
	var propulsion_side_bias := clampf(float(boat_state.get("propulsion_side_bias", 0.0)), -1.0, 1.0)
	var propulsion_port_output := clampf(float(boat_state.get("propulsion_port_output", automation_floor * 0.5)), 0.0, burst_ceiling)
	var propulsion_starboard_output := clampf(float(boat_state.get("propulsion_starboard_output", automation_floor * 0.5)), 0.0, burst_ceiling)
	var efficiency_bonus := 0.0
	var response_multiplier := 1.0
	var yaw_bias := 0.0
	var fault_state := str(boat_state.get("fault_state", PROPULSION_FAULT_STATE_STABLE))

	match family:
		PROPULSION_FAMILY_SAIL_RIG:
			var heading_y := float(boat_state.get("rotation_y", 0.0))
			var boat_forward := -Vector3.FORWARD.rotated(Vector3.UP, heading_y)
			var wind_heading := float(run_state.get("wind_heading", 0.0))
			var wind_vector := -Vector3.FORWARD.rotated(Vector3.UP, wind_heading)
			var tailwind_alignment := clampf((boat_forward.dot(wind_vector) + 1.0) * 0.5, 0.0, 1.0)
			var sail_window := clampf(0.18 + tailwind_alignment * float(run_state.get("wind_strength", 0.75)), 0.1, 1.0)
			var trim_target := clampf(0.72 + tailwind_alignment * 0.28 + support_boost * 0.08, 0.55, 1.05)
			propulsion_trim = move_toward(propulsion_trim, trim_target, delta * (1.0 + support_boost * 0.5))
			propulsion_sync = move_toward(propulsion_sync, clampf(automation_floor + occupant_bonus + support_boost * 0.18, automation_floor, burst_ceiling), delta * 1.2)
			propulsion_heat = maxf(0.0, propulsion_heat - delta * 0.18)
			propulsion_side_bias = move_toward(propulsion_side_bias, 0.0, delta * 0.85)
			propulsion_port_output = move_toward(propulsion_port_output, clampf(propulsion_sync * 0.5, 0.0, burst_ceiling), delta * 1.2)
			propulsion_starboard_output = move_toward(propulsion_starboard_output, clampf(propulsion_sync * 0.5, 0.0, burst_ceiling), delta * 1.2)
			efficiency_bonus = sail_window * 0.26 + propulsion_trim * 0.1 + occupant_bonus + support_boost * 0.14 - absf(propulsion_trim - trim_target) * 0.2
			response_multiplier = 0.68 + sail_window * 0.26
			if sail_window < 0.28:
				fault_state = PROPULSION_FAULT_STATE_LABORING
				fault_severity = maxf(fault_severity, 0.22)
		PROPULSION_FAMILY_STEAM_TUG:
			var pressure_target := 0.18 + throttle_demand * 0.78 + support_boost * 0.12
			propulsion_pressure = move_toward(propulsion_pressure, clampf(pressure_target, 0.0, 1.1), delta * (1.0 + support_boost * 0.4))
			propulsion_heat = clampf(propulsion_heat + throttle_demand * delta * 0.32 + support_boost * delta * 0.12 - ((0.28 if secondary_timer > 0.0 else 0.1) * delta), 0.0, 1.25)
			var pressure_error := absf(clampf(propulsion_pressure - 0.18, 0.0, 0.92) / 0.92 - throttle_demand)
			propulsion_sync = move_toward(propulsion_sync, 1.0 - pressure_error, delta * 1.2)
			propulsion_side_bias = move_toward(propulsion_side_bias, 0.0, delta * 1.1)
			propulsion_port_output = move_toward(propulsion_port_output, clampf(propulsion_pressure * 0.5, 0.0, burst_ceiling), delta * 1.05)
			propulsion_starboard_output = move_toward(propulsion_starboard_output, clampf(propulsion_pressure * 0.5, 0.0, burst_ceiling), delta * 1.05)
			efficiency_bonus = 0.18 + occupant_bonus + support_boost * 0.24 - pressure_error * 0.24
			response_multiplier = 0.54 + propulsion_pressure * 0.72
			if propulsion_pressure > 1.02:
				fault_state = PROPULSION_FAULT_STATE_OVERPRESSURE
				fault_severity = maxf(fault_severity, 0.46)
			elif propulsion_heat > 0.95:
				fault_state = PROPULSION_FAULT_STATE_OVERHEATED
				fault_severity = maxf(fault_severity, 0.38)
		PROPULSION_FAMILY_TWIN_ENGINE:
			var damage_bias := clampf((1.0 - propulsion_health_factor) * 0.72 + fault_severity * 0.26, 0.0, 0.7)
			propulsion_sync = move_toward(propulsion_sync, clampf(automation_floor + occupant_bonus + support_boost * 0.34 - damage_bias * 0.18, 0.0, 1.15), delta * 1.35)
			propulsion_trim = move_toward(propulsion_trim, clampf(1.0 - absf(steer_intent) * 0.14, 0.72, 1.0), delta * 1.8)
			propulsion_heat = clampf(propulsion_heat + throttle_demand * delta * 0.38 + support_boost * delta * 0.18 - ((0.3 if secondary_timer > 0.0 else 0.1) * delta), 0.0, 1.28)
			propulsion_side_bias = move_toward(propulsion_side_bias, clampf(steer_intent * 0.28, -0.35, 0.35), delta * 0.9)
			propulsion_port_output = move_toward(propulsion_port_output, clampf((propulsion_sync - propulsion_side_bias - damage_bias) * 0.52, 0.12, burst_ceiling), delta * 1.4)
			propulsion_starboard_output = move_toward(propulsion_starboard_output, clampf((propulsion_sync + propulsion_side_bias + damage_bias) * 0.52, 0.12, burst_ceiling), delta * 1.4)
			efficiency_bonus = 0.14 + propulsion_sync * 0.18 + support_boost * 0.18 - (1.0 - propulsion_trim) * 0.22
			response_multiplier = 0.98 + propulsion_sync * 0.22
			yaw_bias = (propulsion_starboard_output - propulsion_port_output) * 0.28
			if propulsion_heat > 0.92:
				fault_state = PROPULSION_FAULT_STATE_OVERHEATED
				fault_severity = maxf(fault_severity, 0.36)
			elif propulsion_health_factor < 0.4:
				fault_state = PROPULSION_FAULT_STATE_DESYNC
				fault_severity = maxf(fault_severity, 0.28)
		_:
			var drift_bias := 0.0
			if throttle_demand > 0.35 and not drive_occupied:
				drift_bias = sin(float(run_state.get("elapsed_time", 0.0)) * 1.2) * 0.24
			propulsion_pressure = move_toward(propulsion_pressure, throttle_demand, delta * (1.2 + support_boost * 0.5))
			propulsion_side_bias = move_toward(propulsion_side_bias, clampf(steer_intent * 0.52 + drift_bias, -0.8, 0.8), delta * (1.1 if drive_occupied else 0.55))
			propulsion_sync = move_toward(propulsion_sync, clampf(automation_floor + occupant_bonus + support_boost * 0.42, automation_floor, burst_ceiling), delta * 1.6)
			propulsion_heat = clampf(propulsion_heat + throttle_demand * delta * 0.18 - (0.2 * delta), 0.0, 1.0)
			var paddle_side_target := clampf(propulsion_sync * 0.5, 0.14, burst_ceiling)
			propulsion_port_output = move_toward(propulsion_port_output, clampf(paddle_side_target - propulsion_side_bias * 0.24, 0.12, burst_ceiling), delta * 1.5)
			propulsion_starboard_output = move_toward(propulsion_starboard_output, clampf(paddle_side_target + propulsion_side_bias * 0.24, 0.12, burst_ceiling), delta * 1.5)
			var average_output := (propulsion_port_output + propulsion_starboard_output) * 0.5
			efficiency_bonus = occupant_bonus + support_boost * 0.36 + average_output * 0.18 - absf(propulsion_starboard_output - propulsion_port_output) * 0.1
			response_multiplier = 0.82 + propulsion_sync * 0.34
			yaw_bias = (propulsion_starboard_output - propulsion_port_output) * (0.42 if drive_occupied else 0.76)
			if throttle_demand > 0.5 and not drive_occupied:
				fault_state = PROPULSION_FAULT_STATE_LABORING
				fault_severity = maxf(fault_severity, 0.18)

	var storm_drag := float(boat_state.get("squall_drag_multiplier", 1.0))
	if storm_drag < 0.8 and float(boat_state.get("storm_stability", 50.0)) < 45.0:
		fault_state = PROPULSION_FAULT_STATE_LABORING
		fault_severity = maxf(fault_severity, 0.16)

	if propulsion_health_factor <= 0.2:
		fault_state = PROPULSION_FAULT_STATE_CRIPPLED
		fault_severity = maxf(fault_severity, 0.65)
	elif fault_severity <= 0.02:
		fault_state = PROPULSION_FAULT_STATE_STABLE

	var fault_penalty := fault_severity * 0.3 + (1.0 - propulsion_health_factor) * 0.22
	var propulsion_efficiency := clampf((automation_floor + efficiency_bonus - fault_penalty) * lerpf(0.58, 1.0, propulsion_health_factor), 0.2, burst_ceiling)
	propulsion_efficiency = minf(propulsion_efficiency, burst_ceiling if support_timer > 0.0 else manual_ceiling)
	var acceleration_factor := clampf(float(boat_state.get("acceleration_rating", 50.0)) / 60.0, 0.35, 1.6) * response_multiplier * propulsion_health_factor
	var reverse_scale := 0.62 if family == PROPULSION_FAMILY_RAFT_PADDLES else 0.52
	var target_speed := throttle_intent * top_speed_limit * propulsion_efficiency
	if throttle_intent < 0.0:
		target_speed = throttle_intent * top_speed_limit * reverse_scale * propulsion_efficiency
	return {
		"support_timer": support_timer,
		"secondary_timer": secondary_timer,
		"support_boost": support_boost,
		"fault_state": fault_state,
		"fault_severity": fault_severity,
		"propulsion_heat": propulsion_heat,
		"propulsion_pressure": propulsion_pressure,
		"propulsion_trim": propulsion_trim,
		"propulsion_sync": propulsion_sync,
		"propulsion_port_output": propulsion_port_output,
		"propulsion_starboard_output": propulsion_starboard_output,
		"propulsion_side_bias": propulsion_side_bias,
		"propulsion_efficiency": propulsion_efficiency,
		"target_speed": target_speed,
		"acceleration_factor": acceleration_factor,
		"rudder_response": clampf(PROPULSION_RUDDER_RESPONSE_BASE + propulsion_sync * 0.24 - fault_severity * 0.18, 0.28, 1.18),
		"yaw_bias": yaw_bias,
	}

func _step_boat_buoyancy(delta: float, world_position: Vector3, rotation_y: float, forward_speed: float) -> Dictionary:
	var draft_ratio := clampf(float(boat_state.get("draft_ratio", 0.72)), 0.28, 1.15)
	var reserve_buoyancy := float(boat_state.get("reserve_buoyancy", 0.0))
	var roll_resistance := clampf(float(boat_state.get("roll_resistance", 50.0)) / 100.0, 0.0, 1.0)
	var pitch_resistance := clampf(float(boat_state.get("pitch_resistance", 50.0)) / 100.0, 0.0, 1.0)
	var heel_bias := float(boat_state.get("heel_bias", 0.0))
	var trim_bias := float(boat_state.get("trim_bias", 0.0))
	var hull_length := maxf(3.2, float(boat_state.get("hull_length", 4.4)))
	var hull_beam := maxf(1.9, float(boat_state.get("hull_beam", 2.7)))
	var wave_pose := sample_boat_wave_pose(world_position, rotation_y, hull_length, hull_beam)
	var surface_offset := float(wave_pose.get("height", 0.0))
	var rest_ride_height := 0.36 - clampf((draft_ratio - 0.72) * 0.85, -0.04, 0.34)
	var probe_keel_offset := -clampf(0.30 + draft_ratio * 0.38, 0.30, 0.76)
	var rest_probe_depth := clampf(0.18 + draft_ratio * 0.46, 0.22, 0.72)
	var heave := float(boat_state.get("buoyancy_heave", 0.0))
	var heave_velocity := float(boat_state.get("buoyancy_heave_velocity", 0.0))
	var pitch_angle := float(boat_state.get("buoyancy_pitch", 0.0))
	var pitch_velocity := float(boat_state.get("buoyancy_pitch_velocity", 0.0))
	var roll_angle := float(boat_state.get("buoyancy_roll", 0.0))
	var roll_velocity := float(boat_state.get("buoyancy_roll_velocity", 0.0))
	var boat_center_y := SEA_SURFACE_Y + surface_offset + rest_ride_height + heave
	var forward := -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	var right := Vector3.RIGHT.rotated(Vector3.UP, rotation_y)
	var bow_distance := hull_length * 0.52
	var stern_distance := hull_length * 0.42
	var side_distance := hull_beam * 0.46
	var probe_offsets: Array[Vector2] = [
		Vector2(-side_distance, bow_distance),
		Vector2(side_distance, bow_distance),
		Vector2(-side_distance, -stern_distance),
		Vector2(side_distance, -stern_distance),
	]
	var probe_depths: Array[float] = []
	for probe_offset in probe_offsets:
		var probe_world_position: Vector3 = world_position + forward * probe_offset.y + right * probe_offset.x
		var probe_surface_y: float = get_wave_surface_height(probe_world_position)
		var probe_hull_y: float = boat_center_y + probe_offset.y * sin(pitch_angle) + probe_offset.x * sin(roll_angle) + probe_keel_offset
		probe_depths.append(probe_surface_y - probe_hull_y)

	var average_depth := 0.0
	for depth in probe_depths:
		average_depth += depth
	average_depth /= float(maxi(1, probe_depths.size()))
	var bow_depth := (probe_depths[0] + probe_depths[1]) * 0.5
	var stern_depth := (probe_depths[2] + probe_depths[3]) * 0.5
	var port_depth := (probe_depths[0] + probe_depths[2]) * 0.5
	var starboard_depth := (probe_depths[1] + probe_depths[3]) * 0.5
	var heave_spring := BOAT_HEAVE_SPRING + maxf(0.0, reserve_buoyancy) * 0.35 + roll_resistance * 1.8
	var heave_damping := BOAT_HEAVE_DAMPING + roll_resistance * 1.6
	heave_velocity += (average_depth - rest_probe_depth) * heave_spring * delta
	heave_velocity -= heave_velocity * heave_damping * delta
	heave_velocity = clampf(heave_velocity, -1.8, 1.8)
	heave += heave_velocity * delta
	heave = clampf(heave, -0.42, 0.58)

	var pitch_wave_scale := lerpf(1.12, 0.45, pitch_resistance)
	var roll_wave_scale := lerpf(1.18, 0.40, roll_resistance)
	var hydro_pitch := clampf(trim_bias * 0.30, -0.22, 0.22)
	var hydro_roll := -clampf(heel_bias * 0.38, -0.26, 0.26)
	var pitch_target := float(wave_pose.get("pitch", 0.0)) * pitch_wave_scale + hydro_pitch + clampf((bow_depth - stern_depth) * 0.08, -0.14, 0.14)
	var roll_target := -(float(wave_pose.get("roll", 0.0)) * roll_wave_scale) + hydro_roll - clampf((starboard_depth - port_depth) * 0.10, -0.18, 0.18)
	pitch_velocity += (pitch_target - pitch_angle) * (BOAT_PITCH_SPRING + pitch_resistance * 2.1) * delta
	pitch_velocity -= pitch_velocity * (BOAT_PITCH_DAMPING + pitch_resistance * 1.8) * delta
	roll_velocity += (roll_target - roll_angle) * (BOAT_ROLL_SPRING + roll_resistance * 2.4) * delta
	roll_velocity -= roll_velocity * (BOAT_ROLL_DAMPING + roll_resistance * 2.0) * delta
	pitch_velocity = clampf(pitch_velocity, -0.9, 0.9)
	roll_velocity = clampf(roll_velocity, -1.0, 1.0)
	pitch_angle = clampf(pitch_angle + pitch_velocity * delta, -0.34, 0.34)
	roll_angle = clampf(roll_angle + roll_velocity * delta, -0.42, 0.42)
	var submersion_ratio := clampf(maxf(0.0, average_depth) / maxf(0.01, rest_probe_depth), 0.0, 1.8)
	var sea_resistance := clampf(
		maxf(0.0, submersion_ratio - 1.0) * 0.18
		+ absf(pitch_angle) * 0.22
		+ absf(roll_angle) * 0.24
		+ absf(forward_speed) / maxf(1.0, float(boat_state.get("base_top_speed", BOAT_TOP_SPEED))) * 0.05,
		0.0,
		0.14
	)
	return {
		"water_surface_offset": surface_offset,
		"buoyancy_heave": heave,
		"buoyancy_heave_velocity": heave_velocity,
		"buoyancy_pitch": pitch_angle,
		"buoyancy_pitch_velocity": pitch_velocity,
		"buoyancy_roll": roll_angle,
		"buoyancy_roll_velocity": roll_velocity,
		"water_drag_multiplier": clampf(1.0 - sea_resistance, 0.86, 1.0),
		"buoyancy_submersion": submersion_ratio,
	}

func server_step_shared_boat(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_tick_reaction_state(delta)
	if session_phase == SESSION_PHASE_HANGAR:
		_process_hangar_bump_reactions()
		return
	if session_phase != SESSION_PHASE_RUN:
		return

	if str(run_state.get("phase", "running")) != "running":
		return

	run_state["elapsed_time"] = float(run_state.get("elapsed_time", 0.0)) + delta
	_enforce_run_station_ranges()
	_process_run_avatar_vitals(delta)
	var pressure_changed := _update_run_pressure_state(delta)

	var brace_timer: float = maxf(0.0, float(boat_state.get("brace_timer", 0.0)) - delta)
	var brace_cooldown: float = maxf(0.0, float(boat_state.get("brace_cooldown", 0.0)) - delta)
	var repair_cooldown: float = maxf(0.0, float(boat_state.get("repair_cooldown", 0.0)) - delta)
	boat_state["brace_timer"] = brace_timer
	boat_state["brace_cooldown"] = brace_cooldown
	boat_state["repair_cooldown"] = repair_cooldown

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var base_top_speed: float = float(boat_state.get("base_top_speed", BOAT_TOP_SPEED))
	var boat_position_for_drag: Vector3 = boat_state.get("position", Vector3.ZERO)
	var buoyancy_step := _step_boat_buoyancy(
		delta,
		boat_position_for_drag,
		float(boat_state.get("rotation_y", 0.0)),
		float(boat_state.get("speed", 0.0))
	)
	boat_state["water_surface_offset"] = float(buoyancy_step.get("water_surface_offset", 0.0))
	boat_state["buoyancy_heave"] = float(buoyancy_step.get("buoyancy_heave", 0.0))
	boat_state["buoyancy_heave_velocity"] = float(buoyancy_step.get("buoyancy_heave_velocity", 0.0))
	boat_state["buoyancy_pitch"] = float(buoyancy_step.get("buoyancy_pitch", 0.0))
	boat_state["buoyancy_pitch_velocity"] = float(buoyancy_step.get("buoyancy_pitch_velocity", 0.0))
	boat_state["buoyancy_roll"] = float(buoyancy_step.get("buoyancy_roll", 0.0))
	boat_state["buoyancy_roll_velocity"] = float(buoyancy_step.get("buoyancy_roll_velocity", 0.0))
	boat_state["water_drag_multiplier"] = float(buoyancy_step.get("water_drag_multiplier", 1.0))
	boat_state["buoyancy_submersion"] = float(buoyancy_step.get("buoyancy_submersion", 0.0))
	var squall_drag_multiplier := _get_active_squall_drag_multiplier(boat_position_for_drag)
	boat_state["squall_drag_multiplier"] = squall_drag_multiplier
	var top_speed_limit := base_top_speed * maxf(0.45, 1.0 - float(breach_stacks) * BREACH_SPEED_PENALTY) * squall_drag_multiplier * float(boat_state.get("water_drag_multiplier", 1.0))
	boat_state["top_speed_limit"] = top_speed_limit

	var input_state: Dictionary = _peer_inputs.get(driver_peer_id, {
		"throttle": 0.0,
		"steer": 0.0,
	})
	var throttle: float = clampf(float(input_state.get("throttle", 0.0)), -1.0, 1.0)
	var steer: float = clampf(float(input_state.get("steer", 0.0)), -1.0, 1.0)
	var propulsion_step := _step_propulsion_state(delta, throttle, steer, top_speed_limit)
	boat_state["speed_order"] = _get_speed_order_label(throttle)
	boat_state["rudder_input"] = steer
	boat_state["propulsion_support_timer"] = float(propulsion_step.get("support_timer", 0.0))
	boat_state["propulsion_secondary_timer"] = float(propulsion_step.get("secondary_timer", 0.0))
	boat_state["propulsion_support_boost"] = float(propulsion_step.get("support_boost", 0.0))
	boat_state["propulsion_efficiency"] = float(propulsion_step.get("propulsion_efficiency", float(boat_state.get("automation_floor", 0.65))))
	boat_state["fault_state"] = str(propulsion_step.get("fault_state", PROPULSION_FAULT_STATE_STABLE))
	boat_state["fault_severity"] = float(propulsion_step.get("fault_severity", 0.0))
	boat_state["propulsion_heat"] = float(propulsion_step.get("propulsion_heat", 0.0))
	boat_state["propulsion_pressure"] = float(propulsion_step.get("propulsion_pressure", 0.0))
	boat_state["propulsion_trim"] = float(propulsion_step.get("propulsion_trim", 1.0))
	boat_state["propulsion_sync"] = float(propulsion_step.get("propulsion_sync", float(boat_state.get("automation_floor", 0.65))))
	boat_state["propulsion_port_output"] = float(propulsion_step.get("propulsion_port_output", float(boat_state.get("propulsion_port_output", 0.0))))
	boat_state["propulsion_starboard_output"] = float(propulsion_step.get("propulsion_starboard_output", float(boat_state.get("propulsion_starboard_output", 0.0))))
	boat_state["propulsion_side_bias"] = float(propulsion_step.get("propulsion_side_bias", float(boat_state.get("propulsion_side_bias", 0.0))))
	var current_speed: float = float(boat_state.get("speed", 0.0))
	var target_speed: float = float(propulsion_step.get("target_speed", 0.0))
	var acceleration: float = BOAT_ACCELERATION * float(propulsion_step.get("acceleration_factor", 1.0))
	var deceleration: float = BOAT_DECELERATION * clampf(0.55 + float(propulsion_step.get("acceleration_factor", 1.0)) * 0.35, 0.45, 1.45)
	current_speed = move_toward(current_speed, target_speed, (acceleration if absf(target_speed) > absf(current_speed) else deceleration) * delta)

	if is_zero_approx(throttle):
		current_speed = move_toward(current_speed, 0.0, BOAT_DECELERATION * 0.6 * delta)

	var turn_factor: float = clampf(absf(current_speed) / maxf(1.0, top_speed_limit), 0.2, 1.0)
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var turn_authority_factor := clampf(float(boat_state.get("turn_authority", 50.0)) / 55.0, 0.45, 1.65)
	rotation_y += steer * BOAT_TURN_SPEED * turn_factor * turn_authority_factor * float(propulsion_step.get("rudder_response", 1.0)) * delta
	rotation_y += float(propulsion_step.get("yaw_bias", 0.0)) * clampf(throttle, 0.0, 1.0) * delta

	var forward: Vector3 = -Vector3.FORWARD.rotated(Vector3.UP, rotation_y)
	var position: Vector3 = boat_state.get("position", Vector3.ZERO)
	position += forward * current_speed * delta

	boat_state["position"] = position
	boat_state["rotation_y"] = rotation_y
	boat_state["speed"] = current_speed
	boat_state["throttle"] = throttle
	boat_state["steer"] = steer
	boat_state["actual_thrust"] = 0.0 if is_zero_approx(top_speed_limit) else target_speed / maxf(1.0, top_speed_limit)
	boat_state["tick"] = int(boat_state.get("tick", 0)) + 1
	boat_state["driver_peer_id"] = driver_peer_id
	_update_sinking_chunks(delta)
	_update_active_chunk_streaming()
	_process_extraction_reveals()

	if breach_stacks > 0:
		var leak_damage := HULL_LEAK_DAMAGE_PER_BREACH * float(breach_stacks) * delta
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - leak_damage)
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_broadcast_boat_state()
			_resolve_run_failure("The hull flooded before the crew could repair it.")
			return

	_process_rescue_hold(delta)
	if str(run_state.get("phase", "running")) != "running":
		return
	_process_squall_pressure(delta)
	if str(run_state.get("phase", "running")) != "running":
		return
	_process_hazard_collisions()
	_process_extraction(delta)
	pressure_changed = _update_run_pressure_state(delta) or pressure_changed

	_boat_broadcast_accumulator += delta
	_run_state_broadcast_accumulator += delta
	if _boat_broadcast_accumulator >= BOAT_BROADCAST_INTERVAL:
		_boat_broadcast_accumulator = 0.0
		_broadcast_boat_state()
	if pressure_changed or _run_state_broadcast_accumulator >= 0.35:
		_run_state_broadcast_accumulator = 0.0
		_broadcast_run_state()

func _mode_name() -> String:
	match mode:
		Mode.CLIENT:
			return "client"
		Mode.SERVER:
			return "server"
		_:
			return "offline"

func _set_status(message: String) -> void:
	status_message = message
	emit_signal("status_changed", message)
	print(message)

func _emit_all_runtime_state() -> void:
	emit_signal("session_phase_changed", session_phase)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	emit_signal("progression_state_changed", progression_state.duplicate(true))
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))
	emit_signal("helm_changed", driver_peer_id)
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	emit_signal("station_state_changed", station_state.duplicate(true))
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	emit_signal("run_state_changed", run_state.duplicate(true))

func _broadcast_session_phase() -> void:
	emit_signal("session_phase_changed", session_phase)
	if _has_network_server():
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_session_phase.rpc_id(int(peer_id), session_phase)

func _broadcast_blueprint_state() -> void:
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	if _has_network_server():
		var snapshot := boat_blueprint.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_blueprint_state.rpc_id(int(peer_id), snapshot)

func _broadcast_progression_state() -> void:
	emit_signal("progression_state_changed", progression_state.duplicate(true))
	if _has_network_server():
		var snapshot := progression_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_progression_state.rpc_id(int(peer_id), snapshot)

func _broadcast_peer_snapshot() -> void:
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))
	if _has_network_server():
		var snapshot := peer_snapshot.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_peer_snapshot.rpc_id(int(peer_id), snapshot)

func _broadcast_hangar_avatar_state() -> void:
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))
	if _has_network_server():
		var snapshot := hangar_avatar_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_hangar_avatar_state.rpc_id(int(peer_id), snapshot)

func _broadcast_run_avatar_state() -> void:
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))
	if _has_network_server():
		var snapshot := run_avatar_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_run_avatar_state.rpc_id(int(peer_id), snapshot)

func _broadcast_reaction_state() -> void:
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))
	if _has_network_server():
		var snapshot := reaction_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_reaction_state.rpc_id(int(peer_id), snapshot)

func _broadcast_boat_state() -> void:
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if _has_network_server():
		var state := _build_client_boat_state_snapshot()
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_boat_state.rpc_id(int(peer_id), state, driver_peer_id)

func _broadcast_hazard_state() -> void:
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))
	if _has_network_server():
		var hazards := hazard_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_hazard_state.rpc_id(int(peer_id), hazards)

func _broadcast_station_state() -> void:
	emit_signal("station_state_changed", station_state.duplicate(true))
	if _has_network_server():
		var stations := station_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_station_state.rpc_id(int(peer_id), stations)

func _broadcast_loot_state() -> void:
	emit_signal("loot_state_changed", loot_state.duplicate(true))
	if _has_network_server():
		var targets := loot_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_loot_state.rpc_id(int(peer_id), targets)

func _broadcast_run_state() -> void:
	emit_signal("run_state_changed", run_state.duplicate(true))
	if _has_network_server():
		var state := run_state.duplicate(true)
		for peer_id in _get_server_broadcast_peer_ids():
			client_receive_run_state.rpc_id(int(peer_id), state)

func _get_server_broadcast_peer_ids() -> Array:
	if not _has_network_server():
		return []
	if _disconnect_broadcast_scheduled:
		return []
	return get_player_peer_ids()

func _send_bootstrap(peer_id: int) -> void:
	if not _has_network_server():
		return

	client_receive_bootstrap.rpc_id(peer_id, run_seed, current_port, GameConfig.MAX_PLAYERS, session_phase, boat_blueprint.duplicate(true))
	client_receive_progression_state.rpc_id(peer_id, progression_state.duplicate(true))
	client_receive_boat_state.rpc_id(peer_id, _build_client_boat_state_snapshot(), driver_peer_id)
	client_receive_hazard_state.rpc_id(peer_id, hazard_state.duplicate(true))
	client_receive_station_state.rpc_id(peer_id, station_state.duplicate(true))
	client_receive_loot_state.rpc_id(peer_id, loot_state.duplicate(true))
	client_receive_run_state.rpc_id(peer_id, run_state.duplicate(true))
	client_receive_hangar_avatar_state.rpc_id(peer_id, hangar_avatar_state.duplicate(true))
	client_receive_run_avatar_state.rpc_id(peer_id, run_avatar_state.duplicate(true))
	client_receive_reaction_state.rpc_id(peer_id, reaction_state.duplicate(true))
	if session_phase == SESSION_PHASE_RUN:
		client_receive_runtime_boat_state.rpc_id(peer_id, _build_client_runtime_boat_snapshot())

func _build_client_boat_state_snapshot() -> Dictionary:
	var snapshot := boat_state.duplicate(true)
	snapshot.erase("runtime_blocks")
	snapshot.erase("sinking_chunks")
	snapshot.erase("runtime_chunks")
	snapshot.erase("recent_damage_block_ids")
	snapshot.erase("recent_detached_chunk_ids")
	snapshot.erase("cargo_lost_to_sea")
	return snapshot

func _build_client_runtime_boat_snapshot() -> Dictionary:
	return {
		"runtime_blocks": _build_client_runtime_blocks_snapshot(),
		"sinking_chunks": _build_client_sinking_chunks_snapshot(),
	}

func _build_client_runtime_blocks_snapshot() -> Array:
	var runtime_blocks_snapshot: Array = []
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		runtime_blocks_snapshot.append({
			"id": int(block.get("id", 0)),
			"current_hp": float(block.get("current_hp", 0.0)),
			"destroyed": bool(block.get("destroyed", false)),
			"detached": bool(block.get("detached", false)),
		})
	return runtime_blocks_snapshot

func _build_client_sinking_chunks_snapshot() -> Array:
	var sinking_chunks_snapshot: Array = []
	for chunk_variant in Array(boat_state.get("sinking_chunks", [])):
		var chunk: Dictionary = chunk_variant
		var block_ids: Array = []
		for block_variant in Array(chunk.get("blocks", [])):
			var block: Dictionary = block_variant
			block_ids.append(int(block.get("id", 0)))
		sinking_chunks_snapshot.append({
			"chunk_id": int(chunk.get("chunk_id", 0)),
			"world_position": chunk.get("world_position", Vector3.ZERO),
			"rotation_y": float(chunk.get("rotation_y", 0.0)),
			"sink_elapsed": float(chunk.get("sink_elapsed", 0.0)),
			"drift_velocity": chunk.get("drift_velocity", Vector3.ZERO),
			"block_ids": block_ids,
		})
	return sinking_chunks_snapshot

func _broadcast_runtime_boat_state() -> void:
	if not multiplayer.is_server() or session_phase != SESSION_PHASE_RUN:
		return

	var runtime_snapshot := _build_client_runtime_boat_snapshot()
	for peer_id in get_player_peer_ids():
		client_receive_runtime_boat_state.rpc_id(int(peer_id), runtime_snapshot)

func _tick_reaction_state(delta: float) -> void:
	if not multiplayer.is_server():
		return

	var expired_peers: Array = []
	for peer_id_variant in reaction_state.keys():
		var peer_id := int(peer_id_variant)
		var peer_reaction: Dictionary = reaction_state[peer_id]
		peer_reaction["active_time"] = maxf(0.0, float(peer_reaction.get("active_time", 0.0)) - delta)
		peer_reaction["recovery_time"] = maxf(0.0, float(peer_reaction.get("recovery_time", 0.0)) - delta)
		if float(peer_reaction.get("active_time", 0.0)) <= 0.0 and float(peer_reaction.get("recovery_time", 0.0)) <= 0.0:
			expired_peers.append(peer_id)
			continue
		reaction_state[peer_id] = peer_reaction
	for peer_id_variant in expired_peers:
		reaction_state.erase(int(peer_id_variant))
	if not expired_peers.is_empty():
		_broadcast_reaction_state()

	var expired_pairs: Array = []
	for pair_key_variant in _hangar_bump_pair_cooldowns.keys():
		var pair_key := str(pair_key_variant)
		var remaining: float = maxf(0.0, float(_hangar_bump_pair_cooldowns[pair_key]) - delta)
		if remaining <= 0.0:
			expired_pairs.append(pair_key)
		else:
			_hangar_bump_pair_cooldowns[pair_key] = remaining
	for pair_key_variant in expired_pairs:
		_hangar_bump_pair_cooldowns.erase(str(pair_key_variant))

func _process_hangar_bump_reactions() -> void:
	if session_phase != SESSION_PHASE_HANGAR:
		return
	var peer_ids := get_player_peer_ids()
	if peer_ids.size() < 2:
		return

	for left_index in range(peer_ids.size()):
		var left_peer := int(peer_ids[left_index])
		if _peer_has_reaction_lock(left_peer):
			continue
		var left_state: Dictionary = hangar_avatar_state.get(left_peer, {})
		if left_state.is_empty():
			continue
		var left_position: Vector3 = left_state.get("position", Vector3.ZERO)
		var left_velocity: Vector3 = left_state.get("velocity", Vector3.ZERO)
		for right_index in range(left_index + 1, peer_ids.size()):
			var right_peer := int(peer_ids[right_index])
			if _peer_has_reaction_lock(right_peer):
				continue
			var pair_key := _build_peer_pair_key(left_peer, right_peer)
			if float(_hangar_bump_pair_cooldowns.get(pair_key, 0.0)) > 0.0:
				continue
			var right_state: Dictionary = hangar_avatar_state.get(right_peer, {})
			if right_state.is_empty():
				continue
			var right_position: Vector3 = right_state.get("position", Vector3.ZERO)
			var offset := right_position - left_position
			var distance := offset.length()
			if distance > REACTION_BUMP_COLLISION_RADIUS or distance <= 0.05:
				continue
			var collision_direction := offset / distance
			var right_velocity: Vector3 = right_state.get("velocity", Vector3.ZERO)
			var relative_velocity: Vector3 = left_velocity - right_velocity
			var relative_speed := relative_velocity.length()
			if relative_speed < REACTION_BUMP_SPEED_THRESHOLD:
				continue
			if relative_velocity.dot(collision_direction) <= 0.75:
				continue
			var strength := clampf((relative_speed - REACTION_BUMP_SPEED_THRESHOLD) / 3.0 + 0.35, 0.35, 1.0)
			var knockback_speed := lerpf(REACTION_BUMP_KNOCKBACK * 0.55, REACTION_BUMP_KNOCKBACK, strength)
			_start_peer_reaction(
				left_peer,
				"bump",
				strength,
				-collision_direction * knockback_speed + Vector3.UP * (0.3 + strength * 0.18),
				REACTION_BUMP_ACTIVE_SECONDS + strength * 0.04,
				REACTION_BUMP_RECOVERY_SECONDS + strength * 0.08,
				right_peer
			)
			_start_peer_reaction(
				right_peer,
				"bump",
				strength,
				collision_direction * knockback_speed + Vector3.UP * (0.3 + strength * 0.18),
				REACTION_BUMP_ACTIVE_SECONDS + strength * 0.04,
				REACTION_BUMP_RECOVERY_SECONDS + strength * 0.08,
				left_peer
			)
			_hangar_bump_pair_cooldowns[pair_key] = REACTION_BUMP_PAIR_COOLDOWN
			_set_status("%s slammed into %s in the hangar." % [_get_peer_name(left_peer), _get_peer_name(right_peer)])
			return

func _start_peer_reaction(peer_id: int, reaction_type: String, strength: float, knockback_velocity: Vector3, active_seconds: float, recovery_seconds: float, source_peer_id: int = 0, brace_applied: bool = false, pull_direction: Vector3 = Vector3.ZERO) -> void:
	if not multiplayer.is_server():
		return
	if peer_id <= 0:
		return
	if not peer_snapshot.has(peer_id):
		return
	var current_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not current_reaction.is_empty() and float(current_reaction.get("active_time", 0.0)) > 0.0 and float(current_reaction.get("strength", 0.0)) > strength and str(current_reaction.get("type", "")) == "impact":
		return
	reaction_state[peer_id] = {
		"reaction_id": _next_reaction_id,
		"type": reaction_type,
		"strength": clampf(strength, 0.0, 1.0),
		"active_time": maxf(0.0, active_seconds),
		"active_duration": maxf(0.0, active_seconds),
		"recovery_time": maxf(0.0, recovery_seconds),
		"recovery_duration": maxf(0.0, recovery_seconds),
		"knockback_velocity": knockback_velocity,
		"pull_direction": pull_direction,
		"source_peer_id": source_peer_id,
		"brace_applied": brace_applied,
		"phase": session_phase,
	}
	_next_reaction_id += 1
	_broadcast_reaction_state()

func _apply_run_impact_reactions(base_direction: Vector3, base_strength: float, brace_applied: bool, release_stations: bool, primary_station_id: String = "") -> void:
	if not multiplayer.is_server():
		return
	var direction := base_direction.normalized()
	if direction.length() <= 0.01:
		direction = Vector3.BACK
	var released_any := false
	for peer_id_variant in get_player_peer_ids():
		var peer_id := int(peer_id_variant)
		var station_id := get_peer_station_id(peer_id)
		var strength := clampf(base_strength, 0.0, 1.0)
		if not primary_station_id.is_empty() and station_id == primary_station_id:
			strength = minf(1.0, strength + 0.14)
		var knockback_speed := lerpf(REACTION_IMPACT_KNOCKBACK * 0.65, REACTION_IMPACT_KNOCKBACK, strength)
		var active_seconds := REACTION_IMPACT_ACTIVE_SECONDS + strength * 0.08
		var recovery_seconds := REACTION_IMPACT_RECOVERY_SECONDS + strength * 0.12
		_start_peer_reaction(
			peer_id,
			"impact",
			strength,
			direction * knockback_speed + Vector3.UP * (0.42 + strength * 0.22),
			active_seconds,
			recovery_seconds,
			0,
			brace_applied
		)
		_try_knock_peer_overboard(peer_id, direction * knockback_speed, strength, brace_applied)
		if release_stations and not station_id.is_empty():
			_release_station(peer_id, false)
			released_any = true
	if released_any:
		_broadcast_station_state()
		_broadcast_boat_state()

func _try_knock_peer_overboard(peer_id: int, knockback_velocity: Vector3, strength: float, brace_applied: bool) -> void:
	if brace_applied or strength < RUN_OVERBOARD_MIN_STRENGTH:
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var deck_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var local_knockback := knockback_velocity.rotated(Vector3.UP, -float(boat_state.get("rotation_y", 0.0)))
	local_knockback.y = 0.0
	if local_knockback.length() <= 0.01:
		return
	local_knockback = local_knockback.normalized()
	var overboard_probe := deck_position + local_knockback * RUN_OVERBOARD_PROBE_DISTANCE
	var probe_result := _project_run_deck_position(overboard_probe, RUN_OVERBOARD_EDGE_MARGIN, false)
	if bool(probe_result.get("valid", false)):
		return
	var overboard_local_position := overboard_probe
	_set_peer_overboard(peer_id, overboard_local_position, knockback_velocity)

func _set_peer_overboard(peer_id: int, overboard_local_position: Vector3, knockback_velocity: Vector3, facing_y_override = null) -> void:
	if not multiplayer.is_server():
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	var current_station_id := get_peer_station_id(peer_id)
	if not current_station_id.is_empty():
		_release_station(peer_id, false)
	var world_position := _run_local_to_world(overboard_local_position)
	world_position.y = RUN_OVERBOARD_WATER_HEIGHT
	avatar_state["mode"] = RUN_AVATAR_MODE_OVERBOARD
	avatar_state["world_position"] = world_position
	avatar_state["velocity"] = knockback_velocity.limit_length(6.8)
	avatar_state["grounded"] = false
	if facing_y_override != null:
		avatar_state["facing_y"] = float(facing_y_override)
	avatar_state["overboard_attrition_delay"] = AVATAR_OVERBOARD_ATTRITION_DELAY
	avatar_state["overboard_attrition_timer"] = AVATAR_OVERBOARD_ATTRITION_INTERVAL
	run_avatar_state[peer_id] = avatar_state
	_apply_peer_health_damage(peer_id, AVATAR_OVERBOARD_ENTRY_DAMAGE, 1.0)
	_refresh_run_avatar_runtime_fields(peer_id)
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not peer_reaction.is_empty():
		peer_reaction["type"] = "overboard"
		peer_reaction["active_time"] = maxf(float(peer_reaction.get("active_time", 0.0)), 0.18)
		peer_reaction["recovery_time"] = maxf(float(peer_reaction.get("recovery_time", 0.0)), 0.55)
		reaction_state[peer_id] = peer_reaction
	run_state["overboard_incidents"] = int(run_state.get("overboard_incidents", 0)) + 1
	_refresh_overboard_run_metrics()
	_refresh_crew_vitals_metrics()
	_peer_inputs[peer_id] = {
		"throttle": 0.0,
		"steer": 0.0,
	}
	_broadcast_station_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_run_state()
	_broadcast_boat_state()
	_set_status("%s went overboard." % _get_peer_name(peer_id))

func _request_peer_overboard_transition(peer_id: int, world_position: Vector3, velocity: Vector3, facing_y: float) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty() or _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	var deck_position: Vector3 = avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0])
	var local_position := _run_world_to_local(_sanitize_overboard_world_position(world_position))
	local_position.y = deck_position.y
	_set_peer_overboard(peer_id, local_position, velocity, facing_y)

func _force_peer_overboard_for_debug(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty() or _is_peer_overboard(peer_id):
		return
	var deck_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var probe_directions := [
		Vector3.RIGHT,
		Vector3.LEFT,
		Vector3.BACK,
		Vector3.FORWARD,
	]
	var chosen_direction := Vector3.BACK
	for direction_variant in probe_directions:
		var direction: Vector3 = direction_variant
		var probe_result := _project_run_deck_position(deck_position + direction * RUN_OVERBOARD_PROBE_DISTANCE, RUN_OVERBOARD_EDGE_MARGIN, false)
		if bool(probe_result.get("valid", false)):
			continue
		chosen_direction = direction
		break
	var overboard_local_position := deck_position + chosen_direction * RUN_OVERBOARD_PROBE_DISTANCE
	var knockback_velocity: Vector3 = _run_local_to_world(chosen_direction) - boat_state.get("position", Vector3.ZERO)
	knockback_velocity.y = 0.0
	_set_peer_overboard(peer_id, overboard_local_position, knockback_velocity.normalized() * 4.8)

func _attempt_overboard_recovery(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if not _is_peer_overboard(peer_id):
		return
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var world_position: Vector3 = avatar_state.get("world_position", boat_state.get("position", Vector3.ZERO))
	var direct_reboard_target := get_direct_overboard_reboard_target(world_position)
	if not direct_reboard_target.is_empty():
		avatar_state["mode"] = RUN_AVATAR_MODE_DECK
		avatar_state["deck_position"] = direct_reboard_target.get("deck_position", RUN_DECK_SPAWN_POINTS[0])
		avatar_state["velocity"] = Vector3.ZERO
		avatar_state["grounded"] = true
		avatar_state["overboard_attrition_delay"] = AVATAR_OVERBOARD_ATTRITION_DELAY
		avatar_state["overboard_attrition_timer"] = AVATAR_OVERBOARD_ATTRITION_INTERVAL
		run_avatar_state[peer_id] = avatar_state
		_refresh_run_avatar_runtime_fields(peer_id)
		var direct_peer_reaction: Dictionary = reaction_state.get(peer_id, {})
		if not direct_peer_reaction.is_empty():
			direct_peer_reaction["type"] = "recovering"
			direct_peer_reaction["active_time"] = 0.0
			direct_peer_reaction["recovery_time"] = maxf(float(direct_peer_reaction.get("recovery_time", 0.0)), 0.18)
			reaction_state[peer_id] = direct_peer_reaction
		run_state["recoveries_completed"] = int(run_state.get("recoveries_completed", 0)) + 1
		_refresh_overboard_run_metrics()
		_broadcast_run_avatar_state()
		_broadcast_reaction_state()
		_broadcast_run_state()
		_set_status("%s hauled back aboard over the %s." % [
			_get_peer_name(peer_id),
			str(direct_reboard_target.get("label", "gunwale")),
		])
		return
	var recovery_target := _get_best_overboard_recovery_target(world_position)
	if recovery_target.is_empty() or not bool(recovery_target.get("ready", false)):
		_set_status("%s needs to reach a ladder before climbing back aboard." % _get_peer_name(peer_id))
		return
	avatar_state["mode"] = RUN_AVATAR_MODE_DECK
	avatar_state["deck_position"] = get_nearest_run_avatar_deck_position(recovery_target.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
	avatar_state["velocity"] = Vector3.ZERO
	avatar_state["grounded"] = true
	avatar_state["overboard_attrition_delay"] = AVATAR_OVERBOARD_ATTRITION_DELAY
	avatar_state["overboard_attrition_timer"] = AVATAR_OVERBOARD_ATTRITION_INTERVAL
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if not peer_reaction.is_empty():
		peer_reaction["type"] = "recovering"
		peer_reaction["active_time"] = 0.0
		peer_reaction["recovery_time"] = maxf(float(peer_reaction.get("recovery_time", 0.0)), 0.22)
		reaction_state[peer_id] = peer_reaction
	run_state["recoveries_completed"] = int(run_state.get("recoveries_completed", 0)) + 1
	_refresh_overboard_run_metrics()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_run_state()
	_set_status("%s climbed back aboard via the %s." % [
		_get_peer_name(peer_id),
		str(recovery_target.get("label", "recovery line")),
	])

func _attempt_assist_rally(source_peer_id: int, target_peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if source_peer_id == target_peer_id:
		return
	var source_state: Dictionary = run_avatar_state.get(source_peer_id, {})
	var target_state: Dictionary = run_avatar_state.get(target_peer_id, {})
	if source_state.is_empty() or target_state.is_empty():
		return
	if _peer_has_reaction_lock(source_peer_id):
		return
	if _is_peer_overboard(source_peer_id) or _is_peer_downed(source_peer_id):
		return
	if _is_peer_overboard(target_peer_id) or not _is_peer_downed(target_peer_id):
		return
	var source_position: Vector3 = source_state.get("deck_position", Vector3.ZERO)
	var target_position: Vector3 = target_state.get("deck_position", Vector3.ZERO)
	if source_position.distance_to(target_position) > AVATAR_ASSIST_RALLY_RANGE:
		_set_status("%s needs to get closer to %s before helping." % [
			_get_peer_name(source_peer_id),
			_get_peer_name(target_peer_id),
		])
		return
	if not _spend_peer_stamina(source_peer_id, AVATAR_ASSIST_STAMINA_COST, true):
		_set_status("%s is too winded to rally a crewmate yet." % _get_peer_name(source_peer_id))
		return
	if not _recover_peer_from_downed(target_peer_id):
		return
	_refresh_crew_vitals_metrics()
	_broadcast_run_avatar_state()
	_broadcast_run_state()
	_set_status("%s rallied %s back onto their feet." % [
		_get_peer_name(source_peer_id),
		_get_peer_name(target_peer_id),
	])

func _peer_has_reaction_lock(peer_id: int) -> bool:
	var peer_reaction: Dictionary = reaction_state.get(peer_id, {})
	if peer_reaction.is_empty():
		return false
	return float(peer_reaction.get("active_time", 0.0)) > 0.0

func _build_peer_pair_key(left_peer: int, right_peer: int) -> String:
	var low_peer := mini(left_peer, right_peer)
	var high_peer := maxi(left_peer, right_peer)
	return "%d:%d" % [low_peer, high_peer]

func _reset_progression_runtime() -> void:
	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())

func _reset_blueprint_runtime() -> void:
	boat_blueprint = _decorate_blueprint(DockState.get_boat_blueprint())

func _reset_hangar_avatar_state() -> void:
	hangar_avatar_state = {}

func _reset_run_avatar_state() -> void:
	run_avatar_state = {}

func _reset_reaction_runtime() -> void:
	reaction_state = {}
	_next_reaction_id = 1
	_hangar_bump_pair_cooldowns = {}

func _reset_connected_hangar_avatars() -> void:
	if not multiplayer.is_server():
		return
	hangar_avatar_state = {}
	var peer_ids := get_player_peer_ids()
	for index in range(peer_ids.size()):
		var peer_id := int(peer_ids[index])
		hangar_avatar_state[peer_id] = _make_default_hangar_avatar_state(index)
	_broadcast_hangar_avatar_state()

func _reset_connected_run_avatars() -> void:
	if not multiplayer.is_server():
		return
	run_avatar_state = {}
	var peer_ids := get_player_peer_ids()
	for index in range(peer_ids.size()):
		var peer_id := int(peer_ids[index])
		run_avatar_state[peer_id] = _make_default_run_avatar_state(index)
		_refresh_run_avatar_runtime_fields(peer_id)
	_refresh_overboard_run_metrics()
	_refresh_crew_vitals_metrics()
	_broadcast_run_avatar_state()

func _make_default_hangar_avatar_state(spawn_index: int) -> Dictionary:
	var clamped_index := wrapi(spawn_index, 0, HANGAR_SPAWN_POINTS.size())
	var spawn_position: Vector3 = HANGAR_SPAWN_POINTS[clamped_index]
	var default_block_id := "structure"
	var unlocked_block_ids := get_builder_block_ids()
	if not unlocked_block_ids.is_empty():
		default_block_id = str(unlocked_block_ids[0])
	return {
		"position": spawn_position,
		"velocity": Vector3.ZERO,
		"facing_y": 0.0,
		"grounded": true,
		"selected_block_id": default_block_id,
		"rotation_steps": 0,
		"target_cell": [0, 0, 0],
		"remove_cell": [0, 0, 0],
		"has_target": false,
		"target_feedback_state": "hidden",
	}

func _ensure_offline_local_state() -> void:
	if multiplayer.multiplayer_peer != null:
		return
	peer_snapshot = {
		OFFLINE_LOCAL_PEER_ID: {
			"name": local_player_name if not local_player_name.is_empty() else GameConfig.DEFAULT_PLAYER_NAME,
			"status": "local",
		},
	}
	if not hangar_avatar_state.has(OFFLINE_LOCAL_PEER_ID):
		hangar_avatar_state[OFFLINE_LOCAL_PEER_ID] = _make_default_hangar_avatar_state(0)

func _make_default_run_avatar_state(spawn_index: int) -> Dictionary:
	var clamped_index := wrapi(spawn_index, 0, RUN_DECK_SPAWN_POINTS.size())
	var spawn_position := get_nearest_run_avatar_deck_position(RUN_DECK_SPAWN_POINTS[clamped_index])
	var world_position := _run_local_to_world(spawn_position)
	return {
		"mode": RUN_AVATAR_MODE_DECK,
		"deck_position": spawn_position,
		"world_position": world_position,
		"velocity": Vector3.ZERO,
		"facing_y": PI,
		"grounded": true,
		"recovery_target_id": "",
		"recovery_target_label": "",
		"recovery_ready": false,
		"health": AVATAR_MAX_HEALTH,
		"max_health": AVATAR_MAX_HEALTH,
		"stamina": AVATAR_MAX_STAMINA,
		"max_stamina": AVATAR_MAX_STAMINA,
		"downed_timer": 0.0,
		"last_damage_time": 0.0,
		"stamina_regen_delay": 0.0,
		"stamina_exhausted": false,
		"overboard_attrition_delay": AVATAR_OVERBOARD_ATTRITION_DELAY,
		"overboard_attrition_timer": AVATAR_OVERBOARD_ATTRITION_INTERVAL,
	}

func _run_local_to_world(local_position: Vector3) -> Vector3:
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return boat_position + local_position.rotated(Vector3.UP, rotation_y)

func _run_world_to_local(world_position: Vector3) -> Vector3:
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return (world_position - boat_position).rotated(Vector3.UP, -rotation_y)

func _get_blueprint_block_by_id(block_id: int) -> Dictionary:
	for block_variant in Array(boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		if int(block.get("id", 0)) == block_id:
			return block
	return {}

func _get_runtime_block_navigation_data(block_state: Dictionary) -> Dictionary:
	if bool(block_state.get("destroyed", false)) or bool(block_state.get("detached", false)):
		return {}
	var block_id := int(block_state.get("id", 0))
	var blueprint_block := _get_blueprint_block_by_id(block_id)
	var block_type := str(block_state.get("type", blueprint_block.get("type", "structure")))
	var rotation_steps := wrapi(int(block_state.get("rotation_steps", blueprint_block.get("rotation_steps", 0))), 0, 4)
	var local_position: Vector3 = block_state.get("local_position", Vector3.ZERO)
	if not block_state.has("local_position"):
		local_position = _block_cell_to_local_position(blueprint_block.get("cell", [0, 0, 0]))
	var block_size := Vector3.ONE * RUNTIME_BLOCK_SPACING
	return {
		"id": block_id,
		"type": block_type,
		"rotation_steps": rotation_steps,
		"local_position": local_position,
		"size": block_size,
	}

func get_run_walkable_surfaces() -> Array:
	var surfaces: Array = []
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block_state: Dictionary = block_variant
		var block := _get_runtime_block_navigation_data(block_state)
		if block.is_empty():
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var block_size: Vector3 = block.get("size", Vector3.ONE)
		surfaces.append({
			"block_id": int(block.get("id", 0)),
			"block_type": str(block.get("type", "structure")),
			"local_center": local_position,
			"half_size_x": maxf(0.14, float(block_size.x) * 0.5 - RUN_DECK_SURFACE_MARGIN),
			"half_size_z": maxf(0.14, float(block_size.z) * 0.5 - RUN_DECK_SURFACE_MARGIN),
			"deck_y": local_position.y + float(block_size.y) * 0.5 + RUN_AVATAR_STAND_HEIGHT,
		})
	return surfaces

func _project_run_deck_position(deck_position: Vector3, max_snap_distance: float = RUN_DECK_SURFACE_SNAP_DISTANCE, force_nearest: bool = false) -> Dictionary:
	var surfaces := get_run_walkable_surfaces()
	if surfaces.is_empty():
		return {
			"valid": false,
			"deck_position": Vector3(
				clampf(deck_position.x, RUN_DECK_BOUNDS_MIN.x, RUN_DECK_BOUNDS_MAX.x),
				clampf(deck_position.y, RUN_DECK_BOUNDS_MIN.y, RUN_DECK_BOUNDS_MAX.y),
				clampf(deck_position.z, RUN_DECK_BOUNDS_MIN.z, RUN_DECK_BOUNDS_MAX.z)
			),
			"surface": {},
			"horizontal_distance": INF,
		}

	var best_containing: Dictionary = {}
	var best_containing_score := INF
	var best_snap: Dictionary = {}
	var best_snap_score := INF
	for surface_variant in surfaces:
		var surface: Dictionary = surface_variant
		var local_center: Vector3 = surface.get("local_center", Vector3.ZERO)
		var half_size_x := float(surface.get("half_size_x", 0.4))
		var half_size_z := float(surface.get("half_size_z", 0.4))
		var nearest_x := clampf(deck_position.x, local_center.x - half_size_x, local_center.x + half_size_x)
		var nearest_z := clampf(deck_position.z, local_center.z - half_size_z, local_center.z + half_size_z)
		var horizontal_distance := Vector2(deck_position.x - nearest_x, deck_position.z - nearest_z).length()
		var deck_y := float(surface.get("deck_y", local_center.y + RUN_AVATAR_STAND_HEIGHT))
		var vertical_distance := absf(deck_position.y - deck_y)
		var projected_position := Vector3(nearest_x, deck_y, nearest_z)
		if horizontal_distance <= 0.001:
			if vertical_distance < best_containing_score:
				best_containing_score = vertical_distance
				best_containing = {
					"valid": true,
					"deck_position": projected_position,
					"surface": surface,
					"horizontal_distance": 0.0,
				}
			continue
		var snap_score := horizontal_distance + vertical_distance * 0.35
		if snap_score < best_snap_score:
			best_snap_score = snap_score
			best_snap = {
				"valid": horizontal_distance <= max_snap_distance or force_nearest,
				"deck_position": projected_position,
				"surface": surface,
				"horizontal_distance": horizontal_distance,
			}
	if not best_containing.is_empty():
		return best_containing
	if not best_snap.is_empty():
		return best_snap
	return {
		"valid": false,
		"deck_position": deck_position,
		"surface": {},
		"horizontal_distance": INF,
	}

func get_nearest_run_avatar_deck_position(deck_position: Vector3) -> Vector3:
	var projection := _project_run_deck_position(deck_position, RUN_DECK_SURFACE_SNAP_DISTANCE, true)
	return projection.get("deck_position", deck_position)

func get_run_avatar_support_projection(deck_position: Vector3, support_margin: float = RUN_OVERBOARD_EDGE_MARGIN) -> Dictionary:
	return _project_run_deck_position(deck_position, support_margin, false)

func sanitize_run_avatar_deck_position(deck_position: Vector3, fallback_position = null) -> Vector3:
	var projection := _project_run_deck_position(deck_position)
	if bool(projection.get("valid", false)):
		return projection.get("deck_position", deck_position)
	if fallback_position != null:
		return get_nearest_run_avatar_deck_position(fallback_position)
	return get_nearest_run_avatar_deck_position(deck_position)

func get_direct_overboard_reboard_target(world_position: Vector3) -> Dictionary:
	var sanitized_world_position := _sanitize_overboard_world_position(world_position)
	var local_position := _run_world_to_local(sanitized_world_position)
	var projection := _project_run_deck_position(local_position, RUN_OVERBOARD_DIRECT_REBOARD_RANGE, false)
	if not bool(projection.get("valid", false)):
		return {}
	var deck_position: Vector3 = projection.get("deck_position", local_position)
	var vertical_gap := deck_position.y - local_position.y
	if vertical_gap < 0.0 or vertical_gap > RUN_OVERBOARD_DIRECT_REBOARD_MAX_HEIGHT:
		return {}
	var board_world_position := _run_local_to_world(deck_position)
	if sanitized_world_position.distance_to(board_world_position) > RUN_OVERBOARD_DIRECT_REBOARD_WORLD_DISTANCE:
		return {}
	return {
		"deck_position": deck_position,
		"world_position": board_world_position,
		"horizontal_distance": float(projection.get("horizontal_distance", 0.0)),
		"vertical_gap": vertical_gap,
		"label": "gunwale",
		"ready": true,
	}

func _get_overboard_recovery_targets() -> Array:
	var targets: Array = []
	for target_variant in get_run_recovery_points():
		var target: Dictionary = target_variant
		var world_target := _run_local_to_world(target.get("water_position", Vector3.ZERO))
		world_target.y = RUN_OVERBOARD_WATER_HEIGHT
		targets.append({
			"id": str(target.get("id", "")),
			"label": str(target.get("label", "Recovery")),
			"water_position": world_target,
			"deck_position": get_nearest_run_avatar_deck_position(target.get("deck_position", Vector3.ZERO)),
		})
	return targets

func _get_best_overboard_recovery_target(world_position: Vector3) -> Dictionary:
	var nearest_target: Dictionary = {}
	var nearest_distance := INF
	for target_variant in _get_overboard_recovery_targets():
		var target: Dictionary = target_variant
		var target_world_position: Vector3 = target.get("water_position", Vector3.ZERO)
		var distance := world_position.distance_to(target_world_position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_target = target.duplicate(true)
		nearest_target["distance"] = distance
		nearest_target["ready"] = distance <= RUN_OVERBOARD_RECOVERY_RANGE
	return nearest_target

func _sanitize_overboard_world_position(world_position: Vector3) -> Vector3:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var offset := world_position - boat_position
	offset.y = 0.0
	if offset.length() > RUN_OVERBOARD_SWIM_RADIUS:
		offset = offset.normalized() * RUN_OVERBOARD_SWIM_RADIUS
	var sanitized_position := boat_position + offset
	sanitized_position.y = RUN_OVERBOARD_WATER_HEIGHT
	return sanitized_position

func _refresh_run_avatar_runtime_fields(peer_id: int) -> void:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return
	var avatar_mode := str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK))
	var max_health := maxf(1.0, float(avatar_state.get("max_health", AVATAR_MAX_HEALTH)))
	var max_stamina := maxf(1.0, float(avatar_state.get("max_stamina", AVATAR_MAX_STAMINA)))
	var min_health := 1.0 if avatar_mode == RUN_AVATAR_MODE_OVERBOARD else 0.0
	avatar_state["max_health"] = max_health
	avatar_state["health"] = clampf(float(avatar_state.get("health", max_health)), min_health, max_health)
	avatar_state["max_stamina"] = max_stamina
	avatar_state["stamina"] = clampf(float(avatar_state.get("stamina", max_stamina)), 0.0, max_stamina)
	avatar_state["downed_timer"] = maxf(0.0, float(avatar_state.get("downed_timer", 0.0)))
	if bool(avatar_state.get("stamina_exhausted", false)) and float(avatar_state.get("stamina", max_stamina)) >= AVATAR_STAMINA_EXHAUSTED_RECOVERY_THRESHOLD:
		avatar_state["stamina_exhausted"] = false
	if avatar_mode == RUN_AVATAR_MODE_OVERBOARD:
		var world_position := _sanitize_overboard_world_position(avatar_state.get("world_position", boat_state.get("position", Vector3.ZERO)))
		var recovery_target := _get_best_overboard_recovery_target(world_position)
		avatar_state["world_position"] = world_position
		avatar_state["recovery_target_id"] = str(recovery_target.get("id", ""))
		avatar_state["recovery_target_label"] = str(recovery_target.get("label", ""))
		avatar_state["recovery_ready"] = bool(recovery_target.get("ready", false))
		avatar_state["deck_position"] = get_nearest_run_avatar_deck_position(avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
		avatar_state["overboard_attrition_delay"] = maxf(0.0, float(avatar_state.get("overboard_attrition_delay", AVATAR_OVERBOARD_ATTRITION_DELAY)))
		avatar_state["overboard_attrition_timer"] = maxf(0.0, float(avatar_state.get("overboard_attrition_timer", AVATAR_OVERBOARD_ATTRITION_INTERVAL)))
	elif avatar_mode == RUN_AVATAR_MODE_DOWNED:
		var downed_position := sanitize_run_avatar_deck_position(avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
		avatar_state["mode"] = RUN_AVATAR_MODE_DOWNED
		avatar_state["deck_position"] = downed_position
		avatar_state["world_position"] = _run_local_to_world(downed_position)
		avatar_state["velocity"] = Vector3.ZERO
		avatar_state["grounded"] = true
		avatar_state["recovery_target_id"] = ""
		avatar_state["recovery_target_label"] = ""
		avatar_state["recovery_ready"] = false
	else:
		var deck_position := sanitize_run_avatar_deck_position(avatar_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0]))
		avatar_state["mode"] = RUN_AVATAR_MODE_DECK
		avatar_state["deck_position"] = deck_position
		avatar_state["world_position"] = _run_local_to_world(deck_position)
		avatar_state["recovery_target_id"] = ""
		avatar_state["recovery_target_label"] = ""
		avatar_state["recovery_ready"] = false
	run_avatar_state[peer_id] = avatar_state

func _is_peer_overboard(peer_id: int) -> bool:
	return str(run_avatar_state.get(peer_id, {}).get("mode", RUN_AVATAR_MODE_DECK)) == RUN_AVATAR_MODE_OVERBOARD

func _is_peer_downed(peer_id: int) -> bool:
	return str(run_avatar_state.get(peer_id, {}).get("mode", RUN_AVATAR_MODE_DECK)) == RUN_AVATAR_MODE_DOWNED

func _refresh_overboard_run_metrics() -> void:
	var overboard_count := 0
	for peer_id_variant in run_avatar_state.keys():
		if _is_peer_overboard(int(peer_id_variant)):
			overboard_count += 1
	run_state["overboard_count"] = overboard_count

func _refresh_crew_vitals_metrics() -> bool:
	var previous_downed := int(run_state.get("crew_downed_count", 0))
	var previous_critical := int(run_state.get("crew_critical_count", 0))
	var previous_exhausted := int(run_state.get("crew_exhausted_count", 0))
	var downed_count := 0
	var critical_count := 0
	var exhausted_count := 0
	for peer_id_variant in run_avatar_state.keys():
		var avatar_state: Dictionary = run_avatar_state.get(int(peer_id_variant), {})
		if avatar_state.is_empty():
			continue
		if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) == RUN_AVATAR_MODE_DOWNED:
			downed_count += 1
		elif float(avatar_state.get("health", AVATAR_MAX_HEALTH)) <= AVATAR_CRITICAL_THRESHOLD:
			critical_count += 1
		if bool(avatar_state.get("stamina_exhausted", false)):
			exhausted_count += 1
	run_state["crew_downed_count"] = downed_count
	run_state["crew_critical_count"] = critical_count
	run_state["crew_exhausted_count"] = exhausted_count
	return previous_downed != downed_count or previous_critical != critical_count or previous_exhausted != exhausted_count

func _spend_peer_stamina(peer_id: int, amount: float, require_recovered_threshold: bool = false) -> bool:
	if amount <= 0.0:
		return true
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	var current_stamina := float(avatar_state.get("stamina", AVATAR_MAX_STAMINA))
	if require_recovered_threshold and bool(avatar_state.get("stamina_exhausted", false)):
		return false
	if current_stamina < amount:
		return false
	current_stamina = maxf(0.0, current_stamina - amount)
	avatar_state["stamina"] = current_stamina
	avatar_state["stamina_regen_delay"] = AVATAR_STAMINA_REGEN_DELAY
	if current_stamina <= 0.01:
		avatar_state["stamina"] = 0.0
		avatar_state["stamina_exhausted"] = true
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	return true

func _set_peer_downed(peer_id: int) -> bool:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	if _is_peer_overboard(peer_id):
		return false
	var station_id := get_peer_station_id(peer_id)
	if not station_id.is_empty():
		_release_station(peer_id, false)
		_broadcast_station_state()
		_broadcast_boat_state()
	avatar_state["mode"] = RUN_AVATAR_MODE_DOWNED
	avatar_state["health"] = 0.0
	avatar_state["downed_timer"] = AVATAR_DOWNED_SELF_RECOVERY_SECONDS
	avatar_state["velocity"] = Vector3.ZERO
	avatar_state["grounded"] = true
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	return true

func _recover_peer_from_downed(peer_id: int, health: float = AVATAR_RALLY_HEALTH, stamina: float = AVATAR_RALLY_STAMINA) -> bool:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	var max_health := maxf(1.0, float(avatar_state.get("max_health", AVATAR_MAX_HEALTH)))
	var max_stamina := maxf(1.0, float(avatar_state.get("max_stamina", AVATAR_MAX_STAMINA)))
	avatar_state["mode"] = RUN_AVATAR_MODE_DECK
	avatar_state["health"] = clampf(health, 1.0, max_health)
	avatar_state["stamina"] = clampf(stamina, 0.0, max_stamina)
	avatar_state["stamina_exhausted"] = float(avatar_state.get("stamina", max_stamina)) < AVATAR_STAMINA_EXHAUSTED_RECOVERY_THRESHOLD
	avatar_state["stamina_regen_delay"] = AVATAR_STAMINA_REGEN_DELAY
	avatar_state["downed_timer"] = 0.0
	avatar_state["velocity"] = Vector3.ZERO
	avatar_state["grounded"] = true
	run_avatar_state[peer_id] = avatar_state
	_refresh_run_avatar_runtime_fields(peer_id)
	return true

func _restore_all_crew_vitals() -> bool:
	var changed := false
	for peer_id_variant in run_avatar_state.keys():
		var peer_id := int(peer_id_variant)
		var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
		if avatar_state.is_empty():
			continue
		var max_health := maxf(1.0, float(avatar_state.get("max_health", AVATAR_MAX_HEALTH)))
		var max_stamina := maxf(1.0, float(avatar_state.get("max_stamina", AVATAR_MAX_STAMINA)))
		avatar_state["health"] = max_health
		avatar_state["stamina"] = max_stamina
		avatar_state["stamina_exhausted"] = false
		avatar_state["stamina_regen_delay"] = 0.0
		avatar_state["downed_timer"] = 0.0
		if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) == RUN_AVATAR_MODE_DOWNED:
			avatar_state["mode"] = RUN_AVATAR_MODE_DECK
			avatar_state["velocity"] = Vector3.ZERO
			avatar_state["grounded"] = true
		run_avatar_state[peer_id] = avatar_state
		_refresh_run_avatar_runtime_fields(peer_id)
		changed = true
	return changed

func _apply_peer_health_damage(peer_id: int, amount: float, floor_health: float = 0.0) -> bool:
	if amount <= 0.0:
		return false
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	avatar_state["last_damage_time"] = float(run_state.get("elapsed_time", 0.0))
	if _is_peer_downed(peer_id):
		avatar_state["downed_timer"] = AVATAR_DOWNED_SELF_RECOVERY_SECONDS
		run_avatar_state[peer_id] = avatar_state
		_refresh_run_avatar_runtime_fields(peer_id)
		return true
	var max_health := maxf(1.0, float(avatar_state.get("max_health", AVATAR_MAX_HEALTH)))
	var current_health := float(avatar_state.get("health", max_health))
	var next_health := clampf(current_health - amount, floor_health, max_health)
	avatar_state["health"] = next_health
	run_avatar_state[peer_id] = avatar_state
	if next_health <= 0.0 and floor_health <= 0.0:
		return _set_peer_downed(peer_id)
	_refresh_run_avatar_runtime_fields(peer_id)
	return not is_equal_approx(current_health, next_health)

func _find_exposed_peer_for_impact(impact_local: Vector3) -> int:
	var nearest_peer_id := 0
	var nearest_distance := INF
	for peer_id_variant in run_avatar_state.keys():
		var peer_id := int(peer_id_variant)
		if _is_peer_overboard(peer_id):
			continue
		var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
		if avatar_state.is_empty():
			continue
		var deck_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
		deck_position.y = 0.0
		var distance := Vector3(impact_local.x, 0.0, impact_local.z).distance_to(deck_position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest_peer_id = peer_id
	return nearest_peer_id

func _apply_avatar_impact_damage(was_braced: bool, impact_local: Vector3) -> bool:
	var damage := AVATAR_IMPACT_DAMAGE_BRACED if was_braced else AVATAR_IMPACT_DAMAGE_UNBRACED
	var changed := false
	for peer_id_variant in run_avatar_state.keys():
		var peer_id := int(peer_id_variant)
		if _is_peer_overboard(peer_id):
			continue
		changed = _apply_peer_health_damage(peer_id, damage) or changed
	if not was_braced:
		var exposed_peer_id := _find_exposed_peer_for_impact(impact_local)
		if exposed_peer_id > 0:
			changed = _apply_peer_health_damage(exposed_peer_id, AVATAR_IMPACT_EXPOSED_BONUS) or changed
	return changed

func _apply_salvage_backlash_avatar_damage() -> bool:
	var changed := false
	for peer_id_variant in run_avatar_state.keys():
		var peer_id := int(peer_id_variant)
		if _is_peer_overboard(peer_id):
			continue
		var damage := AVATAR_SALVAGE_BACKLASH_PRIMARY_DAMAGE if get_peer_station_id(peer_id) == "grapple" else AVATAR_SALVAGE_BACKLASH_SPLASH_DAMAGE
		changed = _apply_peer_health_damage(peer_id, damage) or changed
	return changed

func _process_run_avatar_vitals(delta: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	var avatar_changed := false
	for peer_id_variant in run_avatar_state.keys():
		var peer_id := int(peer_id_variant)
		var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
		if avatar_state.is_empty():
			continue
		var avatar_mode := str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK))
		var state_changed := false
		if avatar_mode == RUN_AVATAR_MODE_DOWNED:
			var downed_timer := maxf(0.0, float(avatar_state.get("downed_timer", AVATAR_DOWNED_SELF_RECOVERY_SECONDS)) - delta)
			if not is_equal_approx(downed_timer, float(avatar_state.get("downed_timer", 0.0))):
				avatar_state["downed_timer"] = downed_timer
				state_changed = true
			if downed_timer <= 0.0:
				run_avatar_state[peer_id] = avatar_state
				state_changed = _recover_peer_from_downed(peer_id) or state_changed
				if state_changed:
					_set_status("%s got back on their feet." % _get_peer_name(peer_id))
				avatar_changed = avatar_changed or state_changed
				continue
		else:
			var regen_delay := maxf(0.0, float(avatar_state.get("stamina_regen_delay", 0.0)) - delta)
			if not is_equal_approx(regen_delay, float(avatar_state.get("stamina_regen_delay", 0.0))):
				avatar_state["stamina_regen_delay"] = regen_delay
				state_changed = true
			var current_stamina := float(avatar_state.get("stamina", AVATAR_MAX_STAMINA))
			var max_stamina := maxf(1.0, float(avatar_state.get("max_stamina", AVATAR_MAX_STAMINA)))
			var move_velocity: Vector3 = avatar_state.get("velocity", Vector3.ZERO)
			move_velocity.y = 0.0
			var drain_rate := 0.0
			if avatar_mode == RUN_AVATAR_MODE_DECK and move_velocity.length() > RUN_AVATAR_MOVE_SPEED * 1.05:
				drain_rate = AVATAR_SPRINT_STAMINA_DRAIN
			elif avatar_mode == RUN_AVATAR_MODE_OVERBOARD and move_velocity.length() > RUN_SWIM_MOVE_SPEED * 1.05:
				drain_rate = AVATAR_SWIM_BURST_STAMINA_DRAIN
			if drain_rate > 0.0 and current_stamina > 0.0:
				current_stamina = maxf(0.0, current_stamina - drain_rate * delta)
				avatar_state["stamina"] = current_stamina
				avatar_state["stamina_regen_delay"] = AVATAR_STAMINA_REGEN_DELAY
				if current_stamina <= 0.01:
					avatar_state["stamina"] = 0.0
					avatar_state["stamina_exhausted"] = true
				state_changed = true
			elif regen_delay <= 0.0 and current_stamina < max_stamina:
				var regen_rate := AVATAR_STAMINA_REGEN_OVERBOARD if avatar_mode == RUN_AVATAR_MODE_OVERBOARD else AVATAR_STAMINA_REGEN_DECK
				current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
				avatar_state["stamina"] = current_stamina
				if bool(avatar_state.get("stamina_exhausted", false)) and current_stamina >= AVATAR_STAMINA_EXHAUSTED_RECOVERY_THRESHOLD:
					avatar_state["stamina_exhausted"] = false
				state_changed = true
			if avatar_mode == RUN_AVATAR_MODE_OVERBOARD:
				var attrition_delay := maxf(0.0, float(avatar_state.get("overboard_attrition_delay", AVATAR_OVERBOARD_ATTRITION_DELAY)) - delta)
				avatar_state["overboard_attrition_delay"] = attrition_delay
				state_changed = true
				if attrition_delay <= 0.0:
					var attrition_timer := maxf(0.0, float(avatar_state.get("overboard_attrition_timer", AVATAR_OVERBOARD_ATTRITION_INTERVAL)) - delta)
					avatar_state["overboard_attrition_timer"] = attrition_timer
					if attrition_timer <= 0.0:
						avatar_state["overboard_attrition_timer"] = AVATAR_OVERBOARD_ATTRITION_INTERVAL
						run_avatar_state[peer_id] = avatar_state
						state_changed = _apply_peer_health_damage(peer_id, AVATAR_OVERBOARD_ATTRITION_DAMAGE, 1.0) or state_changed
					else:
						run_avatar_state[peer_id] = avatar_state
				else:
					run_avatar_state[peer_id] = avatar_state
			else:
				var current_health := float(avatar_state.get("health", AVATAR_MAX_HEALTH))
				var max_health := maxf(1.0, float(avatar_state.get("max_health", AVATAR_MAX_HEALTH)))
				var last_damage_time := float(avatar_state.get("last_damage_time", 0.0))
				if current_health > 0.0 and current_health < minf(max_health, AVATAR_HEALTH_REGEN_CAP) and float(run_state.get("elapsed_time", 0.0)) - last_damage_time >= AVATAR_HEALTH_REGEN_DELAY:
					avatar_state["health"] = minf(AVATAR_HEALTH_REGEN_CAP, current_health + AVATAR_HEALTH_REGEN_RATE * delta)
					state_changed = true
				run_avatar_state[peer_id] = avatar_state
		if state_changed:
			_refresh_run_avatar_runtime_fields(peer_id)
			avatar_changed = true
	if avatar_changed:
		_broadcast_run_avatar_state()
	if _refresh_crew_vitals_metrics():
		_broadcast_run_state()

func _get_run_pressure_phase(score: float) -> String:
	if score >= 82.0:
		return RUN_PRESSURE_PHASE_COLLAPSE
	if score >= 64.0:
		return RUN_PRESSURE_PHASE_CASCADE
	if score >= 46.0:
		return RUN_PRESSURE_PHASE_CRITICAL
	if score >= 24.0:
		return RUN_PRESSURE_PHASE_STRAINED
	return RUN_PRESSURE_PHASE_CALM

func _get_run_pressure_label(phase: String, propulsion_crisis: bool, hull_crisis: bool, recovery_crisis: bool) -> String:
	if hull_crisis and recovery_crisis:
		return "Cascade pressure"
	if propulsion_crisis:
		return "Machine pressure"
	if recovery_crisis:
		return "Recovery pressure"
	match phase:
		RUN_PRESSURE_PHASE_COLLAPSE:
			return "Collapse imminent"
		RUN_PRESSURE_PHASE_CASCADE:
			return "Cascade pressure"
		RUN_PRESSURE_PHASE_CRITICAL:
			return "Critical pressure"
		RUN_PRESSURE_PHASE_STRAINED:
			return "Crew strained"
		_:
			return "Calm seas"

func _update_run_pressure_state(delta: float) -> bool:
	if session_phase != SESSION_PHASE_RUN:
		return false
	if str(run_state.get("phase", "running")) != "running":
		return false
	var previous_snapshot := {
		"pressure_phase": str(run_state.get("pressure_phase", RUN_PRESSURE_PHASE_CALM)),
		"pressure_score": float(run_state.get("pressure_score", 0.0)),
		"pressure_label": str(run_state.get("pressure_label", "Calm seas")),
		"pressure_navigation": float(run_state.get("pressure_navigation", 0.0)),
		"pressure_salvage": float(run_state.get("pressure_salvage", 0.0)),
		"pressure_recovery": float(run_state.get("pressure_recovery", 0.0)),
		"pressure_extraction": float(run_state.get("pressure_extraction", 0.0)),
		"propulsion_crisis": bool(run_state.get("propulsion_crisis", false)),
		"hull_crisis": bool(run_state.get("hull_crisis", false)),
		"recovery_crisis": bool(run_state.get("recovery_crisis", false)),
		"support_crisis": bool(run_state.get("support_crisis", false)),
		"recovery_window_seconds": float(run_state.get("recovery_window_seconds", 0.0)),
	}
	var hull_ratio := float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) / maxf(1.0, float(boat_state.get("max_hull_integrity", BOAT_MAX_INTEGRITY)))
	var propulsion_ratio := float(boat_state.get("propulsion_health", 100.0)) / maxf(1.0, float(boat_state.get("propulsion_health_rating", 100.0)))
	var boat_speed_ratio := clampf(absf(float(boat_state.get("speed", 0.0))) / maxf(1.0, float(boat_state.get("top_speed_limit", BOAT_TOP_SPEED))), 0.0, 1.0)
	var cargo_ratio := float(run_state.get("cargo_count", 0)) / maxf(1.0, float(run_state.get("cargo_capacity", 1)))
	var breach_ratio := float(boat_state.get("breach_stacks", 0)) / float(MAX_BREACH_STACKS)
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var inside_squall := _get_active_squall_drag_multiplier(boat_position) < 0.999
	var navigation_pressure := clampf(
		boat_speed_ratio * 18.0
		+ (12.0 if inside_squall else 0.0)
		+ maxf(0.0, (45.0 - float(boat_state.get("storm_stability", 50.0))) * 0.35),
		0.0,
		35.0
	)
	var salvage_pressure := clampf(
		cargo_ratio * 10.0
		+ maxf(0.0, 1.0 - float(boat_state.get("repair_coverage", 50.0)) / 100.0) * 12.0
		+ maxf(0.0, 1.0 - float(boat_state.get("damage_redundancy", 50.0)) / 100.0) * 10.0
		+ (6.0 if bool(run_state.get("rescue_available", false)) else 0.0)
		+ (4.0 if bool(run_state.get("cache_available", false)) else 0.0),
		0.0,
		30.0
	)
	var recovery_pressure := clampf(
		float(run_state.get("overboard_count", 0)) * 12.0
		+ float(run_state.get("crew_downed_count", 0)) * 14.0
		+ float(run_state.get("crew_critical_count", 0)) * 7.0
		+ maxf(0.0, (48.0 - float(boat_state.get("recovery_access_rating", 50.0))) * 0.35),
		0.0,
		36.0
	)
	var extraction_pressure := 0.0
	if int(run_state.get("cargo_count", 0)) > 0:
		extraction_pressure = 8.0 + cargo_ratio * 12.0
		if _get_revealed_extraction_sites().is_empty():
			extraction_pressure += 6.0
		elif not inside_squall:
			extraction_pressure += maxf(0.0, 1.0 - propulsion_ratio) * 8.0
		if float(run_state.get("extraction_progress", 0.0)) > 0.0:
			extraction_pressure += 6.0
	extraction_pressure = clampf(extraction_pressure, 0.0, 26.0)
	var propulsion_crisis := propulsion_ratio < 0.45 or float(boat_state.get("fault_severity", 0.0)) >= 0.3
	var hull_crisis := hull_ratio < 0.46 or breach_ratio >= 0.5 or int(run_state.get("detached_chunk_count", 0)) > 0
	var recovery_crisis := int(run_state.get("overboard_count", 0)) > 0 or int(run_state.get("crew_downed_count", 0)) > 0
	var support_crisis := float(boat_state.get("repair_coverage", 50.0)) < 40.0 or float(boat_state.get("damage_redundancy", 50.0)) < 38.0 or not bool(station_state.get("grapple", {}).get("active", true))
	var pressure_score := clampf(
		navigation_pressure
		+ salvage_pressure
		+ recovery_pressure
		+ extraction_pressure
		+ maxf(0.0, (1.0 - hull_ratio) * 18.0)
		+ maxf(0.0, (1.0 - propulsion_ratio) * 16.0)
		+ float(run_state.get("crew_exhausted_count", 0)) * 4.0,
		0.0,
		100.0
	)
	var pressure_phase := _get_run_pressure_phase(pressure_score)
	var pressure_label := _get_run_pressure_label(pressure_phase, propulsion_crisis, hull_crisis, recovery_crisis)
	var cadence_target := clampf(13.0 - pressure_score * 0.07, 4.5, 13.0)
	var next_spike := maxf(0.0, float(run_state.get("pressure_next_spike_seconds", cadence_target)) - delta)
	if next_spike <= 0.0:
		next_spike = cadence_target
	var recovery_window := float(run_state.get("recovery_window_seconds", 0.0))
	if pressure_score < 24.0 and not propulsion_crisis and not recovery_crisis and not inside_squall:
		recovery_window = minf(6.0, recovery_window + delta)
	else:
		recovery_window = maxf(0.0, recovery_window - delta * 1.4)
	run_state["pressure_phase"] = pressure_phase
	run_state["pressure_score"] = pressure_score
	run_state["pressure_label"] = pressure_label
	run_state["pressure_navigation"] = navigation_pressure
	run_state["pressure_salvage"] = salvage_pressure
	run_state["pressure_recovery"] = recovery_pressure
	run_state["pressure_extraction"] = extraction_pressure
	run_state["pressure_cadence_seconds"] = cadence_target
	run_state["pressure_next_spike_seconds"] = next_spike
	run_state["recovery_window_seconds"] = recovery_window
	run_state["propulsion_crisis"] = propulsion_crisis
	run_state["hull_crisis"] = hull_crisis
	run_state["recovery_crisis"] = recovery_crisis
	run_state["support_crisis"] = support_crisis
	for key in previous_snapshot.keys():
		var previous_value = previous_snapshot.get(key)
		var next_value = run_state.get(key)
		if typeof(previous_value) == TYPE_FLOAT:
			if absf(float(previous_value) - float(next_value)) > 0.45:
				return true
		elif previous_value != next_value:
			return true
	return false

func _is_station_claimable(station_id: String) -> bool:
	var station_data: Dictionary = station_state.get(station_id, {})
	return bool(station_data.get("claimable", false)) and bool(station_data.get("active", true))

func _get_run_station_claim_radius(station_id: String) -> float:
	var station_data: Dictionary = station_state.get(station_id, {})
	return float(station_data.get("claim_radius", 0.0))

func _get_run_station_release_radius(station_id: String) -> float:
	var station_data: Dictionary = station_state.get(station_id, {})
	return float(station_data.get("release_radius", 0.0))

func _get_peer_run_avatar_position(peer_id: int) -> Vector3:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	return avatar_state.get("deck_position", Vector3.ZERO)

func _peer_within_run_station_range(peer_id: int, station_id: String, extra_margin: float = 0.0) -> bool:
	if peer_id <= 0 or not station_state.has(station_id):
		return false
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) != RUN_AVATAR_MODE_DECK:
		return false
	var claim_radius := _get_run_station_claim_radius(station_id)
	if claim_radius <= 0.0:
		return false
	if not bool(station_state.get(station_id, {}).get("active", true)):
		return false
	var avatar_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var station_position := get_station_position(station_id)
	return avatar_position.distance_to(station_position) <= (claim_radius + maxf(0.0, extra_margin))

func _find_nearest_repairable_block(peer_id: int, max_range: float = RUN_REPAIR_RANGE) -> Dictionary:
	if peer_id <= 0:
		return {}
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return {}
	if str(avatar_state.get("mode", RUN_AVATAR_MODE_DECK)) != RUN_AVATAR_MODE_DECK:
		return {}
	var avatar_position: Vector3 = avatar_state.get("deck_position", Vector3.ZERO)
	var nearest_block: Dictionary = {}
	var nearest_distance := max_range
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		if float(block.get("current_hp", 0.0)) >= float(block.get("max_hp", 0.0)) - 0.01:
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := avatar_position.distance_to(local_position)
		if distance > nearest_distance:
			continue
		nearest_distance = distance
		nearest_block = block.duplicate(true)
		nearest_block["repair_distance"] = distance
	return nearest_block

func _get_local_support_profile(local_position: Vector3) -> Dictionary:
	var repair_bonus := 0.0
	var brace_bonus := 0.0
	var recovery_bonus := 0.0
	var salvage_bonus := 0.0
	var backlash_multiplier := 1.0
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var block_def := get_builder_block_definition(str(block.get("type", "structure")))
		var block_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := block_position.distance_to(local_position)
		if distance > 4.5:
			continue
		var influence := clampf(1.0 - distance / 4.5, 0.0, 1.0)
		repair_bonus = maxf(repair_bonus, _get_definition_float(block_def, "repair_zone", 0.0) * influence)
		brace_bonus = maxf(brace_bonus, _get_definition_float(block_def, "brace_zone", 0.0) * influence)
		recovery_bonus = maxf(recovery_bonus, _get_definition_float(block_def, "recovery_access", 0.0) * influence)
		salvage_bonus = maxf(salvage_bonus, _get_definition_float(block_def, "salvage_rating", 0.0) * influence)
		var local_backlash_multiplier := _get_definition_float(block_def, "salvage_backlash_multiplier", 1.0)
		if local_backlash_multiplier > 0.0:
			backlash_multiplier = minf(backlash_multiplier, lerpf(1.0, local_backlash_multiplier, influence))
	return {
		"repair_bonus": repair_bonus,
		"brace_bonus": brace_bonus,
		"recovery_bonus": recovery_bonus,
		"salvage_bonus": salvage_bonus,
		"salvage_backlash_multiplier": backlash_multiplier,
	}

func _get_peer_repair_profile(peer_id: int) -> Dictionary:
	var avatar_state: Dictionary = run_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return {
			"range": RUN_REPAIR_RANGE,
			"heal": REPAIR_HULL_RECOVERY,
		}
	var support_profile := _get_local_support_profile(avatar_state.get("deck_position", Vector3.ZERO))
	return {
		"range": RUN_REPAIR_RANGE + float(support_profile.get("repair_bonus", 0.0)) * 1.8,
		"heal": REPAIR_HULL_RECOVERY * (1.0 + float(support_profile.get("repair_bonus", 0.0)) * 0.35),
	}

func _get_local_brace_multiplier(impact_local: Vector3) -> float:
	var support_profile := _get_local_support_profile(impact_local)
	return 1.0 + float(support_profile.get("brace_bonus", 0.0)) * 0.4

func _enforce_run_station_ranges() -> void:
	if not multiplayer.is_server():
		return
	var released_station_labels := PackedStringArray()
	for station_id_variant in get_claimable_station_ids():
		var station_id := str(station_id_variant)
		var station: Dictionary = station_state.get(station_id, {})
		var occupant_peer_id := int(station.get("occupant_peer_id", 0))
		if occupant_peer_id <= 0:
			continue
		if _peer_within_run_station_range(occupant_peer_id, station_id, _get_run_station_release_radius(station_id) - _get_run_station_claim_radius(station_id)):
			continue
		_release_station(occupant_peer_id, false)
		released_station_labels.append(get_station_label(station_id))
	if not released_station_labels.is_empty():
		_broadcast_station_state()
		_broadcast_boat_state()
		_set_status("%s lost station control after drifting out of range." % ", ".join(released_station_labels))

func _reset_run_runtime() -> void:
	driver_peer_id = 0
	_peer_inputs = {}
	_boat_broadcast_accumulator = 0.0
	_run_state_broadcast_accumulator = 0.0
	_next_hazard_id = 1
	_next_loot_id = 1
	_next_runtime_chunk_id = 1
	_reset_run_avatar_state()
	_reset_reaction_runtime()
	var blueprint_stats := Dictionary(boat_blueprint.get("stats", {}))
	var max_hull_integrity := float(blueprint_stats.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	var top_speed := float(blueprint_stats.get("top_speed", BOAT_TOP_SPEED))
	var cargo_capacity := int(blueprint_stats.get("cargo_capacity", 1))
	var repair_capacity := int(blueprint_stats.get("repair_capacity", REPAIR_SUPPLIES_START))
	var brace_multiplier := float(blueprint_stats.get("brace_multiplier", 1.0))
	var propulsion_family := str(blueprint_stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	var hull_dimensions := _get_runtime_hull_dimensions_from_stats(blueprint_stats)
	var launch_warning_text := _build_blueprint_warning_text()

	boat_state = {
		"position": Vector3.ZERO,
		"rotation_y": 0.0,
		"speed": 0.0,
		"throttle": 0.0,
		"steer": 0.0,
		"speed_order": "Stop",
		"rudder_input": 0.0,
		"actual_thrust": 0.0,
		"tick": 0,
		"driver_peer_id": 0,
		"max_hull_integrity": max_hull_integrity,
		"hull_integrity": max_hull_integrity,
		"brace_timer": 0.0,
		"brace_cooldown": 0.0,
		"repair_cooldown": 0.0,
		"base_top_speed": top_speed,
		"top_speed_limit": top_speed,
		"acceleration_rating": float(blueprint_stats.get("acceleration", 50.0)),
		"turn_authority": float(blueprint_stats.get("turn_authority", 50.0)),
		"storm_stability": float(blueprint_stats.get("storm_stability", 50.0)),
		"draft_ratio": float(blueprint_stats.get("draft_ratio", 0.72)),
		"reserve_buoyancy": float(blueprint_stats.get("reserve_buoyancy", blueprint_stats.get("buoyancy_margin", 0.0))),
		"span_width": int(blueprint_stats.get("span_width", 2)),
		"span_length": int(blueprint_stats.get("span_length", 4)),
		"hull_length": float(hull_dimensions.get("hull_length", 4.4)),
		"hull_beam": float(hull_dimensions.get("hull_beam", 2.7)),
		"roll_resistance": float(blueprint_stats.get("roll_resistance", 50.0)),
		"pitch_resistance": float(blueprint_stats.get("pitch_resistance", 50.0)),
		"heel_bias": float(blueprint_stats.get("heel_bias", 0.0)),
		"trim_bias": float(blueprint_stats.get("trim_bias", 0.0)),
		"water_surface_offset": 0.0,
		"buoyancy_heave": 0.0,
		"buoyancy_heave_velocity": 0.0,
		"buoyancy_pitch": 0.0,
		"buoyancy_pitch_velocity": 0.0,
		"buoyancy_roll": 0.0,
		"buoyancy_roll_velocity": 0.0,
		"water_drag_multiplier": 1.0,
		"buoyancy_submersion": 0.0,
		"freeboard_rating": float(blueprint_stats.get("freeboard_rating", 50.0)),
		"top_heavy_penalty": float(blueprint_stats.get("top_heavy_penalty", 0.0)),
		"hydrostatic_class": str(blueprint_stats.get("hydrostatic_class", "stable")),
		"crew_safety": float(blueprint_stats.get("crew_safety", 50.0)),
		"repair_coverage": float(blueprint_stats.get("repair_coverage", 50.0)),
		"workload": float(blueprint_stats.get("workload", 50.0)),
		"recommended_crew": int(blueprint_stats.get("recommended_crew", 2)),
		"propulsion_family": propulsion_family,
		"propulsion_label": str(blueprint_stats.get("propulsion_label", get_propulsion_family_label(propulsion_family))),
		"propulsion_block_count": int(blueprint_stats.get("propulsion_count", 0)),
		"automation_floor": float(blueprint_stats.get("automation_floor", 0.65)),
		"manual_ceiling": float(blueprint_stats.get("manual_ceiling", 1.0)),
		"burst_ceiling": float(blueprint_stats.get("burst_ceiling", PROPULSION_BURST_SPEED_MULTIPLIER)),
		"propulsion_efficiency": float(blueprint_stats.get("automation_floor", 0.65)),
		"propulsion_health_rating": float(blueprint_stats.get("propulsion_health_rating", 100.0)),
		"propulsion_health": float(blueprint_stats.get("propulsion_health_rating", 100.0)),
		"fault_state": PROPULSION_FAULT_STATE_STABLE,
		"fault_severity": 0.0,
		"propulsion_heat": 0.0,
		"propulsion_pressure": 0.0,
		"propulsion_trim": 1.0,
		"propulsion_sync": float(blueprint_stats.get("automation_floor", 0.65)),
		"propulsion_port_output": float(blueprint_stats.get("automation_floor", 0.65)) * 0.5,
		"propulsion_starboard_output": float(blueprint_stats.get("automation_floor", 0.65)) * 0.5,
		"propulsion_side_bias": 0.0,
		"propulsion_support_timer": 0.0,
		"propulsion_support_boost": 0.0,
		"propulsion_secondary_timer": 0.0,
		"breach_stacks": 0,
		"last_impact_damage": 0.0,
		"last_impact_braced": false,
		"collision_count": 0,
		"cargo_capacity": cargo_capacity,
		"brace_multiplier": brace_multiplier,
		"blueprint_version": int(boat_blueprint.get("version", 1)),
		"runtime_blocks": [],
		"runtime_chunks": [],
		"sinking_chunks": [],
		"main_chunk_id": 0,
		"destroyed_block_count": 0,
		"detached_chunk_count": 0,
		"recent_damage_block_ids": [],
		"recent_detached_chunk_ids": [],
		"cargo_lost_to_sea": 0,
	}

	station_state = _build_station_state_from_stats(blueprint_stats)

	_initialize_generated_run_state(repair_capacity, cargo_capacity, launch_warning_text)

func _initialize_generated_run_state(repair_capacity: int, cargo_capacity: int, launch_warning_text: String) -> void:
	var blueprint_stats := Dictionary(boat_blueprint.get("stats", {}))
	var generated_world := RunWorldGenerator.generate_world(int(run_seed))
	var poi_sites := _copy_array(generated_world.get("poi_sites", []))
	var extraction_sites := _copy_array(generated_world.get("extraction_sites", []))
	var chunk_descriptors := _copy_array(generated_world.get("chunk_descriptors", []))
	var hazard_fields := _copy_array(generated_world.get("hazard_fields", []))
	var primary_salvage_site := _find_site_in_array(poi_sites, RunWorldGenerator.SITE_SALVAGE)
	var primary_distress_site := _find_site_in_array(poi_sites, RunWorldGenerator.SITE_DISTRESS)
	var primary_resupply_site := _find_site_in_array(poi_sites, RunWorldGenerator.SITE_RESUPPLY)
	var primary_extraction_site: Dictionary = extraction_sites[0] if not extraction_sites.is_empty() else {}
	var wind_heading := fposmod(float(run_seed % 360) * 0.37, TAU)
	var wind_strength := clampf(0.74 + sin(float(run_seed % 97)) * 0.08, 0.6, 0.9)

	hazard_state = _build_generated_hazard_state(chunk_descriptors, poi_sites)
	loot_state = _build_generated_loot_state(poi_sites)
	run_state = {
		"phase": "running",
		"run_instance_id": _next_run_instance_id,
		"world_bounds_chunks": _copy_array(generated_world.get("world_bounds_chunks", [RunWorldGenerator.WORLD_SIZE_CHUNKS, RunWorldGenerator.WORLD_SIZE_CHUNKS])),
		"chunk_size_m": float(generated_world.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M)),
		"spawn_chunk": _copy_array(generated_world.get("spawn_chunk", [7, 7])),
		"chunk_descriptors": chunk_descriptors,
		"active_chunk_coords": [],
		"stream_radius_chunks": int(generated_world.get("stream_radius_chunks", RunWorldGenerator.STREAM_RADIUS_CHUNKS)),
		"poi_sites": poi_sites,
		"extraction_sites": extraction_sites,
		"revealed_extraction_ids": [],
		"active_extraction_id": "",
		"hazard_fields": hazard_fields,
		"squall_bands": hazard_fields.duplicate(true),
		"world_label": str(generated_world.get("world_label", "Open Sea")),
		"layout_label": str(generated_world.get("world_label", "Open Sea")),
		"wind_heading": wind_heading,
		"wind_strength": wind_strength,
		"recovery_points": Array(blueprint_stats.get("recovery_points", RUN_RECOVERY_POINTS)).duplicate(true),
		"cargo_count": 0,
		"cargo_manifest": [],
		"secured_manifest": [],
		"run_item_bank": {},
		"run_schematic_bank": [],
		"bonus_manifest": [],
		"cargo_secured": 0,
		"loot_collected": 0,
		"loot_total": loot_state.size(),
		"loot_remaining": loot_state.size(),
		"wreck_position": primary_salvage_site.get("position", Vector3.ZERO),
		"wreck_radius": float(primary_salvage_site.get("radius", 4.4)),
		"salvage_max_speed": float(primary_salvage_site.get("max_speed", SALVAGE_MAX_SPEED)),
		"repair_actions": 0,
		"repair_supplies": repair_capacity,
		"repair_supplies_max": repair_capacity,
		"cargo_capacity": cargo_capacity,
		"rescue_position": primary_distress_site.get("position", Vector3.ZERO),
		"rescue_radius": float(primary_distress_site.get("radius", 3.4)),
		"rescue_max_speed": float(primary_distress_site.get("max_speed", RESCUE_MAX_SPEED)),
		"rescue_duration": float(primary_distress_site.get("duration", RESCUE_DURATION)),
		"rescue_progress": 0.0,
		"rescue_available": not primary_distress_site.is_empty() and bool(primary_distress_site.get("available", true)),
		"rescue_engaged": false,
		"rescue_completed": false,
		"rescue_label": str(primary_distress_site.get("label", "Distress Rescue")),
		"rescue_bonus_gold": int(primary_distress_site.get("bonus_gold", RESCUE_GOLD_BONUS_MIN)),
		"rescue_bonus_salvage": int(primary_distress_site.get("bonus_salvage", RESCUE_SALVAGE_BONUS_MIN)),
		"rescue_patch_kit_bonus": int(primary_distress_site.get("patch_kit_bonus", RESCUE_PATCH_KIT_GRANT)),
		"cache_position": primary_resupply_site.get("position", Vector3.ZERO),
		"cache_radius": float(primary_resupply_site.get("radius", RESUPPLY_CACHE_RADIUS)),
		"cache_max_speed": float(primary_resupply_site.get("max_speed", RESUPPLY_CACHE_MAX_SPEED)),
		"cache_available": not primary_resupply_site.is_empty() and bool(primary_resupply_site.get("available", true)),
		"cache_label": str(primary_resupply_site.get("label", "Resupply Cache")),
		"cache_recovered": false,
		"bonus_gold_bank": 0,
		"bonus_salvage_bank": 0,
		"extraction_position": primary_extraction_site.get("position", Vector3.ZERO),
		"extraction_radius": float(primary_extraction_site.get("radius", EXTRACTION_RADIUS)),
		"extraction_progress": 0.0,
		"extraction_duration": float(primary_extraction_site.get("duration", EXTRACTION_DURATION)),
		"reward_gold": 0,
		"reward_salvage": 0,
		"reward_items": {},
		"reward_schematics": [],
		"loot_lost_items": {},
		"repair_debt_delta": {},
		"result_title": "",
		"result_message": "",
		"failure_reason": "",
		"eligible_reward_peer_ids": get_player_peer_ids(),
		"launch_warning": launch_warning_text,
		"blueprint_version": int(boat_blueprint.get("version", 1)),
		"cargo_lost_to_sea": 0,
		"detached_chunk_count": 0,
		"destroyed_block_count": 0,
		"overboard_count": 0,
		"overboard_incidents": 0,
		"recoveries_completed": 0,
		"crew_downed_count": 0,
		"crew_critical_count": 0,
		"crew_exhausted_count": 0,
		"elapsed_time": 0.0,
		"launch_loose_chunks": int(blueprint_stats.get("loose_blocks", 0)),
		"pressure_phase": RUN_PRESSURE_PHASE_CALM,
		"pressure_score": 0.0,
		"pressure_label": "Calm seas",
		"pressure_navigation": 0.0,
		"pressure_salvage": 0.0,
		"pressure_recovery": 0.0,
		"pressure_extraction": 0.0,
		"pressure_cadence_seconds": 12.0,
		"pressure_next_spike_seconds": 12.0,
		"recovery_window_seconds": 0.0,
		"propulsion_crisis": false,
		"hull_crisis": false,
		"recovery_crisis": false,
		"support_crisis": false,
		"builder_overlay_modes": BUILDER_OVERLAY_ORDER.duplicate(),
	}
	boat_state["position"] = generated_world.get("spawn_position", Vector3.ZERO)
	_initialize_runtime_boat_from_blueprint()
	_sync_generated_world_runtime_metrics()
	_update_active_chunk_streaming(true)

func _apply_launch_repair_penalty() -> void:
	var repair_resolution := DockState.resolve_launch_repair_debt()
	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())
	var remaining_ratio := float(repair_resolution.get("remaining_ratio", 0.0))
	run_state["repair_debt_snapshot"] = Dictionary(repair_resolution.get("remaining_debt", {})).duplicate(true)
	if remaining_ratio <= 0.0:
		run_state["launch_repair_penalty"] = {}
		return
	var propulsion_health_factor := clampf(float(repair_resolution.get("propulsion_health_factor", 1.0)), 0.55, 1.0)
	var stability_factor := clampf(float(repair_resolution.get("stability_factor", 1.0)), 0.7, 1.0)
	var patch_kit_penalty := maxi(0, int(repair_resolution.get("patch_kit_penalty", 0)))
	boat_state["propulsion_health"] = minf(
		float(boat_state.get("propulsion_health", 100.0)),
		float(boat_state.get("propulsion_health_rating", 100.0)) * propulsion_health_factor
	)
	boat_state["storm_stability"] = float(boat_state.get("storm_stability", 50.0)) * stability_factor
	run_state["repair_supplies"] = maxi(0, int(run_state.get("repair_supplies", 0)) - patch_kit_penalty)
	run_state["launch_repair_penalty"] = {
		"remaining_ratio": remaining_ratio,
		"propulsion_health_factor": propulsion_health_factor,
		"stability_factor": stability_factor,
		"patch_kit_penalty": patch_kit_penalty,
		"summary": str(repair_resolution.get("summary", "Outstanding repair debt left the crew on a jury-rigged launch.")),
	}
	var launch_warning := str(run_state.get("launch_warning", ""))
	if not launch_warning.is_empty():
		launch_warning += " "
	launch_warning += "Jury-rigged launch: propulsion starts damaged, spare kits are limited, and the deck feels less settled."
	run_state["launch_warning"] = launch_warning

func _build_generated_hazard_state(chunk_descriptors: Array, poi_sites: Array) -> Array:
	var hazards: Array = []
	var occupied_coords := {}
	for site_variant in poi_sites:
		var site: Dictionary = site_variant
		occupied_coords[_coord_key(site.get("coord", [0, 0]))] = true
	for descriptor_variant in chunk_descriptors:
		var descriptor: Dictionary = descriptor_variant
		if bool(descriptor.get("is_border_chunk", false)):
			continue
		if occupied_coords.has(_coord_key(descriptor.get("coord", [0, 0]))):
			continue
		var hazard_level := float(descriptor.get("hazard_level", 0.0))
		if hazard_level < 0.56:
			continue
		if int(descriptor.get("props_seed", 0)) % 7 != 0:
			continue
		var center: Vector3 = descriptor.get("world_center", Vector3.ZERO)
		var biome_id := str(descriptor.get("biome_id", RunWorldGenerator.BIOME_OPEN_OCEAN))
		var label := "Debris Cluster"
		if biome_id == RunWorldGenerator.BIOME_REEF_WATERS:
			label = "Reef Teeth"
		elif biome_id == RunWorldGenerator.BIOME_GRAVEYARD_WATERS:
			label = "Broken Spar"
		elif biome_id == RunWorldGenerator.BIOME_STORM_BELT:
			label = "Storm Debris"
		hazards.append(_make_hazard(
			center + Vector3(
				sin(float(int(descriptor.get("props_seed", 0)) % 360)) * 4.2,
				0.0,
				cos(float(int(descriptor.get("props_seed", 0)) % 360)) * 3.6
			),
			lerpf(1.05, 1.6, clampf((hazard_level - 0.48) / 0.52, 0.0, 1.0)),
			label,
			{
				"chunk_coord": _copy_coord_array(descriptor.get("coord", [0, 0])),
				"home_position": center,
			}
		))
	return hazards

func _build_generated_loot_state(poi_sites: Array) -> Array:
	var generated_loot: Array = []
	for site_variant in poi_sites:
		var site: Dictionary = site_variant
		if str(site.get("site_type", "")) != RunWorldGenerator.SITE_SALVAGE:
			continue
		var loot_count := maxi(1, int(site.get("loot_count", 1)))
		var site_id := str(site.get("id", "salvage"))
		var site_label := str(site.get("label", "Wreck Salvage"))
		var site_position: Vector3 = site.get("position", Vector3.ZERO)
		for loot_index in range(loot_count):
			var angle := float((site_id.hash() + loot_index * 97) % 360)
			var offset := Vector3(sin(deg_to_rad(angle)) * 1.25, 0.0, cos(deg_to_rad(angle)) * 1.15)
			var industrial_grade: bool = (abs(site_id.hash()) + loot_index * 11) % 5 == 0
			var loot_bundle := _build_salvage_loot_bundle(site_id, loot_index, industrial_grade)
			var loot_label := "%s Cargo %d" % [site_label, loot_index + 1]
			if industrial_grade:
				loot_label = "%s Industrial Crate %d" % [site_label, loot_index + 1]
			generated_loot.append(_make_loot(
				site_position + offset,
				1,
				loot_label,
				true,
				{
					"site_id": site_id,
					"site_type": RunWorldGenerator.SITE_SALVAGE,
					"site_label": site_label,
					"chunk_coord": _copy_coord_array(site.get("coord", [0, 0])),
					"material_bundle": Dictionary(loot_bundle.get("materials", {})).duplicate(true),
					"schematic_ids": Array(loot_bundle.get("schematics", [])).duplicate(true),
					"industrial_grade": industrial_grade,
				}
			))
	return generated_loot

func _build_salvage_loot_bundle(site_id: String, loot_index: int, industrial_grade: bool) -> Dictionary:
	var bundle := {
		"materials": {
			"scrap_metal": 1 + ((abs(site_id.hash()) + loot_index) % 2),
			"machined_parts": 1 + ((abs(site_id.hash()) + loot_index * 3) % 2),
		},
		"schematics": [],
	}
	if (abs(site_id.hash()) + loot_index * 13) % 6 == 0:
		bundle["schematics"] = [_pick_schematic_from_pool([
			"keel_hull",
			"reinforced_hull",
			"repair_bay",
			"heavy_winch",
			"engine",
		], site_id, loot_index)]
	if industrial_grade:
		var industrial_materials := Dictionary(bundle.get("materials", {})).duplicate(true)
		industrial_materials["boiler_parts"] = 1 + ((abs(site_id.hash()) + loot_index * 5) % 2)
		industrial_materials["shock_insulation"] = 1
		bundle["materials"] = industrial_materials
		bundle["schematics"] = _merge_schematic_lists_ui(bundle.get("schematics", []), [
			_pick_schematic_from_pool([
				"engine",
				"twin_engine",
				"armored_housing",
				"shock_bulkhead",
				"high_pressure_boiler",
			], site_id, loot_index + 17)
		])
	return {
		"materials": _normalize_material_dict_ui(bundle.get("materials", {})),
		"schematics": _normalize_schematic_list_ui(bundle.get("schematics", [])),
	}

func _pick_schematic_from_pool(pool: Array, site_id: String, salt: int) -> String:
	if pool.is_empty():
		return ""
	var index: int = abs(site_id.hash() + salt * 37) % pool.size()
	return str(pool[index])

func _build_rescue_reward_bundle(site: Dictionary) -> Dictionary:
	var site_id := str(site.get("id", "rescue"))
	var materials := {
		"treated_planks": 2,
		"rigging": 1 + (abs(site_id.hash()) % 2),
	}
	var schematics: Array = []
	if abs(site_id.hash()) % 4 == 0:
		schematics.append(_pick_schematic_from_pool([
			"guard_rail",
			"rescue_net",
			"brace_frame",
			"utility_bay",
		], site_id, 5))
	return {
		"gold": int(site.get("bonus_gold", RESCUE_GOLD_BONUS_MIN)),
		"materials": _normalize_material_dict_ui(materials),
		"schematics": _normalize_schematic_list_ui(schematics),
	}

func _build_cache_reward_bundle(site: Dictionary) -> Dictionary:
	var site_id := str(site.get("id", "cache"))
	var materials := {
		"scrap_metal": 1 + (abs(site_id.hash()) % 2),
		"treated_planks": 1,
	}
	if abs(site_id.hash()) % 3 == 0:
		materials["machined_parts"] = 1
	var schematics: Array = []
	if abs(site_id.hash()) % 5 == 0:
		schematics.append(_pick_schematic_from_pool([
			"repair_bay",
			"stabilizer",
			"sail_rig",
		], site_id, 9))
	return {
		"gold": int(site.get("bonus_gold", RESUPPLY_CACHE_GOLD_BONUS)),
		"materials": _normalize_material_dict_ui(materials),
		"schematics": _normalize_schematic_list_ui(schematics),
	}

func _sync_generated_world_runtime_metrics() -> void:
	var poi_sites := _copy_array(run_state.get("poi_sites", []))
	var salvage_position := Vector3.ZERO
	var rescue_position := Vector3.ZERO
	var cache_position := Vector3.ZERO
	var rescue_available := false
	var rescue_engaged := false
	var rescue_completed := false
	var rescue_progress := 0.0
	var rescue_duration := RESCUE_DURATION
	var rescue_max_speed := RESCUE_MAX_SPEED
	var rescue_label := "Distress Rescue"
	var rescue_bonus_gold := RESCUE_GOLD_BONUS_MIN
	var rescue_bonus_salvage := RESCUE_SALVAGE_BONUS_MIN
	var rescue_patch_kit_bonus := RESCUE_PATCH_KIT_GRANT
	var cache_available := false
	var cache_recovered := false
	var cache_label := "Resupply Cache"
	var cache_radius := RESUPPLY_CACHE_RADIUS
	var cache_max_speed := RESUPPLY_CACHE_MAX_SPEED
	for site_index in range(poi_sites.size()):
		var site: Dictionary = poi_sites[site_index]
		var site_type := str(site.get("site_type", ""))
		if site_type == RunWorldGenerator.SITE_SALVAGE:
			var total_loot := 0
			var remaining_loot := 0
			for loot_variant in loot_state:
				var loot_target: Dictionary = loot_variant
				if str(loot_target.get("site_id", "")) != str(site.get("id", "")):
					continue
				total_loot += 1
				remaining_loot += 1
			site["loot_remaining"] = remaining_loot
			if salvage_position == Vector3.ZERO and remaining_loot > 0:
				salvage_position = site.get("position", Vector3.ZERO)
				run_state["wreck_radius"] = float(site.get("radius", 4.4))
				run_state["salvage_max_speed"] = float(site.get("max_speed", SALVAGE_MAX_SPEED))
		elif site_type == RunWorldGenerator.SITE_DISTRESS:
			if bool(site.get("completed", false)):
				rescue_completed = true
			if rescue_position == Vector3.ZERO and bool(site.get("available", true)):
				rescue_position = site.get("position", Vector3.ZERO)
				rescue_available = bool(site.get("available", true))
				rescue_engaged = bool(site.get("engaged", false))
				rescue_progress = float(site.get("progress", 0.0))
				rescue_duration = float(site.get("duration", RESCUE_DURATION))
				rescue_max_speed = float(site.get("max_speed", RESCUE_MAX_SPEED))
				rescue_label = str(site.get("label", "Distress Rescue"))
				rescue_bonus_gold = int(site.get("bonus_gold", RESCUE_GOLD_BONUS_MIN))
				rescue_bonus_salvage = int(site.get("bonus_salvage", RESCUE_SALVAGE_BONUS_MIN))
				rescue_patch_kit_bonus = int(site.get("patch_kit_bonus", RESCUE_PATCH_KIT_GRANT))
				run_state["rescue_radius"] = float(site.get("radius", 3.4))
		elif site_type == RunWorldGenerator.SITE_RESUPPLY:
			if bool(site.get("recovered", false)):
				cache_recovered = true
			if cache_position == Vector3.ZERO and bool(site.get("available", true)):
				cache_position = site.get("position", Vector3.ZERO)
				cache_available = bool(site.get("available", true))
				cache_label = str(site.get("label", "Resupply Cache"))
				cache_radius = float(site.get("radius", RESUPPLY_CACHE_RADIUS))
				cache_max_speed = float(site.get("max_speed", RESUPPLY_CACHE_MAX_SPEED))
		poi_sites[site_index] = site

	run_state["poi_sites"] = poi_sites
	run_state["loot_total"] = loot_state.size()
	run_state["loot_remaining"] = loot_state.size()
	run_state["wreck_position"] = salvage_position
	run_state["rescue_position"] = rescue_position
	run_state["rescue_available"] = rescue_available
	run_state["rescue_engaged"] = rescue_engaged
	run_state["rescue_completed"] = rescue_completed
	run_state["rescue_progress"] = rescue_progress
	run_state["rescue_duration"] = rescue_duration
	run_state["rescue_max_speed"] = rescue_max_speed
	run_state["rescue_label"] = rescue_label
	run_state["rescue_bonus_gold"] = rescue_bonus_gold
	run_state["rescue_bonus_salvage"] = rescue_bonus_salvage
	run_state["rescue_patch_kit_bonus"] = rescue_patch_kit_bonus
	run_state["cache_position"] = cache_position
	run_state["cache_available"] = cache_available
	run_state["cache_recovered"] = cache_recovered
	run_state["cache_label"] = cache_label
	run_state["cache_radius"] = cache_radius
	run_state["cache_max_speed"] = cache_max_speed
	run_state["squall_bands"] = _copy_array(run_state.get("hazard_fields", []))
	var visible_extractions := _get_revealed_extraction_sites()
	var all_extractions := _copy_array(run_state.get("extraction_sites", []))
	var primary_extraction: Dictionary = visible_extractions[0] if not visible_extractions.is_empty() else (all_extractions[0] if not all_extractions.is_empty() else {})
	run_state["extraction_position"] = primary_extraction.get("position", Vector3.ZERO)
	run_state["extraction_radius"] = float(primary_extraction.get("radius", EXTRACTION_RADIUS))
	run_state["extraction_duration"] = float(primary_extraction.get("duration", EXTRACTION_DURATION))

func _find_site_in_array(sites: Array, site_type: String) -> Dictionary:
	for site_variant in sites:
		var site: Dictionary = site_variant
		if str(site.get("site_type", "")) == site_type:
			return site.duplicate(true)
	return {}

func _coord_key(coord_value: Variant) -> String:
	var coord := _coord_from_variant(coord_value)
	return "%d:%d" % [coord.x, coord.y]

func _coord_from_variant(coord_value: Variant) -> Vector2i:
	if coord_value is Vector2i:
		return coord_value
	if coord_value is Vector2:
		return Vector2i(int(coord_value.x), int(coord_value.y))
	if coord_value is Array and coord_value.size() >= 2:
		return Vector2i(int(coord_value[0]), int(coord_value[1]))
	return Vector2i.ZERO

func _copy_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

func _copy_coord_array(coord_value: Variant) -> Array:
	var coord := _coord_from_variant(coord_value)
	return [coord.x, coord.y]

func _get_world_bounds_chunks() -> Vector2i:
	var bounds := _copy_array(run_state.get("world_bounds_chunks", [RunWorldGenerator.WORLD_SIZE_CHUNKS, RunWorldGenerator.WORLD_SIZE_CHUNKS]))
	if bounds.size() < 2:
		return Vector2i(RunWorldGenerator.WORLD_SIZE_CHUNKS, RunWorldGenerator.WORLD_SIZE_CHUNKS)
	return Vector2i(int(bounds[0]), int(bounds[1]))

func _get_chunk_size_m() -> float:
	return float(run_state.get("chunk_size_m", RunWorldGenerator.CHUNK_SIZE_M))

func get_world_chunk_coord(world_position: Vector3) -> Array:
	var chunk_size := _get_chunk_size_m()
	var spawn_chunk := _coord_from_variant(run_state.get("spawn_chunk", [7, 7]))
	var chunk_x := int(round(world_position.x / chunk_size)) + spawn_chunk.x
	var chunk_z := int(round(world_position.z / chunk_size)) + spawn_chunk.y
	var world_bounds := _get_world_bounds_chunks()
	return [
		clampi(chunk_x, 0, world_bounds.x - 1),
		clampi(chunk_z, 0, world_bounds.y - 1),
	]

func get_chunk_world_center(coord_value: Variant) -> Vector3:
	return RunWorldGenerator._chunk_center_world_position(coord_value, run_state.get("spawn_chunk", [7, 7]))

func get_chunk_descriptor(coord_value: Variant) -> Dictionary:
	var target_key := _coord_key(coord_value)
	for descriptor_variant in _copy_array(run_state.get("chunk_descriptors", [])):
		var descriptor: Dictionary = descriptor_variant
		if _coord_key(descriptor.get("coord", [0, 0])) == target_key:
			return descriptor.duplicate(true)
	return {}

func _update_active_chunk_streaming(force_broadcast: bool = false) -> void:
	if str(run_state.get("phase", "running")) not in ["running", "success", "failed"]:
		return
	var center_coord := _coord_from_variant(get_world_chunk_coord(boat_state.get("position", Vector3.ZERO)))
	var radius := int(run_state.get("stream_radius_chunks", RunWorldGenerator.STREAM_RADIUS_CHUNKS))
	var world_bounds := _get_world_bounds_chunks()
	var active_coords: Array = []
	for z in range(center_coord.y - radius, center_coord.y + radius + 1):
		for x in range(center_coord.x - radius, center_coord.x + radius + 1):
			if x < 0 or z < 0:
				continue
			if x >= world_bounds.x:
				continue
			if z >= world_bounds.y:
				continue
			active_coords.append([x, z])
	var previous := _copy_array(run_state.get("active_chunk_coords", []))
	if not force_broadcast and previous.hash() == active_coords.hash():
		return
	run_state["active_chunk_coords"] = active_coords
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_broadcast_run_state()

func _get_revealed_extraction_sites() -> Array:
	var revealed_ids := {}
	for extraction_id_variant in _copy_array(run_state.get("revealed_extraction_ids", [])):
		revealed_ids[str(extraction_id_variant)] = true
	var sites: Array = []
	for site_variant in _copy_array(run_state.get("extraction_sites", [])):
		var site: Dictionary = site_variant
		if revealed_ids.has(str(site.get("id", ""))):
			sites.append(site.duplicate(true))
	return sites

func _initialize_runtime_boat_from_blueprint() -> void:
	var runtime_blocks: Array = []
	for block_variant in Array(boat_blueprint.get("blocks", [])):
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure"))
		var block_def := get_builder_block_definition(block_type)
		runtime_blocks.append({
			"id": int(block.get("id", 0)),
			"type": block_type,
			"cell": _normalize_blueprint_cell(block.get("cell", [0, 0, 0])),
			"rotation_steps": wrapi(int(block.get("rotation_steps", 0)), 0, 4),
			"local_position": _block_cell_to_local_position(block.get("cell", [0, 0, 0])),
			"max_hp": float(block_def.get("max_hp", 12.0)),
			"current_hp": float(block_def.get("max_hp", 12.0)),
			"destroyed": false,
			"detached": false,
			"chunk_id": 0,
		})

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["runtime_chunks"] = []
	boat_state["sinking_chunks"] = []
	boat_state["recent_damage_block_ids"] = []
	boat_state["recent_detached_chunk_ids"] = []
	_recompute_runtime_connectivity(true, "launch_disconnect")

func _block_cell_to_local_position(cell_value: Variant) -> Vector3:
	var cell := _normalize_blueprint_cell(cell_value)
	return Vector3(float(cell[0]), float(cell[1]), float(cell[2])) * RUNTIME_BLOCK_SPACING

func _collect_active_runtime_blocks() -> Array:
	var active_blocks: Array = []
	for block_variant in Array(boat_state.get("runtime_blocks", [])):
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		active_blocks.append(block)
	return active_blocks

func _recompute_runtime_connectivity(initial_launch: bool = false, detached_reason: String = "detached") -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var active_blocks := _collect_active_runtime_blocks()
	var components := _compute_runtime_components(active_blocks)
	var previous_main_chunk_id := int(boat_state.get("main_chunk_id", 0))
	var main_component_index := -1

	for index in range(components.size()):
		var component: Dictionary = components[index]
		if bool(component.get("contains_core", false)):
			main_component_index = index
			break
	if main_component_index == -1:
		var largest_component_size := -1
		for index in range(components.size()):
			var component_size := Array(components[index].get("block_ids", [])).size()
			if component_size > largest_component_size:
				largest_component_size = component_size
				main_component_index = index

	var main_block_ids: Array = []
	var runtime_chunks: Array = []
	var detached_chunk_ids: Array = []
	for index in range(components.size()):
		var component: Dictionary = components[index]
		var chunk_id := _next_runtime_chunk_id
		_next_runtime_chunk_id += 1
		var is_main := index == main_component_index
		var block_ids := Array(component.get("block_ids", [])).duplicate(true)
		var chunk_record := {
			"chunk_id": chunk_id,
			"block_ids": block_ids,
			"contains_core": bool(component.get("contains_core", false)),
			"is_main": is_main,
			"detached": not is_main,
		}
		runtime_chunks.append(chunk_record)
		for block_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[block_index]
			if not block_ids.has(int(block.get("id", 0))):
				continue
			block["chunk_id"] = chunk_id
			runtime_blocks[block_index] = block
		if is_main:
			main_block_ids = block_ids
		else:
			detached_chunk_ids.append(chunk_id)
			runtime_blocks = _mark_runtime_blocks_detached(runtime_blocks, block_ids)
			var detached_blocks := _get_runtime_blocks_by_ids(runtime_blocks, block_ids)
			var sinking_chunk := _build_sinking_chunk_snapshot(chunk_id, detached_blocks, detached_reason, initial_launch)
			var sinking_chunks: Array = Array(boat_state.get("sinking_chunks", [])).duplicate(true)
			sinking_chunks.append(sinking_chunk)
			boat_state["sinking_chunks"] = sinking_chunks

	if main_component_index == -1 or main_block_ids.is_empty():
		boat_state["runtime_blocks"] = runtime_blocks
		boat_state["runtime_chunks"] = runtime_chunks
		boat_state["main_chunk_id"] = 0
		boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		boat_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
		boat_state["recent_detached_chunk_ids"] = detached_chunk_ids
		run_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
		run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		_resolve_run_failure("The main hull broke apart in open water.")
		return

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["runtime_chunks"] = runtime_chunks
	boat_state["main_chunk_id"] = int(runtime_chunks[main_component_index].get("chunk_id", previous_main_chunk_id))
	boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
	boat_state["recent_detached_chunk_ids"] = detached_chunk_ids
	boat_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
	run_state["detached_chunk_count"] = int(run_state.get("detached_chunk_count", 0)) + detached_chunk_ids.size()
	run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
	_apply_runtime_stats_from_main_blocks(runtime_blocks, main_block_ids)
	if detached_chunk_ids.size() > 0:
		_set_status(_build_detachment_status(runtime_blocks, detached_chunk_ids))

func _compute_runtime_components(active_blocks: Array) -> Array:
	var blocks_by_key := {}
	for block_variant in active_blocks:
		var block: Dictionary = block_variant
		blocks_by_key[_cell_to_key(block.get("cell", [0, 0, 0]))] = block

	var components: Array = []
	var visited := {}
	for block_variant in active_blocks:
		var block: Dictionary = block_variant
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		var key := _cell_to_key(cell)
		if visited.has(key):
			continue

		var queue: Array = [cell]
		var component_block_ids: Array = []
		var contains_core := false
		visited[key] = true
		while not queue.is_empty():
			var current_cell: Array = queue.pop_front()
			var current_key := _cell_to_key(current_cell)
			var current_block: Dictionary = blocks_by_key.get(current_key, {})
			if current_block.is_empty():
				continue
			component_block_ids.append(int(current_block.get("id", 0)))
			if str(current_block.get("type", "")) == "core":
				contains_core = true
			for neighbor in _get_adjacent_cells(current_cell):
				var neighbor_key := _cell_to_key(neighbor)
				if not blocks_by_key.has(neighbor_key) or visited.has(neighbor_key):
					continue
				visited[neighbor_key] = true
				queue.append(neighbor)
		components.append({
			"block_ids": component_block_ids,
			"contains_core": contains_core,
		})
	return components

func _mark_runtime_blocks_detached(runtime_blocks: Array, block_ids: Array) -> Array:
	for index in range(runtime_blocks.size()):
		var block: Dictionary = runtime_blocks[index]
		if not block_ids.has(int(block.get("id", 0))):
			continue
		block["detached"] = true
		runtime_blocks[index] = block
	return runtime_blocks

func _get_runtime_blocks_by_ids(runtime_blocks: Array, block_ids: Array) -> Array:
	var matched_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if block_ids.has(int(block.get("id", 0))):
			matched_blocks.append(block.duplicate(true))
	return matched_blocks

func _build_sinking_chunk_snapshot(chunk_id: int, detached_blocks: Array, reason: String, launch_chunk: bool) -> Dictionary:
	var center := Vector3.ZERO
	if not detached_blocks.is_empty():
		for block_variant in detached_blocks:
			var block: Dictionary = block_variant
			var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
			center += local_position
		center /= float(detached_blocks.size())

	var facing_vector := Vector3(
		sin(float(boat_state.get("rotation_y", 0.0))),
		0.0,
		cos(float(boat_state.get("rotation_y", 0.0)))
	)
	var drift_sign := -1.0 if chunk_id % 2 == 0 else 1.0
	var drift_velocity := Vector3(drift_sign * RUNTIME_SINK_DRIFT_SPEED, -RUNTIME_SINK_SPEED, RUNTIME_SINK_DRIFT_SPEED * 0.18).rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0)))
	var chunk_blocks: Array = []
	for block_variant in detached_blocks:
		var block: Dictionary = block_variant
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		chunk_blocks.append({
			"id": int(block.get("id", 0)),
			"type": str(block.get("type", "structure")),
			"rotation_steps": int(block.get("rotation_steps", 0)),
			"local_offset": local_position - center,
			"destroyed": bool(block.get("destroyed", false)),
		})

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return {
		"chunk_id": chunk_id,
		"reason": reason,
		"launch_chunk": launch_chunk,
		"world_position": boat_position + center.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
		"rotation_y": float(boat_state.get("rotation_y", 0.0)),
		"sink_elapsed": 0.0,
		"drift_velocity": drift_velocity + facing_vector * 0.12,
		"blocks": chunk_blocks,
	}

func _apply_runtime_stats_from_main_blocks(runtime_blocks: Array, main_block_ids: Array) -> void:
	var stat_source_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if block.get("destroyed", false) or block.get("detached", false):
			continue
		if main_block_ids.has(int(block.get("id", 0))):
			stat_source_blocks.append(block)

	var stats := _compute_runtime_stats_for_blocks(stat_source_blocks)
	var new_cargo_capacity := int(stats.get("cargo_capacity", 1))
	var overflow := maxi(0, int(run_state.get("cargo_count", 0)) - new_cargo_capacity)
	if overflow > 0:
		run_state["cargo_count"] = new_cargo_capacity
		run_state["cargo_lost_to_sea"] = int(run_state.get("cargo_lost_to_sea", 0)) + overflow
		_spill_inventory_quantity("cargo_manifest", overflow)

	var new_max_hull := float(stats.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	var hull_dimensions := _get_runtime_hull_dimensions_from_stats(stats)
	boat_state["max_hull_integrity"] = new_max_hull
	boat_state["hull_integrity"] = minf(float(boat_state.get("hull_integrity", new_max_hull)), new_max_hull)
	boat_state["base_top_speed"] = float(stats.get("top_speed", BOAT_TOP_SPEED))
	boat_state["top_speed_limit"] = float(stats.get("top_speed", BOAT_TOP_SPEED))
	boat_state["acceleration_rating"] = float(stats.get("acceleration", 50.0))
	boat_state["turn_authority"] = float(stats.get("turn_authority", 50.0))
	boat_state["storm_stability"] = float(stats.get("storm_stability", 50.0))
	boat_state["draft_ratio"] = float(stats.get("draft_ratio", 0.72))
	boat_state["reserve_buoyancy"] = float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0)))
	boat_state["span_width"] = int(stats.get("span_width", boat_state.get("span_width", 2)))
	boat_state["span_length"] = int(stats.get("span_length", boat_state.get("span_length", 4)))
	boat_state["hull_length"] = float(hull_dimensions.get("hull_length", boat_state.get("hull_length", 4.4)))
	boat_state["hull_beam"] = float(hull_dimensions.get("hull_beam", boat_state.get("hull_beam", 2.7)))
	boat_state["roll_resistance"] = float(stats.get("roll_resistance", 50.0))
	boat_state["pitch_resistance"] = float(stats.get("pitch_resistance", 50.0))
	boat_state["heel_bias"] = float(stats.get("heel_bias", 0.0))
	boat_state["trim_bias"] = float(stats.get("trim_bias", 0.0))
	boat_state["freeboard_rating"] = float(stats.get("freeboard_rating", 50.0))
	boat_state["top_heavy_penalty"] = float(stats.get("top_heavy_penalty", 0.0))
	boat_state["hydrostatic_class"] = str(stats.get("hydrostatic_class", "stable"))
	boat_state["crew_safety"] = float(stats.get("crew_safety", 50.0))
	boat_state["repair_coverage"] = float(stats.get("repair_coverage", 50.0))
	boat_state["pathing_score"] = float(stats.get("pathing_score", 50.0))
	boat_state["damage_redundancy"] = float(stats.get("damage_redundancy", 50.0))
	boat_state["recovery_access_rating"] = float(stats.get("recovery_access_rating", 50.0))
	boat_state["propulsion_family"] = str(stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES))
	boat_state["propulsion_label"] = str(stats.get("propulsion_label", get_propulsion_family_label(str(stats.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES)))))
	boat_state["automation_floor"] = float(stats.get("automation_floor", 0.65))
	boat_state["manual_ceiling"] = float(stats.get("manual_ceiling", 1.0))
	boat_state["burst_ceiling"] = float(stats.get("burst_ceiling", PROPULSION_BURST_SPEED_MULTIPLIER))
	boat_state["workload"] = float(stats.get("workload", 50.0))
	boat_state["recommended_crew"] = int(stats.get("recommended_crew", 2))
	boat_state["propulsion_health_rating"] = float(stats.get("propulsion_health_rating", 100.0))
	boat_state["propulsion_health"] = minf(float(boat_state.get("propulsion_health", float(stats.get("propulsion_health_rating", 100.0)))), float(stats.get("propulsion_health_rating", 100.0)))
	boat_state["propulsion_exposure_rating"] = float(stats.get("propulsion_exposure_rating", 100.0))
	boat_state["cargo_capacity"] = new_cargo_capacity
	boat_state["brace_multiplier"] = float(stats.get("brace_multiplier", 1.0))
	boat_state["active_block_count"] = int(stats.get("main_chunk_blocks", 0))
	run_state["cargo_capacity"] = new_cargo_capacity
	run_state["repair_supplies_max"] = int(stats.get("repair_capacity", REPAIR_SUPPLIES_START))
	run_state["repair_supplies"] = mini(int(run_state.get("repair_supplies", 0)), int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_START)))
	run_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
	run_state["recovery_points"] = Array(stats.get("recovery_points", RUN_RECOVERY_POINTS)).duplicate(true)

	if overflow > 0:
		_set_status("Chunk loss dumped %d cargo item(s) into the sea." % overflow)

	var previous_station_hash := station_state.hash()
	_apply_station_state_from_stats(stats)
	if station_state.hash() != previous_station_hash:
		_broadcast_station_state()

	if int(stats.get("propulsion_count", 0)) < int(boat_state.get("propulsion_block_count", int(stats.get("propulsion_count", 0)))):
		_apply_propulsion_damage(PROPULSION_DAMAGE_DETACHMENT, 0.28, PROPULSION_FAULT_STATE_CRIPPLED)
	boat_state["propulsion_block_count"] = int(stats.get("propulsion_count", 0))

	if str(stats.get("hydrostatic_class", "stable")) == "sinking" or float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0))) < -0.75:
		_resolve_run_failure("The remaining hull lost too much buoyancy and sank.")

func _compute_runtime_stats_for_blocks(blocks: Array) -> Dictionary:
	return _compute_boat_stats_for_blocks(blocks)

func _count_destroyed_runtime_blocks(runtime_blocks: Array) -> int:
	var count := 0
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)):
			count += 1
	return count

func _build_detachment_status(runtime_blocks: Array, detached_chunk_ids: Array) -> String:
	var type_counts := {}
	for chunk_id in detached_chunk_ids:
		for block_variant in runtime_blocks:
			var block: Dictionary = block_variant
			if int(block.get("chunk_id", 0)) != chunk_id or not bool(block.get("detached", false)):
				continue
			var block_type := str(block.get("type", "structure"))
			type_counts[block_type] = int(type_counts.get(block_type, 0)) + 1

	var fragments := PackedStringArray()
	for block_type in type_counts.keys():
		var label := str(get_builder_block_definition(str(block_type)).get("label", str(block_type).capitalize()))
		fragments.append("%s x%d" % [label, int(type_counts[block_type])])
	return "Chunk detached: %s." % ", ".join(fragments)

func _update_sinking_chunks(delta: float) -> void:
	var sinking_chunks: Array = Array(boat_state.get("sinking_chunks", [])).duplicate(true)
	var updated_chunks: Array = []
	for chunk_variant in sinking_chunks:
		var chunk: Dictionary = chunk_variant
		var sink_elapsed := float(chunk.get("sink_elapsed", 0.0)) + delta
		if sink_elapsed >= RUNTIME_SINK_LIFETIME:
			continue
		chunk["sink_elapsed"] = sink_elapsed
		var world_position: Vector3 = chunk.get("world_position", Vector3.ZERO)
		var drift_velocity: Vector3 = chunk.get("drift_velocity", Vector3.ZERO)
		chunk["world_position"] = world_position + drift_velocity * delta
		updated_chunks.append(chunk)
	boat_state["sinking_chunks"] = updated_chunks

func _apply_localized_block_damage(total_damage: float, impact_point_local: Vector3, event_label: String) -> bool:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var candidate_entries: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
		var distance := local_position.distance_to(impact_point_local)
		if distance > RUNTIME_DAMAGE_CLUSTER_RADIUS:
			continue
		candidate_entries.append({
			"id": int(block.get("id", 0)),
			"distance": distance,
		})

	if candidate_entries.is_empty():
		var nearest_id := 0
		var nearest_distance := INF
		for block_variant in runtime_blocks:
			var block: Dictionary = block_variant
			if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
				continue
			var local_position: Vector3 = block.get("local_position", Vector3.ZERO)
			var distance := local_position.distance_to(impact_point_local)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_id = int(block.get("id", 0))
		if nearest_id > 0:
			candidate_entries.append({
				"id": nearest_id,
				"distance": nearest_distance,
			})

	candidate_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
	)

	var hit_block_ids: Array = []
	var destroyed_now := false
	var max_hits := mini(candidate_entries.size(), RUNTIME_DAMAGE_CLUSTER_WEIGHTS.size())
	for hit_index in range(max_hits):
		var entry: Dictionary = candidate_entries[hit_index]
		var block_id := int(entry.get("id", 0))
		var weight := float(RUNTIME_DAMAGE_CLUSTER_WEIGHTS[hit_index])
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			block["current_hp"] = maxf(0.0, float(block.get("current_hp", 0.0)) - total_damage * weight)
			if float(block.get("current_hp", 0.0)) <= 0.0:
				block["destroyed"] = true
				destroyed_now = true
			runtime_blocks[runtime_index] = block
			hit_block_ids.append(block_id)
			break

	boat_state["runtime_blocks"] = runtime_blocks
	boat_state["recent_damage_block_ids"] = hit_block_ids
	if destroyed_now:
		_recompute_runtime_connectivity(false, event_label)
	else:
		boat_state["recent_detached_chunk_ids"] = []
		boat_state["destroyed_block_count"] = _count_destroyed_runtime_blocks(runtime_blocks)
		run_state["destroyed_block_count"] = int(boat_state.get("destroyed_block_count", 0))
	return str(run_state.get("phase", "running")) == "running"

func _heal_runtime_blocks(total_heal: float) -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var damaged_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		if float(block.get("current_hp", 0.0)) >= float(block.get("max_hp", 0.0)):
			continue
		damaged_blocks.append(block.duplicate(true))

	damaged_blocks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("current_hp", 0.0)) < float(b.get("current_hp", 0.0))
	)

	var remaining_heal := total_heal
	for damaged_block_variant in damaged_blocks:
		if remaining_heal <= 0.0:
			break
		var damaged_block: Dictionary = damaged_block_variant
		var block_id := int(damaged_block.get("id", 0))
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			var missing_hp := float(block.get("max_hp", 0.0)) - float(block.get("current_hp", 0.0))
			var applied_heal := minf(missing_hp, remaining_heal)
			block["current_hp"] = float(block.get("current_hp", 0.0)) + applied_heal
			runtime_blocks[runtime_index] = block
			remaining_heal -= applied_heal
			break

	boat_state["runtime_blocks"] = runtime_blocks

func _heal_runtime_blocks_around(center_local: Vector3, total_heal: float) -> void:
	var runtime_blocks: Array = Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var damaged_blocks: Array = []
	for block_variant in runtime_blocks:
		var block: Dictionary = block_variant
		if bool(block.get("destroyed", false)) or bool(block.get("detached", false)):
			continue
		var max_hp := float(block.get("max_hp", 0.0))
		var current_hp := float(block.get("current_hp", max_hp))
		if current_hp >= max_hp - 0.01:
			continue
		var distance := center_local.distance_to(block.get("local_position", Vector3.ZERO))
		if distance > RUN_REPAIR_HEAL_RADIUS:
			continue
		var block_copy := block.duplicate(true)
		block_copy["repair_distance"] = distance
		damaged_blocks.append(block_copy)

	if damaged_blocks.is_empty():
		_heal_runtime_blocks(total_heal)
		return

	damaged_blocks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("repair_distance", 0.0)) < float(b.get("repair_distance", 0.0))
	)

	var remaining_heal := total_heal
	for damaged_block_variant in damaged_blocks:
		if remaining_heal <= 0.0:
			break
		var damaged_block: Dictionary = damaged_block_variant
		var block_id := int(damaged_block.get("id", 0))
		for runtime_index in range(runtime_blocks.size()):
			var block: Dictionary = runtime_blocks[runtime_index]
			if int(block.get("id", 0)) != block_id:
				continue
			var missing_hp := float(block.get("max_hp", 0.0)) - float(block.get("current_hp", 0.0))
			var applied_heal := minf(missing_hp, remaining_heal)
			block["current_hp"] = float(block.get("current_hp", 0.0)) + applied_heal
			runtime_blocks[runtime_index] = block
			remaining_heal -= applied_heal
			break

	boat_state["runtime_blocks"] = runtime_blocks

func _launch_run_session(peer_id: int) -> void:
	if not _has_runtime_authority():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return

	_next_run_instance_id += 1
	_reset_run_runtime()
	_apply_launch_repair_penalty()
	_set_session_phase(SESSION_PHASE_RUN)
	_reset_connected_run_avatars()
	_broadcast_boat_state()
	_broadcast_hazard_state()
	_broadcast_station_state()
	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_broadcast_runtime_boat_state()
	_broadcast_progression_state()
	_set_status("Run launched by %s using blueprint v%d." % [
		_get_peer_name(peer_id),
		int(boat_blueprint.get("version", 1)),
	])

func _return_to_hangar_session(peer_id: int) -> void:
	if not _has_runtime_authority():
		return
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) == "running":
		return

	_reset_run_runtime()
	_clear_run_state_for_hangar()
	_reset_connected_hangar_avatars()
	_set_session_phase(SESSION_PHASE_HANGAR)
	_broadcast_boat_state()
	_broadcast_hazard_state()
	_broadcast_station_state()
	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()
	_set_status("%s returned the crew to the hangar." % _get_peer_name(peer_id))

func _clear_run_state_for_hangar() -> void:
	hazard_state = []
	loot_state = []
	run_avatar_state = {}
	reaction_state = {}
	run_state = {
		"phase": "hangar",
		"run_instance_id": _next_run_instance_id,
		"layout_label": "Hangar",
		"world_label": "Hangar",
		"active_chunk_coords": [],
		"poi_sites": [],
		"extraction_sites": [],
		"revealed_extraction_ids": [],
		"cargo_count": 0,
		"cargo_manifest": [],
		"secured_manifest": [],
		"run_item_bank": {},
		"run_schematic_bank": [],
		"bonus_manifest": [],
		"cargo_secured": 0,
		"loot_collected": 0,
		"loot_total": 0,
		"loot_remaining": 0,
		"repair_actions": 0,
		"repair_supplies": 0,
		"repair_supplies_max": 0,
		"crew_downed_count": 0,
		"crew_critical_count": 0,
		"crew_exhausted_count": 0,
		"elapsed_time": 0.0,
		"reward_gold": 0,
		"reward_salvage": 0,
		"reward_items": {},
		"reward_schematics": [],
		"loot_lost_items": {},
		"repair_debt_delta": {},
		"result_title": "",
		"result_message": "",
		"failure_reason": "",
	}

func _donate_workshop_resource(peer_id: int, resource_id: String, quantity: int) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	var donation_result := DockState.add_host_workshop_resource(resource_id, quantity)
	if donation_result.is_empty():
		return
	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())
	_broadcast_progression_state()
	_set_status("%s donated %d %s to the host workshop." % [
		_get_peer_name(peer_id),
		quantity,
		str(MATERIAL_LABELS.get(resource_id, resource_id.replace("_", " "))),
	])

func _unlock_builder_block(peer_id: int, block_type: String) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not BUILDER_BLOCK_LIBRARY.has(block_type):
		return
	if _is_block_unlocked(block_type):
		return

	var block_def := get_builder_block_definition(block_type)
	if not bool(block_def.get("unlockable", false)):
		return

	var recipe := {
		"gold": int(block_def.get("recipe_gold", 0)),
		"materials": Dictionary(block_def.get("recipe_materials", {})).duplicate(true),
		"required_schematic": str(block_def.get("required_schematic", "")),
	}
	var unlock_result: Dictionary = DockState.unlock_workshop_block(
		block_type,
		recipe,
		str(block_def.get("label", block_type.capitalize())),
		str(block_def.get("description", ""))
	)
	if unlock_result.is_empty():
		var required_schematic := str(block_def.get("required_schematic", ""))
		if not required_schematic.is_empty() and not Array(progression_state.get("host_known_schematics", [])).has(required_schematic):
			_set_status("%s still needs the %s schematic before the host workshop can craft it." % [
				str(block_def.get("label", block_type.capitalize())),
				str(block_def.get("label", block_type.capitalize())),
			])
		else:
			_set_status("The host workshop is missing the materials or gold to craft %s." % str(block_def.get("label", block_type.capitalize())))
		return

	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())
	_broadcast_progression_state()
	_set_status("%s crafted %s for the host workshop." % [
		_get_peer_name(peer_id),
		str(block_def.get("label", block_type.capitalize())),
	])

func _place_blueprint_block(peer_id: int, cell: Array, block_type: String, rotation_steps: int) -> void:
	if not _has_runtime_authority():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not _cell_within_builder_bounds(cell):
		return
	if not _peer_within_builder_range(peer_id, cell):
		return
	if not BUILDER_BLOCK_LIBRARY.has(block_type):
		return
	if not _is_block_unlocked(block_type):
		return

	var persisted := _extract_persisted_blueprint(boat_blueprint)
	var blocks: Array = Array(persisted.get("blocks", [])).duplicate(true)
	if _find_block_index_by_cell(blocks, cell) != -1:
		return

	var next_block_id := int(persisted.get("next_block_id", 1))
	blocks.append({
		"id": next_block_id,
		"type": block_type,
		"cell": _normalize_blueprint_cell(cell),
		"rotation_steps": wrapi(rotation_steps, 0, 4),
	})
	persisted["blocks"] = blocks
	persisted["next_block_id"] = next_block_id + 1
	persisted["version"] = int(persisted.get("version", 1)) + 1
	boat_blueprint = _decorate_blueprint(persisted)
	_save_server_blueprint()
	_broadcast_blueprint_state()
	_set_status("%s placed %s at %s." % [
		_get_peer_name(peer_id),
		get_builder_block_definition(block_type).get("label", block_type.capitalize()),
		str(_cell_to_vector3i(cell)),
	])

func _remove_blueprint_block(peer_id: int, cell: Array) -> void:
	if not _has_runtime_authority():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return
	if not _peer_within_builder_range(peer_id, cell):
		return

	var persisted := _extract_persisted_blueprint(boat_blueprint)
	var blocks: Array = Array(persisted.get("blocks", [])).duplicate(true)
	var block_index := _find_block_index_by_cell(blocks, cell)
	if block_index == -1:
		return
	if blocks.size() <= 1:
		return

	var removed_block: Dictionary = blocks[block_index]
	blocks.remove_at(block_index)
	persisted["blocks"] = blocks
	persisted["version"] = int(persisted.get("version", 1)) + 1
	boat_blueprint = _decorate_blueprint(persisted)
	_save_server_blueprint()
	_broadcast_blueprint_state()
	_set_status("%s removed %s from %s." % [
		_get_peer_name(peer_id),
		get_builder_block_definition(str(removed_block.get("type", "structure"))).get("label", "Block"),
		str(_cell_to_vector3i(cell)),
	])

func _reset_blueprint_for_peer(peer_id: int) -> void:
	if not _has_runtime_authority():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return

	var reset_snapshot := DockState.reset_boat_blueprint()
	boat_blueprint = _decorate_blueprint(reset_snapshot)
	_broadcast_blueprint_state()
	_set_status("%s reset the boat to the core block." % _get_peer_name(peer_id))

func _save_server_blueprint() -> void:
	if _has_runtime_authority():
		DockState.save_boat_blueprint(_extract_persisted_blueprint(boat_blueprint))

func _extract_persisted_blueprint(snapshot: Dictionary) -> Dictionary:
	return {
		"geometry_schema_version": maxi(
			BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION,
			int(snapshot.get("geometry_schema_version", BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION))
		),
		"version": int(snapshot.get("version", 1)),
		"next_block_id": int(snapshot.get("next_block_id", 1)),
		"blocks": Array(snapshot.get("blocks", [])).duplicate(true),
	}

func _decorate_progression_snapshot(snapshot: Dictionary) -> Dictionary:
	var host_workshop: Dictionary = Dictionary(snapshot.get("host_workshop_state", {})).duplicate(true)
	if host_workshop.is_empty():
		host_workshop = {
			"available_gold": int(snapshot.get("workshop_gold", snapshot.get("total_gold", 0))),
			"stock_items": Dictionary(snapshot.get("workshop_stock", {})).duplicate(true),
			"known_schematics": Array(snapshot.get("host_known_schematics", [])).duplicate(true),
			"unlocked_blocks": Array(snapshot.get("unlocked_blocks", [])).duplicate(true),
			"last_unlock": Dictionary(snapshot.get("last_unlock", {})).duplicate(true),
			"repair_debt": Dictionary(snapshot.get("repair_debt", {})).duplicate(true),
		}
	var normalized := {
		"schema_version": int(snapshot.get("schema_version", 2)),
		"total_gold": max(0, int(host_workshop.get("available_gold", snapshot.get("total_gold", 0)))),
		"total_salvage": 0,
		"total_runs": max(0, int(snapshot.get("total_runs", 0))),
		"successful_runs": max(0, int(snapshot.get("successful_runs", 0))),
		"last_run": {},
		"last_unlock": {},
		"host_workshop_state": {},
		"unlocked_blocks": [],
		"unlock_tier_counts": {},
		"highest_unlock_tier": 0,
		"workshop_stock": _normalize_material_dict_ui(host_workshop.get("stock_items", {})),
		"workshop_gold": max(0, int(host_workshop.get("available_gold", 0))),
		"host_known_schematics": _normalize_schematic_list_ui(host_workshop.get("known_schematics", [])),
		"repair_debt": Dictionary(host_workshop.get("repair_debt", {})).duplicate(true),
		"archetype_presets": BUILDER_ARCHETYPE_PRESETS.duplicate(true),
	}
	var last_run_variant: Variant = snapshot.get("last_run", {})
	if typeof(last_run_variant) == TYPE_DICTIONARY:
		normalized["last_run"] = Dictionary(last_run_variant).duplicate(true)
	var last_unlock_variant: Variant = host_workshop.get("last_unlock", snapshot.get("last_unlock", {}))
	if typeof(last_unlock_variant) == TYPE_DICTIONARY:
		normalized["last_unlock"] = Dictionary(last_unlock_variant).duplicate(true)
	normalized["host_workshop_state"] = {
		"available_gold": int(normalized.get("workshop_gold", 0)),
		"stock_items": Dictionary(normalized.get("workshop_stock", {})).duplicate(true),
		"known_schematics": Array(normalized.get("host_known_schematics", [])).duplicate(true),
		"unlocked_blocks": Array(host_workshop.get("unlocked_blocks", [])).duplicate(true),
		"last_unlock": Dictionary(normalized.get("last_unlock", {})).duplicate(true),
		"repair_debt": Dictionary(normalized.get("repair_debt", {})).duplicate(true),
	}
	normalized["total_salvage"] = 0
	for quantity_variant in Dictionary(normalized.get("workshop_stock", {})).values():
		normalized["total_salvage"] = int(normalized.get("total_salvage", 0)) + int(quantity_variant)

	var unlocked_lookup := {}
	for base_block_variant in _get_default_unlocked_block_ids():
		var base_block_id := str(base_block_variant)
		unlocked_lookup[base_block_id] = true
	for block_value in Array(host_workshop.get("unlocked_blocks", snapshot.get("unlocked_blocks", []))):
		var block_id := str(block_value).strip_edges().to_lower()
		if block_id.is_empty() or not BUILDER_BLOCK_LIBRARY.has(block_id):
			continue
		unlocked_lookup[block_id] = true

	var ordered_unlocked_blocks: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var ordered_block_id := str(block_id_variant)
		if unlocked_lookup.has(ordered_block_id):
			ordered_unlocked_blocks.append(ordered_block_id)
			var block_def := get_builder_block_definition(ordered_block_id)
			var unlock_tier := int(block_def.get("unlock_tier", 0))
			normalized["unlock_tier_counts"][unlock_tier] = int(normalized["unlock_tier_counts"].get(unlock_tier, 0)) + 1
			normalized["highest_unlock_tier"] = maxi(int(normalized.get("highest_unlock_tier", 0)), unlock_tier)
	normalized["unlocked_blocks"] = ordered_unlocked_blocks
	return normalized

func _get_default_unlocked_block_ids() -> Array:
	var block_ids: Array = []
	for block_id_variant in BUILDER_BLOCK_ORDER:
		var block_id := str(block_id_variant)
		var block_def := Dictionary(BUILDER_BLOCK_LIBRARY.get(block_id, {}))
		if bool(block_def.get("unlockable", false)):
			continue
		block_ids.append(block_id)
	return block_ids

func _get_unlocked_block_lookup() -> Dictionary:
	var unlocked_lookup := {}
	for block_id_variant in Array(progression_state.get("unlocked_blocks", [])):
		var block_id := str(block_id_variant)
		if block_id.is_empty():
			continue
		unlocked_lookup[block_id] = true
	return unlocked_lookup

func _is_block_unlocked(block_type: String) -> bool:
	return _get_unlocked_block_lookup().has(block_type.strip_edges().to_lower())

func _decorate_blueprint(snapshot: Dictionary) -> Dictionary:
	var normalized := _normalize_blueprint(snapshot)
	var blocks: Array = Array(normalized.get("blocks", []))
	var blocks_by_key := {}
	var blocks_by_id := {}
	var component_entries: Array = []
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var key := _cell_to_key(block.get("cell", [0, 0, 0]))
		blocks_by_key[key] = block
		blocks_by_id[int(block.get("id", 0))] = block

	var visited := {}
	for block_variant in blocks:
		var block: Dictionary = block_variant
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		var key := _cell_to_key(cell)
		if visited.has(key):
			continue

		var queue: Array = [cell]
		var component_block_ids: Array = []
		var contains_core := false
		visited[key] = true
		while not queue.is_empty():
			var current_cell: Array = queue.pop_front()
			var current_key := _cell_to_key(current_cell)
			var current_block: Dictionary = blocks_by_key.get(current_key, {})
			if current_block.is_empty():
				continue
			component_block_ids.append(int(current_block.get("id", 0)))
			if str(current_block.get("type", "")) == "core":
				contains_core = true
			for neighbor in _get_adjacent_cells(current_cell):
				var neighbor_key := _cell_to_key(neighbor)
				if not blocks_by_key.has(neighbor_key) or visited.has(neighbor_key):
					continue
				visited[neighbor_key] = true
				queue.append(neighbor)
		component_entries.append({
			"block_ids": component_block_ids,
			"contains_core": contains_core,
		})

	var main_component: Dictionary = {}
	for component in component_entries:
		if bool(component.get("contains_core", false)):
			main_component = component
			break
	if main_component.is_empty():
		for component in component_entries:
			if Array(component.get("block_ids", [])).size() > Array(main_component.get("block_ids", [])).size():
				main_component = component

	var main_block_ids: Array = Array(main_component.get("block_ids", [])).duplicate(true)
	var loose_block_ids: Array = []
	for block_variant in blocks:
		var block: Dictionary = block_variant
		if main_block_ids.has(int(block.get("id", 0))):
			continue
		loose_block_ids.append(int(block.get("id", 0)))

	var main_blocks: Array = []
	for block_id in main_block_ids:
		var block: Dictionary = blocks_by_id.get(int(block_id), {})
		main_blocks.append(block)

	var stats := _compute_boat_stats_for_blocks(main_blocks)
	stats["block_count"] = blocks.size()
	stats["main_chunk_blocks"] = main_block_ids.size()
	stats["loose_blocks"] = loose_block_ids.size()
	stats["component_count"] = component_entries.size()
	var warnings := _build_blueprint_warnings_from_stats(stats, loose_block_ids.size())
	var seaworthy := int(stats.get("main_chunk_blocks", 0)) > 0 \
		and str(stats.get("hydrostatic_class", "stable")) != "sinking" \
		and float(stats.get("reserve_buoyancy", stats.get("buoyancy_margin", 0.0))) >= -1.2 \
		and bool(stats.get("has_salvage_station", false)) \
		and bool(stats.get("has_recovery_access", false)) \
		and bool(stats.get("required_roles_ok", false))

	normalized["stats"] = stats
	normalized["warnings"] = warnings
	normalized["seaworthy"] = seaworthy
	normalized["main_chunk_block_ids"] = main_block_ids
	normalized["loose_block_ids"] = loose_block_ids
	return normalized

func _normalize_blueprint(snapshot: Dictionary) -> Dictionary:
	var geometry_schema_version := maxi(
		BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION,
		int(snapshot.get("geometry_schema_version", BOAT_BLUEPRINT_GEOMETRY_SCHEMA_VERSION))
	)
	var normalized := {
		"geometry_schema_version": geometry_schema_version,
		"version": maxi(1, int(snapshot.get("version", 1))),
		"next_block_id": maxi(1, int(snapshot.get("next_block_id", 1))),
		"blocks": [],
	}
	var normalized_blocks: Array = []
	var seen_cells := {}
	var next_block_id := int(normalized.get("next_block_id", 1))

	for block_variant in Array(snapshot.get("blocks", [])):
		if typeof(block_variant) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_variant
		var block_type := str(block.get("type", "structure")).strip_edges().to_lower()
		if not BUILDER_BLOCK_LIBRARY.has(block_type):
			continue
		var block_id := int(block.get("id", 0))
		if block_id <= 0:
			block_id = next_block_id
			next_block_id += 1
		var cell := _normalize_blueprint_cell(block.get("cell", [0, 0, 0]))
		if not _cell_within_builder_bounds(cell):
			continue
		var cell_key := _cell_to_key(cell)
		if seen_cells.has(cell_key):
			continue
		seen_cells[cell_key] = true
		normalized_blocks.append({
			"id": block_id,
			"type": block_type,
			"cell": cell,
			"rotation_steps": wrapi(int(block.get("rotation_steps", 0)), 0, 4),
		})
		next_block_id = maxi(next_block_id, block_id + 1)

	if normalized_blocks.is_empty():
		normalized_blocks = Array(DockState.get_boat_blueprint().get("blocks", [])).duplicate(true)
		next_block_id = maxi(next_block_id, int(DockState.get_boat_blueprint().get("next_block_id", 1)))

	normalized["blocks"] = normalized_blocks
	normalized["next_block_id"] = next_block_id
	return normalized

func _build_blueprint_warning_text() -> String:
	var warnings := get_blueprint_warnings()
	if warnings.is_empty():
		return ""
	var lines := PackedStringArray()
	for warning in warnings:
		lines.append(str(warning))
	return "\n".join(lines)

func _normalize_blueprint_cell(cell_value: Variant) -> Array:
	if cell_value is Vector3i:
		var cell_vec := cell_value as Vector3i
		return [cell_vec.x, cell_vec.y, cell_vec.z]
	if typeof(cell_value) == TYPE_ARRAY and cell_value.size() >= 3:
		return [int(cell_value[0]), int(cell_value[1]), int(cell_value[2])]
	if typeof(cell_value) == TYPE_DICTIONARY:
		return [
			int(cell_value.get("x", 0)),
			int(cell_value.get("y", 0)),
			int(cell_value.get("z", 0)),
		]
	return [0, 0, 0]

func _cell_within_builder_bounds(cell: Array) -> bool:
	var cell_vec := _cell_to_vector3i(cell)
	return cell_vec.x >= BUILDER_BOUNDS_MIN.x and cell_vec.x <= BUILDER_BOUNDS_MAX.x and cell_vec.y >= BUILDER_BOUNDS_MIN.y and cell_vec.y <= BUILDER_BOUNDS_MAX.y and cell_vec.z >= BUILDER_BOUNDS_MIN.z and cell_vec.z <= BUILDER_BOUNDS_MAX.z

func _builder_cell_to_world_position(cell_value: Variant) -> Vector3:
	var cell_vec := _cell_to_vector3i(cell_value)
	return BUILDER_WORLD_ORIGIN + Vector3(cell_vec) * BUILDER_CELL_SIZE

func _peer_within_builder_range(peer_id: int, cell: Array) -> bool:
	if peer_id <= 0:
		return false
	var avatar_state: Dictionary = hangar_avatar_state.get(peer_id, {})
	if avatar_state.is_empty():
		return false
	var avatar_position: Vector3 = avatar_state.get("position", Vector3.ZERO)
	return avatar_position.distance_to(_builder_cell_to_world_position(cell)) <= (HANGAR_BUILD_RANGE + 0.35)

func _cell_to_key(cell_value: Variant) -> String:
	var cell := _normalize_blueprint_cell(cell_value)
	return "%d:%d:%d" % [int(cell[0]), int(cell[1]), int(cell[2])]

func _cell_to_vector3i(cell_value: Variant) -> Vector3i:
	var cell := _normalize_blueprint_cell(cell_value)
	return Vector3i(int(cell[0]), int(cell[1]), int(cell[2]))

func _get_adjacent_cells(cell_value: Variant) -> Array:
	var cell_vec := _cell_to_vector3i(cell_value)
	return [
		[cell_vec.x + 1, cell_vec.y, cell_vec.z],
		[cell_vec.x - 1, cell_vec.y, cell_vec.z],
		[cell_vec.x, cell_vec.y + 1, cell_vec.z],
		[cell_vec.x, cell_vec.y - 1, cell_vec.z],
		[cell_vec.x, cell_vec.y, cell_vec.z + 1],
		[cell_vec.x, cell_vec.y, cell_vec.z - 1],
	]

func _find_block_index_by_cell(blocks: Array, cell_value: Variant) -> int:
	var target_key := _cell_to_key(cell_value)
	for index in range(blocks.size()):
		var block: Dictionary = blocks[index]
		if _cell_to_key(block.get("cell", [0, 0, 0])) == target_key:
			return index
	return -1

func _set_session_phase(next_phase: String) -> void:
	if session_phase == next_phase:
		return
	session_phase = next_phase
	_broadcast_session_phase()

func _get_peer_name(peer_id: int) -> String:
	var peer_data: Dictionary = peer_snapshot.get(peer_id, {})
	return str(peer_data.get("name", "Peer %d" % peer_id))

func _make_hazard(position: Vector3, radius: float, label: String, extras: Dictionary = {}) -> Dictionary:
	var hazard_id: int = _next_hazard_id
	_next_hazard_id += 1
	var hazard := {
		"id": hazard_id,
		"position": position,
		"radius": radius,
		"label": label,
	}
	for key_variant in extras.keys():
		hazard[str(key_variant)] = extras[key_variant]
	return hazard

func _make_loot(position: Vector3, value: int, label: String, requires_brace: bool = true, extras: Dictionary = {}) -> Dictionary:
	var loot_id: int = _next_loot_id
	_next_loot_id += 1
	var loot := {
		"id": loot_id,
		"position": position,
		"value": value,
		"label": label,
		"requires_brace": requires_brace,
	}
	for key_variant in extras.keys():
		loot[str(key_variant)] = extras[key_variant]
	return loot

func _set_driver(peer_id: int, broadcast: bool = true) -> void:
	if driver_peer_id == peer_id:
		return

	driver_peer_id = peer_id
	boat_state["driver_peer_id"] = driver_peer_id
	if driver_peer_id == 0:
		boat_state["throttle"] = 0.0
		boat_state["steer"] = 0.0
		boat_state["speed_order"] = "Stop"
		boat_state["rudder_input"] = 0.0
	emit_signal("helm_changed", driver_peer_id)
	if broadcast:
		_broadcast_boat_state()

func _claim_station(peer_id: int, station_id: String) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if not station_state.has(station_id):
		return
	if not _is_station_claimable(station_id):
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if not _peer_within_run_station_range(peer_id, station_id):
		return

	var station: Dictionary = station_state.get(station_id, {})
	if not bool(station.get("active", true)):
		return
	var occupant_peer_id := int(station.get("occupant_peer_id", 0))
	if occupant_peer_id != 0 and occupant_peer_id != peer_id:
		return

	var current_station_id := get_peer_station_id(peer_id)
	if current_station_id == station_id:
		return

	if not current_station_id.is_empty():
		_release_station(peer_id, false)

	station["occupant_peer_id"] = peer_id
	station_state[station_id] = station
	if station_id == "helm":
		_set_driver(peer_id, false)

	_broadcast_station_state()
	_broadcast_boat_state()
	_set_status("%s claimed by %s." % [get_station_label(station_id), get_station_occupant_name(station_id)])

func _release_station(peer_id: int, broadcast: bool = true) -> void:
	var current_station_id := get_peer_station_id(peer_id)
	if current_station_id.is_empty():
		return

	var station: Dictionary = station_state.get(current_station_id, {})
	station["occupant_peer_id"] = 0
	station_state[current_station_id] = station
	if current_station_id == "helm" and driver_peer_id == peer_id:
		_set_driver(0, false)

	if broadcast:
		_broadcast_station_state()
		_broadcast_boat_state()

func _receive_boat_input(peer_id: int, throttle: float, steer: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		_peer_inputs[peer_id] = {
			"throttle": 0.0,
			"steer": 0.0,
		}
		return
	if _peer_has_reaction_lock(peer_id):
		_peer_inputs[peer_id] = {
			"throttle": 0.0,
			"steer": 0.0,
		}
		return
	if peer_id != driver_peer_id:
		return
	if get_peer_station_id(peer_id) != "helm":
		return
	if not _peer_within_run_station_range(peer_id, "helm", RUN_HELM_RELEASE_RADIUS - RUN_HELM_ZONE_RADIUS):
		_release_station(peer_id)
		return

	_peer_inputs[peer_id] = {
		"throttle": throttle,
		"steer": steer,
	}

func _begin_brace(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if not run_avatar_state.has(peer_id):
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	if float(boat_state.get("brace_cooldown", 0.0)) > 0.0:
		return
	if not _spend_peer_stamina(peer_id, AVATAR_BRACE_STAMINA_COST, true):
		return

	boat_state["brace_timer"] = BRACE_ACTIVE_SECONDS
	boat_state["brace_cooldown"] = BRACE_COOLDOWN_SECONDS
	if _refresh_crew_vitals_metrics():
		_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_boat_state()
	_set_status("%s braced for impact." % _get_peer_name(peer_id))

func _process_repair(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	if float(boat_state.get("repair_cooldown", 0.0)) > 0.0:
		return
	if int(run_state.get("repair_supplies", 0)) <= 0:
		_set_status("The crew is out of patch kits.")
		return

	var breach_stacks := int(boat_state.get("breach_stacks", 0))
	var hull_integrity: float = float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY))
	var max_hull_integrity: float = float(boat_state.get("max_hull_integrity", BOAT_MAX_INTEGRITY))
	if breach_stacks <= 0 and hull_integrity >= max_hull_integrity - 0.1:
		return
	var repair_profile := _get_peer_repair_profile(peer_id)
	var repair_range := float(repair_profile.get("range", RUN_REPAIR_RANGE))
	var repair_heal := float(repair_profile.get("heal", REPAIR_HULL_RECOVERY))
	var repair_target := _find_nearest_repairable_block(peer_id, repair_range)
	if repair_target.is_empty():
		_set_status("%s needs to move closer to the damaged hull to patch it." % _get_peer_name(peer_id))
		return
	if not _spend_peer_stamina(peer_id, AVATAR_REPAIR_STAMINA_COST, true):
		return

	boat_state["breach_stacks"] = maxi(0, breach_stacks - 1)
	boat_state["hull_integrity"] = minf(max_hull_integrity, hull_integrity + repair_heal)
	boat_state["repair_cooldown"] = REPAIR_COOLDOWN_SECONDS
	run_state["repair_actions"] = int(run_state.get("repair_actions", 0)) + 1
	run_state["repair_supplies"] = maxi(0, int(run_state.get("repair_supplies", 0)) - 1)
	_heal_runtime_blocks_around(repair_target.get("local_position", Vector3.ZERO), repair_heal)
	if _refresh_crew_vitals_metrics():
		_broadcast_run_state()
	_broadcast_run_avatar_state()
	_broadcast_runtime_boat_state()
	_broadcast_boat_state()
	_broadcast_run_state()
	_set_status("%s patched the hull. %d patch kit(s) left." % [
		_get_peer_name(peer_id),
		int(run_state.get("repair_supplies", 0)),
	])

func _get_poi_site_index(site_id: String) -> int:
	var sites := _copy_array(run_state.get("poi_sites", []))
	for site_index in range(sites.size()):
		var site: Dictionary = sites[site_index]
		if str(site.get("id", "")) == site_id:
			return site_index
	return -1

func _get_poi_site(site_id: String) -> Dictionary:
	var site_index := _get_poi_site_index(site_id)
	if site_index == -1:
		return {}
	return Dictionary(_copy_array(run_state.get("poi_sites", []))[site_index]).duplicate(true)

func _store_poi_site(site: Dictionary) -> void:
	var sites := _copy_array(run_state.get("poi_sites", []))
	var site_id := str(site.get("id", ""))
	for site_index in range(sites.size()):
		var existing_site: Dictionary = sites[site_index]
		if str(existing_site.get("id", "")) != site_id:
			continue
		sites[site_index] = site
		run_state["poi_sites"] = sites
		_sync_generated_world_runtime_metrics()
		return

func _get_extraction_site_index(site_id: String) -> int:
	var sites := _copy_array(run_state.get("extraction_sites", []))
	for site_index in range(sites.size()):
		var site: Dictionary = sites[site_index]
		if str(site.get("id", "")) == site_id:
			return site_index
	return -1

func _find_nearest_active_site(site_type: String, from_position: Vector3, require_available: bool = true) -> Dictionary:
	var best_site: Dictionary = {}
	var best_distance := INF
	for site_variant in _copy_array(run_state.get("poi_sites", [])):
		var site: Dictionary = site_variant
		if str(site.get("site_type", "")) != site_type:
			continue
		if require_available:
			if site_type == RunWorldGenerator.SITE_DISTRESS and not bool(site.get("available", false)):
				continue
			if site_type == RunWorldGenerator.SITE_RESUPPLY and not bool(site.get("available", false)):
				continue
		if site_type == RunWorldGenerator.SITE_SALVAGE and int(site.get("loot_remaining", 0)) <= 0:
			continue
		var distance := from_position.distance_to(site.get("position", Vector3.ZERO))
		if distance >= best_distance:
			continue
		best_distance = distance
		best_site = site.duplicate(true)
	return best_site

func _find_nearest_extraction_site(from_position: Vector3, revealed_only: bool = true) -> Dictionary:
	var revealed_lookup := {}
	for extraction_id_variant in _copy_array(run_state.get("revealed_extraction_ids", [])):
		revealed_lookup[str(extraction_id_variant)] = true
	var best_site: Dictionary = {}
	var best_distance := INF
	for site_variant in _copy_array(run_state.get("extraction_sites", [])):
		var site: Dictionary = site_variant
		if revealed_only and not revealed_lookup.has(str(site.get("id", ""))):
			continue
		var distance := from_position.distance_to(site.get("position", Vector3.ZERO))
		if distance >= best_distance:
			continue
		best_distance = distance
		best_site = site.duplicate(true)
	return best_site

func _process_grapple(peer_id: int) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return
	if _peer_has_reaction_lock(peer_id):
		return
	if _is_peer_overboard(peer_id) or _is_peer_downed(peer_id):
		return
	if get_peer_station_id(peer_id) != "grapple":
		return
	if _process_rescue_grapple():
		return
	if _process_resupply_cache_grapple():
		return
	if loot_state.is_empty():
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var salvage_site := _find_nearest_active_site(RunWorldGenerator.SITE_SALVAGE, boat_position, false)
	if salvage_site.is_empty():
		_set_status("Bring the crew to a salvage site before grappling cargo.")
		return
	var salvage_position: Vector3 = salvage_site.get("position", Vector3.ZERO)
	var salvage_radius: float = float(salvage_site.get("radius", 4.4))
	var salvage_max_speed: float = float(salvage_site.get("max_speed", SALVAGE_MAX_SPEED))
	if boat_position.distance_to(salvage_position) > salvage_radius:
		_set_status("Bring the boat into the salvage ring before grappling cargo.")
		return
	if absf(float(boat_state.get("speed", 0.0))) > salvage_max_speed:
		_set_status("Slow the boat down before attempting salvage.")
		return

	var grapple_position := _get_station_world_position("grapple")
	var closest_index := -1
	var closest_distance := GRAPPLE_RANGE
	for index in range(loot_state.size()):
		var loot_target: Dictionary = loot_state[index]
		if str(loot_target.get("site_id", "")) != str(salvage_site.get("id", "")):
			continue
		var loot_position: Vector3 = loot_target.get("position", Vector3.ZERO)
		var distance := grapple_position.distance_to(loot_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_index = index

	if closest_index == -1:
		_set_status("Swing the crane closer to the salvage before grappling.")
		return

	var loot_target: Dictionary = loot_state[closest_index]
	var cargo_value := int(loot_target.get("value", 1))
	var material_bundle := _normalize_material_dict_ui(loot_target.get("material_bundle", {}))
	var schematic_ids := _normalize_schematic_list_ui(loot_target.get("schematic_ids", []))
	var cargo_capacity := int(run_state.get("cargo_capacity", int(boat_state.get("cargo_capacity", 1))))
	if int(run_state.get("cargo_count", 0)) + cargo_value > cargo_capacity:
		_set_status("Cargo hold is full. Expand the shared boat before hauling more salvage.")
		return
	var requires_brace := bool(loot_target.get("requires_brace", true))
	var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
	run_state["cargo_count"] = int(run_state.get("cargo_count", 0)) + cargo_value
	_append_inventory_entry(
		"cargo_manifest",
		str(loot_target.get("label", "Recovered Cargo")),
		cargo_value,
		"cargo",
		_build_material_detail(material_bundle, 0, 0, schematic_ids)
	)
	_append_run_materials(material_bundle)
	_append_run_schematics(schematic_ids)
	run_state["loot_collected"] = int(run_state.get("loot_collected", 0)) + 1
	loot_state.remove_at(closest_index)
	if requires_brace:
		boat_state["brace_timer"] = 0.0
		if was_braced:
			boat_state["last_impact_damage"] = 0.0
			boat_state["last_impact_braced"] = true
			_apply_run_impact_reactions(
				Vector3.BACK.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
				0.24,
				true,
				false,
				"grapple"
			)
		else:
			var grapple_impact_local := get_station_position("grapple") + Vector3(0.0, 0.0, 0.55)
			var support_profile := _get_local_support_profile(get_station_position("grapple"))
			var backlash_multiplier := float(support_profile.get("salvage_backlash_multiplier", 1.0))
			var backlash_damage := SALVAGE_BACKLASH_DAMAGE * backlash_multiplier
			var run_continues := _apply_localized_block_damage(backlash_damage, grapple_impact_local, "salvage_backlash")
			_broadcast_runtime_boat_state()
			if not run_continues:
				_sync_generated_world_runtime_metrics()
				_broadcast_loot_state()
				_broadcast_run_state()
				_broadcast_boat_state()
				return
			boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - backlash_damage)
			boat_state["last_impact_damage"] = backlash_damage
			boat_state["last_impact_braced"] = false
			boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + SALVAGE_BACKLASH_BREACHES)
			_apply_propulsion_damage(PROPULSION_DAMAGE_BACKLASH * backlash_multiplier, 0.22, PROPULSION_FAULT_STATE_LABORING)
			_apply_run_impact_reactions(
				Vector3.BACK.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))),
				0.74,
				false,
				false,
				"grapple"
			)
			if _apply_salvage_backlash_avatar_damage():
				_refresh_crew_vitals_metrics()
				_broadcast_run_avatar_state()
			if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
				_sync_generated_world_runtime_metrics()
				_broadcast_loot_state()
				_broadcast_run_state()
				_broadcast_boat_state()
				_resolve_run_failure("The salvage surge tore the hull apart.")
				return
	_sync_generated_world_runtime_metrics()
	_broadcast_loot_state()
	_broadcast_run_state()
	_broadcast_boat_state()
	if requires_brace and not was_braced:
		_set_status("Recovered %s, but the unbraced salvage surge damaged the hull." % str(loot_target.get("label", "Loot")))
	else:
		_set_status("Grappled %s." % str(loot_target.get("label", "Loot")))

func _process_resupply_cache_grapple() -> bool:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var cache_site := _find_nearest_active_site(RunWorldGenerator.SITE_RESUPPLY, boat_position)
	if cache_site.is_empty():
		return false
	var cache_position: Vector3 = cache_site.get("position", Vector3.ZERO)
	var cache_radius: float = float(cache_site.get("radius", RESUPPLY_CACHE_RADIUS))
	var cache_max_speed: float = float(cache_site.get("max_speed", RESUPPLY_CACHE_MAX_SPEED))
	if boat_position.distance_to(cache_position) > cache_radius:
		return false
	if absf(float(boat_state.get("speed", 0.0))) > cache_max_speed:
		_set_status("Slow the boat down before attempting cache recovery.")
		return true
	var grapple_position := _get_station_world_position("grapple")
	if grapple_position.distance_to(cache_position) > GRAPPLE_RANGE:
		return false
	cache_site["available"] = false
	cache_site["recovered"] = true
	_store_poi_site(cache_site)
	var cache_bundle := _build_cache_reward_bundle(cache_site)
	run_state["repair_supplies"] = mini(
		int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_MAX)),
		int(run_state.get("repair_supplies", 0)) + int(cache_site.get("supply_grant", RESUPPLY_CACHE_SUPPLY_GRANT))
	)
	run_state["bonus_gold_bank"] = int(run_state.get("bonus_gold_bank", 0)) + int(cache_bundle.get("gold", RESUPPLY_CACHE_GOLD_BONUS))
	_append_run_materials(cache_bundle.get("materials", {}))
	_append_run_schematics(cache_bundle.get("schematics", []))
	_append_inventory_entry(
		"bonus_manifest",
		str(cache_site.get("label", "Resupply Cache")),
		1,
		"repair-kit",
		_build_material_detail(cache_bundle.get("materials", {}), int(cache_bundle.get("gold", 0)), int(cache_site.get("supply_grant", RESUPPLY_CACHE_SUPPLY_GRANT)), cache_bundle.get("schematics", []))
	)
	if _restore_all_crew_vitals():
		_refresh_crew_vitals_metrics()
		_broadcast_run_avatar_state()
	_sync_generated_world_runtime_metrics()
	_broadcast_run_state()
	_set_status("Recovered %s: %s." % [
		str(cache_site.get("label", "Resupply Cache")),
		_build_material_detail(cache_bundle.get("materials", {}), int(cache_bundle.get("gold", 0)), int(cache_site.get("supply_grant", RESUPPLY_CACHE_SUPPLY_GRANT)), cache_bundle.get("schematics", [])),
	])
	return true

func _process_rescue_grapple() -> bool:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var rescue_site := _find_nearest_active_site(RunWorldGenerator.SITE_DISTRESS, boat_position)
	if rescue_site.is_empty():
		return false
	var rescue_position: Vector3 = rescue_site.get("position", Vector3.ZERO)
	var rescue_radius: float = float(rescue_site.get("radius", 3.4))
	var rescue_max_speed: float = float(rescue_site.get("max_speed", RESCUE_MAX_SPEED))
	if boat_position.distance_to(rescue_position) > rescue_radius:
		return false
	if absf(float(boat_state.get("speed", 0.0))) > rescue_max_speed:
		_set_status("Slow the boat down before attempting the rescue.")
		return true
	var grapple_position := _get_station_world_position("grapple")
	if grapple_position.distance_to(rescue_position) > GRAPPLE_RANGE:
		return false
	if bool(rescue_site.get("engaged", false)):
		_set_status("Hold the boat steady while the rescue line stays tight.")
		return true
	rescue_site["engaged"] = true
	rescue_site["progress"] = maxf(float(rescue_site.get("progress", 0.0)), 0.08)
	_store_poi_site(rescue_site)
	_broadcast_run_state()
	_set_status("Rescue line secured. Hold steady until the evac completes.")
	return true

func _process_rescue_hold(delta: float) -> void:
	var any_updates := false
	for site_variant in _copy_array(run_state.get("poi_sites", [])):
		var rescue_site: Dictionary = site_variant
		if str(rescue_site.get("site_type", "")) != RunWorldGenerator.SITE_DISTRESS:
			continue
		if not bool(rescue_site.get("available", false)) or not bool(rescue_site.get("engaged", false)):
			continue
		var rescue_position: Vector3 = rescue_site.get("position", Vector3.ZERO)
		var rescue_radius: float = float(rescue_site.get("radius", 3.4))
		var rescue_max_speed: float = float(rescue_site.get("max_speed", RESCUE_MAX_SPEED))
		var rescue_duration: float = float(rescue_site.get("duration", RESCUE_DURATION))
		var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
		var boat_speed: float = absf(float(boat_state.get("speed", 0.0)))
		var progress := float(rescue_site.get("progress", 0.0))
		var progress_before := progress
		if boat_position.distance_to(rescue_position) <= rescue_radius and boat_speed <= rescue_max_speed:
			progress = minf(rescue_duration, progress + delta)
		else:
			progress = maxf(0.0, progress - delta * 1.5)
		rescue_site["progress"] = progress
		if progress >= rescue_duration:
			rescue_site["available"] = false
			rescue_site["engaged"] = false
			rescue_site["completed"] = true
			var rescue_bundle := _build_rescue_reward_bundle(rescue_site)
			run_state["repair_supplies"] = mini(
				int(run_state.get("repair_supplies_max", REPAIR_SUPPLIES_MAX)),
				int(run_state.get("repair_supplies", 0)) + int(rescue_site.get("patch_kit_bonus", RESCUE_PATCH_KIT_GRANT))
			)
			run_state["bonus_gold_bank"] = int(run_state.get("bonus_gold_bank", 0)) + int(rescue_bundle.get("gold", RESCUE_GOLD_BONUS_MIN))
			_append_run_materials(rescue_bundle.get("materials", {}))
			_append_run_schematics(rescue_bundle.get("schematics", []))
			_append_inventory_entry(
				"bonus_manifest",
				str(rescue_site.get("label", "Rescue")),
				1,
				"salvage",
				_build_material_detail(rescue_bundle.get("materials", {}), int(rescue_bundle.get("gold", 0)), int(rescue_site.get("patch_kit_bonus", RESCUE_PATCH_KIT_GRANT)), rescue_bundle.get("schematics", []))
			)
			if _restore_all_crew_vitals():
				_refresh_crew_vitals_metrics()
				_broadcast_run_avatar_state()
			_set_status("%s completed: %s." % [
				str(rescue_site.get("label", "Rescue")),
				_build_material_detail(rescue_bundle.get("materials", {}), int(rescue_bundle.get("gold", 0)), int(rescue_site.get("patch_kit_bonus", RESCUE_PATCH_KIT_GRANT)), rescue_bundle.get("schematics", [])),
			])
		_store_poi_site(rescue_site)
		if not is_equal_approx(progress_before, progress) or bool(rescue_site.get("completed", false)):
			any_updates = true
	if any_updates:
		_broadcast_run_state()

func _get_active_squall_drag_multiplier(position: Vector3) -> float:
	var drag_multiplier := 1.0
	for band_variant in _copy_array(run_state.get("squall_bands", [])):
		var band: Dictionary = band_variant
		if not _position_inside_squall(position, band):
			continue
		drag_multiplier = minf(drag_multiplier, float(band.get("drag_multiplier", 1.0)))
	return drag_multiplier

func _process_squall_pressure(delta: float) -> void:
	var bands := _copy_array(run_state.get("squall_bands", []))
	if bands.is_empty():
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var updated_bands := false
	for band_index in range(bands.size()):
		var band: Dictionary = bands[band_index]
		var pulse_timer := float(band.get("pulse_timer", float(band.get("pulse_interval", SQUALL_PULSE_INTERVAL_MIN))))
		pulse_timer = maxf(0.0, pulse_timer - delta)
		if _position_inside_squall(boat_position, band) and pulse_timer <= 0.0:
			var pulse_interval: float = float(band.get("pulse_interval", SQUALL_PULSE_INTERVAL_MIN))
			pulse_timer = pulse_interval
			_resolve_squall_pulse(band)
			if str(run_state.get("phase", "running")) != "running":
				return
		band["pulse_timer"] = pulse_timer
		bands[band_index] = band
		updated_bands = true

	if updated_bands:
		run_state["squall_bands"] = bands
		run_state["hazard_fields"] = bands.duplicate(true)

func _resolve_squall_pulse(band: Dictionary) -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var band_center: Vector3 = band.get("center", Vector3.ZERO)
	var pulse_damage := float(band.get("pulse_damage", SQUALL_PULSE_DAMAGE_MIN))
	var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
	var impact_local := Vector3(0.7 * (1.0 if boat_position.x <= band_center.x else -1.0), 0.0, 0.45)
	var brace_multiplier: float = float(boat_state.get("brace_multiplier", 1.0)) * _get_local_brace_multiplier(impact_local)
	if was_braced:
		pulse_damage = maxf(1.5, pulse_damage / maxf(1.0, brace_multiplier))
		boat_state["brace_timer"] = 0.0

	var pulse_sign := 1.0 if boat_position.x <= band_center.x else -1.0
	var survives := _apply_localized_block_damage(pulse_damage, impact_local, "squall_pulse")
	_broadcast_runtime_boat_state()
	if not survives:
		_broadcast_run_state()
		_broadcast_boat_state()
		return

	boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - pulse_damage)
	boat_state["last_impact_damage"] = pulse_damage
	boat_state["last_impact_braced"] = was_braced
	_apply_propulsion_damage(
		PROPULSION_DAMAGE_SQUALL_BRACED if was_braced else PROPULSION_DAMAGE_SQUALL_UNBRACED,
		0.12 if was_braced else 0.2,
		PROPULSION_FAULT_STATE_LABORING
	)
	var reaction_direction := Vector3.RIGHT.rotated(Vector3.UP, float(boat_state.get("rotation_y", 0.0))) * pulse_sign
	_apply_run_impact_reactions(
		reaction_direction,
		clampf(pulse_damage / SQUALL_PULSE_DAMAGE_MAX, 0.26, 0.62),
		was_braced,
		false,
		"squall"
	)
	if _apply_avatar_impact_damage(was_braced, impact_local):
		_refresh_crew_vitals_metrics()
		_broadcast_run_avatar_state()
	_broadcast_run_state()
	_broadcast_boat_state()
	if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
		_resolve_run_failure("A squall surge smashed the hull apart before the crew could extract.")
		return
	_set_status("Braced through the squall surge." if was_braced else "A squall surge slammed the hull.")

func _position_inside_squall(position: Vector3, band: Dictionary) -> bool:
	var center: Vector3 = band.get("center", Vector3.ZERO)
	var half_extents: Vector3 = band.get("half_extents", Vector3(4.0, 0.0, 2.4))
	return absf(position.x - center.x) <= half_extents.x and absf(position.z - center.z) <= half_extents.z

func _process_hazard_collisions() -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return

	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	for index in range(hazard_state.size()):
		var hazard: Dictionary = hazard_state[index]
		var hazard_position: Vector3 = hazard.get("position", Vector3.ZERO)
		var hazard_radius: float = float(hazard.get("radius", 1.25))
		if boat_position.distance_to(hazard_position) > BOAT_COLLISION_RADIUS + hazard_radius:
			continue

		var was_braced := float(boat_state.get("brace_timer", 0.0)) > 0.0
		var impact_local := (hazard_position - boat_position).rotated(Vector3.UP, -float(boat_state.get("rotation_y", 0.0)))
		var brace_multiplier: float = float(boat_state.get("brace_multiplier", 1.0)) * _get_local_brace_multiplier(impact_local)
		var damage := COLLISION_DAMAGE_BRACED if was_braced else COLLISION_DAMAGE_UNBRACED
		if was_braced:
			damage = maxf(2.0, damage / maxf(1.0, brace_multiplier))
		var run_continues := _apply_localized_block_damage(damage, impact_local, "collision")
		_broadcast_runtime_boat_state()
		if not run_continues:
			_respawn_hazard(index)
			_broadcast_hazard_state()
			_broadcast_boat_state()
			return
		var breach_delta := 1 if was_braced else 2
		boat_state["hull_integrity"] = maxf(0.0, float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) - damage)
		boat_state["speed"] = float(boat_state.get("speed", 0.0)) * (0.72 if was_braced else 0.38)
		boat_state["breach_stacks"] = mini(MAX_BREACH_STACKS, int(boat_state.get("breach_stacks", 0)) + breach_delta)
		boat_state["last_impact_damage"] = damage
		boat_state["last_impact_braced"] = was_braced
		boat_state["collision_count"] = int(boat_state.get("collision_count", 0)) + 1
		boat_state["brace_timer"] = 0.0
		_apply_propulsion_damage(
			PROPULSION_DAMAGE_COLLISION_BRACED if was_braced else PROPULSION_DAMAGE_COLLISION_UNBRACED,
			0.18 if was_braced else 0.3,
			PROPULSION_FAULT_STATE_LABORING
		)
		_apply_run_impact_reactions(
			(boat_position - hazard_position).normalized(),
			0.42 if was_braced else 0.92,
			was_braced,
			not was_braced
		)
		if _apply_avatar_impact_damage(was_braced, impact_local):
			_refresh_crew_vitals_metrics()
			_broadcast_run_avatar_state()

		_respawn_hazard(index)
		_broadcast_hazard_state()
		_broadcast_boat_state()
		_set_status("%s impact for %.1f damage." % ["Braced" if was_braced else "Unbraced", damage])
		if float(boat_state.get("hull_integrity", BOAT_MAX_INTEGRITY)) <= 0.0:
			_resolve_run_failure("Hull destroyed in open water.")
		return

func _process_extraction_reveals() -> void:
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var revealed_ids := _copy_array(run_state.get("revealed_extraction_ids", []))
	var revealed_lookup := {}
	for extraction_id_variant in revealed_ids:
		revealed_lookup[str(extraction_id_variant)] = true
	var sites := _copy_array(run_state.get("extraction_sites", []))
	var changed := false
	for site_index in range(sites.size()):
		var site: Dictionary = sites[site_index]
		var site_id := str(site.get("id", ""))
		if revealed_lookup.has(site_id):
			if not bool(site.get("revealed", false)):
				site["revealed"] = true
				sites[site_index] = site
				changed = true
			continue
		if boat_position.distance_to(site.get("position", Vector3.ZERO)) > float(site.get("reveal_radius", RunWorldGenerator.EXTRACTION_REVEAL_RADIUS)):
			continue
		revealed_ids.append(site_id)
		revealed_lookup[site_id] = true
		site["revealed"] = true
		sites[site_index] = site
		changed = true
		_set_status("%s sighted on the horizon. Extraction is now available." % str(site.get("label", "Outpost")))
	if not changed:
		return
	run_state["revealed_extraction_ids"] = revealed_ids
	run_state["extraction_sites"] = sites
	_sync_generated_world_runtime_metrics()
	_broadcast_run_state()

func _process_extraction(delta: float) -> void:
	if session_phase != SESSION_PHASE_RUN:
		return
	if str(run_state.get("phase", "running")) != "running":
		return

	var previous_progress: float = float(run_state.get("extraction_progress", 0.0))
	var extraction_progress := previous_progress
	var cargo_count := int(run_state.get("cargo_count", 0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	var boat_speed: float = float(boat_state.get("speed", 0.0))
	var active_site := _find_nearest_extraction_site(boat_position, true)
	var can_extract := false
	if not active_site.is_empty():
		var extraction_position: Vector3 = active_site.get("position", Vector3.ZERO)
		var extraction_radius: float = float(active_site.get("radius", EXTRACTION_RADIUS))
		can_extract = cargo_count > 0 and boat_position.distance_to(extraction_position) <= extraction_radius and boat_speed <= EXTRACTION_MAX_SPEED
		run_state["active_extraction_id"] = str(active_site.get("id", ""))
	else:
		run_state["active_extraction_id"] = ""

	if can_extract:
		extraction_progress = minf(float(run_state.get("extraction_duration", EXTRACTION_DURATION)), previous_progress + delta)
	else:
		extraction_progress = maxf(0.0, previous_progress - delta * 1.5)

	run_state["extraction_progress"] = extraction_progress
	if not is_equal_approx(previous_progress, extraction_progress):
		_broadcast_run_state()

	if extraction_progress >= float(run_state.get("extraction_duration", EXTRACTION_DURATION)):
		_resolve_run_success()

func _calculate_repair_debt_delta(failed_run: bool) -> Dictionary:
	var propulsion_ratio := clampf(
		float(boat_state.get("propulsion_health", 100.0)) / maxf(1.0, float(boat_state.get("propulsion_health_rating", 100.0))),
		0.0,
		1.0
	)
	var detached_chunk_count := int(run_state.get("detached_chunk_count", 0))
	var destroyed_block_count := int(run_state.get("destroyed_block_count", 0))
	var collision_count := int(boat_state.get("collision_count", 0))
	var failure_multiplier := 1.45 if failed_run else 1.0
	var materials := {
		"scrap_metal": maxi(0, int(round((destroyed_block_count + detached_chunk_count * 2 + collision_count) * failure_multiplier))),
		"treated_planks": maxi(0, int(round((detached_chunk_count + int(run_state.get("cargo_lost_to_sea", 0))) * failure_multiplier))),
		"rigging": maxi(0, int(round(float(int(run_state.get("overboard_incidents", 0))) * 0.5 * failure_multiplier))),
		"machined_parts": 0,
		"boiler_parts": 0,
		"shock_insulation": 0,
	}
	if propulsion_ratio < 0.82:
		materials["machined_parts"] = maxi(1, int(round((1.0 - propulsion_ratio) * 4.0 * failure_multiplier)))
	if str(boat_state.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES)) == PROPULSION_FAMILY_STEAM_TUG or str(boat_state.get("propulsion_family", "")) == "high_pressure_boiler":
		if propulsion_ratio < 0.68:
			materials["boiler_parts"] = maxi(1, int(round((1.0 - propulsion_ratio) * 3.0 * failure_multiplier)))
	if str(boat_state.get("propulsion_family", PROPULSION_FAMILY_RAFT_PADDLES)) == PROPULSION_FAMILY_TWIN_ENGINE or detached_chunk_count > 1:
		if propulsion_ratio < 0.58 or detached_chunk_count > 1:
			materials["shock_insulation"] = maxi(1, int(round((1.0 - propulsion_ratio) * 2.0 * failure_multiplier)))
	var gold_cost := maxi(0, int(round((destroyed_block_count * 4 + detached_chunk_count * 7 + collision_count * 2) * failure_multiplier)))
	return {
		"gold": gold_cost,
		"items": _normalize_material_dict_ui(materials),
		"severity": "heavy" if failed_run else ("moderate" if gold_cost > 10 else "light"),
	}

func _resolve_run_success() -> void:
	if str(run_state.get("phase", "running")) != "running":
		return

	_freeze_boat()
	var cargo_secured := int(run_state.get("cargo_count", 0))
	var reward_gold := cargo_secured * REWARD_GOLD_PER_CARGO + int(run_state.get("bonus_gold_bank", 0))
	var reward_items := _normalize_material_dict_ui(run_state.get("run_item_bank", {}))
	var reward_schematics := _normalize_schematic_list_ui(run_state.get("run_schematic_bank", []))
	var repair_debt_delta := _calculate_repair_debt_delta(false)
	var extraction_site := _find_nearest_extraction_site(boat_state.get("position", Vector3.ZERO), true)
	var extraction_label := str(extraction_site.get("label", "the outpost"))
	run_state["phase"] = "success"
	run_state["cargo_secured"] = cargo_secured
	run_state["secured_manifest"] = Array(run_state.get("cargo_manifest", [])).duplicate(true)
	run_state["reward_gold"] = reward_gold
	run_state["reward_salvage"] = _sum_material_dict_ui(reward_items)
	run_state["reward_items"] = reward_items
	run_state["reward_schematics"] = reward_schematics
	run_state["loot_lost_items"] = {}
	run_state["repair_debt_delta"] = repair_debt_delta
	run_state["result_title"] = "Extraction Successful"
	run_state["result_message"] = "Secured %d cargo item(s) at %s for %d gold plus %d material unit(s)." % [
		cargo_secured,
		extraction_label,
		reward_gold,
		_sum_material_dict_ui(reward_items),
	]
	_record_host_run_result()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_progression_state()
	_set_status(str(run_state.get("result_message", "")))

func _resolve_run_failure(reason: String) -> void:
	if str(run_state.get("phase", "running")) != "running":
		return

	_freeze_boat()
	var consolation_gold := int(round(float(int(run_state.get("bonus_gold_bank", 0))) * 0.35))
	var loot_lost_items := _normalize_material_dict_ui(run_state.get("run_item_bank", {}))
	var repair_debt_delta := _calculate_repair_debt_delta(true)
	run_state["phase"] = "failed"
	run_state["cargo_secured"] = 0
	run_state["secured_manifest"] = []
	run_state["reward_gold"] = consolation_gold
	run_state["reward_salvage"] = 0
	run_state["reward_items"] = {}
	run_state["reward_schematics"] = []
	run_state["loot_lost_items"] = loot_lost_items
	run_state["repair_debt_delta"] = repair_debt_delta
	run_state["failure_reason"] = reason
	run_state["result_title"] = "Run Failed"
	run_state["result_message"] = "%s Lost %d cargo item(s) and %d material unit(s)." % [
		reason,
		int(run_state.get("cargo_count", 0)),
		_sum_material_dict_ui(loot_lost_items),
	]
	_record_host_run_result()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_progression_state()
	_set_status(str(run_state.get("result_message", "")))

func _record_host_run_result() -> void:
	if not multiplayer.is_server():
		return
	DockState.apply_host_run_outcome(run_seed, run_state)
	progression_state = _decorate_progression_snapshot(DockState.get_host_progression_snapshot())

func _freeze_boat() -> void:
	boat_state["speed"] = 0.0
	boat_state["throttle"] = 0.0
	boat_state["steer"] = 0.0
	boat_state["actual_thrust"] = 0.0
	boat_state["speed_order"] = "Stop"
	boat_state["propulsion_support_timer"] = 0.0
	boat_state["propulsion_secondary_timer"] = 0.0
	boat_state["propulsion_port_output"] = float(boat_state.get("automation_floor", 0.65)) * 0.5
	boat_state["propulsion_starboard_output"] = float(boat_state.get("automation_floor", 0.65)) * 0.5
	boat_state["propulsion_side_bias"] = 0.0
	_peer_inputs = {}

func _respawn_hazard(index: int) -> void:
	var hazard: Dictionary = hazard_state[index]
	var home_position: Vector3 = hazard.get("home_position", hazard.get("position", Vector3.ZERO))
	var jitter_seed := int(hazard.get("id", index + 1)) * 97 + int(boat_state.get("tick", 0))
	hazard["position"] = home_position + Vector3(
		sin(float(jitter_seed % 360)) * 3.6,
		0.0,
		cos(float((jitter_seed * 3) % 360)) * 3.1
	)
	hazard_state[index] = hazard

func _get_station_world_position(station_id: String) -> Vector3:
	var local_position := get_station_position(station_id)
	var rotation_y: float = float(boat_state.get("rotation_y", 0.0))
	var boat_position: Vector3 = boat_state.get("position", Vector3.ZERO)
	return boat_position + local_position.rotated(Vector3.UP, rotation_y)

func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	peer_snapshot[peer_id] = {
		"name": "Crewmate %d" % peer_id,
		"status": "connecting",
	}
	_broadcast_peer_snapshot()
	_reset_connected_hangar_avatars()
	_set_status("Peer %d connected." % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_peer_inputs.erase(peer_id)
	_release_station(peer_id, false)
	peer_snapshot.erase(peer_id)
	hangar_avatar_state.erase(peer_id)
	run_avatar_state.erase(peer_id)
	reaction_state.erase(peer_id)
	if multiplayer.is_server() and session_phase == SESSION_PHASE_RUN:
		_refresh_overboard_run_metrics()
		_refresh_crew_vitals_metrics()
	var expired_pair_keys: Array = []
	for pair_key_variant in _hangar_bump_pair_cooldowns.keys():
		var pair_key := str(pair_key_variant)
		if pair_key.begins_with("%d:" % peer_id) or pair_key.ends_with(":%d" % peer_id):
			expired_pair_keys.append(pair_key)
	for pair_key_variant in expired_pair_keys:
		_hangar_bump_pair_cooldowns.erase(str(pair_key_variant))
	_schedule_disconnect_updates()
	if multiplayer.is_server():
		_set_status("Peer %d disconnected." % peer_id)

func _broadcast_disconnect_updates() -> void:
	if not multiplayer.is_server():
		return
	_broadcast_station_state()
	_broadcast_boat_state()
	_broadcast_run_state()
	_broadcast_peer_snapshot()
	_broadcast_hangar_avatar_state()
	_broadcast_run_avatar_state()
	_broadcast_reaction_state()

func _schedule_disconnect_updates() -> void:
	if not multiplayer.is_server():
		return
	if _disconnect_broadcast_scheduled:
		return
	_disconnect_broadcast_scheduled = true
	_finish_disconnect_updates()

func _finish_disconnect_updates() -> void:
	await get_tree().create_timer(DISCONNECT_BROADCAST_DELAY_SECONDS).timeout
	_disconnect_broadcast_scheduled = false
	_broadcast_disconnect_updates()

func _on_connected_to_server() -> void:
	_set_status("Connected to %s:%d as %s." % [current_host, current_port, local_player_name])
	server_register_player.rpc_id(1, local_player_name)

func _on_connection_failed() -> void:
	_set_status("Connection failed. Check the host IP and port, or make sure the host started the server.")
	emit_signal("client_connect_failed")

func _on_server_disconnected() -> void:
	_set_status("Server disconnected. Ask the host to restart the server or return to the connect screen.")
	emit_signal("client_disconnected")

@rpc("any_peer", "call_remote", "reliable")
func server_register_player(player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	peer_snapshot[peer_id] = {
		"name": player_name,
		"status": "ready",
	}
	if not hangar_avatar_state.has(peer_id):
		hangar_avatar_state[peer_id] = _make_default_hangar_avatar_state(hangar_avatar_state.size())
	if session_phase == SESSION_PHASE_RUN and not run_avatar_state.has(peer_id):
		run_avatar_state[peer_id] = _make_default_run_avatar_state(run_avatar_state.size())
		_refresh_run_avatar_runtime_fields(peer_id)
		_refresh_overboard_run_metrics()
		_refresh_crew_vitals_metrics()
	_send_bootstrap(peer_id)
	_broadcast_peer_snapshot()
	_broadcast_hangar_avatar_state()
	_broadcast_run_avatar_state()

@rpc("any_peer", "call_remote", "reliable")
func server_request_driver_control() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_claim_station(peer_id, "helm")

@rpc("any_peer", "call_remote", "reliable")
func server_request_station_claim(station_id: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_claim_station(peer_id, station_id.to_lower())

@rpc("any_peer", "call_remote", "reliable")
func server_request_station_release() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_release_station(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_brace() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_begin_brace(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_grapple() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_grapple(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_repair() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_repair(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_propulsion_primary() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_propulsion_primary(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_propulsion_secondary() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_process_propulsion_secondary(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_overboard_recovery() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_attempt_overboard_recovery(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_assist_rally(target_peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_attempt_assist_rally(peer_id, target_peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_overboard() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_force_peer_overboard_for_debug(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_local_overboard_transition(world_position: Vector3, velocity: Vector3, facing_y: float) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_request_peer_overboard_transition(peer_id, world_position, velocity, facing_y)

@rpc("any_peer", "call_remote", "reliable")
func server_request_place_blueprint_block(cell: Array, block_type: String, rotation_steps: int) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_place_blueprint_block(peer_id, cell, block_type, rotation_steps)

@rpc("any_peer", "call_remote", "reliable")
func server_request_remove_blueprint_block(cell: Array) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_remove_blueprint_block(peer_id, cell)

@rpc("any_peer", "call_remote", "reliable")
func server_request_reset_blueprint() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_reset_blueprint_for_peer(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_unlock_builder_block(block_type: String) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_unlock_builder_block(peer_id, block_type.strip_edges().to_lower())

@rpc("any_peer", "call_remote", "reliable")
func server_request_donate_workshop_resource(resource_id: String, quantity: int) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_donate_workshop_resource(peer_id, resource_id.strip_edges().to_lower(), quantity)

@rpc("any_peer", "call_remote", "reliable")
func server_request_launch_run() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_launch_run_session(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func server_request_return_to_hangar() -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_return_to_hangar_session(peer_id)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_hangar_avatar_state(
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell: Array,
	remove_cell: Array,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_HANGAR:
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_hangar_avatar_state(
		peer_id,
		position,
		velocity,
		facing_y,
		grounded,
		selected_block_id,
		rotation_steps,
		target_cell,
		remove_cell,
		has_target,
		target_feedback_state
	)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_run_avatar_state(deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, avatar_mode: String) -> void:
	if not multiplayer.is_server():
		return
	if session_phase != SESSION_PHASE_RUN:
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_run_avatar_state(peer_id, deck_position, world_position, velocity, facing_y, grounded, avatar_mode)

@rpc("any_peer", "call_remote", "unreliable")
func server_receive_boat_input(throttle: float, steer: float) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	_receive_boat_input(peer_id, throttle, steer)

@rpc("authority", "call_remote", "unreliable")
func client_receive_hangar_avatar_state(snapshot: Dictionary) -> void:
	hangar_avatar_state = snapshot.duplicate(true)
	emit_signal("hangar_avatar_state_changed", hangar_avatar_state.duplicate(true))

@rpc("authority", "call_remote", "unreliable")
func client_receive_run_avatar_state(snapshot: Dictionary) -> void:
	run_avatar_state = snapshot.duplicate(true)
	emit_signal("run_avatar_state_changed", run_avatar_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_reaction_state(snapshot: Dictionary) -> void:
	reaction_state = snapshot.duplicate(true)
	emit_signal("reaction_state_changed", reaction_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_bootstrap(seed: int, server_port: int, max_players: int, phase: String, blueprint_snapshot: Dictionary) -> void:
	run_seed = seed
	current_port = server_port
	session_phase = phase
	boat_blueprint = _decorate_blueprint(blueprint_snapshot)
	emit_signal("run_seed_changed", run_seed)
	emit_signal("session_phase_changed", session_phase)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))
	_set_status("Run bootstrap received: seed %d, max players %d." % [run_seed, max_players])
	if not _client_bootstrap_complete:
		_client_bootstrap_complete = true
		emit_signal("connection_ready")

@rpc("authority", "call_remote", "reliable")
func client_receive_session_phase(phase: String) -> void:
	session_phase = phase
	emit_signal("session_phase_changed", session_phase)

@rpc("authority", "call_remote", "reliable")
func client_receive_blueprint_state(snapshot: Dictionary) -> void:
	boat_blueprint = _decorate_blueprint(snapshot)
	emit_signal("boat_blueprint_changed", boat_blueprint.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_progression_state(snapshot: Dictionary) -> void:
	progression_state = _decorate_progression_snapshot(snapshot)
	emit_signal("progression_state_changed", progression_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_peer_snapshot(snapshot: Dictionary) -> void:
	peer_snapshot = snapshot.duplicate(true)
	emit_signal("peer_snapshot_changed", peer_snapshot.duplicate(true))

func _normalize_hangar_feedback_state(feedback_state: String) -> String:
	match feedback_state.strip_edges().to_lower():
		"ready":
			return "ready"
		"occupied":
			return "occupied"
		"range":
			return "range"
		"blocked":
			return "blocked"
		_:
			return "hidden"

func _normalize_hangar_selected_block_id(block_type: String) -> String:
	var normalized := block_type.strip_edges().to_lower()
	if BUILDER_BLOCK_LIBRARY.has(normalized):
		return normalized
	return "structure"

func _build_hangar_avatar_presence_snapshot(
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> Dictionary:
	var normalized_presence := {
		"selected_block_id": _normalize_hangar_selected_block_id(selected_block_id),
		"rotation_steps": wrapi(rotation_steps, 0, 4),
		"target_cell": _normalize_blueprint_cell(target_cell_value),
		"remove_cell": _normalize_blueprint_cell(remove_cell_value),
		"has_target": has_target,
		"target_feedback_state": _normalize_hangar_feedback_state(target_feedback_state),
	}
	if not bool(normalized_presence.get("has_target", false)):
		normalized_presence["target_feedback_state"] = "hidden"
		normalized_presence["target_cell"] = [0, 0, 0]
		normalized_presence["remove_cell"] = [0, 0, 0]
	return normalized_presence

func _receive_hangar_avatar_state(
	peer_id: int,
	position: Vector3,
	velocity: Vector3,
	facing_y: float,
	grounded: bool,
	selected_block_id: String,
	rotation_steps: int,
	target_cell_value: Variant,
	remove_cell_value: Variant,
	has_target: bool,
	target_feedback_state: String
) -> void:
	if not _has_runtime_authority():
		return
	if not peer_snapshot.has(peer_id):
		if multiplayer.multiplayer_peer == null and peer_id == OFFLINE_LOCAL_PEER_ID:
			_ensure_offline_local_state()
		else:
			return
	if not peer_snapshot.has(peer_id):
		return

	var existing_state: Dictionary = hangar_avatar_state.get(peer_id, _make_default_hangar_avatar_state(hangar_avatar_state.size()))
	var normalized_presence := _build_hangar_avatar_presence_snapshot(
		selected_block_id if not selected_block_id.is_empty() else str(existing_state.get("selected_block_id", "structure")),
		rotation_steps,
		target_cell_value,
		remove_cell_value,
		has_target,
		target_feedback_state
	)
	hangar_avatar_state[peer_id] = {
		"position": position,
		"velocity": velocity,
		"facing_y": facing_y,
		"grounded": grounded,
		"selected_block_id": str(normalized_presence.get("selected_block_id", "structure")),
		"rotation_steps": int(normalized_presence.get("rotation_steps", 0)),
		"target_cell": normalized_presence.get("target_cell", [0, 0, 0]),
		"remove_cell": normalized_presence.get("remove_cell", [0, 0, 0]),
		"has_target": bool(normalized_presence.get("has_target", false)),
		"target_feedback_state": str(normalized_presence.get("target_feedback_state", "hidden")),
	}
	_broadcast_hangar_avatar_state()

func _receive_run_avatar_state(peer_id: int, deck_position: Vector3, world_position: Vector3, velocity: Vector3, facing_y: float, grounded: bool, _avatar_mode: String) -> void:
	if not multiplayer.is_server():
		return
	if not peer_snapshot.has(peer_id):
		return

	var previous_overboard_count := int(run_state.get("overboard_count", 0))
	var existing_state: Dictionary = run_avatar_state.get(peer_id, _make_default_run_avatar_state(run_avatar_state.size()))
	var normalized_mode := str(existing_state.get("mode", RUN_AVATAR_MODE_DECK))
	existing_state["mode"] = normalized_mode
	if normalized_mode == RUN_AVATAR_MODE_OVERBOARD:
		existing_state["velocity"] = velocity.limit_length(9.5)
		existing_state["facing_y"] = facing_y
		existing_state["grounded"] = grounded
		existing_state["world_position"] = _sanitize_overboard_world_position(world_position)
	elif normalized_mode == RUN_AVATAR_MODE_DOWNED:
		existing_state["velocity"] = Vector3.ZERO
		existing_state["grounded"] = true
	else:
		existing_state["deck_position"] = sanitize_run_avatar_deck_position(
			deck_position,
			existing_state.get("deck_position", RUN_DECK_SPAWN_POINTS[0])
		)
		existing_state["velocity"] = velocity.limit_length(9.5)
		existing_state["facing_y"] = facing_y
		existing_state["grounded"] = grounded
	run_avatar_state[peer_id] = existing_state
	_refresh_run_avatar_runtime_fields(peer_id)
	_refresh_overboard_run_metrics()
	_broadcast_run_avatar_state()
	if int(run_state.get("overboard_count", 0)) != previous_overboard_count:
		_broadcast_run_state()

@rpc("authority", "call_remote", "unreliable")
func client_receive_boat_state(state: Dictionary, current_driver_id: int) -> void:
	var driver_changed := driver_peer_id != current_driver_id
	var preserved_runtime_blocks := Array(boat_state.get("runtime_blocks", [])).duplicate(true)
	var preserved_sinking_chunks := Array(boat_state.get("sinking_chunks", [])).duplicate(true)
	boat_state = state.duplicate(true)
	boat_state["runtime_blocks"] = preserved_runtime_blocks
	boat_state["sinking_chunks"] = preserved_sinking_chunks
	driver_peer_id = current_driver_id
	emit_signal("boat_state_changed", boat_state.duplicate(true))
	if driver_changed:
		emit_signal("helm_changed", driver_peer_id)

@rpc("authority", "call_remote", "reliable")
func client_receive_runtime_boat_state(runtime_state: Dictionary) -> void:
	boat_state["runtime_blocks"] = Array(runtime_state.get("runtime_blocks", [])).duplicate(true)
	boat_state["sinking_chunks"] = Array(runtime_state.get("sinking_chunks", [])).duplicate(true)
	emit_signal("boat_state_changed", boat_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_hazard_state(hazards: Array) -> void:
	hazard_state = hazards.duplicate(true)
	emit_signal("hazard_state_changed", hazard_state.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func client_receive_station_state(stations: Dictionary) -> void:
	var previous_driver := driver_peer_id
	station_state = stations.duplicate(true)
	var helm_station: Dictionary = station_state.get("helm", {})
	driver_peer_id = int(helm_station.get("occupant_peer_id", 0))
	emit_signal("station_state_changed", station_state.duplicate(true))
	if previous_driver != driver_peer_id:
		emit_signal("helm_changed", driver_peer_id)

@rpc("authority", "call_remote", "reliable")
func client_receive_loot_state(targets: Array) -> void:
	loot_state = targets.duplicate(true)
	emit_signal("loot_state_changed", loot_state.duplicate(true))

func _maybe_apply_local_run_result() -> void:
	var phase := str(run_state.get("phase", "running"))
	if phase == "running" or phase == "hangar":
		_last_applied_local_result_run_instance_id = -1
		return
	var run_instance_id := int(run_state.get("run_instance_id", -1))
	if run_instance_id == _last_applied_local_result_run_instance_id:
		return
	var local_peer_id := 1 if multiplayer.multiplayer_peer == null else multiplayer.get_unique_id()
	var eligible_peer_ids := Array(run_state.get("eligible_reward_peer_ids", []))
	var eligible := false
	for peer_id_variant in eligible_peer_ids:
		if int(peer_id_variant) == local_peer_id:
			eligible = true
			break
	if eligible:
		DockState.apply_local_run_result(run_seed, run_state)
	_last_applied_local_result_run_instance_id = run_instance_id

@rpc("authority", "call_remote", "reliable")
func client_receive_run_state(state: Dictionary) -> void:
	run_state = state.duplicate(true)
	_maybe_apply_local_run_result()
	emit_signal("run_state_changed", run_state.duplicate(true))
