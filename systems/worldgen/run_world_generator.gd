class_name RunWorldGenerator
extends RefCounted

const WORLD_SIZE_CHUNKS := 16
const CHUNK_SIZE_M := 24.0
const STREAM_RADIUS_CHUNKS := 2
const EXTRACTION_REVEAL_RADIUS := 60.0
const MAX_GENERATION_RETRIES := 5
const EXTRACTION_TARGET_COUNT := 2
const MIN_POI_SPACING_CHUNKS := 2.1
const MIN_EXTRACTION_SPACING_CHUNKS := 5.0
const MAX_ROUTE_HAZARD_COST := 48.0

const BIOME_OPEN_OCEAN := "open_ocean"
const BIOME_REEF_WATERS := "reef_waters"
const BIOME_FOG_BANK := "fog_bank"
const BIOME_STORM_BELT := "storm_belt"
const BIOME_GRAVEYARD_WATERS := "graveyard_waters"

const SITE_SALVAGE := "salvage_site"
const SITE_DISTRESS := "distress_site"
const SITE_RESUPPLY := "resupply_site"
const SITE_EXTRACTION := "extraction_outpost"

static func generate_world(run_seed: int) -> Dictionary:
	for retry_index in range(MAX_GENERATION_RETRIES):
		var layout := _generate_world_attempt(run_seed, retry_index)
		if _validate_world_layout(layout):
			layout["generation_retry_index"] = retry_index
			return layout
	return _build_safe_fallback_world(run_seed)

