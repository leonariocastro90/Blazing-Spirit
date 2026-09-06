extends CharacterBody2D

signal portal_requested(info: Dictionary)
signal attack_requested(damage: int, origin: Vector2, facing: float)
signal summon_requested(damage: int, origin: Vector2, facing: float)
signal health_changed(current: int, maximum: int)

const BASE_SPEED := 245.0
const BASE_RUN_SPEED := 370.0
const JUMP_VELOCITY := -620.0
const GRAVITY := 1450.0
const GROUND_ACCELERATION := 2100.0
const AIR_ACCELERATION := 1150.0
const GROUND_FRICTION := 2600.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER_TIME := 0.13
const ATTACK_VISUAL_TIME := 0.30
const BASE_VISUAL_SCALE := 0.46
const ATTACK_POSE_SCALE := 0.105
const JUMP_POSE_SCALE := 0.15

var sprite: Sprite2D
var attack_sprite: Sprite2D
var jump_sprite: Sprite2D
var collision: CollisionShape2D
var ground_shadow: Polygon2D
var portal_candidates: Array[Dictionary] = []
var current_anim := "idle"
var frame_cursor := 0.0
var facing := 1.0
var character_data: Dictionary = {}
var stats := {"str": 5, "agi": 5, "vit": 5, "ene": 5}
var health := 100
var max_health := 100
var attack_cooldown := 0.0
var hurt_cooldown := 0.0
var crouching := false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var was_on_floor := false
var landing_squash := 0.0
var hurt_animation_timer := 0.0
var attack_animation_timer := 0.0
var attack_chain := 0
var sheet_rows := 4
var frame_size := Vector2(256, 256)

func setup(data: Dictionary) -> void:
	character_data = data.duplicate(true)
	sheet_rows = int(data.get("rows", 4))
	stats = data.get("stats", stats).duplicate(true)
	max_health = 120 + int(stats.vit) * 10
	health = max_health
	if sprite != null:
		sprite.texture = load(str(data.texture))
	if attack_sprite != null:
		attack_sprite.texture = load(str(data.get("attack_texture", "")))
	if jump_sprite != null:
		jump_sprite.texture = load(str(data.get("jump_texture", "")))
	health_changed.emit(health, max_health)

