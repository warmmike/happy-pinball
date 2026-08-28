extends Label

func _ready():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.1, 0.5)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