static func _generate_world_attempt(run_seed: int, retry_index: int) -> Dictionary:
	var base_seed := int(run_seed) + retry_index * 7919
	var rng := RandomNumberGenerator.new()
	rng.seed = int(base_seed) * 104729 + 17
	var biome_noise := _make_noise(base_seed * 17 + 3, 0.085)
	var hazard_noise := _make_noise(base_seed * 29 + 5, 0.11)
	var richness_noise := _make_noise(base_seed * 41 + 7, 0.095)
	var descriptors: Array = []
	var descriptor_lookup := {}

	for z in range(WORLD_SIZE_CHUNKS):
		for x in range(WORLD_SIZE_CHUNKS):
			var biome_value := biome_noise.get_noise_2d(float(x), float(z))
			var hazard_value := clampf((hazard_noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5, 0.0, 1.0)
			var richness_value := clampf((richness_noise.get_noise_2d(float(x), float(z)) + 1.0) * 0.5, 0.0, 1.0)
			var biome_id := _resolve_biome_id(biome_value, hazard_value, richness_value)
			var is_border_chunk := x == 0 or z == 0 or x == WORLD_SIZE_CHUNKS - 1 or z == WORLD_SIZE_CHUNKS - 1
			var reef_core_blocker := biome_id == BIOME_REEF_WATERS and hazard_value >= 0.72
			var descriptor := {
				"coord": [x, z],
				"biome_id": biome_id,
				"hazard_level": hazard_value,
				"richness_level": richness_value,
				"props_seed": int(base_seed) * 8191 + x * 131 + z * 977,
				"poi_id": "",
				"is_extraction_chunk": false,
				"is_border_chunk": is_border_chunk,
				"is_blocked": is_border_chunk or reef_core_blocker,
				"world_center": Vector3.ZERO,
			}
			descriptors.append(descriptor)
			descriptor_lookup[_coord_key([x, z])] = descriptor

	var spawn_chunk := _select_spawn_chunk(descriptors, rng)
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		descriptor["world_center"] = _chunk_center_world_position(descriptor.get("coord", [0, 0]), spawn_chunk)

	var poi_sites: Array = []
	var extraction_sites: Array = []
	var used_coords := {}
	var site_counter := {
		SITE_SALVAGE: 0,
		SITE_DISTRESS: 0,
		SITE_RESUPPLY: 0,
		SITE_EXTRACTION: 0,
	}

	var extraction_candidates := _pick_extraction_chunks(descriptors, spawn_chunk, rng)
	for coord_variant in extraction_candidates:
		var coord := _coord_from_variant(coord_variant)
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		if descriptor.is_empty():
			continue
		site_counter[SITE_EXTRACTION] = int(site_counter.get(SITE_EXTRACTION, 0)) + 1
		var extraction_id := "extract_%d" % int(site_counter[SITE_EXTRACTION])
		var extraction_site := {
			"id": extraction_id,
			"site_type": SITE_EXTRACTION,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": "Outpost %d" % int(site_counter[SITE_EXTRACTION]),
			"position": descriptor.get("world_center", Vector3.ZERO) + Vector3(rng.randf_range(-4.0, 4.0), 0.0, rng.randf_range(-4.0, 4.0)),
			"radius": 4.9,
			"duration": 1.6,
			"reveal_radius": EXTRACTION_REVEAL_RADIUS,
			"revealed": false,
		}
		descriptor["is_extraction_chunk"] = true
		extraction_sites.append(extraction_site)
		used_coords[_coord_key(coord)] = true

	var salvage_count := rng.randi_range(4, 6)
	var distress_count := rng.randi_range(1, 2)
	var resupply_count := rng.randi_range(1, 2)
	var salvage_coords := _pick_salvage_chunks(descriptors, spawn_chunk, salvage_count, used_coords, rng)
	var distress_coords := _pick_distress_chunks(descriptors, spawn_chunk, distress_count, used_coords, rng)
	var resupply_coords := _pick_resupply_chunks(descriptors, spawn_chunk, resupply_count, used_coords, rng)

	for coord_variant in salvage_coords:
		var coord := _coord_from_variant(coord_variant)
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		if descriptor.is_empty():
			continue
		site_counter[SITE_SALVAGE] = int(site_counter.get(SITE_SALVAGE, 0)) + 1
		var site_id := "salvage_%d" % int(site_counter[SITE_SALVAGE])
		var loot_count := 2 if float(descriptor.get("richness_level", 0.5)) >= 0.62 else 1
		var site := {
			"id": site_id,
			"site_type": SITE_SALVAGE,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": _salvage_label_for_biome(str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)), int(site_counter[SITE_SALVAGE])),
			"position": descriptor.get("world_center", Vector3.ZERO) + Vector3(rng.randf_range(-3.2, 3.2), 0.0, rng.randf_range(-3.2, 3.2)),
			"radius": 4.4,
			"max_speed": 1.55,
			"loot_count": loot_count,
		}
		descriptor["poi_id"] = site_id
		poi_sites.append(site)
		used_coords[_coord_key(coord)] = true

	for coord_variant in distress_coords:
		var coord := _coord_from_variant(coord_variant)
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		if descriptor.is_empty():
			continue
		site_counter[SITE_DISTRESS] = int(site_counter.get(SITE_DISTRESS, 0)) + 1
		var site_id := "distress_%d" % int(site_counter[SITE_DISTRESS])
		var site := {
			"id": site_id,
			"site_type": SITE_DISTRESS,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": _distress_label_for_index(int(site_counter[SITE_DISTRESS])),
			"position": descriptor.get("world_center", Vector3.ZERO) + Vector3(rng.randf_range(-2.8, 2.8), 0.0, rng.randf_range(-2.8, 2.8)),
			"radius": rng.randf_range(3.15, 3.85),
			"duration": rng.randf_range(1.6, 2.2),
			"max_speed": 1.25,
			"progress": 0.0,
			"engaged": false,
			"available": true,
			"completed": false,
			"bonus_gold": rng.randi_range(22, 34),
			"bonus_salvage": rng.randi_range(1, 2),
			"patch_kit_bonus": 1,
		}
		descriptor["poi_id"] = site_id
		poi_sites.append(site)
		used_coords[_coord_key(coord)] = true

	for coord_variant in resupply_coords:
		var coord := _coord_from_variant(coord_variant)
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		if descriptor.is_empty():
			continue
		site_counter[SITE_RESUPPLY] = int(site_counter.get(SITE_RESUPPLY, 0)) + 1
		var site_id := "resupply_%d" % int(site_counter[SITE_RESUPPLY])
		var site := {
			"id": site_id,
			"site_type": SITE_RESUPPLY,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": "Resupply Cache %d" % int(site_counter[SITE_RESUPPLY]),
			"position": descriptor.get("world_center", Vector3.ZERO) + Vector3(rng.randf_range(-2.2, 2.2), 0.0, rng.randf_range(-2.2, 2.2)),
			"radius": 4.3,
			"max_speed": 8.0,
			"available": true,
			"recovered": false,
			"bonus_gold": 18,
			"bonus_salvage": 1,
			"supply_grant": 1,
		}
		descriptor["poi_id"] = site_id
		poi_sites.append(site)
		used_coords[_coord_key(coord)] = true

	var hazard_fields := _build_hazard_fields(descriptors, rng)
	var world_label := "Open Sea %s | %d salvage, %d rescue, %d cache, %d extraction" % [
		str(int(run_seed)),
		salvage_coords.size(),
		distress_coords.size(),
		resupply_coords.size(),
		extraction_sites.size(),
	]
	return {
		"world_bounds_chunks": [WORLD_SIZE_CHUNKS, WORLD_SIZE_CHUNKS],
		"chunk_size_m": CHUNK_SIZE_M,
		"stream_radius_chunks": STREAM_RADIUS_CHUNKS,
		"spawn_chunk": spawn_chunk,
		"spawn_position": Vector3.ZERO,
		"chunk_descriptors": descriptors,
		"poi_sites": poi_sites,
		"extraction_sites": extraction_sites,
		"hazard_fields": hazard_fields,
		"world_label": world_label,
	}

static func _build_safe_fallback_world(run_seed: int) -> Dictionary:
	var descriptors: Array = []
	var spawn_chunk := [7, 7]
	for z in range(WORLD_SIZE_CHUNKS):
		for x in range(WORLD_SIZE_CHUNKS):
			var coord := [x, z]
			descriptors.append({
				"coord": coord,
				"biome_id": BIOME_OPEN_OCEAN if x > 0 and z > 0 and x < WORLD_SIZE_CHUNKS - 1 and z < WORLD_SIZE_CHUNKS - 1 else BIOME_STORM_BELT,
				"hazard_level": 0.18 if x > 0 and z > 0 and x < WORLD_SIZE_CHUNKS - 1 and z < WORLD_SIZE_CHUNKS - 1 else 1.0,
				"richness_level": 0.5,
				"props_seed": int(run_seed) * 101 + x * 17 + z * 37,
				"poi_id": "",
				"is_extraction_chunk": false,
				"is_border_chunk": x == 0 or z == 0 or x == WORLD_SIZE_CHUNKS - 1 or z == WORLD_SIZE_CHUNKS - 1,
				"is_blocked": x == 0 or z == 0 or x == WORLD_SIZE_CHUNKS - 1 or z == WORLD_SIZE_CHUNKS - 1,
				"world_center": _chunk_center_world_position(coord, spawn_chunk),
			})
	var descriptor_lookup := {}
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		descriptor_lookup[_coord_key(descriptor.get("coord", [0, 0]))] = descriptor
	var poi_sites: Array = []
	var salvage_coords := [[6, 5], [8, 5], [5, 8], [9, 8]]
	var distress_coords := [[10, 9]]
	var resupply_coords := [[11, 6]]
	var extraction_coord := [12, 12]
	var site_index := 0
	for coord_variant in salvage_coords:
		var coord := _coord_from_variant(coord_variant)
		site_index += 1
		var site_id := "salvage_%d" % site_index
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		descriptor["poi_id"] = site_id
		poi_sites.append({
			"id": site_id,
			"site_type": SITE_SALVAGE,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": "Fallback Wreck %d" % site_index,
			"position": descriptor.get("world_center", Vector3.ZERO),
			"radius": 4.4,
			"max_speed": 1.55,
			"loot_count": 1,
		})
	for coord_variant in distress_coords:
		var coord := _coord_from_variant(coord_variant)
		site_index += 1
		var site_id := "distress_1"
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		descriptor["poi_id"] = site_id
		poi_sites.append({
			"id": site_id,
			"site_type": SITE_DISTRESS,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": "Fallback Rescue",
			"position": descriptor.get("world_center", Vector3.ZERO),
			"radius": 3.4,
			"duration": 1.85,
			"max_speed": 1.25,
			"progress": 0.0,
			"engaged": false,
			"available": true,
			"completed": false,
			"bonus_gold": 24,
			"bonus_salvage": 1,
			"patch_kit_bonus": 1,
		})
	for coord_variant in resupply_coords:
		var coord := _coord_from_variant(coord_variant)
		var site_id := "resupply_1"
		var descriptor: Dictionary = descriptor_lookup.get(_coord_key(coord), {})
		descriptor["poi_id"] = site_id
		poi_sites.append({
			"id": site_id,
			"site_type": SITE_RESUPPLY,
			"coord": coord,
			"biome_id": str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
			"label": "Fallback Cache",
			"position": descriptor.get("world_center", Vector3.ZERO),
			"radius": 4.3,
			"max_speed": 8.0,
			"available": true,
			"recovered": false,
			"bonus_gold": 18,
			"bonus_salvage": 1,
			"supply_grant": 1,
		})
	var extraction_descriptor: Dictionary = descriptor_lookup.get(_coord_key(extraction_coord), {})
	extraction_descriptor["is_extraction_chunk"] = true
	var extraction_sites := [{
		"id": "extract_1",
		"site_type": SITE_EXTRACTION,
		"coord": extraction_coord,
		"biome_id": str(extraction_descriptor.get("biome_id", BIOME_OPEN_OCEAN)),
		"label": "Fallback Outpost",
		"position": extraction_descriptor.get("world_center", Vector3.ZERO),
		"radius": 4.9,
		"duration": 1.6,
		"reveal_radius": EXTRACTION_REVEAL_RADIUS,
		"revealed": false,
	}]
	return {
		"world_bounds_chunks": [WORLD_SIZE_CHUNKS, WORLD_SIZE_CHUNKS],
		"chunk_size_m": CHUNK_SIZE_M,
		"stream_radius_chunks": STREAM_RADIUS_CHUNKS,
		"spawn_chunk": spawn_chunk,
		"spawn_position": Vector3.ZERO,
		"chunk_descriptors": descriptors,
		"poi_sites": poi_sites,
		"extraction_sites": extraction_sites,
		"hazard_fields": [],
		"world_label": "Fallback Open Sea %s" % str(int(run_seed)),
		"generation_retry_index": -1,
	}

static func _make_noise(seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = frequency
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.55
	noise.fractal_lacunarity = 2.0
	return noise

static func _resolve_biome_id(biome_value: float, hazard_value: float, richness_value: float) -> String:
	if hazard_value >= 0.76:
		return BIOME_STORM_BELT
	if biome_value <= -0.38:
		return BIOME_REEF_WATERS
	if biome_value >= 0.42:
		return BIOME_GRAVEYARD_WATERS
	if richness_value <= 0.24:
		return BIOME_FOG_BANK
	return BIOME_OPEN_OCEAN

static func _select_spawn_chunk(descriptors: Array, rng: RandomNumberGenerator) -> Array:
	var candidates: Array = []
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		var coord := _coord_from_variant(descriptor.get("coord", [7, 7]))
		if coord.x < 5 or coord.x > 10 or coord.y < 5 or coord.y > 10:
			continue
		if bool(descriptor.get("is_blocked", false)):
			continue
		if str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)) != BIOME_OPEN_OCEAN:
			continue
		candidates.append(descriptor)
	if candidates.is_empty():
		return [7, 7]
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var coord_a := _coord_from_variant(a.get("coord", [7, 7]))
		var coord_b := _coord_from_variant(b.get("coord", [7, 7]))
		var score_a: float = float(a.get("hazard_level", 0.0)) + Vector2(coord_a.x - 7.5, coord_a.y - 7.5).length() * 0.08
		var score_b: float = float(b.get("hazard_level", 0.0)) + Vector2(coord_b.x - 7.5, coord_b.y - 7.5).length() * 0.08
		return score_a < score_b
	)
	var pick_pool := mini(4, candidates.size())
	var picked: Dictionary = candidates[int(rng.randi() % pick_pool)]
	return picked.get("coord", [7, 7])

