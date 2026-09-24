@tool
class_name MultiMeshInstaceHexTiller
extends MultiMeshInstance3D

@export var columns := 20
@export var rows := 20
@export var hex_radius := 1.0
@export var height := 1.0

@export var RunGenerate : bool = false:
	set(_val):
		_build()
		return false

func _build() -> void:
	var mm : MultiMesh
	if self.multimesh:
		mm = self.multimesh
	else:
		mm = MultiMesh.new()

	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = columns * rows
	var i := 0

	var hex_rotation := Basis(Vector3.UP, PI / 6.0)

	for column in columns:
		for row in rows:
			var x := column * hex_radius * 1.5
			var z := row * hex_radius * sqrt(3.0)

			if column & 1:
				z += hex_radius * sqrt(3.0) * 0.5

			var transform := Transform3D(
				hex_rotation.scaled(Vector3(1.0, height, 1.0)),
				Vector3(x, 0.0, z)
			)

			mm.set_instance_transform(i, transform)
			i += 1
	multimesh = mm