func _ready() -> void:
	add_to_group("player")
	sprite = Sprite2D.new()
	sprite.texture = load(str(character_data.get("texture", "res://assets/sprites_clean/elfa.png")))
	frame_size = Vector2(sprite.texture.get_width() / 6.0, sprite.texture.get_height() / float(sheet_rows))
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, frame_size.y * 2.0, frame_size.x, frame_size.y)
	sprite.scale = Vector2(BASE_VISUAL_SCALE, BASE_VISUAL_SCALE)
	# En las celdas de 256 px los pies terminan cerca de y=200, no en y=256.
	# Este anclaje compensa el margen transparente y coincide con la base física.
	sprite.position.y = -38
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	attack_sprite = Sprite2D.new()
	var attack_texture_path := str(character_data.get("attack_texture", ""))
	if not attack_texture_path.is_empty(): attack_sprite.texture = load(attack_texture_path)
	attack_sprite.position = Vector2(0, -40)
	attack_sprite.scale = Vector2(ATTACK_POSE_SCALE, ATTACK_POSE_SCALE)
	attack_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	attack_sprite.visible = false
	attack_sprite.z_index = 1
	add_child(attack_sprite)
	jump_sprite = Sprite2D.new()
	var jump_texture_path := str(character_data.get("jump_texture", ""))
	if not jump_texture_path.is_empty(): jump_sprite.texture = load(jump_texture_path)
	jump_sprite.position = Vector2(0, -50)
	jump_sprite.scale = Vector2(JUMP_POSE_SCALE, JUMP_POSE_SCALE)
	jump_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	jump_sprite.visible = false
	jump_sprite.z_index = 1
	add_child(jump_sprite)
	ground_shadow = Polygon2D.new()
	var shadow_points := PackedVector2Array()
	for point_index in range(18):
		var angle := TAU * float(point_index) / 18.0
		shadow_points.append(Vector2(cos(angle) * 27.0, sin(angle) * 5.0 - 1.0))
	ground_shadow.polygon = shadow_points
	ground_shadow.color = Color(0.02,0.035,0.08,0.42)
	ground_shadow.z_index = -2
	add_child(ground_shadow)
	collision = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 20
	capsule.height = 84
	collision.shape = capsule
	collision.position.y = -42
	add_child(collision)
	if not character_data.is_empty():
		setup(character_data)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	hurt_cooldown = maxf(hurt_cooldown - delta, 0.0)
	hurt_animation_timer = maxf(hurt_animation_timer - delta, 0.0)
	attack_animation_timer = maxf(attack_animation_timer - delta, 0.0)
	if is_on_floor(): coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump"): jump_buffer_timer = JUMP_BUFFER_TIME
	else: jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	crouching = is_on_floor() and (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("crouch"))
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not crouching:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	# Soltar el botón recorta el salto y permite controlar su altura.
	if Input.is_action_just_released("jump") and velocity.y < -210.0: velocity.y *= 0.52
	var axis := Input.get_axis("move_left", "move_right")
	var running := Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("run")
	var agility_bonus := 1.0 + float(stats.agi - 5) * 0.025
	var target_speed := 0.0 if crouching else axis * (BASE_RUN_SPEED if running else BASE_SPEED) * agility_bonus
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	if absf(axis) < 0.01 and is_on_floor(): acceleration = GROUND_FRICTION
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	if absf(axis) > 0.01:
		facing = signf(axis)
		sprite.flip_h = facing < 0
		attack_sprite.flip_h = facing < 0
		jump_sprite.flip_h = facing < 0
	if (Input.is_key_pressed(KEY_J) or Input.is_action_just_pressed("attack")) and attack_cooldown <= 0.0 and not crouching: _attack()
	if Input.is_action_just_pressed("skill_1") and attack_cooldown <= 0.0:
		if str(character_data.get("id", "")) == "invocadora": _summon_water_leviathan()
		else: _skill_attack(1.45, Color("8cecff"))
	if Input.is_action_just_pressed("skill_2") and attack_cooldown <= 0.0:
		velocity.x = facing * 520.0
		_skill_attack(1.15, Color("a9adff"))
	if Input.is_action_just_pressed("skill_3") and attack_cooldown <= 0.0: _skill_attack(2.1, Color("e7a2ff"))
	move_and_slide()
	ground_shadow.visible = is_on_floor()
	if ground_shadow.visible:
		ground_shadow.scale.x = lerpf(ground_shadow.scale.x, 1.0 - clampf(absf(velocity.x) / BASE_RUN_SPEED, 0.0, 1.0) * 0.18, minf(delta * 10.0, 1.0))
	if is_on_floor() and not was_on_floor and velocity.y >= 0.0:
		landing_squash = 1.0
	was_on_floor = is_on_floor()
	landing_squash = move_toward(landing_squash, 0.0, delta * 7.5)
	if hurt_animation_timer > 0.0: _set_animation("hurt")
	elif attack_animation_timer > 0.0: _set_animation("attack")
	elif not is_on_floor(): _set_animation("jump")
	elif crouching: _set_animation("crouch")
	elif absf(velocity.x) > 300.0: _set_animation("run")
	elif absf(velocity.x) > 1.0: _set_animation("walk")
	else: _set_animation("idle")
	# Ajuste visual progresivo para evitar cambios rígidos entre estados.
	var target_sprite_y := _animation_anchor_y()
	var target_sprite_x := 0.0
	var motion_wave := sin(frame_cursor * PI)
	var idle_breath := sin(Time.get_ticks_msec() * 0.004) * 1.2 if current_anim == "idle" else 0.0
	var movement_bob := absf(motion_wave) * 1.8 if current_anim in ["walk", "run"] else 0.0
	if current_anim == "attack":
		var attack_phase := 1.0 - attack_animation_timer / ATTACK_VISUAL_TIME
		target_sprite_x = facing * sin(attack_phase * PI) * 11.0
		target_sprite_y -= sin(attack_phase * PI) * 2.5
	sprite.position.y = lerpf(sprite.position.y, target_sprite_y + idle_breath - movement_bob, minf(delta * 14.0, 1.0))
	sprite.position.x = lerpf(sprite.position.x, target_sprite_x, minf(delta * 22.0, 1.0))
	var target_rotation := 0.0
	if current_anim in ["walk", "run"]: target_rotation = facing * 0.025
	elif current_anim == "attack":
		var attack_phase := 1.0 - attack_animation_timer / ATTACK_VISUAL_TIME
		target_rotation = facing * lerpf(-0.08, 0.12, sin(attack_phase * PI))
	elif current_anim == "hurt":
		target_rotation = -facing * 0.10 * clampf(hurt_animation_timer / 0.42, 0.0, 1.0)
	elif current_anim == "idle": target_rotation = sin(Time.get_ticks_msec() * 0.0018) * 0.008
	sprite.rotation = lerpf(sprite.rotation, target_rotation, minf(delta * 8.0, 1.0))
	var motion_stretch := clampf(absf(velocity.x) / BASE_RUN_SPEED, 0.0, 1.0)
	var target_scale := Vector2(BASE_VISUAL_SCALE + motion_stretch * 0.012, BASE_VISUAL_SCALE - motion_stretch * 0.008)
	if not is_on_floor():
		var airborne_blend := clampf(-velocity.y / absf(JUMP_VELOCITY), -1.0, 1.0)
		target_scale = Vector2(BASE_VISUAL_SCALE - 0.005 - airborne_blend * 0.012, BASE_VISUAL_SCALE + 0.005 + airborne_blend * 0.014)
	if landing_squash > 0.0:
		target_scale += Vector2(0.035, -0.032) * landing_squash
	if current_anim == "attack":
		var attack_phase := 1.0 - attack_animation_timer / ATTACK_VISUAL_TIME
		target_scale += Vector2(0.025, -0.012) * sin(attack_phase * PI)
	sprite.scale = sprite.scale.lerp(target_scale, minf(delta * 10.0, 1.0))
	if attack_sprite != null and attack_sprite.texture != null:
		attack_sprite.flip_h = facing < 0.0
		if current_anim == "attack":
			var attack_phase := 1.0 - attack_animation_timer / ATTACK_VISUAL_TIME
			# Anticipación, contacto y recuperación usan curvas distintas. Así la
			# pose no queda congelada durante los 0.30 s del ataque.
			var contact_phase := clampf(attack_phase / 0.32, 0.0, 1.0)
			var recovery_phase := clampf((attack_phase - 0.32) / 0.68, 0.0, 1.0)
			var strike_x := lerpf(-7.0, 18.0, ease(contact_phase, 2.4))
			if attack_phase > 0.32: strike_x = lerpf(18.0, 1.0, ease(recovery_phase, -2.0))
			var impact_snap := 1.0 - clampf(absf(attack_phase - 0.32) / 0.32, 0.0, 1.0)
			attack_sprite.position = Vector2(facing * strike_x, -40.0 - impact_snap * 3.0)
			attack_sprite.rotation = facing * lerpf(-0.075, 0.045, contact_phase)
			if attack_phase > 0.32: attack_sprite.rotation = facing * lerpf(0.045, 0.0, recovery_phase)
			attack_sprite.scale = Vector2(ATTACK_POSE_SCALE * (1.0 + impact_snap * 0.075), ATTACK_POSE_SCALE * (1.0 - impact_snap * 0.045))
	if jump_sprite != null and jump_sprite.texture != null:
		jump_sprite.flip_h = facing < 0.0
		var ascent := clampf(-velocity.y / absf(JUMP_VELOCITY), -1.0, 1.0)
		var horizontal_motion := clampf(absf(velocity.x) / BASE_RUN_SPEED, 0.0, 1.0)
		jump_sprite.position = jump_sprite.position.lerp(Vector2(facing * horizontal_motion * 3.0, -50.0 - absf(ascent) * 2.5), minf(delta * 12.0, 1.0))
		jump_sprite.rotation = lerpf(jump_sprite.rotation, facing * (-0.035 + ascent * 0.045), minf(delta * 9.0, 1.0))
		var jump_stretch := 0.025 * absf(ascent)
		var jump_target_scale := Vector2(JUMP_POSE_SCALE - jump_stretch * 0.35, JUMP_POSE_SCALE + jump_stretch)
		jump_sprite.scale = jump_sprite.scale.lerp(jump_target_scale, minf(delta * 11.0, 1.0))
	position.x = clampf(position.x, 35.0, 3805.0)
	_animate(delta)
	if Input.is_action_just_pressed("portal_forward") and not portal_candidates.is_empty(): portal_requested.emit(portal_candidates[0])