static func _pick_extraction_chunks(descriptors: Array, spawn_chunk: Array, rng: RandomNumberGenerator) -> Array:
	var candidates: Array = []
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		var coord := _coord_from_variant(descriptor.get("coord", [0, 0]))
		if bool(descriptor.get("is_border_chunk", false)):
			continue
		if bool(descriptor.get("is_blocked", false)):
			continue
		if _distance_to_world_edge(coord) > 2:
			continue
		if _chunk_distance(coord, _coord_from_variant(spawn_chunk)) < 5.5:
			continue
		if str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)) == BIOME_STORM_BELT:
			continue
		if _count_navigable_neighbors(coord, descriptors) < 2:
			continue
		candidates.append(descriptor)
	candidates.shuffle()
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var coord_a := _coord_from_variant(a.get("coord", [0, 0]))
		var coord_b := _coord_from_variant(b.get("coord", [0, 0]))
		var score_a: float = _chunk_distance(coord_a, _coord_from_variant(spawn_chunk)) - float(a.get("hazard_level", 0.0)) * 2.0
		var score_b: float = _chunk_distance(coord_b, _coord_from_variant(spawn_chunk)) - float(b.get("hazard_level", 0.0)) * 2.0
		return score_a > score_b
	)
	var picked: Array = []
	for descriptor_variant in candidates:
		var descriptor: Dictionary = descriptor_variant
		var coord := _coord_from_variant(descriptor.get("coord", [0, 0]))
		var allowed := true
		for picked_variant in picked:
			var picked_coord := _coord_from_variant(picked_variant)
			if _chunk_distance(coord, picked_coord) < MIN_EXTRACTION_SPACING_CHUNKS:
				allowed = false
				break
		if not allowed:
			continue
		picked.append([coord.x, coord.y])
		if picked.size() >= EXTRACTION_TARGET_COUNT:
			break
	if picked.is_empty():
		picked.append([12, 12])
	return picked

