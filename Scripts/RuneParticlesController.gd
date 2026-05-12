extends CPUParticles2D
class_name RuneParticlesController

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(delete_me)

func delete_me() -> void:
	queue_free()