func _animation_anchor_y() -> float:
	# Cada fila tiene una línea de pies distinta dentro de su celda. Mantener un
	# único anclaje producía saltos verticales y la sensación de estar flotando.
	match current_anim:
		"idle", "hurt": return -33.0
		"walk": return -49.0
		"run": return -42.0
		"crouch": return -58.0
		"jump": return -38.0
		_: return -38.0

func _attack() -> void:
	attack_cooldown = maxf(0.24, 0.55 - float(stats.agi) * 0.025)
	attack_animation_timer = ATTACK_VISUAL_TIME
	attack_chain = (attack_chain + 1) % 2
	velocity.x += facing * (55.0 if is_on_floor() else 28.0)
	var damage := 5 + int(stats.str) * 2 + int(stats.ene / 3)
	var strike_facing := facing
	_set_animation("attack")
	# El daño ocurre cuando el puño llega al frente, no al iniciar la pose.
	await get_tree().create_timer(0.085).timeout
	if not is_inside_tree(): return
	attack_requested.emit(damage, global_position, strike_facing)
	_spawn_attack_arc(strike_facing)
	_spawn_afterimage(strike_facing)
	var tween := create_tween()
	var strike_visual: Sprite2D = attack_sprite if attack_sprite != null and attack_sprite.texture != null else sprite
	tween.tween_property(strike_visual, "modulate", Color("fff0a0"), 0.045)
	tween.tween_property(strike_visual, "modulate", Color.WHITE, 0.10)