static func _pick_salvage_chunks(descriptors: Array, spawn_chunk: Array, target_count: int, used_coords: Dictionary, rng: RandomNumberGenerator) -> Array:
	var preferred := [BIOME_REEF_WATERS, BIOME_GRAVEYARD_WATERS, BIOME_OPEN_OCEAN]
	return _pick_poi_chunks(descriptors, spawn_chunk, target_count, used_coords, preferred, func(descriptor: Dictionary, coord: Vector2i) -> bool:
		if bool(descriptor.get("is_blocked", false)) or bool(descriptor.get("is_border_chunk", false)):
			return false
		var hazard_level := float(descriptor.get("hazard_level", 0.0))
		return hazard_level >= 0.22 and hazard_level <= 0.82 and _chunk_distance(coord, _coord_from_variant(spawn_chunk)) >= 2.0
	, rng)

static func _pick_distress_chunks(descriptors: Array, spawn_chunk: Array, target_count: int, used_coords: Dictionary, rng: RandomNumberGenerator) -> Array:
	var preferred := [BIOME_OPEN_OCEAN, BIOME_FOG_BANK, BIOME_GRAVEYARD_WATERS]
	return _pick_poi_chunks(descriptors, spawn_chunk, target_count, used_coords, preferred, func(descriptor: Dictionary, coord: Vector2i) -> bool:
		if bool(descriptor.get("is_blocked", false)) or bool(descriptor.get("is_border_chunk", false)):
			return false
		var distance := _chunk_distance(coord, _coord_from_variant(spawn_chunk))
		return distance >= 4.0 and distance <= 8.8
	, rng)

