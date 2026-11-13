extends RefCounted
static var cache: Dictionary = {}
static func metal(kind: String = "steel") -> StandardMaterial3D:
	if cache.has(kind): return cache[kind]
	var m := StandardMaterial3D.new()
	m.albedo_texture = preload("res://assets/environment/wall_panel.png") if kind == "wall" else (preload("res://assets/environment/floor_plate.png") if kind == "floor" else preload("res://assets/environment/steel_color.png"))
	m.normal_enabled = kind == "steel"
	if kind == "steel": m.normal_texture = preload("res://assets/environment/steel_normal.png")
	m.normal_scale = .8
	m.roughness_texture = load("res://assets/environment/"+kind+"_rough.png")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = .48 if kind == "floor" else .85
	m.metallic = .55 if kind == "floor" else .55
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * (.5 if kind != "steel" else 1.2)
	cache[kind] = m
	return m
static func screen() -> StandardMaterial3D:
	if cache.has("screen"): return cache.screen
	var m := StandardMaterial3D.new()
	m.albedo_texture = preload("res://assets/environment/console.png")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = false
	m.emission_texture = m.albedo_texture
	m.emission = Color.WHITE
	m.emission_energy_multiplier = .7
	m.roughness = .32
	cache.screen = m
	return m
