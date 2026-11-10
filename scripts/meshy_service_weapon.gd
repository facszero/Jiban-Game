extends "res://scripts/service_weapon.gd"
var imported_visual: Node3D
func _ready() -> void:
	include_pistol_mesh=false
	super._ready()
	imported_visual=preload("res://assets/service_pistol/service_pistol.glb").instantiate()
	imported_visual.name="MeshyServicePistol"
	imported_visual.scale=Vector3.ONE*.15
	imported_visual.rotation.y=-PI/2
	imported_visual.position=Vector3(0,-.0535,-.04)
	add_child(imported_visual)
	apply_material(imported_visual)
	# Calibrated against the imported barrel ring, in this weapon's local space.
	muzzle.position=Vector3(0,.020,-.184)
func apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source=node.get_active_material(surface)
			if source is StandardMaterial3D:
				var material := ShaderMaterial.new()
				material.shader=preload("res://shaders/service_pistol.gdshader")
				material.set_shader_parameter("color_map",source.albedo_texture)
				material.set_shader_parameter("normal_map",source.normal_texture)
				material.set_shader_parameter("orm_map",source.roughness_texture)
				node.set_surface_override_material(surface,material)
	for child in node.get_children():apply_material(child)