static func _pick_resupply_chunks(descriptors: Array, spawn_chunk: Array, target_count: int, used_coords: Dictionary, rng: RandomNumberGenerator) -> Array:
	var preferred := [BIOME_OPEN_OCEAN, BIOME_FOG_BANK]
	return _pick_poi_chunks(descriptors, spawn_chunk, target_count, used_coords, preferred, func(descriptor: Dictionary, coord: Vector2i) -> bool:
		if bool(descriptor.get("is_blocked", false)) or bool(descriptor.get("is_border_chunk", false)):
			return false
		var distance := _chunk_distance(coord, _coord_from_variant(spawn_chunk))
		var hazard_level := float(descriptor.get("hazard_level", 0.0))
		return distance >= 5.0 and distance <= 10.5 and hazard_level <= 0.58
	, rng)

static func _pick_poi_chunks(descriptors: Array, spawn_chunk: Array, target_count: int, used_coords: Dictionary, preferred_biomes: Array, predicate: Callable, rng: RandomNumberGenerator) -> Array:
	var scored: Array = []
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		var coord := _coord_from_variant(descriptor.get("coord", [0, 0]))
		if used_coords.has(_coord_key(coord)):
			continue
		if not predicate.call(descriptor, coord):
			continue
		var biome_bonus := 0.0 if preferred_biomes.has(str(descriptor.get("biome_id", BIOME_OPEN_OCEAN))) else 1.5
		var hazard_bias := absf(float(descriptor.get("hazard_level", 0.5)) - 0.48)
		var score := biome_bonus + hazard_bias + rng.randf_range(0.0, 0.12)
		scored.append({
			"coord": [coord.x, coord.y],
			"score": score,
		})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) < float(b.get("score", 0.0))
	)
	var picked: Array = []
	for entry_variant in scored:
		var entry: Dictionary = entry_variant
		var coord := _coord_from_variant(entry.get("coord", [0, 0]))
		var allowed := true
		for picked_variant in picked:
			var picked_coord := _coord_from_variant(picked_variant)
			if _chunk_distance(coord, picked_coord) < MIN_POI_SPACING_CHUNKS:
				allowed = false
				break
		if not allowed:
			continue
		picked.append([coord.x, coord.y])
		used_coords[_coord_key(coord)] = true
		if picked.size() >= target_count:
			break
	return picked

