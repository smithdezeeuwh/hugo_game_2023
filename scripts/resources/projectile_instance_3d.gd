extends MeshInstance3D

var lifetime: float = 4.0
var last_position := Vector3.ZERO
var is_active: bool = true
var speed: float = 5.0
var damage: float = 1.0
var is_fired_by_enemy:bool = false
var dust_impact: PackedScene = load("res://scenes/effects/dust_impact.tscn")

func _physics_process(delta):
	# Get the last position of the bullet, from which we can draw the ray.
	last_position = transform.origin

	# Delete bullet if it's existed for too long.
	lifetime -= delta
	if lifetime < 0:
		# Delete the bullet and remove it from the array.
		queue_free()
	
	transform.origin = transform.origin + (-transform.basis.z * speed)
	var space_state = get_world_3d().direct_space_state
	var ray_parameters := PhysicsRayQueryParameters3D.create(
			last_position,
			transform.origin,) #TODO: collision mask, self

	var collision = space_state.intersect_ray(ray_parameters)
	if collision:
		#print("collision au")
		var impact
		# Spawn the hit effect a little bit away from the surface to reduce clipping.
		var impact_position = (collision.position) + (collision.normal * 0.2)
		var hit = collision.collider

		# Check if we hit an enemy, then damage them. Spawn the correct impact effect.
		if hit.is_in_group("Enemy"):
			#hit.damage(damage)
			hit.damage(20)

			#impact_effects.append(new_impact)
			var impact_transform = Transform3D(Basis(), collision.position)
			
			var new_impact: GPUParticles3D = instantiate_node(dust_impact, impact_transform)
			new_impact.emitting = true
		else:
			#"hit not enemy")
			#var impact_transform = Transform3D(collision.normal, collision.position)
			var impact_transform = Transform3D(Basis(), collision.position)
			
			var new_impact: GPUParticles3D = instantiate_node(dust_impact, impact_transform)
			new_impact.emitting = true
		# Delete the bullet and remove it from the array.
		queue_free()

func instantiate_node(packed_scene: PackedScene, p_transform: Transform3D) -> Node3D:
	var clone = packed_scene.instantiate()
	add_child(clone)
	clone.global_transform.origin = p_transform.origin
	
	return clone
