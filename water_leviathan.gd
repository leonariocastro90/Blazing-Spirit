extends Node2D

signal blast_requested(damage: int, origin: Vector2, facing: float, reach: float, vertical_tolerance: float)
signal rain_pulse_requested(damage: int, center: Vector2, radius: float)

const SUMMON_TEXTURE := preload("res://assets/summons/water_leviathan/water_leviathan_v2.png")
const CREATURE_SCALE := 0.125
const JET_REACH := 320.0
const RAIN_RADIUS := 150.0

var damage := 1
var cast_origin := Vector2.ZERO
var facing := 1.0
var life_time := 0.0
var leviathan: Sprite2D
var aura_root: Node2D
var rain_marker: Node2D
var jet_line: Line2D
var jet_core: Line2D
var jet_progress := 0.0
var jet_active := false

func setup(new_damage: int, origin: Vector2, direction: float) -> void:
	damage = new_damage
	cast_origin = origin
	facing = -1.0 if direction < 0.0 else 1.0
	global_position = cast_origin + Vector2(facing * 50.0, -136.0)

func _ready() -> void:
	z_index = 20
	_create_ground_seal()
	_create_invocation_aura()
	_create_leviathan()
	_spawn_summon_motes()
	_summon_sequence()

func _process(delta: float) -> void:
	life_time += delta
	if aura_root != null:
		aura_root.rotation += delta * 0.65 * facing
	if leviathan != null:
		# Dos ritmos superpuestos evitan el movimiento mecánico de arriba/abajo.
		leviathan.position.y = sin(life_time * 5.1) * 3.2 + sin(life_time * 8.7) * 1.1
		leviathan.position.x = sin(life_time * 3.4) * 2.0 * facing
		leviathan.rotation = (sin(life_time * 4.2) * 0.018 + sin(life_time * 2.1) * 0.012) * facing
	if jet_active:
		_update_water_jet()

func _create_leviathan() -> void:
	leviathan = Sprite2D.new()
	leviathan.texture = SUMMON_TEXTURE
	leviathan.scale = Vector2(0.018, 0.018)
	leviathan.position = Vector2(-facing * 34.0, 22.0)
	leviathan.rotation = -0.16 * facing
	leviathan.flip_h = facing < 0.0
	leviathan.modulate = Color(0.45, 0.92, 1.0, 0.0)
	leviathan.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leviathan.z_index = 4
	add_child(leviathan)