func _spawn_attack_arc(strike_facing: float) -> void:
	var arc := Line2D.new()
	arc.width = 10.0
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	arc.z_index = 8
	var arc_gradient := Gradient.new()
	arc_gradient.colors = PackedColorArray([Color(0.45,0.94,1.0,0.05), Color(1.0,0.86,0.35,0.95), Color(1.0,1.0,1.0,0.0)])
	arc.gradient = arc_gradient
	var start_angle := -1.05 if attack_chain == 0 else -0.72
	var end_angle := 0.72 if attack_chain == 0 else 1.08
	for point_index in range(12):
		var weight := float(point_index) / 11.0
		var angle := lerpf(start_angle, end_angle, weight)
		arc.add_point(Vector2(cos(angle) * 76.0 * strike_facing, sin(angle) * 58.0 - 47.0))
	add_child(arc)
	arc.scale = Vector2(0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(arc, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arc, "modulate:a", 0.0, 0.19).set_delay(0.08)
	tween.tween_callback(arc.queue_free)

func _spawn_afterimage(strike_facing: float) -> void:
	var source_sprite: Sprite2D = attack_sprite if attack_sprite != null and attack_sprite.texture != null else sprite
	var echo := Sprite2D.new()
	echo.texture = source_sprite.texture
	echo.region_enabled = source_sprite.region_enabled
	if source_sprite.region_enabled: echo.region_rect = source_sprite.region_rect
	echo.flip_h = source_sprite.flip_h
	echo.position = source_sprite.position - Vector2(strike_facing * 8.0, 0.0)
	echo.scale = source_sprite.scale
	echo.material = source_sprite.material
	echo.modulate = Color(0.45, 0.90, 1.0, 0.32)
	echo.z_index = source_sprite.z_index - 1
	add_child(echo)
	var tween := create_tween()
	tween.tween_property(echo, "position:x", echo.position.x - strike_facing * 18.0, 0.18)
	tween.parallel().tween_property(echo, "modulate:a", 0.0, 0.18)
	tween.tween_callback(echo.queue_free)

func _skill_attack(multiplier: float, flash_color: Color) -> void:
	attack_cooldown = 0.72
	var base_damage := 5 + int(stats.str) * 2 + int(stats.ene / 3)
	attack_requested.emit(roundi(base_damage * multiplier), global_position, facing)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", flash_color, 0.10)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.20)

func _summon_water_leviathan() -> void:
	attack_cooldown = 1.55
	var base_damage := 5 + int(stats.str) * 2 + int(stats.ene / 3)
	var cast_ring := Line2D.new()
	cast_ring.width = 5.0
	cast_ring.default_color = Color(0.30, 0.92, 1.0, 0.92)
	cast_ring.z_index = 7
	for point_index in range(29):
		var angle := TAU * float(point_index) / 28.0
		cast_ring.add_point(Vector2(cos(angle) * 38.0, sin(angle) * 12.0 - 4.0))
	cast_ring.scale = Vector2(0.25, 0.25)
	add_child(cast_ring)
	var ring_tween := create_tween()
	ring_tween.tween_property(cast_ring, "scale", Vector2(1.45, 1.45), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(cast_ring, "modulate:a", 0.0, 0.30)
	ring_tween.tween_callback(cast_ring.queue_free)
	var caster_tween := create_tween()
	caster_tween.tween_property(sprite, "modulate", Color("75eaff"), 0.10)
	caster_tween.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	await get_tree().create_timer(0.16).timeout
	if is_inside_tree():
		summon_requested.emit(roundi(base_damage * 2.4), global_position, facing)

func take_damage(raw_damage: int) -> void:
	if hurt_cooldown > 0.0: return
	var defense := int(stats.vit) * 2
	var final_damage := maxi(1, raw_damage - int(defense * 0.35))
	health = maxi(0, health - final_damage)
	hurt_cooldown = 0.7
	hurt_animation_timer = 0.42
	_set_animation("hurt")
	health_changed.emit(health, max_health)
	velocity = Vector2(-facing * 150.0, -170.0)
	_spawn_hurt_sparks()
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color("ff655f"), 0.07)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)
	if health <= 0:
		health = max_health
		position = Vector2(220, 610)
		health_changed.emit(health, max_health)