static func _build_hazard_fields(descriptors: Array, rng: RandomNumberGenerator) -> Array:
	var hazard_fields: Array = []
	var field_index := 0
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		if str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)) != BIOME_STORM_BELT:
			continue
		if bool(descriptor.get("is_border_chunk", false)):
			continue
		if int(descriptor.get("props_seed", 0)) % 3 != 0:
			continue
		field_index += 1
		var center: Vector3 = descriptor.get("world_center", Vector3.ZERO)
		hazard_fields.append({
			"id": field_index,
			"center": center,
			"half_extents": Vector3(CHUNK_SIZE_M * rng.randf_range(0.45, 0.85), 0.0, CHUNK_SIZE_M * rng.randf_range(0.42, 0.72)),
			"label": "Squall Front",
			"drag_multiplier": rng.randf_range(0.60, 0.82),
			"pulse_interval": rng.randf_range(2.1, 2.9),
			"pulse_timer": rng.randf_range(0.6, 1.8),
			"pulse_damage": rng.randf_range(3.4, 5.6),
			"biome_id": BIOME_STORM_BELT,
		})
	return hazard_fields

static func _validate_world_layout(layout: Dictionary) -> bool:
	var descriptors: Array = Array(layout.get("chunk_descriptors", []))
	var spawn_chunk := _coord_from_variant(layout.get("spawn_chunk", [7, 7]))
	var extractions: Array = Array(layout.get("extraction_sites", []))
	if descriptors.is_empty() or extractions.is_empty():
		return false
	var descriptor_lookup := {}
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		descriptor_lookup[_coord_key(descriptor.get("coord", [0, 0]))] = descriptor
	var spawn_descriptor: Dictionary = descriptor_lookup.get(_coord_key(spawn_chunk), {})
	if spawn_descriptor.is_empty():
		return false
	if bool(spawn_descriptor.get("is_blocked", false)):
		return false
	if str(spawn_descriptor.get("biome_id", BIOME_OPEN_OCEAN)) != BIOME_OPEN_OCEAN:
		return false
	if float(spawn_descriptor.get("hazard_level", 1.0)) > 0.45:
		return false
	var reachable_extractions := 0
	for extraction_variant in extractions:
		var extraction: Dictionary = extraction_variant
		var extraction_coord := _coord_from_variant(extraction.get("coord", [0, 0]))
		if _compute_route_cost(spawn_chunk, extraction_coord, descriptor_lookup) <= MAX_ROUTE_HAZARD_COST:
			reachable_extractions += 1
	if reachable_extractions <= 0:
		return false
	return true