func _create_ground_seal() -> void:
	rain_marker = Node2D.new()
	rain_marker.position = Vector2(facing * 228.0, 136.0)
	rain_marker.scale = Vector2(0.62, 0.62)
	rain_marker.modulate.a = 0.0
	rain_marker.z_index = -2
	add_child(rain_marker)
	var outer := _ellipse_line(RAIN_RADIUS, 25.0, 4.0, Color(0.20, 0.86, 1.0, 0.78))
	rain_marker.add_child(outer)
	var inner := _ellipse_line(104.0, 17.0, 2.0, Color(0.72, 0.98, 1.0, 0.62))
	rain_marker.add_child(inner)
	for rune_index in range(10):
		var angle := TAU * float(rune_index) / 10.0
		var tick := Line2D.new()
		tick.width = 3.0
		tick.default_color = Color(0.45, 0.94, 1.0, 0.76)
		var start := Vector2(cos(angle) * 112.0, sin(angle) * 18.0)
		var finish := Vector2(cos(angle) * 141.0, sin(angle) * 23.0)
		tick.points = PackedVector2Array([start, finish])
		rain_marker.add_child(tick)
	var marker_tween := create_tween()
	marker_tween.set_parallel(true)
	marker_tween.tween_property(rain_marker, "modulate:a", 1.0, 0.28)
	marker_tween.tween_property(rain_marker, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _create_invocation_aura() -> void:
	aura_root = Node2D.new()
	aura_root.position = Vector2(0, 58)
	aura_root.scale = Vector2(0.24, 0.24)
	aura_root.modulate.a = 0.0
	aura_root.z_index = -1
	add_child(aura_root)
	var halo := _ellipse_line(82.0, 20.0, 5.0, Color(0.30, 0.92, 1.0, 0.90))
	aura_root.add_child(halo)
	var halo_inner := _ellipse_line(55.0, 13.0, 2.5, Color(0.88, 1.0, 1.0, 0.82))
	aura_root.add_child(halo_inner)
	for rune_index in range(8):
		var angle := TAU * float(rune_index) / 8.0
		var rune := Polygon2D.new()
		rune.polygon = PackedVector2Array([Vector2(0,-7), Vector2(5,0), Vector2(0,7), Vector2(-5,0)])
		rune.color = Color(0.55, 0.98, 1.0, 0.92)
		rune.position = Vector2(cos(angle) * 68.0, sin(angle) * 17.0)
		rune.rotation = angle
		aura_root.add_child(rune)
	var light_column := Polygon2D.new()
	light_column.polygon = PackedVector2Array([Vector2(-54,12), Vector2(-20,-175), Vector2(20,-175), Vector2(54,12)])
	light_column.color = Color(0.26, 0.82, 1.0, 0.14)
	light_column.z_index = -3
	aura_root.add_child(light_column)
	var aura_tween := create_tween()
	aura_tween.set_parallel(true)
	aura_tween.tween_property(aura_root, "modulate:a", 1.0, 0.18)
	aura_tween.tween_property(aura_root, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _ellipse_line(radius_x: float, radius_y: float, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	for point_index in range(41):
		var angle := TAU * float(point_index) / 40.0
		line.add_point(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return line

func _ellipse_polygon(radius_x: float, radius_y: float, color: Color) -> Polygon2D:
	var shape := Polygon2D.new()
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	shape.polygon = points
	shape.color = color
	return shape

func _spawn_summon_motes() -> void:
	for mote_index in range(18):
		var angle := TAU * float(mote_index) / 18.0
		var mote := Polygon2D.new()
		var size := 2.5 + float(mote_index % 3)
		mote.polygon = PackedVector2Array([Vector2(0,-size * 1.7), Vector2(size,0), Vector2(0,size * 1.7), Vector2(-size,0)])
		mote.color = Color(0.56, 0.96, 1.0, 0.88)
		mote.position = Vector2(cos(angle) * (42.0 + mote_index % 4 * 10.0), sin(angle) * 26.0 + 24.0)
		mote.modulate.a = 0.0
		mote.z_index = 3
		add_child(mote)
		var destination := mote.position + Vector2(cos(angle + 0.65) * 32.0, -55.0 - float(mote_index % 5) * 8.0)
		var tween := create_tween()
		tween.tween_interval(float(mote_index % 6) * 0.025)
		tween.tween_property(mote, "modulate:a", 1.0, 0.09)
		tween.tween_property(mote, "position", destination, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(mote, "modulate:a", 0.0, 0.32).set_delay(0.18)
		tween.tween_callback(mote.queue_free)

func _summon_sequence() -> void:
	var arrival := create_tween()
	arrival.set_parallel(true)
	arrival.tween_property(leviathan, "scale", Vector2(CREATURE_SCALE, CREATURE_SCALE), 0.40).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrival.tween_property(leviathan, "position:x", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arrival.tween_property(leviathan, "rotation", 0.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrival.tween_property(leviathan, "modulate", Color.WHITE, 0.20)
	await get_tree().create_timer(0.26).timeout
	if not is_inside_tree(): return
	_spawn_entry_echo()
	await get_tree().create_timer(0.18).timeout
	if not is_inside_tree(): return
	_fire_water_jet()
	await get_tree().create_timer(0.22).timeout
	if not is_inside_tree(): return
	_start_local_rain()
	await get_tree().create_timer(1.02).timeout
	if not is_inside_tree(): return
	var departure := create_tween()
	departure.set_parallel(true)
	departure.tween_property(self, "modulate:a", 0.0, 0.30)
	departure.tween_property(leviathan, "scale", Vector2(0.075, 0.075), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	departure.tween_property(leviathan, "position:y", -24.0, 0.30)
	await get_tree().create_timer(0.34).timeout
	if is_inside_tree(): queue_free()

func _spawn_entry_echo() -> void:
	for echo_index in range(3):
		var echo := Sprite2D.new()
		echo.texture = SUMMON_TEXTURE
		echo.flip_h = facing < 0.0
		echo.scale = Vector2(CREATURE_SCALE, CREATURE_SCALE)
		echo.modulate = Color(0.32, 0.88, 1.0, 0.22 - echo_index * 0.045)
		echo.z_index = 2 - echo_index
		add_child(echo)
		var tween := create_tween()
		tween.tween_interval(echo_index * 0.035)
		tween.tween_property(echo, "scale", Vector2(CREATURE_SCALE * 1.18, CREATURE_SCALE * 1.18), 0.28)
		tween.parallel().tween_property(echo, "modulate:a", 0.0, 0.28)
		tween.tween_callback(echo.queue_free)

func _fire_water_jet() -> void:
	jet_line = Line2D.new()
	jet_line.width = 23.0
	jet_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	jet_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	jet_line.z_index = 1
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.92,1.0,1.0,0.98), Color(0.12,0.78,1.0,0.96), Color(0.10,0.36,1.0,0.08)])
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	jet_line.gradient = gradient
	add_child(jet_line)
	jet_core = Line2D.new()
	jet_core.width = 6.0
	jet_core.default_color = Color(0.94, 1.0, 1.0, 0.94)
	jet_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	jet_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	jet_core.z_index = 2
	add_child(jet_core)
	jet_active = true
	jet_progress = 0.02
	var jet_tween := create_tween()
	jet_tween.tween_property(self, "jet_progress", 1.0, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.11).timeout
	if not is_inside_tree(): return
	var mouth := global_position + Vector2(facing * 86.0, -8.0)
	blast_requested.emit(maxi(1, roundi(damage * 0.58)), mouth, facing, JET_REACH, 100.0)
	_spawn_jet_droplets()
	await get_tree().create_timer(0.24).timeout
	if not is_inside_tree(): return
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(jet_line, "modulate:a", 0.0, 0.17)
	fade.tween_property(jet_core, "modulate:a", 0.0, 0.13)
	await get_tree().create_timer(0.18).timeout
	jet_active = false

func _update_water_jet() -> void:
	if jet_line == null or jet_core == null: return
	var points := PackedVector2Array()
	var core_points := PackedVector2Array()
	var mouth := Vector2(facing * 86.0, -8.0)
	for point_index in range(15):
		var weight := float(point_index) / 14.0
		var travel := JET_REACH * jet_progress * weight
		var wave := sin(weight * TAU * 2.4 - life_time * 18.0) * (3.0 + weight * 7.0)
		var turbulence := sin(weight * TAU * 5.0 + life_time * 11.0) * weight * 2.5
		points.append(mouth + Vector2(facing * travel, wave + turbulence))
		core_points.append(mouth + Vector2(facing * travel, wave * 0.48 - turbulence * 0.25))
	jet_line.points = points
	jet_core.points = core_points

func _spawn_jet_droplets() -> void:
	for drop_index in range(14):
		var drop := Polygon2D.new()
		drop.polygon = PackedVector2Array([Vector2(-3,0), Vector2(0,-7), Vector2(3,0), Vector2(0,4)])
		drop.color = Color("68eaff") if drop_index % 2 == 0 else Color("ddffff")
		drop.position = Vector2(facing * (96.0 + drop_index * 19.0), -9.0 + (drop_index % 4) * 5.0)
		drop.z_index = 3
		add_child(drop)
		var destination := drop.position + Vector2(facing * (35.0 + drop_index * 2.0), -22.0 + (drop_index % 3) * 20.0)
		var tween := create_tween()
		tween.tween_property(drop, "position", destination, 0.25 + drop_index * 0.009).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(drop, "modulate:a", 0.0, 0.22).set_delay(0.08)
		tween.tween_callback(drop.queue_free)

func _start_local_rain() -> void:
	var rain_center := Vector2(facing * 228.0, 136.0)
	var cloud := Node2D.new()
	cloud.position = rain_center + Vector2(0, -180.0)
	cloud.modulate.a = 0.0
	cloud.z_index = 3
	add_child(cloud)
	var cloud_body := _ellipse_polygon(132.0, 25.0, Color(0.06, 0.34, 0.68, 0.25))
	cloud.add_child(cloud_body)
	var cloud_offsets := [-92.0, -47.0, -8.0, 36.0, 82.0]
	for cloud_index in range(cloud_offsets.size()):
		var puff := _ellipse_polygon(42.0 + float(cloud_index % 2) * 8.0, 16.0 + float(cloud_index % 3) * 3.0, Color(0.20, 0.68, 0.92, 0.26 + cloud_index * 0.018))
		puff.position = Vector2(cloud_offsets[cloud_index], sin(float(cloud_index) * 1.8) * 7.0)
		cloud.add_child(puff)
		var rim := _ellipse_line(38.0 + float(cloud_index % 2) * 8.0, 13.0 + float(cloud_index % 3) * 2.0, 1.5, Color(0.62, 0.96, 1.0, 0.16))
		rim.position = puff.position
		cloud.add_child(rim)
	var cloud_glow := _ellipse_line(126.0, 25.0, 7.0, Color(0.30, 0.84, 1.0, 0.18))
	cloud.add_child(cloud_glow)
	create_tween().tween_property(cloud, "modulate:a", 1.0, 0.16)
	for drop_index in range(46):
		_spawn_rain_drop(drop_index, rain_center)
	for pulse_index in range(3):
		await get_tree().create_timer(0.22).timeout
		if not is_inside_tree(): return
		var center_world := global_position + rain_center
		rain_pulse_requested.emit(maxi(1, roundi(damage * 0.24)), center_world, RAIN_RADIUS)
		_spawn_rain_splash(rain_center, pulse_index)
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(cloud, "modulate:a", 0.0, 0.20)
	fade.tween_property(rain_marker, "modulate:a", 0.0, 0.24)
	fade.tween_property(rain_marker, "scale", Vector2(1.10, 1.10), 0.24)

func _spawn_rain_drop(drop_index: int, center: Vector2) -> void:
	var column := float((drop_index * 67) % 281) - 140.0
	var start_height := -190.0 - float((drop_index * 23) % 75)
	var drop := Line2D.new()
	drop.width = 2.2 if drop_index % 3 else 3.5
	drop.default_color = Color(0.54, 0.92, 1.0, 0.78)
	drop.begin_cap_mode = Line2D.LINE_CAP_ROUND
	drop.end_cap_mode = Line2D.LINE_CAP_ROUND
	drop.points = PackedVector2Array([Vector2(0,-11), Vector2(facing * 4.0,8)])
	drop.position = center + Vector2(column, start_height)
	drop.modulate.a = 0.0
	drop.z_index = 2
	add_child(drop)
	var delay := float(drop_index % 13) * 0.035
	var fall_time := 0.30 + float(drop_index % 4) * 0.025
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(drop, "modulate:a", 1.0, 0.045)
	tween.tween_property(drop, "position:y", center.y - 2.0, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(drop, "position:x", drop.position.x + facing * 16.0, fall_time)
	tween.tween_property(drop, "modulate:a", 0.0, 0.06)
	tween.tween_callback(drop.queue_free)

func _spawn_rain_splash(center: Vector2, pulse_index: int) -> void:
	for splash_index in range(5):
		var spread := float((splash_index * 61 + pulse_index * 37) % 241) - 120.0
		var ring := _ellipse_line(18.0 + float(splash_index % 3) * 7.0, 4.0 + float(splash_index % 2) * 2.0, 3.0, Color(0.62, 0.96, 1.0, 0.82))
		ring.position = center + Vector2(spread, -2.0)
		ring.scale = Vector2(0.30, 0.30)
		ring.z_index = 3
		add_child(ring)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(1.9, 1.9), 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "modulate:a", 0.0, 0.23)
		get_tree().create_timer(0.24).timeout.connect(ring.queue_free)
	await get_tree().create_timer(0.26).timeout
