extends RefCounted
static func apply(environment: Environment) -> void:
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color=Color(.55,.60,.68)
	material.sky_horizon_color=Color(.8,.8,.8)
	material.ground_bottom_color=Color(.18,.19,.22)
	material.ground_horizon_color=Color(.8,.8,.8)
	sky.sky_material=material
	environment.sky=sky
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
