extends CharacterBody2D

signal defeated(slime: CharacterBody2D, reward: int)
signal hit_player(damage: int)

const GRAVITY := 1450.0
const VISUAL_SCALE := 0.112
var health := 45
var max_health := 45
var level := 1
var target: CharacterBody2D
var hurt_cooldown := 0.0
var attack_cooldown := 0.0
var body_visual: Sprite2D
var normal_texture: Texture2D
var hurt_texture: Texture2D
var hp_bar: ProgressBar
var facing := 1.0
var displayed_facing := 1.0
var turn_target := 1.0
var turn_timer := 0.0
var movement_phase := 0.0
var patrol_direction := 1.0
var patrol_left := -INF
var patrol_right := INF
var attack_windup := 0.0
var hp_visible_timer := 0.0
var hurt_face_timer := 0.0
var impact_direction := 1.0
var defeated_state := false

func setup(new_level: int, player_target: CharacterBody2D, roaming_platform: Rect2 = Rect2()) -> void:
	level = new_level
	target = player_target
	max_health = 24 + level * 7
	health = max_health
	patrol_direction = -1.0 if level % 2 == 0 else 1.0
	if roaming_platform.size.x > 0.0:
		patrol_left = roaming_platform.position.x + 46.0
		patrol_right = roaming_platform.end.x - 46.0

func _ready() -> void:
	add_to_group("slimes")
	_create_visual()

func _create_visual() -> void:
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-42,-2), Vector2(42,-2), Vector2(31,6), Vector2(-31,6)])
	shadow.color = Color(0.02, 0.04, 0.08, 0.45)
	add_child(shadow)
	body_visual = Sprite2D.new()
	normal_texture = load("res://assets/enemies/slime_arcano_normal_v1.png")
	hurt_texture = load("res://assets/enemies/slime_arcano_hurt_v1.png")
	body_visual.texture = normal_texture
	body_visual.region_enabled = true
	body_visual.region_rect = Rect2(115, 135, 1025, 900)
	body_visual.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	# El recorte elimina casi todo el margen de la ilustración y fija la base
	# gelatinosa exactamente en y=0, que también es la base de la colisión.
	body_visual.position = Vector2(0, -47)
	body_visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	body_visual.modulate.a = 0.0
	add_child(body_visual)
	var reveal_tween := create_tween()
	reveal_tween.tween_property(body_visual, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var spawn_ring := Line2D.new()
	spawn_ring.width = 4.0
	spawn_ring.default_color = Color(0.30,0.94,1.0,0.82)
	spawn_ring.z_index = -1
	for point_index in range(25):
		var angle := TAU * float(point_index) / 24.0
		spawn_ring.add_point(Vector2(cos(angle) * 42.0, sin(angle) * 9.0 - 2.0))
	spawn_ring.scale = Vector2(0.18, 0.18)
	add_child(spawn_ring)
	var ring_tween := create_tween()
	ring_tween.tween_property(spawn_ring, "scale", Vector2(1.25,1.25), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(spawn_ring, "modulate:a", 0.0, 0.34)
	ring_tween.tween_callback(spawn_ring.queue_free)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 30
	capsule.height = 58
	shape.shape = capsule
	shape.position.y = -27
	add_child(shape)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(-38, -108)
	hp_bar.size = Vector2(76, 7)
	hp_bar.show_percentage = false
	hp_bar.max_value = max_health
	hp_bar.value = health
	hp_bar.visible = false
	var hp_background := StyleBoxFlat.new()
	hp_background.bg_color = Color(0.02,0.035,0.06,0.88)
	hp_background.border_color = Color(0.25,0.38,0.48,0.85)
	hp_background.set_border_width_all(1)
	hp_background.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", hp_background)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("61d978")
	hp_fill.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	add_child(hp_bar)

func _physics_process(delta: float) -> void:
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	hurt_face_timer = maxf(0.0, hurt_face_timer - delta)
	if hurt_face_timer <= 0.0 and body_visual.texture != normal_texture:
		body_visual.texture = normal_texture
	hp_visible_timer = maxf(0.0, hp_visible_timer - delta)
	if hp_bar != null: hp_bar.visible = hp_visible_timer > 0.0
	if not is_on_floor(): velocity.y += GRAVITY * delta
	if is_instance_valid(target):
		var distance := target.global_position.x - global_position.x
		var vertical_distance := target.global_position.y - global_position.y
		var aware_of_player := absf(distance) < 560.0 and absf(vertical_distance) < 230.0
		var same_floor := absf(vertical_distance) < 92.0
		# Mira al jugador incluso cuando este salta o cruza por detrás; no depende
		# de que el slime ya esté caminando para cambiar de dirección.
		if aware_of_player and absf(distance) > 8.0:
			facing = signf(distance)
		var target_velocity := patrol_direction * (32.0 + level * 2.0)
		if aware_of_player and same_floor and absf(distance) > 60.0:
			target_velocity = signf(distance) * (48.0 + level * 5.0)
		if global_position.x <= patrol_left and target_velocity < 0.0:
			patrol_direction = 1.0
			target_velocity = absf(target_velocity)
		if global_position.x >= patrol_right and target_velocity > 0.0:
			patrol_direction = -1.0
			target_velocity = -absf(target_velocity)
		if attack_windup > 0.0:
			var previous_windup := attack_windup
			attack_windup = maxf(0.0, attack_windup - delta)
			target_velocity = 0.0
			if previous_windup > 0.0 and attack_windup <= 0.0:
				var final_offset := target.global_position - global_position
				if absf(final_offset.x) <= 70.0 and absf(final_offset.y) < 90.0:
					hit_player.emit(8 + level * 2)
		else:
			if absf(distance) <= 64.0 and absf(vertical_distance) < 85.0 and attack_cooldown <= 0.0:
				attack_cooldown = 1.15
				attack_windup = 0.25
				_telegraph_attack()
		velocity.x = move_toward(velocity.x, target_velocity, 250.0 * delta)
	move_and_slide()
	# El giro anterior comprimía al slime casi a una línea. Ahora anticipa el
	# cambio, voltea la mirada a mitad del gesto y conserva todo su volumen.
	if turn_timer <= 0.0 and facing != displayed_facing:
		turn_target = facing
		turn_timer = 0.24
	var turn_phase := 1.0
	if turn_timer > 0.0:
		turn_timer = maxf(0.0, turn_timer - delta)
		turn_phase = 1.0 - turn_timer / 0.24
		if turn_phase >= 0.42 and displayed_facing != turn_target:
			displayed_facing = turn_target
			body_visual.flip_h = displayed_facing < 0.0
	var turn_squash := sin(turn_phase * PI) * 0.010 if turn_timer > 0.0 else 0.0
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006 + global_position.x * 0.01) * 0.035
	movement_phase += absf(velocity.x) * delta * 0.055
	var locomotion := clampf(absf(velocity.x) / 80.0, 0.0, 1.0)
	var hop_wave := maxf(0.0, sin(movement_phase)) * locomotion
	var movement_squash := locomotion * 0.004 + hop_wave * 0.003
	var attack_squash := sin((0.25 - attack_windup) / 0.25 * PI) * 0.015 if attack_windup > 0.0 else 0.0
	var hurt_squash := sin(clampf(hurt_face_timer / 0.32, 0.0, 1.0) * PI) * 0.020 if hurt_face_timer > 0.0 else 0.0
	body_visual.scale = Vector2(VISUAL_SCALE / pulse + movement_squash + attack_squash + hurt_squash - turn_squash, VISUAL_SCALE * pulse - movement_squash - attack_squash * 0.6 - hurt_squash * 0.75 + turn_squash * 0.7)
	body_visual.position.y = lerpf(body_visual.position.y, -47.0 - hop_wave * 5.5, minf(delta * 16.0, 1.0))
	if hurt_face_timer > 0.0:
		body_visual.rotation = lerpf(body_visual.rotation, impact_direction * 0.085 * sin(hurt_face_timer * 34.0), minf(delta * 18.0, 1.0))
	elif is_instance_valid(target):
		var look_height := clampf((target.global_position.y - global_position.y) / 320.0, -0.045, 0.045)
		var movement_lean := sin(movement_phase) * 0.024 * locomotion
		var turn_lean := sin(turn_phase * PI) * 0.075 * turn_target if turn_timer > 0.0 else 0.0
		body_visual.rotation = lerpf(body_visual.rotation, look_height * facing + movement_lean + turn_lean, minf(delta * 8.0, 1.0))

func _telegraph_attack() -> void:
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color("fff09a"), 0.10)
	tween.tween_property(body_visual, "modulate", Color.WHITE, 0.15)

