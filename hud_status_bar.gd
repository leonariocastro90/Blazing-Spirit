extends Control

@export var caption := "HP"
@export var value := 100.0
@export var max_value := 100.0
@export var fill_color := Color("e94a32")
@export var highlight_color := Color("ff9b68")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_value(new_value: float, new_max: float) -> void:
	value = clampf(new_value, 0.0, new_max)
	max_value = maxf(new_max, 1.0)
	queue_redraw()

func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	var bar_rect := Rect2(3, 5, size.x - 6, size.y - 8)
	var inner := Rect2(7, 9, size.x - 14, size.y - 16)
	var ratio := clampf(value / max_value, 0.0, 1.0)
	# Marco grueso tipo MMORPG clásico.
	draw_style_box(_box(Color("111722"), Color("030508"), 3, 5), full)
	draw_style_box(_box(Color("c99b3c"), Color("f4d675"), 1, 3), bar_rect)
	draw_style_box(_box(Color("242b35"), Color("080b0f"), 1, 2), inner)
	var fill_rect := Rect2(inner.position + Vector2(2, 2), Vector2((inner.size.x - 4) * ratio, inner.size.y - 4))
	if fill_rect.size.x > 0.0:
		draw_rect(fill_rect, fill_color)
		draw_rect(Rect2(fill_rect.position, Vector2(fill_rect.size.x, maxf(2.0, fill_rect.size.y * 0.32))), highlight_color)
	var font := ThemeDB.fallback_font
	var baseline := size.y * 0.68
	draw_string(font, Vector2(10, baseline), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var amount := "%d / %d" % [roundi(value), roundi(max_value)]
	draw_string(font, Vector2(70, baseline), amount, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 82, 14, Color.WHITE)

func _box(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