func _spawn_hurt_sparks() -> void:
	for spark_index in range(5):
		var spark := Line2D.new()
		spark.width = 3.0
		spark.default_color = Color("ffd36a") if spark_index % 2 == 0 else Color("ff6f66")
		spark.points = PackedVector2Array([Vector2.ZERO, Vector2(8,0)])
		spark.position = Vector2(facing * 15.0, -48.0)
		spark.rotation = -2.4 + float(spark_index) * 0.34
		spark.z_index = 9
		add_child(spark)
		var direction := Vector2.from_angle(spark.rotation) * (28.0 + spark_index * 4.0)
		var spark_tween := create_tween()
		spark_tween.tween_property(spark, "position", spark.position + direction, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.22)
		spark_tween.tween_callback(spark.queue_free)

func _set_animation(value: String) -> void:
	if current_anim == value: return
	current_anim = value
	frame_cursor = 0.0

func _animate(delta: float) -> void:
	var attack_phase := 0.0
	if current_anim == "attack": attack_phase = 1.0 - attack_animation_timer / ATTACK_VISUAL_TIME
	# Conserva un instante de anticipación con la pose normal y cambia al dibujo
	# ofensivo justo antes del contacto. La transición hace legible el golpe.
	var use_attack_pose := current_anim == "attack" and attack_phase >= 0.16 and attack_sprite != null and attack_sprite.texture != null
	var use_jump_pose := current_anim == "jump" and jump_sprite != null and jump_sprite.texture != null
	sprite.visible = not use_attack_pose and not use_jump_pose
	if attack_sprite != null: attack_sprite.visible = use_attack_pose
	if jump_sprite != null: jump_sprite.visible = use_jump_pose
	if current_anim == "idle":
		# Dos poses de espera reales del spritesheet, con pausas largas para que
		# parezca una reacción ocasional y no una animación mecánica.
		var idle_cycle := fmod(Time.get_ticks_msec() / 1000.0, 5.0)
		var idle_frame := 5 if idle_cycle > 4.25 else 0
		sprite.region_rect = Rect2(idle_frame * frame_size.x, 2 * frame_size.y, frame_size.x, frame_size.y)
		return
	if current_anim == "hurt":
		# Las hojas limpias no contienen una quinta fila válida. La reacción usa
		# una pose estable, retroceso físico y destello, sin mostrar fragmentos.
		sprite.region_rect = Rect2(0, 2 * frame_size.y, frame_size.x, frame_size.y)
		return
	if current_anim == "jump":
		if use_jump_pose:
			return
		var jump_frame := 1
		if velocity.y < -260.0: jump_frame = 1
		elif velocity.y < -60.0: jump_frame = 2
		elif velocity.y < 190.0: jump_frame = 3
		else: jump_frame = 4
		sprite.region_rect = Rect2(jump_frame * frame_size.x, 3 * frame_size.y, frame_size.x, frame_size.y)
		return
	if current_anim == "attack":
		# El ataque conserva una silueta estable y usa desplazamiento, giro, rastro
		# y arco de energía; evita reciclar cuadros de carrera como golpe.
		sprite.region_rect = Rect2(0, 2 * frame_size.y, frame_size.x, frame_size.y)
		return
	var row := 2
	var fps := 3.0
	var frames := 1
	var first_frame := 0
	match current_anim:
		"walk": row = 0; fps = 8.0; frames = 6
		# Los cuadros extremos de esta fila contienen píxeles cortados en el borde
		# de la celda. Usar los cuatro cuadros completos evita el salto de pies.
		"run": row = 1; fps = 11.0; frames = 4; first_frame = 1
		"crouch": row = 2; fps = 4.0; frames = 4; first_frame = 1
		"hurt": row = mini(4, sheet_rows - 1); fps = 10.0; frames = 3
	frame_cursor = fmod(frame_cursor + delta * fps, float(frames))
	sprite.region_rect = Rect2((first_frame + int(frame_cursor)) * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
	if crouching:
		collision.position.y = -27
		(collision.shape as CapsuleShape2D).height = 54
	else:
		collision.position.y = -42
		(collision.shape as CapsuleShape2D).height = 84

func register_portal(info: Dictionary) -> void:
	if not portal_candidates.has(info): portal_candidates.append(info)

func unregister_portal(info: Dictionary) -> void:
	portal_candidates.erase(info)