func take_damage(amount: int, from_x: float) -> void:
	if hurt_cooldown > 0.0 or defeated_state: return
	health = maxi(0, health - amount)
	hp_bar.value = health
	hp_visible_timer = 2.4
	hurt_cooldown = 0.18
	hurt_face_timer = 0.32
	impact_direction = signf(global_position.x - from_x)
	body_visual.texture = hurt_texture
	velocity = Vector2(impact_direction * 210.0, -155.0)
	_spawn_impact_burst(impact_direction)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color("ff938b"), 0.05)
	tween.tween_property(body_visual, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		defeated_state = true
		defeated.emit(self, 8 + level * 4)
		hp_bar.hide()
		set_physics_process(false)
		var death_tween := create_tween()
		death_tween.tween_property(body_visual, "scale", Vector2(VISUAL_SCALE * 1.35, VISUAL_SCALE * 0.45), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		death_tween.tween_property(body_visual, "scale", Vector2(VISUAL_SCALE * 0.15, VISUAL_SCALE * 0.15), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		death_tween.parallel().tween_property(body_visual, "modulate:a", 0.0, 0.18)
		death_tween.tween_callback(queue_free)

func _spawn_impact_burst(direction: float) -> void:
	for spark_index in range(7):
		var spark := Line2D.new()
		spark.width = 3.0 if spark_index % 2 == 0 else 2.0
		spark.default_color = Color("9ff8ff") if spark_index % 2 == 0 else Color("ffe36f")
		spark.points = PackedVector2Array([Vector2.ZERO, Vector2(9.0 + spark_index, 0)])
		spark.position = Vector2(-direction * 24.0, -50.0)
		var spread := -1.25 + float(spark_index) * 0.34
		spark.rotation = spread if direction > 0.0 else PI - spread
		spark.z_index = 10
		add_child(spark)
		var destination := spark.position + Vector2.from_angle(spark.rotation) * (24.0 + spark_index * 3.0)
		var spark_tween := create_tween()
		spark_tween.tween_property(spark, "position", destination, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.20)
		spark_tween.tween_callback(spark.queue_free)
