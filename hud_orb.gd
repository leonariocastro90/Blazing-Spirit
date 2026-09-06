extends Control

@export var fill_color := Color("df3e52")
@export var glow_color := Color("ff8794")
@export var caption := "VIDA"
var value := 100.0
var maximum := 100.0

func set_value(current: float, max_value: float) -> void:
	value = current
	maximum = maxf(max_value, 1.0)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.46)
	var radius := minf(size.x, size.y) * 0.36
	draw_circle(center, radius + 6.0, Color(0.03,0.04,0.09,0.96))
	draw_arc(center, radius + 5.0, 0, TAU, 48, Color("d9b45f"), 3.0, true)
	var ratio := clampf(value / maximum, 0.0, 1.0)
	var liquid_radius := radius * sqrt(ratio)
	if ratio > 0.0:
		draw_circle(center + Vector2(0, radius - liquid_radius), liquid_radius, Color(fill_color, 0.92))
		draw_circle(center + Vector2(-radius*0.25, radius-liquid_radius-radius*0.18), radius*0.10, Color(glow_color,0.75))
	draw_string(ThemeDB.fallback_font, center + Vector2(-25, 5), "%d" % int(value), HORIZONTAL_ALIGNMENT_CENTER, 50, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(0,size.y-3), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("f2dcaa"))