static func _compute_route_cost(spawn_chunk: Vector2i, target_chunk: Vector2i, descriptor_lookup: Dictionary) -> float:
	if spawn_chunk == target_chunk:
		return 0.0
	var open: Array = [{
		"coord": [spawn_chunk.x, spawn_chunk.y],
		"cost": 0.0,
	}]
	var best_costs := {
		_coord_key(spawn_chunk): 0.0,
	}
	while not open.is_empty():
		open.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("cost", 0.0)) < float(b.get("cost", 0.0))
		)
		var current: Dictionary = open.pop_front()
		var current_coord := _coord_from_variant(current.get("coord", [0, 0]))
		var current_cost := float(current.get("cost", 0.0))
		if current_coord == target_chunk:
			return current_cost
		for neighbor in _neighbor_coords(current_coord):
			var descriptor: Dictionary = descriptor_lookup.get(_coord_key(neighbor), {})
			if descriptor.is_empty():
				continue
			if bool(descriptor.get("is_blocked", false)):
				continue
			var move_cost := 1.0 + float(descriptor.get("hazard_level", 0.0)) * 2.2
			if str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)) == BIOME_STORM_BELT:
				move_cost += 1.4
			elif str(descriptor.get("biome_id", BIOME_OPEN_OCEAN)) == BIOME_FOG_BANK:
				move_cost += 0.35
			var total_cost: float = current_cost + move_cost
			var neighbor_key := _coord_key(neighbor)
			if total_cost >= float(best_costs.get(neighbor_key, INF)):
				continue
			best_costs[neighbor_key] = total_cost
			open.append({
				"coord": [neighbor.x, neighbor.y],
				"cost": total_cost,
			})
	return INF

static func _chunk_center_world_position(coord_value: Variant, spawn_chunk_value: Variant) -> Vector3:
	var coord := _coord_from_variant(coord_value)
	var spawn_chunk := _coord_from_variant(spawn_chunk_value)
	return Vector3(
		float(coord.x - spawn_chunk.x) * CHUNK_SIZE_M,
		0.0,
		float(coord.y - spawn_chunk.y) * CHUNK_SIZE_M
	)

static func _distance_to_world_edge(coord: Vector2i) -> int:
	return mini(mini(coord.x, coord.y), mini(WORLD_SIZE_CHUNKS - 1 - coord.x, WORLD_SIZE_CHUNKS - 1 - coord.y))

static func _count_navigable_neighbors(coord: Vector2i, descriptors: Array) -> int:
	var lookup := {}
	for descriptor_variant in descriptors:
		var descriptor: Dictionary = descriptor_variant
		lookup[_coord_key(descriptor.get("coord", [0, 0]))] = descriptor
	var count := 0
	for neighbor in _neighbor_coords(coord):
		var descriptor: Dictionary = lookup.get(_coord_key(neighbor), {})
		if descriptor.is_empty():
			continue
		if bool(descriptor.get("is_blocked", false)):
			continue
		count += 1
	return count

static func _neighbor_coords(coord: Vector2i) -> Array:
	return [
		Vector2i(coord.x + 1, coord.y),
		Vector2i(coord.x - 1, coord.y),
		Vector2i(coord.x, coord.y + 1),
		Vector2i(coord.x, coord.y - 1),
	]

static func _chunk_distance(a_value: Variant, b_value: Variant) -> float:
	var a := _coord_from_variant(a_value)
	var b := _coord_from_variant(b_value)
	return Vector2(float(a.x - b.x), float(a.y - b.y)).length()

static func _coord_from_variant(coord_value: Variant) -> Vector2i:
	if coord_value is Vector2i:
		return coord_value
	if coord_value is Array and coord_value.size() >= 2:
		return Vector2i(int(coord_value[0]), int(coord_value[1]))
	if coord_value is Vector2:
		return Vector2i(int(coord_value.x), int(coord_value.y))
	return Vector2i.ZERO

static func _coord_key(coord_value: Variant) -> String:
	var coord := _coord_from_variant(coord_value)
	return "%d:%d" % [coord.x, coord.y]

static func _salvage_label_for_biome(biome_id: String, index: int) -> String:
	match biome_id:
		BIOME_REEF_WATERS:
			return "Reef Wreck %d" % index
		BIOME_GRAVEYARD_WATERS:
			return "Graveyard Hull %d" % index
		_:
			return "Open Drift Wreck %d" % index

static func _distress_label_for_index(index: int) -> String:
	match index % 3:
		0:
			return "Smoke Signal"
		1:
			return "Broken Skiff"
		_:
			return "Distress Flare"
