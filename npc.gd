extends Node2D

var sprite: Sprite2D
var frame_cursor := 0.0

func setup(character_name: String, texture_path: String) -> void:
	sprite = Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 256, 256)
	sprite.scale = Vector2(0.42, 0.42)
	sprite.position.y = -50
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/checker_mask.gdshader")
	sprite.material = material
	add_child(sprite)
	var label := Label.new()
	label.text = character_name
	label.position = Vector2(-48, 6)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)

func _process(delta: float) -> void:
	if sprite == null: return
	frame_cursor = fmod(frame_cursor + delta * 5.0, 6.0)
	sprite.region_rect = Rect2(int(frame_cursor) * 256, 0, 256, 256)

