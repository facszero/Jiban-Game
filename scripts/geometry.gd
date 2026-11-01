extends RefCounted

static func material(color: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic * 0.65
	m.roughness = 0.35 if metallic > 0.0 else 0.8
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(node)
	node.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	node.add_child(mesh)
	if solid:
		var col := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		col.shape = bounds
		node.add_child(col)
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

static func light(parent: Node3D, pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	parent.add_child(lamp)
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	return lamp

static func label(parent: Node3D, pos: Vector3, text: String, size: int = 48) -> Label3D:
	var sign := Label3D.new()
	parent.add_child(sign)
	sign.position = pos
	sign.text = text
	sign.font_size = size
	sign.pixel_size = 0.008
	sign.modulate = Color(0.55, 0.8, 0.9)
	return sign

# Low-poly ellipsoids keep organic silhouettes inexpensive on mobile.
static func ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	node.material_override = mat
	parent.add_child(node)
	node.position = pos
	node.scale = size
	return node

static func link(parent: Node3D, start: Vector3, end: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var node := cylinder(parent, (start + end) * 0.5, radius, start.distance_to(end), mat)
	var axis := (end - start).normalized()
	if absf(axis.dot(Vector3.UP)) < 0.999:
		node.quaternion = Quaternion(Vector3.UP, axis)
	return node
