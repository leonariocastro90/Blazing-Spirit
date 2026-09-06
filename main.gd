extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const SlimeScript = preload("res://scripts/slime.gd")
const WaterLeviathanScript = preload("res://scripts/water_leviathan.gd")
const HudStatusBarScript = preload("res://scripts/hud_status_bar.gd")
const WORLD_WIDTH := 3840.0
const WORLD_HEIGHT := 720.0
const SLIME_POPULATION_LIMIT := 20
const SLIME_INITIAL_POPULATION := 10
const SLIME_RESPAWN_INTERVAL := 3.0
const SAVE_PATH := "user://blazing_spirit.save"
const SETTINGS_PATH := "user://blazing_spirit_settings.cfg"
const CHARACTERS := [
	{"id":"elfa", "name":"Lyris", "race":"Elfa silvana", "role":"Exploradora ágil", "texture":"res://assets/characters/movement/elfa_movement_v1.png", "attack_texture":"res://assets/characters/combat/attack_elfa_v1.png", "jump_texture":"res://assets/characters/movement/jump/jump_elfa_v1.png", "rows":4, "stats":{"str":5,"agi":9,"vit":5,"ene":5}},
	{"id":"guerrero", "name":"Kael", "race":"Dracónido", "role":"Guerrero guardián", "texture":"res://assets/characters/movement/guerrero_movement_v1.png", "attack_texture":"res://assets/characters/combat/attack_guerrero_v1.png", "jump_texture":"res://assets/characters/movement/jump/jump_guerrero_v1.png", "rows":4, "stats":{"str":9,"agi":4,"vit":9,"ene":2}},
	{"id":"invocadora", "name":"Astra", "race":"Astral", "role":"Invocadora espiritual", "texture":"res://assets/characters/movement/invocadora_movement_v1.png", "attack_texture":"res://assets/characters/combat/attack_invocadora_v1.png", "jump_texture":"res://assets/characters/movement/jump/jump_invocadora_v1.png", "rows":4, "stats":{"str":3,"agi":6,"vit":5,"ene":10}},
	{"id":"maga", "name":"Nyx", "race":"Humana", "role":"Maga de las sombras", "texture":"res://assets/characters/movement/maga_movement_v1.png", "attack_texture":"res://assets/characters/combat/attack_maga_v1.png", "jump_texture":"res://assets/characters/movement/jump/jump_maga_v1.png", "rows":4, "stats":{"str":3,"agi":7,"vit":4,"ene":10}}
]
const MAP_SCENES := [
	preload("res://scenes/map_01_villa_arce.tscn"),
	preload("res://scenes/map_02_bosque.tscn"),
	preload("res://scenes/map_03_canon.tscn"),
	preload("res://scenes/map_04_ruinas.tscn"),
	preload("res://scenes/map_05_pantano.tscn"),
	preload("res://scenes/map_06_santuario.tscn")
]
const MAPS := [
	{"name":"Sendero de las Brasas Azules", "background":"res://Imagenes/Sendero de las Brasas Azules.png", "sky":Color("#80d8ff"), "ground":Color("#493d57"), "accent":Color("#65d7ff")},
	{"name":"Arboleda de Hongos Lunares", "background":"res://Imagenes/Arboleda de hongos lunares.png", "sky":Color("#19324a"), "ground":Color("#40385e"), "accent":Color("#8ee6ff")},
	{"name":"Cañada de Raíces Susurrantes", "background":"res://Imagenes/Cañada de las raíces susurrantes.png", "sky":Color("#7e71dd"), "ground":Color("#4a456c"), "accent":Color("#7ee5d1")},
	{"name":"Bosque de la Brasa Azul", "background":"res://Imagenes/Bosque de la Brasa Azul.png", "sky":Color("#172252"), "ground":Color("#373452"), "accent":Color("#55cfff")},
	{"name":"Ruinas del Guardián Musgoso", "background":"res://Imagenes/Ruinas del guardián musgoso.png", "sky":Color("#776de0"), "ground":Color("#4f4c70"), "accent":Color("#75e0b3")},
	{"name":"Santuario del Gran Espíritu", "background":"res://Imagenes/Santuario del Gran Espíritu.png", "sky":Color("#5544cf"), "ground":Color("#4b426e"), "accent":Color("#ffd76a")}
]

var world := Node2D.new()
var player: CharacterBody2D
var current_map := 0
var spawn_portal := 0
var title_label: Label
var hint_label: Label
var game_ui: CanvasLayer
var menu_layer: CanvasLayer
var menu_root: Control
var continue_button: Button
var options_panel: PanelContainer
var extra_panel: PanelContainer
var character_panel: PanelContainer
var character_creator_panel: PanelContainer
var class_select_panel: PanelContainer
var simple_creator_panel: PanelContainer
var simple_name_input: LineEdit
var simple_status_label: Label
var simple_preview: TextureRect
var simple_info_label: Label
var pending_character_id := "elfa"
const CLASS_FLAVOR := {
	"guerrero": {"pet": "Cachorro de dracónido", "path": "Guardián", "weapon": "Espada larga"},
	"invocadora": {"pet": "Espíritu menor", "path": "Invocadora", "weapon": "Bastón astral"},
	"maga": {"pet": "Familiar sombrío", "path": "Hechicera", "weapon": "Grimorio arcano"},
}
var character_lobby_label: Label
var character_list: VBoxContainer
var enter_character_button: Button
var character_profiles: Array[Dictionary] = []
var selected_profile_index := -1
var character_name_input: LineEdit
var hair_selector: OptionButton
var hair_color_selector: OptionButton
var eyes_selector: OptionButton
var pet_selector: OptionButton
var path_selector: OptionButton
var weapon_selector: OptionButton
var creator_status_label: Label
var creator_preview: TextureRect
var lobby_preview: TextureRect
const ELF_HAIR_SHEETS := [
	"res://assets/characters/elf/customization/hair/hair_01_long.png",
	"res://assets/characters/elf/customization/hair/hair_02_bob.png",
	"res://assets/characters/elf/customization/hair/hair_03_ponytail.png",
	"res://assets/characters/elf/customization/hair/hair_04_side_braid.png",
	"res://assets/characters/elf/customization/hair/hair_05_twin_braids.png"
]
const ELF_HAIR_COLORS := [Color("8f421f"), Color("e2ad45"), Color("24222a"), Color("d4d9e1"), Color("b63f28")]
const ELF_EYE_COLORS := [Color("55c85a"), Color("7abf55"), Color("22a85d"), Color("25d9cf"), Color("176c3a")]
var game_started := false
var selected_character: Dictionary = CHARACTERS[0]
var stats_label: Label
var health_bar: ProgressBar
var health_label: Label
var souls_label: Label
var souls := 0
var coins := 1250
var hero_level := 1
var experience := 0
var next_level_xp := 100
var stat_points := 5
var skill_points := 1
var mana := 100
var max_mana := 100
var profile_health_to_restore := -1
var xp_bar: ProgressBar
var level_label: Label
var life_orb: Control
var mana_orb: Control
var inventory_panel: PanelContainer
var attributes_panel: PanelContainer
var system_panel: PanelContainer
var attributes_values_label: Label
var inventory_items := ["Poción menor", "Cristal azul", "Hoja antigua"]
var inventory_currency_label: Label
var touch_controls: Control
var skill_one_touch_button: Button
var menu_background: TextureRect
var menu_logo: Control
var ui_audio: AudioStreamPlayer
var intro_music: AudioStreamPlayer
var slime_spawn_timer: Timer
var slime_spawn_cursor := 0
var slime_spawn_serial := 0

func _ready() -> void:
	add_child(world)
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_load_settings()
	_create_main_menu()
	if "--test-character-creator" in OS.get_cmdline_user_args():
		_open_elf_creator.call_deferred()
	if "--test-gameplay" in OS.get_cmdline_user_args():
		_start_game.call_deferred(0, 0)
	if "--test-combat" in OS.get_cmdline_user_args():
		_run_test_combat_sequence.call_deferred()
	if "--test-summon" in OS.get_cmdline_user_args():
		_run_test_summon_sequence.call_deferred()
	if "--test-roster" in OS.get_cmdline_user_args():
		_run_test_roster_storage.call_deferred()
	if "--test-jump-preview" in OS.get_cmdline_user_args():
		_run_test_jump_preview.call_deferred()

func _run_test_combat_sequence() -> void:
	_start_game(0, 0)
	await get_tree().create_timer(0.55).timeout
	Input.action_press("move_right")
	await get_tree().create_timer(0.42).timeout
	Input.action_press("jump")
	await get_tree().create_timer(0.22).timeout
	Input.action_release("jump")
	await get_tree().create_timer(0.12).timeout
	Input.action_press("attack")
	await get_tree().process_frame
	Input.action_release("attack")
	await get_tree().create_timer(0.48).timeout
	Input.action_release("move_right")
	# Segunda parte determinista: coloca al héroe a distancia de ataque de un
	# slime del suelo para que la revisión automática capture pose, impacto,
	# rostro herido y retroceso en una misma secuencia.
	await get_tree().create_timer(0.18).timeout
	var review_target: CharacterBody2D
	for slime in get_tree().get_nodes_in_group("slimes"):
		if is_instance_valid(slime) and absf(slime.global_position.y - 680.0) < 45.0:
			review_target = slime
			break
	if is_instance_valid(review_target) and is_instance_valid(player):
		player.global_position = review_target.global_position + Vector2(-86.0, 0.0)
		player.velocity = Vector2.ZERO
		player.facing = 1.0
		await get_tree().create_timer(0.12).timeout
		Input.action_press("attack")
		await get_tree().process_frame
		Input.action_release("attack")

func _run_test_summon_sequence() -> void:
	character_profiles.clear()
	selected_profile_index = -1
	selected_character = _find_character_data("invocadora").duplicate(true)
	selected_character.name = "AstraTest"
	_new_game()
	await get_tree().create_timer(0.55).timeout
	var review_target: CharacterBody2D
	for slime in get_tree().get_nodes_in_group("slimes"):
		if is_instance_valid(slime):
			review_target = slime
			break
	if is_instance_valid(review_target) and is_instance_valid(player):
		review_target.global_position = player.global_position + Vector2(255.0, 0.0)
		review_target.velocity = Vector2.ZERO
		review_target.patrol_left = review_target.global_position.x - 8.0
		review_target.patrol_right = review_target.global_position.x + 8.0
	var health_before := int(review_target.health) if is_instance_valid(review_target) else -1
	var souls_before := souls
	player.call("_summon_water_leviathan")
	await get_tree().create_timer(1.18).timeout
	print("SUMMON_TEST_STATE mana=", mana, " target_valid=", is_instance_valid(review_target), " health=", int(review_target.health) if is_instance_valid(review_target) else -1, " player=", player.global_position, " target=", review_target.global_position if is_instance_valid(review_target) else Vector2.ZERO)
	if (is_instance_valid(review_target) and int(review_target.health) < health_before) or souls > souls_before:
		var measured_damage := health_before - int(review_target.health) if is_instance_valid(review_target) else health_before
		print("SUMMON_TEST_OK damage=", measured_damage)
	else:
		push_error("SUMMON_TEST_FAILED: the water blast did not damage its target")
	if DisplayServer.get_name() != "headless":
		var capture := get_viewport().get_texture().get_image()
		if capture != null: capture.save_png("res://test_output/water_leviathan_skill_test.png")
	await get_tree().create_timer(0.45).timeout
	get_tree().quit()

func _run_test_roster_storage() -> void:
	character_profiles.clear()
	selected_profile_index = -1
	selected_character = _find_character_data("elfa").duplicate(true)
	selected_character.name = "RosterLyris"
	souls = 17
	coins = 1337
	hero_level = 3
	_save_game(2, 1)
	selected_profile_index = -1
	selected_character = _find_character_data("invocadora").duplicate(true)
	selected_character.name = "RosterAstra"
	souls = 44
	coins = 2222
	hero_level = 5
	_save_game(4, 0)
	character_profiles.clear()
	selected_profile_index = -1
	_load_character_profiles()
	var valid := character_profiles.size() == 2
	if valid:
		var first_progress: Dictionary = character_profiles[0].get("progress", {})
		var second_progress: Dictionary = character_profiles[1].get("progress", {})
		valid = str(character_profiles[0].get("name", "")) == "RosterLyris" and int(first_progress.get("coins", 0)) == 1337
		valid = valid and str(character_profiles[1].get("name", "")) == "RosterAstra" and int(second_progress.get("map", -1)) == 4
	if valid:
		print("ROSTER_TEST_OK characters=", character_profiles.size())
	else:
		push_error("ROSTER_TEST_FAILED: multiple profiles did not round-trip correctly")
	get_tree().quit()

func _run_test_jump_preview() -> void:
	character_profiles.clear()
	selected_profile_index = -1
	selected_character = _find_character_data("invocadora").duplicate(true)
	selected_character.name = "AstraJumpTest"
	_new_game()
	await get_tree().create_timer(0.65).timeout
	player.global_position.y -= 90.0
	player.velocity = Vector2(150.0, -270.0)
	await get_tree().create_timer(0.10).timeout
	if DisplayServer.get_name() != "headless":
		var capture := get_viewport().get_texture().get_image()
		if capture != null: capture.save_png("res://test_output/jump_pose_test.png")
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and game_started and not menu_root.visible:
		if event.keycode == KEY_I:
			_toggle_game_panel(inventory_panel); get_viewport().set_input_as_handled(); return
		if event.keycode == KEY_K:
			_toggle_game_panel(attributes_panel); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("ui_cancel") and game_started and not menu_root.visible:
		if inventory_panel.visible or attributes_panel.visible or system_panel.visible:
			inventory_panel.hide(); attributes_panel.hide(); system_panel.hide()
		else:
			_toggle_game_panel(system_panel)
		get_viewport().set_input_as_handled()

func _panel_style(color: Color, border_color: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func _button_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style := _panel_style(color, border_color, 8)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _create_main_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 20
	add_child(menu_layer)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(menu_root)

	menu_background = TextureRect.new()
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_background.texture = load("res://design/start_menu/v1/background_chibi_battle_v1.png")
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_background.scale = Vector2(1.025, 1.025)
	menu_background.position = Vector2(-16, -9)
	menu_root.add_child(menu_background)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.018, 0.06, 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(shade)

	var logo_frame := Control.new()
	logo_frame.position = Vector2(280, 8)
	logo_frame.size = Vector2(720, 330)
	logo_frame.clip_contents = true
	logo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(logo_frame)
	menu_logo = Control.new()
	menu_logo.set_script(load("res://scripts/scaled_logo.gd"))
	menu_logo.position = Vector2(60, 5)
	menu_logo.size = Vector2(600, 310)
	menu_logo.custom_minimum_size = Vector2.ZERO
	menu_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	menu_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_logo.pivot_offset = menu_logo.size * 0.5
	logo_frame.add_child(menu_logo)
	menu_logo.call("set_logo_texture", load("res://design/start_menu/v1/blazing_spirit_logo.png"))
	var logo_tween := create_tween().set_loops()
	logo_tween.tween_property(menu_logo, "position:y", 0.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.parallel().tween_property(menu_logo, "modulate", Color(1.0, 0.94, 0.82, 1.0), 2.4)
	logo_tween.tween_property(menu_logo, "position:y", 5.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.parallel().tween_property(menu_logo, "modulate", Color.WHITE, 2.4)
	var subtitle := Label.new()
	subtitle.text = "—  EPISODE I  ·  AWAKENING OF THE SPIRIT  —"
	subtitle.position = Vector2(390, 350)
	subtitle.size = Vector2(500, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("f0cf73"))
	subtitle.add_theme_color_override("font_shadow_color", Color(0.15, 0.8, 1.0, 0.8))
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	subtitle.add_theme_font_size_override("font_size", 15)
	menu_root.add_child(subtitle)

	var menu_box := VBoxContainer.new()
	menu_box.position = Vector2(705, 397)
	menu_box.size = Vector2(310, 190)
	menu_box.add_theme_constant_override("separation", 8)
	menu_root.add_child(menu_box)
	var new_button := _make_title_button("START GAME")
	new_button.pressed.connect(_open_character_selection)
	menu_box.add_child(new_button)
	new_button.call_deferred("grab_focus")
	var options_button := _make_title_button("CONFIGURATION")
	options_button.pressed.connect(func(): _toggle_popup(options_panel))
	menu_box.add_child(options_button)
	var support_button := _make_title_button("CONTACT SUPPORT", Color("f0c85d"))
	support_button.pressed.connect(func(): OS.shell_open("https://wa.me/51994913304"))
	menu_box.add_child(support_button)

	var whatsapp := _make_social_button("res://assets/ui/social/whatsapp_icon.svg", "Contactar por WhatsApp", Color("39df8a"))
	whatsapp.position = Vector2(24, 658)
	whatsapp.pressed.connect(func(): OS.shell_open("https://wa.me/51994913304"))
	menu_root.add_child(whatsapp)
	var discord := _make_social_button("res://assets/ui/social/discord_icon.svg", "Discord oficial", Color("8294ff"))
	discord.position = Vector2(78, 658)
	discord.pressed.connect(func(): _show_notice("DISCORD", "El servidor oficial estará disponible próximamente."))
	menu_root.add_child(discord)

	var credits := Label.new()
	credits.text = "DEVELOPERS\nMartin Castro · Alejandro Castro\nVERSION 1.0"
	credits.position = Vector2(986, 644)
	credits.size = Vector2(196, 62)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credits.add_theme_color_override("font_color", Color("e7efff"))
	credits.add_theme_font_size_override("font_size", 12)
	menu_root.add_child(credits)
	var brand := TextureRect.new()
	brand.texture = load("res://design/branding/ma_chick_logo_final.svg")
	brand.position = Vector2(1190, 646)
	brand.size = Vector2(68, 68)
	brand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(brand)

	ui_audio = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.12
	ui_audio.stream = generator
	menu_root.add_child(ui_audio)
	intro_music = AudioStreamPlayer.new()
	var intro_stream := load("res://assets/audio/music/menu/mosslight_village_intro.mp3") as AudioStreamMP3
	if intro_stream != null:
		intro_stream.loop = true
		intro_music.stream = intro_stream
		intro_music.volume_db = -30.0
		menu_root.add_child(intro_music)
		intro_music.play()
		create_tween().tween_property(intro_music, "volume_db", -5.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var bg_tween := create_tween().set_loops()
	bg_tween.tween_property(menu_background, "position", Vector2(-25, -13), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(menu_background, "position", Vector2(-16, -9), 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	options_panel = _create_options_panel()
	menu_root.add_child(options_panel)
	extra_panel = _create_extra_panel()
	menu_root.add_child(extra_panel)
	character_panel = _create_character_panel()
	menu_root.add_child(character_panel)
	character_creator_panel = _create_elf_creator_panel()
	menu_root.add_child(character_creator_panel)
	class_select_panel = _create_class_select_panel()
	menu_root.add_child(class_select_panel)
	simple_creator_panel = _create_simple_creator_panel()
	menu_root.add_child(simple_creator_panel)
	continue_button = new_button

func _make_title_button(label_text: String, color: Color = Color.WHITE) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(300, 48)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.05, 0.15, 0.30, 0.58)
	hover.border_color = Color("62e5f2")
	hover.border_width_bottom = 2
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_left = 4
	hover.corner_radius_bottom_right = 4
	hover.content_margin_left = 20
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.mouse_entered.connect(func(): button.grab_focus(); _play_ui_tone(720.0))
	button.focus_entered.connect(func(): _animate_menu_focus(button))
	button.pressed.connect(func(): _play_ui_tone(1040.0))
	return button

func _make_social_button(icon_path: String, tooltip: String, _accent: Color) -> Button:
	var button := Button.new()
	button.tooltip_text = tooltip
	button.size = Vector2(44, 44)
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var icon_view := Control.new()
	icon_view.set_script(load("res://scripts/scaled_logo.gd"))
	icon_view.position = Vector2(2, 2)
	icon_view.size = Vector2(40, 40)
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_view)
	icon_view.call("set_logo_texture", load(icon_path))
	button.mouse_entered.connect(func():
		_play_ui_tone(780.0)
		create_tween().tween_property(button, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.12)
	)
	button.mouse_exited.connect(func(): create_tween().tween_property(button, "modulate", Color.WHITE, 0.16))
	return button

func _animate_menu_focus(button: Button) -> void:
	button.modulate = Color(0.55, 0.95, 1.0, 0.72)
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, 0.24).set_trans(Tween.TRANS_QUAD)

func _play_ui_tone(frequency: float) -> void:
	if ui_audio == null:
		return
	ui_audio.play()
	var playback := ui_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for i in range(1764):
		var envelope := 1.0 - float(i) / 1764.0
		var sample := sin(TAU * frequency * float(i) / 22050.0) * 0.10 * envelope
		playback.push_frame(Vector2(sample, sample))

func _show_notice(title_text: String, message: String) -> void:
	extra_panel.show()
	var box := extra_panel.get_child(0) as VBoxContainer
	var label := box.get_child(1) as Label
	label.text = "%s\n\n%s" % [title_text, message]

func _make_menu_button(label_text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color("eef8ff"))
	button.add_theme_color_override("font_hover_color", Color("fff0a6"))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.07, 0.10, 0.20, 0.92), Color(0.25, 0.50, 0.72, 0.8)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.16, 0.16, 0.28, 0.98), Color("ffb443")))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.18, 0.08, 0.12, 1.0), Color("ff794d")))
	return button

func _create_popup(title_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.position = Vector2(600, 145)
	panel.size = Vector2(570, 430)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.035, 0.10, 0.97), Color("ffb443"), 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("ffd36a"))
	box.add_child(heading)
	return {"panel": panel, "box": box}

func _create_options_panel() -> PanelContainer:
	var popup := _create_popup("CONFIGURATION")
	var panel: PanelContainer = popup.panel
	var box: VBoxContainer = popup.box
	var volume_label := Label.new()
	volume_label.text = "Volumen general"
	volume_label.add_theme_font_size_override("font_size", 19)
	box.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0
	volume.custom_minimum_size.y = 34
	volume.value_changed.connect(_on_volume_changed)
	box.add_child(volume)
	var resolution_label := Label.new()
	resolution_label.text = "Resolución"
	resolution_label.add_theme_font_size_override("font_size", 19)
	box.add_child(resolution_label)
	var resolution := OptionButton.new()
	resolution.add_item("1280 × 720")
	resolution.add_item("1600 × 900")
	resolution.add_item("1920 × 1080")
	resolution.selected = 0
	resolution.item_selected.connect(_on_resolution_selected)
	box.add_child(resolution)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Pantalla completa"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.add_theme_font_size_override("font_size", 18)
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	box.add_child(fullscreen)
	var close := _make_menu_button("VOLVER", "Cerrar opciones")
	close.pressed.connect(func(): panel.hide())
	box.add_child(close)
	return panel

func _on_resolution_selected(index: int) -> void:
	var sizes := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	if index >= 0 and index < sizes.size():
		DisplayServer.window_set_size(sizes[index])
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - sizes[index]) / 2)

func _create_extra_panel() -> PanelContainer:
	var popup := _create_popup("EXTRA")
	var panel: PanelContainer = popup.panel
	var box: VBoxContainer = popup.box
	var text_label := Label.new()
	text_label.text = "ARCHIVO DEL GRAN ESPÍRITU\n\nExplora seis regiones encantadas y conoce a los\nhéroes de Blazing Spirit.\n\nGalería de arte: disponible próximamente.\nCréditos: Creado con Godot Engine."
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color("d9e9ff"))
	box.add_child(text_label)
	var close := _make_menu_button("VOLVER", "Cerrar extras")
	close.pressed.connect(func(): panel.hide())
	box.add_child(close)
	return panel

func _create_character_panel() -> PanelContainer:
	var popup := _create_popup("CHARACTER LOBBY")
	var panel: PanelContainer = popup.panel
	panel.position = Vector2(480, 76)
	panel.size = Vector2(730, 585)
	var box: VBoxContainer = popup.box
	box.add_theme_constant_override("separation", 12)
	var content := HBoxContainer.new()
	content.custom_minimum_size = Vector2(0, 312)
	content.add_theme_constant_override("separation", 18)
	box.add_child(content)
	var list_column := VBoxContainer.new()
	list_column.custom_minimum_size = Vector2(275, 0)
	list_column.add_theme_constant_override("separation", 8)
	content.add_child(list_column)
	var list_heading := Label.new()
	list_heading.text = "SAVED CHARACTERS"
	list_heading.add_theme_font_size_override("font_size", 14)
	list_heading.add_theme_color_override("font_color", Color("7ee5f4"))
	list_column.add_child(list_heading)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(275, 280)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_column.add_child(scroll)
	character_list = VBoxContainer.new()
	character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_list.add_theme_constant_override("separation", 7)
	scroll.add_child(character_list)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 7)
	content.add_child(detail)
	var face_atlas := AtlasTexture.new()
	face_atlas.atlas = load("res://assets/sprites_clean/elfa.png")
	face_atlas.region = Rect2(0, 512, 256, 256)
	lobby_preview = TextureRect.new()
	lobby_preview.texture = face_atlas
	lobby_preview.custom_minimum_size = Vector2(360, 205)
	lobby_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lobby_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lobby_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lobby_preview.material = _elf_preview_material(ELF_HAIR_COLORS[0])
	detail.add_child(lobby_preview)
	character_lobby_label = Label.new()
	character_lobby_label.text = "LYRIS\nLEVEL 1\nWOODLAND ELF\n\nAgile guardian of the ancient forest."
	character_lobby_label.custom_minimum_size = Vector2(360, 78)
	character_lobby_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_lobby_label.add_theme_font_size_override("font_size", 15)
	character_lobby_label.add_theme_color_override("font_color", Color("dcecff"))
	detail.add_child(character_lobby_label)
	enter_character_button = _make_menu_button("ENTER WORLD", "Entrar con el personaje seleccionado")
	enter_character_button.custom_minimum_size.y = 46
	enter_character_button.pressed.connect(_continue_game)
	box.add_child(enter_character_button)
	var create_new := _make_menu_button("NEW CHARACTER", "Crear un personaje nuevo")
	create_new.custom_minimum_size.y = 46
	create_new.pressed.connect(_open_class_select)
	box.add_child(create_new)
	var cancel := _make_menu_button("BACK", "Regresar al menú")
	cancel.custom_minimum_size.y = 42
	cancel.pressed.connect(func(): panel.hide())
	box.add_child(cancel)
	return panel

func _open_character_selection() -> void:
	options_panel.hide()
	extra_panel.hide()
	character_creator_panel.hide()
	simple_creator_panel.hide()
	_load_character_profiles()
	if not character_profiles.is_empty():
		_refresh_character_list()
		character_panel.show()
	else:
		_open_class_select()

func _open_class_select() -> void:
	character_panel.hide()
	character_creator_panel.hide()
	simple_creator_panel.hide()
	class_select_panel.show()

func _on_class_selected(character_id: String) -> void:
	pending_character_id = character_id
	class_select_panel.hide()
	if character_id == "elfa":
		_open_elf_creator()
	else:
		_open_simple_creator(character_id)

func _open_elf_creator() -> void:
	character_panel.hide()
	character_creator_panel.show()
	character_name_input.grab_focus()

func _create_elf_creator_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(55, 25)
	panel.size = Vector2(1170, 670)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.075, 0.975), Color("57dff3"), 18))
	var root := Control.new()
	panel.add_child(root)
	_creator_text(root, "NEW CHARACTER", Vector2(22, 4), Vector2(420, 48), 34, Color("eaf8ff"))
	_creator_text(root, "WOODLAND ELF · EPISODE I", Vector2(785, 14), Vector2(325, 28), 14, Color("e7c46a"), HORIZONTAL_ALIGNMENT_RIGHT)

	var preview_frame := Panel.new()
	preview_frame.position = Vector2(18, 58)
	preview_frame.size = Vector2(390, 530)
	preview_frame.clip_contents = true
	preview_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.015,0.04,0.09,1), Color("d7aa4d"), 14))
	root.add_child(preview_frame)
	creator_preview = TextureRect.new()
	creator_preview.texture = _elf_preview_texture(0)
	creator_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creator_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creator_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	creator_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	creator_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	creator_preview.material = _elf_preview_material(ELF_HAIR_COLORS[0])
	preview_frame.add_child(creator_preview)
	_creator_text(root, "Customize your hero before entering the world", Vector2(23, 594), Vector2(380, 25), 13, Color("9bc9dd"), HORIZONTAL_ALIGNMENT_CENTER)

	_creator_text(root, "NAME", Vector2(438, 55), Vector2(90, 25), 15, Color("7ee5f4"))
	character_name_input = LineEdit.new()
	character_name_input.position = Vector2(438, 82)
	character_name_input.size = Vector2(468, 42)
	character_name_input.placeholder_text = "Enter character name..."
	character_name_input.max_length = 16
	character_name_input.add_theme_font_size_override("font_size", 17)
	root.add_child(character_name_input)
	var check := _compact_creator_button("CHECK", Vector2(918, 82), Vector2(180, 42))
	check.pressed.connect(_check_character_name)
	root.add_child(check)

	hair_selector = _hidden_selector(root, ["Long", "Bob", "High ponytail", "Side braid", "Twin braids"])
	hair_color_selector = _hidden_selector(root, ["Chestnut", "Blonde", "Black", "Silver", "Auburn"])
	eyes_selector = _hidden_selector(root, ["Bright", "Gentle", "Focused", "Mystic", "Determined"])
	pet_selector = _hidden_selector(root, ["Forest chick", "Blue slime", "Leaf fox"])
	path_selector = _hidden_selector(root, ["Healer", "Archer"])
	weapon_selector = _hidden_selector(root, ["Staff", "Bow"])
	path_selector.item_selected.connect(_sync_elf_weapon)

	_creator_text(root, "HAIRSTYLE", Vector2(438, 138), Vector2(220, 24), 15, Color("7ee5f4"))
	var hair_row := Control.new()
	hair_row.position = Vector2(438, 166)
	hair_row.size = Vector2(465, 82)
	root.add_child(hair_row)
	for i in range(5):
		var hair_region := Rect2(35 + i * 403, 142, 365, 405)
		var hair_button := _image_choice("res://design/character_creation/v1/elf_hairstyles_5_v1.png", hair_region, Vector2(i * 92, 0), Vector2(84, 78))
		hair_button.pressed.connect(_select_creator_hair.bind(i, hair_row, hair_button))
		hair_row.add_child(hair_button)
		if i == 0: hair_button.button_pressed = true

	_creator_text(root, "HAIR COLOR", Vector2(438, 254), Vector2(220, 24), 15, Color("7ee5f4"))
	var color_row := Control.new()
	color_row.position = Vector2(438, 282)
	root.add_child(color_row)
	var colors := ELF_HAIR_COLORS
	for i in range(colors.size()):
		var swatch := Button.new()
		swatch.position = Vector2(i * 51, 0)
		swatch.size = Vector2(42, 34)
		swatch.toggle_mode = true
		swatch.add_theme_stylebox_override("normal", _color_swatch(colors[i], Color(0.35,0.48,0.62,1)))
		swatch.add_theme_stylebox_override("hover", _color_swatch(colors[i].lightened(0.12), Color.WHITE))
		swatch.add_theme_stylebox_override("pressed", _color_swatch(colors[i], Color("58e6f4"), 3))
		swatch.pressed.connect(_select_creator_hair_color.bind(i, color_row, swatch))
		color_row.add_child(swatch)
		if i == 0: swatch.button_pressed = true

	_creator_text(root, "EYES", Vector2(438, 329), Vector2(120, 24), 15, Color("7ee5f4"))
	var eyes_row := Control.new()
	eyes_row.position = Vector2(438, 356)
	root.add_child(eyes_row)
	for i in range(5):
		var eye_region := Rect2(i * 384, 120, 384, 420)
		var eye_button := _image_choice("res://design/character_creation/v3/modular_layers/elf_eye_styles_v3.png", eye_region, Vector2(i * 68, 0), Vector2(62, 66))
		eye_button.pressed.connect(_select_creator_eyes.bind(i, eyes_row, eye_button))
		eyes_row.add_child(eye_button)
		if i == 0: eye_button.button_pressed = true

	_creator_text(root, "LIVE PREVIEW", Vector2(918, 329), Vector2(180, 24), 15, Color("e7c46a"), HORIZONTAL_ALIGNMENT_CENTER)
	_creator_text(root, "Hair and eyes update instantly.\nEquipment is assigned automatically.", Vector2(900, 365), Vector2(215, 70), 13, Color("9bc9dd"), HORIZONTAL_ALIGNMENT_CENTER)
	creator_status_label = _creator_text(root, "", Vector2(438, 515), Vector2(660, 28), 13, Color("ffd36a"))
	var back := _compact_creator_button("BACK", Vector2(18, 620), Vector2(190, 42))
	back.pressed.connect(_close_elf_creator)
	root.add_child(back)
	var create := _compact_creator_button("CREATE CHARACTER", Vector2(842, 604), Vector2(268, 50), true)
	create.pressed.connect(_create_elf_character)
	root.add_child(create)
	return panel

func _character_portrait_texture(character: Dictionary) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var tex := load(str(character.texture)) as Texture2D
	atlas.atlas = tex
	if tex != null:
		var rows := int(character.get("rows", 4))
		var frame_w := tex.get_width() / 6.0
		var frame_h := tex.get_height() / float(rows)
		atlas.region = Rect2(0, frame_h * 2.0, frame_w, frame_h)
	return atlas

func _create_class_select_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(140, 70)
	panel.size = Vector2(1000, 580)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.075, 0.975), Color("57dff3"), 18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = "CHOOSE YOUR HERO"
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("ffd36a"))
	box.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "Cada héroe tiene su propio estilo de juego. Podrás crear más adelante."
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("9bc9dd"))
	box.add_child(subtitle)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	for character in CHARACTERS:
		row.add_child(_make_class_card(character))
	var back := _make_menu_button("BACK", "Regresar al menú")
	back.custom_minimum_size = Vector2(190, 44)
	back.pressed.connect(func():
		class_select_panel.hide()
		if not character_profiles.is_empty():
			_load_lobby_profile()
			character_panel.show()
	)
	box.add_child(back)
	return panel

func _make_class_card(character: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(226, 430)
	card.clip_contents = true
	card.add_theme_stylebox_override("normal", _button_style(Color(0.02,0.05,0.11,0.96), Color(0.22,0.39,0.55,1)))
	card.add_theme_stylebox_override("hover", _button_style(Color(0.05,0.13,0.23,1), Color("72e6f5")))
	card.add_theme_stylebox_override("pressed", _button_style(Color(0.06,0.14,0.25,1), Color("ffd36a")))
	card.pressed.connect(_on_class_selected.bind(character.id))
	var portrait_frame := Control.new()
	portrait_frame.position = Vector2(13, 14)
	portrait_frame.size = Vector2(200, 200)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait_frame)
	var portrait := Control.new()
	portrait.set_script(load("res://scripts/scaled_logo.gd"))
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_material := ShaderMaterial.new()
	portrait_material.shader = load("res://shaders/checker_mask.gdshader")
	portrait.material = portrait_material
	portrait_frame.add_child(portrait)
	portrait.call("set_logo_texture", _character_portrait_texture(character))
	var name_label := Label.new()
	name_label.text = str(character.name).to_upper()
	name_label.position = Vector2(14, 222)
	name_label.size = Vector2(198, 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("eaf8ff"))
	card.add_child(name_label)
	var role_label := Label.new()
	role_label.text = "%s\n%s" % [character.race, character.role]
	role_label.position = Vector2(14, 254)
	role_label.size = Vector2(198, 48)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color("e7c46a"))
	card.add_child(role_label)
	var stats: Dictionary = character.stats
	var stats_label := Label.new()
	stats_label.text = "STR %d   AGI %d\nVIT %d    ENE %d" % [stats.str, stats.agi, stats.vit, stats.ene]
	stats_label.position = Vector2(14, 306)
	stats_label.size = Vector2(198, 44)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color("9bc9dd"))
	card.add_child(stats_label)
	var pick_label := Label.new()
	pick_label.text = "SELECT"
	pick_label.position = Vector2(14, 372)
	pick_label.size = Vector2(198, 30)
	pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_label.add_theme_font_size_override("font_size", 16)
	pick_label.add_theme_color_override("font_color", Color("ffd36a"))
	card.add_child(pick_label)
	card.mouse_entered.connect(func(): _play_ui_tone(720.0))
	return card

func _open_simple_creator(character_id: String) -> void:
	character_creator_panel.hide()
	class_select_panel.hide()
	var character := _find_character_data(character_id)
	simple_preview.texture = _character_portrait_texture(character)
	simple_info_label.text = "%s\n%s · %s" % [character.name, character.race, character.role]
	simple_name_input.text = ""
	simple_status_label.text = ""
	simple_creator_panel.show()
	simple_name_input.grab_focus()

func _create_simple_creator_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(300, 130)
	panel.size = Vector2(680, 380)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.025, 0.075, 0.975), Color("57dff3"), 18))
	var root := Control.new()
	panel.add_child(root)
	var portrait_frame := Panel.new()
	portrait_frame.position = Vector2(20, 20)
	portrait_frame.size = Vector2(190, 220)
	portrait_frame.clip_contents = true
	portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.015,0.04,0.09,1), Color("d7aa4d"), 14))
	root.add_child(portrait_frame)
	simple_preview = TextureRect.new()
	simple_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	simple_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	simple_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	simple_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(simple_preview)
	simple_info_label = _creator_text(root, "", Vector2(230, 20), Vector2(430, 60), 18, Color("e7c46a"))
	_creator_text(root, "NAME", Vector2(230, 92), Vector2(90, 24), 15, Color("7ee5f4"))
	simple_name_input = LineEdit.new()
	simple_name_input.position = Vector2(230, 118)
	simple_name_input.size = Vector2(430, 42)
	simple_name_input.placeholder_text = "Enter character name..."
	simple_name_input.max_length = 16
	simple_name_input.add_theme_font_size_override("font_size", 17)
	root.add_child(simple_name_input)
	simple_status_label = _creator_text(root, "", Vector2(230, 172), Vector2(430, 28), 13, Color("ffd36a"))
	var back := _compact_creator_button("BACK", Vector2(20, 310), Vector2(190, 42))
	back.pressed.connect(func():
		simple_creator_panel.hide()
		class_select_panel.show()
	)
	root.add_child(back)
	var create := _compact_creator_button("CREATE CHARACTER", Vector2(470, 310), Vector2(190, 42), true)
	create.pressed.connect(_create_simple_character)
	root.add_child(create)
	return panel

func _create_simple_character() -> void:
	var clean_name := simple_name_input.text.strip_edges()
	if clean_name.length() < 3:
		simple_status_label.text = "Name must contain at least 3 characters."
		return
	if _character_name_exists(clean_name):
		simple_status_label.text = "That name already exists."
		return
	selected_character = _find_character_data(pending_character_id).duplicate(true)
	selected_character.name = clean_name
	var flavor: Dictionary = CLASS_FLAVOR.get(pending_character_id, {})
	selected_character["hair"] = ""
	selected_character["hair_color"] = ""
	selected_character["eyes"] = ""
	selected_character["eyes_index"] = 0
	selected_character["pet"] = str(flavor.get("pet", ""))
	selected_character["path"] = str(flavor.get("path", selected_character.role))
	selected_character["weapon"] = str(flavor.get("weapon", ""))
	selected_profile_index = -1
	simple_creator_panel.hide()
	_new_game()

func _creator_text(parent: Control, value: String, pos: Vector2, text_size: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = text_size
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _hidden_selector(parent: Control, values: Array) -> OptionButton:
	var selector := OptionButton.new()
	for value in values: selector.add_item(str(value))
	selector.visible = false
	parent.add_child(selector)
	return selector

func _image_choice(path: String, region: Rect2, pos: Vector2, card_size: Vector2) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = card_size
	button.custom_minimum_size = card_size
	button.clip_contents = true
	button.toggle_mode = true
	button.add_theme_stylebox_override("normal", _button_style(Color(0.02,0.05,0.11,0.96), Color(0.22,0.39,0.55,1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.04,0.11,0.20,1), Color("72e6f5")))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.04,0.12,0.22,1), Color("ffd36a")))
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = region
	var image := Control.new()
	image.set_script(load("res://scripts/scaled_logo.gd"))
	image.position = Vector2(5, 5)
	image.size = card_size - Vector2(10, 10)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image_material := ShaderMaterial.new()
	image_material.shader = load("res://shaders/checker_mask.gdshader")
	image.material = image_material
	button.add_child(image)
	image.call("set_logo_texture", atlas)
	return button

func _compact_creator_button(text_value: String, pos: Vector2, button_size: Vector2, primary := false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = pos
	button.custom_minimum_size = button_size
	button.size = button_size
	button.add_theme_font_size_override("font_size", 16 if not primary else 19)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.03,0.08,0.16,0.98), Color("d3a94e") if primary else Color(0.25,0.48,0.65,1)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.07,0.19,0.31,1), Color("72e6f5")))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10,0.16,0.27,1), Color("ffd36a")))
	return button

func _color_swatch(color: Color, border: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	return style

func _choose_creator_option(selector: OptionButton, index: int, group: Control, clicked: BaseButton) -> void:
	selector.select(index)
	for child in group.get_children():
		if child is BaseButton and child != clicked:
			(child as BaseButton).button_pressed = false

func _select_creator_hair(index: int, group: Control, clicked: BaseButton) -> void:
	_choose_creator_option(hair_selector, index, group, clicked)
	creator_preview.texture = _elf_preview_texture(index)
	creator_status_label.text = "HAIR %02d / 05" % [index + 1]

func _select_creator_hair_color(index: int, group: Control, clicked: BaseButton) -> void:
	_choose_creator_option(hair_color_selector, index, group, clicked)
	if creator_preview.material is ShaderMaterial:
		(creator_preview.material as ShaderMaterial).set_shader_parameter("hair_color", ELF_HAIR_COLORS[index])
	creator_status_label.text = "HAIR COLOR %02d / 05" % [index + 1]

func _select_creator_eyes(index: int, group: Control, clicked: BaseButton) -> void:
	_choose_creator_option(eyes_selector, index, group, clicked)
	if creator_preview.material is ShaderMaterial:
		(creator_preview.material as ShaderMaterial).set_shader_parameter("eye_color", ELF_EYE_COLORS[index])
	creator_status_label.text = "EYES %02d / 05" % [index + 1]

func _elf_preview_texture(hair_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ELF_HAIR_SHEETS[clampi(hair_index, 0, ELF_HAIR_SHEETS.size() - 1)])
	atlas.region = Rect2(48, 496, 160, 272)
	return atlas

func _elf_preview_material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/elf_creator_preview.gdshader")
	material.set_shader_parameter("hair_color", color)
	material.set_shader_parameter("eye_color", ELF_EYE_COLORS[0])
	return material

func _check_character_name() -> void:
	var clean_name := character_name_input.text.strip_edges()
	if clean_name.length() < 3:
		creator_status_label.text = "Use at least 3 characters."
	elif _character_name_exists(clean_name):
		creator_status_label.text = "That name already exists."
	else:
		creator_status_label.text = "✓ Name available."

func _close_elf_creator() -> void:
	character_creator_panel.hide()
	if not character_profiles.is_empty():
		character_panel.show()
	else:
		class_select_panel.show()

func _sync_elf_weapon(index: int) -> void:
	weapon_selector.select(0 if index == 0 else 1)

func _find_character_data(character_id: String) -> Dictionary:
	for data in CHARACTERS:
		if data.id == character_id:
			return data
	return CHARACTERS[0]

func _create_elf_character() -> void:
	var clean_name := character_name_input.text.strip_edges()
	if clean_name.length() < 3:
		creator_status_label.text = "Name must contain at least 3 characters."
		return
	if _character_name_exists(clean_name):
		creator_status_label.text = "That name already exists."
		return
	selected_character = _find_character_data("elfa").duplicate(true)
	selected_character.name = clean_name
	selected_character["hair"] = hair_selector.get_item_text(hair_selector.selected)
	selected_character["hair_color"] = hair_color_selector.get_item_text(hair_color_selector.selected)
	selected_character["eyes"] = eyes_selector.get_item_text(eyes_selector.selected)
	selected_character["eyes_index"] = eyes_selector.selected
	selected_character["pet"] = ""
	selected_character["path"] = "Generic"
	selected_character["weapon"] = "Generic"
	selected_profile_index = -1
	character_creator_panel.hide()
	_new_game()

func _load_lobby_profile() -> void:
	_load_character_profiles()
	_refresh_character_list()

func _load_character_profiles() -> void:
	character_profiles.clear()
	selected_profile_index = -1
	if not FileAccess.file_exists(_active_save_path()): return
	var save := ConfigFile.new()
	if save.load(_active_save_path()) != OK: return
	var stored: Variant = save.get_value("roster", "characters", [])
	if stored is Array:
		for item in stored:
			if item is Dictionary:
				var stored_profile: Dictionary = item
				character_profiles.append(stored_profile.duplicate(true))
		if not character_profiles.is_empty():
			selected_profile_index = clampi(int(save.get_value("roster", "selected", 0)), 0, character_profiles.size() - 1)
	# Migration path for the original one-character save. No existing progress is
	# discarded when the roster format is introduced.
	if character_profiles.is_empty() and save.has_section("progress"):
		var old_id := str(save.get_value("progress", "character", "elfa"))
		var old_character := _find_character_data(old_id)
		character_profiles.append({
			"id": old_id,
			"name": str(save.get_value("profile", "name", old_character.name)),
			"hair": str(save.get_value("profile", "hair", "Long")),
			"hair_color": str(save.get_value("profile", "hair_color", "Chestnut")),
			"eyes": str(save.get_value("profile", "eyes", "Bright")),
			"eyes_index": int(save.get_value("profile", "eyes_index", 0)),
			"pet": str(save.get_value("profile", "pet", "")),
			"path": str(save.get_value("profile", "path", "Generic")),
			"weapon": str(save.get_value("profile", "weapon", "Generic")),
			"stats": old_character.stats.duplicate(true),
			"progress": {
				"map": int(save.get_value("progress", "map", 0)),
				"portal": int(save.get_value("progress", "portal", 0)),
				"souls": int(save.get_value("progress", "souls", 0)),
				"coins": int(save.get_value("progress", "coins", 1250)),
				"level": int(save.get_value("progress", "level", 1)),
				"experience": int(save.get_value("progress", "experience", 0)),
				"next_level_xp": int(save.get_value("progress", "next_level_xp", 100)),
				"stat_points": int(save.get_value("progress", "stat_points", 5)),
				"skill_points": int(save.get_value("progress", "skill_points", 1)),
				"mana": int(save.get_value("progress", "mana", 100)),
				"health": int(save.get_value("progress", "health", 120 + int(old_character.stats.vit) * 10))
			}
		})
		selected_profile_index = 0
		_write_character_profiles()

func _write_character_profiles() -> void:
	var save := ConfigFile.new()
	save.set_value("roster", "version", 2)
	save.set_value("roster", "selected", selected_profile_index)
	save.set_value("roster", "characters", character_profiles)
	var save_error := save.save(_active_save_path())
	if save_error != OK:
		push_warning("No se pudo guardar la lista de personajes: %s" % error_string(save_error))

func _character_name_exists(candidate: String) -> bool:
	if character_profiles.is_empty() and FileAccess.file_exists(_active_save_path()):
		_load_character_profiles()
	for profile in character_profiles:
		if str(profile.get("name", "")).to_lower() == candidate.to_lower():
			return true
	return false

func _active_save_path() -> String:
	if "--test-summon" in OS.get_cmdline_user_args() or "--test-roster" in OS.get_cmdline_user_args() or "--test-jump-preview" in OS.get_cmdline_user_args():
		return "res://test_output/automated_roster_test.cfg"
	return SAVE_PATH

func _refresh_character_list() -> void:
	if character_list == null: return
	for child in character_list.get_children(): child.queue_free()
	if character_profiles.is_empty():
		character_lobby_label.text = "No saved characters yet."
		enter_character_button.disabled = true
		return
	selected_profile_index = clampi(selected_profile_index, 0, character_profiles.size() - 1)
	for profile_index in range(character_profiles.size()):
		var profile: Dictionary = character_profiles[profile_index]
		var progress: Dictionary = profile.get("progress", {})
		var character := _find_character_data(str(profile.get("id", "elfa")))
		var row := Button.new()
		row.text = "%s\nLv. %d  ·  %s" % [str(profile.get("name", character.name)).to_upper(), int(progress.get("level", 1)), str(character.race)]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size = Vector2(255, 58)
		row.toggle_mode = true
		row.button_pressed = profile_index == selected_profile_index
		row.set_meta("profile_index", profile_index)
		row.add_theme_font_size_override("font_size", 13)
		row.add_theme_color_override("font_color", Color("dcecff"))
		row.add_theme_stylebox_override("normal", _button_style(Color(0.025,0.06,0.12,0.96), Color(0.16,0.35,0.52,1)))
		row.add_theme_stylebox_override("hover", _button_style(Color(0.04,0.13,0.21,1), Color("58dff2")))
		row.add_theme_stylebox_override("pressed", _button_style(Color(0.08,0.16,0.24,1), Color("ffd36a")))
		row.pressed.connect(_select_character_profile.bind(profile_index))
		character_list.add_child(row)
	_select_character_profile(selected_profile_index, false)

func _select_character_profile(profile_index: int, refresh_buttons := true) -> void:
	if profile_index < 0 or profile_index >= character_profiles.size(): return
	selected_profile_index = profile_index
	var profile: Dictionary = character_profiles[profile_index]
	var character_id := str(profile.get("id", "elfa"))
	var character := _find_character_data(character_id)
	var progress: Dictionary = profile.get("progress", {})
	var profile_name := str(profile.get("name", character.name))
	if character_id == "elfa":
		var hair_name := str(profile.get("hair", "Long"))
		var hair_index: int = maxi(0, ["Long", "Bob", "High ponytail", "Side braid", "Twin braids"].find(hair_name))
		var color_name := str(profile.get("hair_color", "Chestnut"))
		var color_index: int = maxi(0, ["Chestnut", "Blonde", "Black", "Silver", "Auburn"].find(color_name))
		lobby_preview.texture = _elf_preview_texture(hair_index)
		lobby_preview.material = _elf_preview_material(ELF_HAIR_COLORS[color_index])
		var eye_index: int = clampi(int(profile.get("eyes_index", 0)), 0, 4)
		(lobby_preview.material as ShaderMaterial).set_shader_parameter("eye_color", ELF_EYE_COLORS[eye_index])
		character_lobby_label.text = "%s  ·  LEVEL %d\n%s\nHair %02d  ·  Eyes %02d  ·  Region %d/6" % [profile_name.to_upper(), int(progress.get("level", 1)), character.race, hair_index + 1, eye_index + 1, int(progress.get("map", 0)) + 1]
	else:
		lobby_preview.texture = _character_portrait_texture(character)
		lobby_preview.material = null
		character_lobby_label.text = "%s  ·  LEVEL %d\n%s · %s\nRegion %d/6  ·  %d coins" % [profile_name.to_upper(), int(progress.get("level", 1)), character.race, character.role, int(progress.get("map", 0)) + 1, int(progress.get("coins", 1250))]
	enter_character_button.disabled = false
	if refresh_buttons:
		for child in character_list.get_children():
			if child is Button:
				child.button_pressed = int(child.get_meta("profile_index", -1)) == selected_profile_index

func _toggle_popup(panel: PanelContainer) -> void:
	var should_open := not panel.visible
	options_panel.hide()
	extra_panel.hide()
	character_panel.hide()
	character_creator_panel.hide()
	class_select_panel.hide()
	simple_creator_panel.hide()
	panel.visible = should_open

func _new_game() -> void:
	souls = 0
	coins = 1250
	hero_level = 1
	experience = 0
	next_level_xp = 100
	stat_points = 5
	skill_points = 1
	mana = 100
	profile_health_to_restore = -1
	_start_game(0, 0)

func _continue_game() -> void:
	if character_profiles.is_empty(): _load_character_profiles()
	if character_profiles.is_empty():
		continue_button.disabled = true
		return
	selected_profile_index = clampi(selected_profile_index, 0, character_profiles.size() - 1)
	var profile: Dictionary = character_profiles[selected_profile_index]
	var character_id := str(profile.get("id", "elfa"))
	selected_character = _find_character_data(character_id).duplicate(true)
	for appearance_key in ["name", "hair", "hair_color", "eyes", "eyes_index", "pet", "path", "weapon"]:
		if profile.has(appearance_key): selected_character[appearance_key] = profile[appearance_key]
	var saved_stats: Variant = profile.get("stats", {})
	if saved_stats is Dictionary:
		selected_character.stats = (saved_stats as Dictionary).duplicate(true)
	var progress: Dictionary = profile.get("progress", {})
	souls = int(progress.get("souls", 0))
	coins = int(progress.get("coins", 1250))
	hero_level = int(progress.get("level", 1))
	experience = int(progress.get("experience", 0))
	next_level_xp = int(progress.get("next_level_xp", 100 + (hero_level - 1) * 55))
	stat_points = int(progress.get("stat_points", 5))
	skill_points = int(progress.get("skill_points", 1))
	mana = int(progress.get("mana", max_mana))
	profile_health_to_restore = int(progress.get("health", 120 + int(selected_character.stats.vit) * 10))
	_write_character_profiles()
	_start_game(int(progress.get("map", 0)), int(progress.get("portal", 0)))

func _start_game(map_index: int, arrival_portal: int) -> void:
	if intro_music != null and intro_music.playing:
		var music_fade := create_tween()
		music_fade.tween_property(intro_music, "volume_db", -35.0, 0.65)
		music_fade.tween_callback(intro_music.stop)
	menu_root.hide()
	world.visible = true
	world.process_mode = Node.PROCESS_MODE_INHERIT
	if not game_started:
		_create_ui()
		game_started = true
	if skill_one_touch_button != null:
		skill_one_touch_button.text = "LEVI" if str(selected_character.get("id", "")) == "invocadora" else "I"
		skill_one_touch_button.tooltip_text = "Leviatán de agua · Tecla 1" if str(selected_character.get("id", "")) == "invocadora" else "Skill I · Tecla 1"
	game_ui.show()
	_load_map(clampi(map_index, 0, MAPS.size() - 1), arrival_portal)

func _show_main_menu() -> void:
	_save_game(current_map, 0)
	if slime_spawn_timer != null: slime_spawn_timer.stop()
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	game_ui.hide()
	continue_button.disabled = false
	options_panel.hide()
	extra_panel.hide()
	character_panel.hide()
	character_creator_panel.hide()
	menu_root.show()
	if intro_music != null and not intro_music.playing:
		intro_music.volume_db = -30.0
		intro_music.play()
		create_tween().tween_property(intro_music, "volume_db", -5.0, 1.4)
	continue_button.grab_focus()

func _save_game(map_index: int, arrival_portal: int) -> void:
	var current_health := 120 + int(selected_character.stats.vit) * 10
	if is_instance_valid(player): current_health = int(player.health)
	profile_health_to_restore = current_health
	var profile := {
		"id": str(selected_character.get("id", "elfa")),
		"name": str(selected_character.get("name", "Lyris")),
		"hair": str(selected_character.get("hair", "Long")),
		"hair_color": str(selected_character.get("hair_color", "Chestnut")),
		"eyes": str(selected_character.get("eyes", "Bright")),
		"eyes_index": int(selected_character.get("eyes_index", 0)),
		"pet": str(selected_character.get("pet", "")),
		"path": str(selected_character.get("path", "Generic")),
		"weapon": str(selected_character.get("weapon", "Generic")),
		"stats": selected_character.stats.duplicate(true),
		"progress": {
			"map": map_index,
			"portal": arrival_portal,
			"souls": souls,
			"coins": coins,
			"level": hero_level,
			"experience": experience,
			"next_level_xp": next_level_xp,
			"stat_points": stat_points,
			"skill_points": skill_points,
			"mana": mana,
			"health": current_health
		}
	}
	if selected_profile_index < 0 or selected_profile_index >= character_profiles.size():
		character_profiles.append(profile)
		selected_profile_index = character_profiles.size() - 1
	else:
		character_profiles[selected_profile_index] = profile
	_write_character_profiles()

func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		_on_volume_changed(float(settings.get_value("audio", "volume", 80.0)))

func _save_settings(volume: float) -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "volume", volume)
	settings.save(SETTINGS_PATH)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
	AudioServer.set_bus_mute(0, value <= 0.0)
	_save_settings(value)

func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _create_ui() -> void:
	game_ui = CanvasLayer.new()
	add_child(game_ui)
	_create_action_hud()
	_create_game_panels()
	_create_touch_controls()

func _create_action_hud() -> void:
	life_orb = Control.new()
	life_orb.set_script(HudStatusBarScript)
	life_orb.position = Vector2(18, 112)
	life_orb.size = Vector2(194, 38)
	life_orb.set("caption", "HP")
	life_orb.set("fill_color", Color("d93850"))
	life_orb.set("highlight_color", Color("ff8a67"))
	game_ui.add_child(life_orb)
	mana_orb = Control.new()
	mana_orb.set_script(HudStatusBarScript)
	mana_orb.position = Vector2(18, 154)
	mana_orb.size = Vector2(194, 38)
	mana_orb.set("caption", "MP")
	mana_orb.set("fill_color", Color("287bd9"))
	mana_orb.set("highlight_color", Color("71d7ff"))
	game_ui.add_child(mana_orb)
	mana_orb.call("set_value", mana, max_mana)
	var hero_button := Button.new()
	hero_button.text = "✦  HÉROE"
	hero_button.position = Vector2(18, 198)
	hero_button.size = Vector2(194, 32)
	hero_button.add_theme_font_size_override("font_size", 12)
	hero_button.add_theme_stylebox_override("normal", _button_style(Color(0.04,0.08,0.14,0.92), Color("4fa8c9")))
	hero_button.add_theme_stylebox_override("hover", _button_style(Color(0.10,0.15,0.23,1), Color("ffd168")))
	hero_button.pressed.connect(func(): _toggle_game_panel(attributes_panel))
	game_ui.add_child(hero_button)

func _game_popup(title_text: String, popup_size: Vector2) -> Dictionary:
	var panel := PanelContainer.new()
	panel.position = (Vector2(1280,720) - popup_size) * 0.5
	panel.size = popup_size
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025,0.035,0.085,0.98), Color("d4ad55"), 16))
	game_ui.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("ffd36a"))
	box.add_child(heading)
	return {"panel":panel,"box":box}

func _create_game_panels() -> void:
	var inv := _game_popup("MOCHILA ESPIRITUAL", Vector2(360,402))
	inventory_panel = inv.panel
	inventory_panel.position = Vector2(18, 240)
	var inv_box: VBoxContainer = inv.box
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	inv_box.add_child(tabs)
	for tab_data in [["EQUIPO","Armas y armaduras"],["USO","Consumibles"],["MATERIA","Materiales"],["MISIÓN","Objetos especiales"]]:
		var tab := Button.new()
		tab.text = tab_data[0]
		tab.tooltip_text = tab_data[1]
		tab.custom_minimum_size = Vector2(75, 27)
		tab.add_theme_font_size_override("font_size", 9)
		tab.add_theme_stylebox_override("normal", _button_style(Color(0.07,0.10,0.17,1), Color(0.27,0.44,0.60,1)))
		tab.add_theme_stylebox_override("hover", _button_style(Color(0.12,0.19,0.29,1), Color("68d9ec")))
		tabs.add_child(tab)
	var capacity := Label.new()
	capacity.text = "OBJETOS  3 / 20"
	capacity.add_theme_font_size_override("font_size", 10)
	capacity.add_theme_color_override("font_color", Color("8fb4cb"))
	inv_box.add_child(capacity)
	var slots := GridContainer.new()
	slots.columns = 5
	slots.add_theme_constant_override("h_separation", 4)
	slots.add_theme_constant_override("v_separation", 4)
	inv_box.add_child(slots)
	var item_marks := ["✚","◆","⚔"]
	var item_colors := [Color("b83b4b"), Color("397fa8"), Color("9a7532")]
	for i in range(20):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(55,48)
		slot.text = item_marks[i] if i < inventory_items.size() else ""
		slot.tooltip_text = inventory_items[i] if i < inventory_items.size() else "Espacio vacío"
		slot.add_theme_font_size_override("font_size", 18)
		var slot_border: Color = item_colors[i] if i < item_colors.size() else Color(0.22,0.30,0.39,1)
		slot.add_theme_stylebox_override("normal", _button_style(Color(0.045,0.06,0.105,1), slot_border))
		slot.add_theme_stylebox_override("hover", _button_style(Color(0.10,0.14,0.21,1), Color("efc85b")))
		slots.add_child(slot)
	var wallet := PanelContainer.new()
	wallet.add_theme_stylebox_override("panel", _panel_style(Color(0.035,0.055,0.09,1), Color(0.22,0.42,0.55,1), 7))
	inv_box.add_child(wallet)
	inventory_currency_label = Label.new()
	inventory_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_currency_label.add_theme_font_size_override("font_size", 12)
	inventory_currency_label.add_theme_color_override("font_color", Color("ffe18a"))
	wallet.add_child(inventory_currency_label)
	var close_inv := _make_menu_button("CERRAR", "Cerrar inventario")
	close_inv.custom_minimum_size.y = 30
	close_inv.add_theme_font_size_override("font_size", 13)
	close_inv.pressed.connect(func(): inventory_panel.hide())
	inv_box.add_child(close_inv)

	var attr := _game_popup("ATRIBUTOS", Vector2(350,330))
	attributes_panel = attr.panel
	attributes_panel.position = Vector2(18, 240)
	var attr_box: VBoxContainer = attr.box
	attributes_values_label = Label.new()
	attributes_values_label.add_theme_font_size_override("font_size", 15)
	attr_box.add_child(attributes_values_label)
	for stat_data in [["str","STR","Aumenta el daño físico"],["agi","AGI","Velocidad y frecuencia de ataque"],["vit","VIT","Vida máxima y defensa"],["ene","ENE","Maná y poder espiritual"]]:
		var row := HBoxContainer.new()
		var description := Label.new()
		description.text = "%s  ·  %s" % [stat_data[1], stat_data[2]]
		description.custom_minimum_size.x = 235
		description.add_theme_font_size_override("font_size", 12)
		row.add_child(description)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(36,30)
		plus.pressed.connect(_add_stat.bind(stat_data[0]))
		row.add_child(plus)
		attr_box.add_child(row)
	var close_attr := _make_menu_button("CONFIRMAR", "Cerrar atributos")
	close_attr.custom_minimum_size.y = 34
	close_attr.add_theme_font_size_override("font_size", 13)
	close_attr.pressed.connect(func(): attributes_panel.hide())
	attr_box.add_child(close_attr)

	var sys := _game_popup("OPCIONES", Vector2(310,350))
	system_panel = sys.panel
	system_panel.position = Vector2(18, 240)
	var sys_box: VBoxContainer = sys.box
	var resolution_label := Label.new()
	resolution_label.text = "Resolución"
	resolution_label.add_theme_font_size_override("font_size", 13)
	sys_box.add_child(resolution_label)
	var resolutions := OptionButton.new()
	for label in ["1280 × 720", "1600 × 900", "1920 × 1080"]: resolutions.add_item(label)
	resolutions.selected = 0
	resolutions.item_selected.connect(_change_resolution)
	sys_box.add_child(resolutions)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Pantalla completa"
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	sys_box.add_child(fullscreen)
	var touch_toggle := CheckButton.new()
	touch_toggle.text = "Controles táctiles"
	touch_toggle.button_pressed = true
	touch_toggle.toggled.connect(func(enabled: bool):
		if touch_controls != null: touch_controls.visible = enabled
	)
	sys_box.add_child(touch_toggle)
	var change_character := _make_menu_button("CAMBIAR PERSONAJE", "Volver a elegir raza")
	change_character.custom_minimum_size.y = 32
	change_character.add_theme_font_size_override("font_size", 13)
	change_character.pressed.connect(_return_to_character_selection)
	sys_box.add_child(change_character)
	var main_menu := _make_menu_button("VOLVER AL MENÚ", "Guardar y salir al menú inicial")
	main_menu.custom_minimum_size.y = 32
	main_menu.add_theme_font_size_override("font_size", 13)
	main_menu.pressed.connect(_show_main_menu)
	sys_box.add_child(main_menu)
	var close_sys := _make_menu_button("CONTINUAR", "Regresar al juego")
	close_sys.custom_minimum_size.y = 32
	close_sys.add_theme_font_size_override("font_size", 13)
	close_sys.pressed.connect(func(): system_panel.hide())
	sys_box.add_child(close_sys)

func _toggle_game_panel(panel: PanelContainer) -> void:
	var open := not panel.visible
	inventory_panel.hide(); attributes_panel.hide(); system_panel.hide()
	panel.visible = open
	if panel == attributes_panel: _refresh_attributes_panel()

func _create_touch_controls() -> void:
	for action_name in ["crouch", "run", "attack", "skill_1", "skill_2", "skill_3"]:
		if not InputMap.has_action(action_name): InputMap.add_action(action_name)
	var skill_keys := {"skill_1": KEY_1, "skill_2": KEY_2, "skill_3": KEY_3}
	for action_name in skill_keys:
		if InputMap.action_get_events(action_name).is_empty():
			var key_event := InputEventKey.new()
			key_event.physical_keycode = skill_keys[action_name]
			InputMap.action_add_event(action_name, key_event)
	touch_controls = Control.new()
	touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_ui.add_child(touch_controls)
	# Cruceta izquierda: cómoda para pulgares, translúcida y separada del HUD.
	_touch_button("◀", Vector2(34, 594), Vector2(62,62), "move_left", Color("334a5d"))
	_touch_button("▶", Vector2(112, 594), Vector2(62,62), "move_right", Color("334a5d"))
	_touch_button("▼", Vector2(73, 647), Vector2(62,62), "crouch", Color("334a5d"))
	_touch_button("⇧", Vector2(73, 541), Vector2(62,62), "jump", Color("385a67"))
	# Acciones derechas con jerarquía visual propia de Blazing Spirit.
	_touch_button("ATK", Vector2(1134, 596), Vector2(76,76), "attack", Color("8f3e39"))
	_touch_button("SALTO", Vector2(1048, 626), Vector2(64,64), "jump", Color("37657d"), 11)
	skill_one_touch_button = _touch_button("LEVI" if str(selected_character.get("id", "")) == "invocadora" else "I", Vector2(1110, 522), Vector2(54,54), "skill_1", Color("376f9b"), 10)
	_touch_button("II", Vector2(1170, 500), Vector2(54,54), "skill_2", Color("53639a"))
	_touch_button("III", Vector2(1218, 548), Vector2(54,54), "skill_3", Color("785180"))

func _touch_button(text_value: String, at: Vector2, button_size: Vector2, action_name: String, color: Color, font_size: int = 15) -> Button:
	var button := Button.new()
	button.text = text_value
	button.position = at
	button.size = button_size
	button.modulate.a = 0.82
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _touch_style(color, Color(0.72,0.88,0.95,0.75), int(button_size.x * 0.5)))
	button.add_theme_stylebox_override("hover", _touch_style(color.lightened(0.12), Color("ffe088"), int(button_size.x * 0.5)))
	button.add_theme_stylebox_override("pressed", _touch_style(color.darkened(0.18), Color.WHITE, int(button_size.x * 0.5)))
	button.button_down.connect(func(): Input.action_press(action_name))
	button.button_up.connect(func(): Input.action_release(action_name))
	button.mouse_exited.connect(func():
		if button.button_pressed: Input.action_release(action_name)
	)
	touch_controls.add_child(button)
	return button

func _touch_style(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0,0,0,0.45)
	style.shadow_size = 5
	return style

func _add_stat(stat_key: String) -> void:
	if stat_points <= 0: return
	selected_character.stats[stat_key] = int(selected_character.stats[stat_key]) + 1
	stat_points -= 1
	if is_instance_valid(player):
		player.stats = selected_character.stats.duplicate(true)
		player.max_health = 120 + int(player.stats.vit) * 10
	_update_stats_ui()
	_refresh_attributes_panel()

func _refresh_attributes_panel() -> void:
	if attributes_values_label == null: return
	var s: Dictionary = selected_character.stats
	attributes_values_label.text = "Puntos disponibles: %d\n\nSTR %d     AGI %d     VIT %d     ENE %d" % [stat_points,s.str,s.agi,s.vit,s.ene]

func _change_resolution(index: int) -> void:
	var sizes := [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]
	DisplayServer.window_set_size(sizes[index])

func _return_to_character_selection() -> void:
	_save_game(current_map, 0)
	if slime_spawn_timer != null: slime_spawn_timer.stop()
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	game_ui.hide()
	menu_root.show()
	options_panel.hide(); extra_panel.hide(); system_panel.hide()
	_load_character_profiles()
	_refresh_character_list()
	character_panel.show()

func _load_map(index: int, arrival_portal: int) -> void:
	current_map = wrapi(index, 0, MAPS.size())
	for child in world.get_children(): child.queue_free()
	await get_tree().process_frame
	var data: Dictionary = MAPS[current_map]
	world.add_child(MAP_SCENES[current_map].instantiate())
	RenderingServer.set_default_clear_color(data.sky)
	_draw_background(data)
	var platforms := _platform_layout(current_map)
	for rect in platforms: _make_platform(rect, data)
	_make_portal(Vector2(95, 660), wrapi(current_map - 1, 0, MAPS.size()), 1, "◀")
	_make_portal(Vector2(WORLD_WIDTH-95, 660), wrapi(current_map + 1, 0, MAPS.size()), 0, "▶")
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	player.setup(selected_character)
	world.add_child(player)
	player.position = Vector2(210 if arrival_portal == 0 else WORLD_WIDTH-210, 610)
	player.portal_requested.connect(_on_portal_requested)
	player.attack_requested.connect(_on_player_attack)
	player.summon_requested.connect(_on_player_summon)
	player.health_changed.connect(_on_player_health_changed)
	if profile_health_to_restore >= 0:
		player.health = clampi(profile_health_to_restore, 1, player.max_health)
		_on_player_health_changed(player.health, player.max_health)
	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = int(WORLD_HEIGHT)
	player.add_child(camera)
	if title_label != null: title_label.text = "%d/6  %s" % [current_map + 1, data.name]
	_update_stats_ui()
	_spawn_slimes()
	_start_slime_spawner()
	if current_map == 0: _spawn_alejandro_guide()
	_save_game(current_map, arrival_portal)

func _spawn_alejandro_guide() -> void:
	var npc := Node2D.new()
	npc.name = "AlejandroGuideNPC"
	# El origen del NPC coincide con la superficie del suelo, igual que el héroe.
	npc.position = Vector2(410, 680)
	npc.z_index = 6
	world.add_child(npc)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-27,-3),Vector2(27,-3),Vector2(20,4),Vector2(-20,4)])
	shadow.color = Color(0.01,0.02,0.05,0.42)
	npc.add_child(shadow)

	var portrait := Sprite2D.new()
	portrait.texture = load("res://assets/npcs/alejandro/npc_alejandro_chibi_v2.png")
	portrait.region_enabled = true
	portrait.region_rect = Rect2(100, 170, 824, 1180)
	portrait.position = Vector2(0, -46)
	portrait.scale = Vector2(0.088, 0.088)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var clean_material := ShaderMaterial.new()
	clean_material.shader = load("res://shaders/checker_mask.gdshader")
	portrait.material = clean_material
	npc.add_child(portrait)

	var nameplate := Label.new()
	nameplate.text = "ALEJANDRO"
	nameplate.position = Vector2(-55, -116)
	nameplate.size = Vector2(110, 20)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.add_theme_font_size_override("font_size", 12)
	nameplate.add_theme_color_override("font_color", Color("ffe084"))
	nameplate.add_theme_color_override("font_outline_color", Color("101728"))
	nameplate.add_theme_constant_override("outline_size", 4)
	npc.add_child(nameplate)

	var bubble := PanelContainer.new()
	bubble.position = Vector2(48, -167)
	bubble.size = Vector2(292, 76)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bubble_style := _panel_style(Color(0.96,0.98,1.0,0.97), Color("59cfe6"), 14)
	bubble_style.content_margin_left = 14
	bubble_style.content_margin_right = 14
	bubble_style.content_margin_top = 9
	bubble_style.content_margin_bottom = 9
	bubble_style.shadow_color = Color(0,0,0,0.38)
	bubble_style.shadow_size = 8
	bubble.add_theme_stylebox_override("panel", bubble_style)
	npc.add_child(bubble)
	var greeting := Label.new()
	greeting.text = "¡Bienvenido a Blazing Spirit!\nSoy Alejandro y te guiaré en tu camino."
	greeting.add_theme_font_size_override("font_size", 12)
	greeting.add_theme_color_override("font_color", Color("15253c"))
	greeting.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(greeting)

	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(52,-105),Vector2(77,-110),Vector2(59,-88)])
	tail.color = Color(0.96,0.98,1.0,0.96)
	npc.add_child(tail)
	bubble.hide()
	tail.hide()

	var click_hint := PanelContainer.new()
	click_hint.position = Vector2(-17, -143)
	click_hint.size = Vector2(34, 22)
	click_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_style := _panel_style(Color(0.025,0.055,0.09,0.94), Color("59cfe6"), 11)
	hint_style.content_margin_left = 0
	hint_style.content_margin_right = 0
	hint_style.content_margin_top = 0
	hint_style.content_margin_bottom = 0
	click_hint.add_theme_stylebox_override("panel", hint_style)
	npc.add_child(click_hint)
	var hint_text := Label.new()
	hint_text.text = "•••"
	hint_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_text.add_theme_font_size_override("font_size", 10)
	hint_text.add_theme_color_override("font_color", Color("8eefff"))
	click_hint.add_child(hint_text)

	var interaction := Area2D.new()
	interaction.name = "DialogueInteraction"
	interaction.input_pickable = true
	npc.add_child(interaction)
	var interaction_shape := CollisionShape2D.new()
	var interaction_box := RectangleShape2D.new()
	interaction_box.size = Vector2(80, 112)
	interaction_shape.shape = interaction_box
	interaction_shape.position = Vector2(0, -54)
	interaction.add_child(interaction_shape)
	interaction.mouse_entered.connect(func():
		portrait.modulate = Color(1.08,1.08,1.08,1.0)
		click_hint.scale = Vector2(1.08,1.08)
	)
	interaction.mouse_exited.connect(func():
		portrait.modulate = Color.WHITE
		click_hint.scale = Vector2.ONE
	)
	interaction.input_event.connect(func(viewport, event, _shape_index):
		var activated: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		activated = activated or (event is InputEventScreenTouch and event.pressed)
		if activated:
			_toggle_npc_dialog(bubble, tail)
			viewport.set_input_as_handled()
	)

func _toggle_npc_dialog(bubble: PanelContainer, tail: Polygon2D) -> void:
	var opening := not bubble.visible
	if opening:
		bubble.show()
		tail.show()
		bubble.modulate.a = 0.0
		tail.modulate.a = 0.0
		bubble.scale = Vector2(0.92,0.92)
		var open_tween := create_tween()
		open_tween.tween_property(bubble, "modulate:a", 1.0, 0.16)
		open_tween.parallel().tween_property(tail, "modulate:a", 1.0, 0.16)
		open_tween.parallel().tween_property(bubble, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var close_tween := create_tween()
		close_tween.tween_property(bubble, "modulate:a", 0.0, 0.13)
		close_tween.parallel().tween_property(tail, "modulate:a", 0.0, 0.13)
		close_tween.tween_callback(bubble.hide)
		close_tween.parallel().tween_callback(tail.hide)

func _draw_background(data: Dictionary) -> void:
	for column in range(3):
		var background := Sprite2D.new()
		background.texture = load(data.background)
		background.position = Vector2(640 + column*1280, 360)
		# Las ilustraciones no son mosaicos continuos. Alternarlas en espejo hace
		# coincidir cada borde consigo mismo; el pequeño solape evita líneas por
		# redondeo subpíxel durante el movimiento de cámara.
		background.flip_h = column % 2 == 1
		var texture_size: Vector2 = background.texture.get_size()
		background.scale = Vector2(1282.0 / texture_size.x, 722.0 / texture_size.y)
		background.z_index = -20
		world.add_child(background)

func _platform_layout(map_index: int) -> Array:
	var result: Array = [Rect2(0, 680, WORLD_WIDTH, 40)]
	var platform_sets := [
		[
			Rect2(300,570,360,24), Rect2(755,472,330,24), Rect2(1110,365,285,24),
			Rect2(1420,555,410,24), Rect2(1900,445,350,24), Rect2(2300,335,310,24),
			Rect2(2645,548,390,24), Rect2(3090,438,330,24), Rect2(3450,330,270,24)
		],
		[
			Rect2(245,505,330,24), Rect2(630,390,300,24), Rect2(995,535,390,24),
			Rect2(1460,420,320,24), Rect2(1815,300,300,24), Rect2(2160,535,420,24),
			Rect2(2650,410,340,24), Rect2(3040,525,390,24), Rect2(3460,395,280,24)
		],
		[
			Rect2(330,535,420,24), Rect2(805,415,270,24), Rect2(1135,300,310,24),
			Rect2(1510,500,350,24), Rect2(1920,375,400,24), Rect2(2380,525,320,24),
			Rect2(2750,390,300,24), Rect2(3100,280,310,24), Rect2(3440,500,300,24)
		]
	]
	for rect in platform_sets[map_index % platform_sets.size()]: result.append(rect)
	return result

func _make_platform(rect: Rect2, data: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "Ground" if rect.position.y >= 675.0 else "FloatingPlatform"
	body.position = rect.position + rect.size / 2
	body.set_meta("platform_rect", rect)
	world.add_child(body)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = rect.position.y < 675.0
	shape.one_way_collision_margin = 7.0
	body.add_child(shape)
	var theme_index := 0 if current_map < 3 else (1 if current_map < 5 else 2)
	var sheets := ["res://assets/platforms/forest_platforms.png", "res://assets/platforms/ruins_platforms.png", "res://assets/platforms/sanctuary_platforms.png"]
	# Cada plataforma usa una pieza con proporciones cercanas a su tamaño. Antes
	# se comprimía una tira de 1345 px dentro de plataformas de 270 px.
	var floating_regions := [Rect2(92,488,540,150), Rect2(104,522,552,160), Rect2(378,82,460,124)]
	var ground_regions := [Rect2(94,48,1348,205), Rect2(103,82,1336,205), Rect2(378,72,460,138)]
	var source_region: Rect2 = ground_regions[theme_index] if rect.position.y >= 675.0 else floating_regions[theme_index]
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/magenta_key.gdshader")
	var remaining := rect.size.x
	var start_x := -rect.size.x / 2.0
	while remaining > 0.0:
		var chunk_width := minf(remaining, 680.0 if rect.position.y >= 675.0 else rect.size.x)
		var visual_height := 88.0 if rect.position.y >= 675.0 else (72.0 if theme_index == 2 else 82.0)
		var visual := Sprite2D.new()
		visual.texture = load(sheets[theme_index])
		visual.region_enabled = true
		visual.region_rect = source_region
		visual.scale = Vector2((chunk_width + 2.0) / source_region.size.x, visual_height / source_region.size.y)
		# La parte superior visible y la superficie física comparten exactamente y.
		visual.position = Vector2(start_x + chunk_width/2.0, -rect.size.y/2.0 + visual_height/2.0)
		visual.material = material
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		body.add_child(visual)
		start_x += chunk_width
		remaining -= chunk_width

func _make_portal(pos: Vector2, target: int, target_id: int, arrow: String) -> void:
	var area := Area2D.new()
	area.position = pos
	world.add_child(area)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 38
	capsule.height = 108
	shape.shape = capsule
	shape.position.y = -45
	area.add_child(shape)
	var ring := Line2D.new()
	ring.width = 9
	ring.default_color = MAPS[current_map].accent
	for i in range(25):
		var angle := TAU * i / 24.0
		ring.add_point(Vector2(cos(angle)*34, sin(angle)*52-45))
	area.add_child(ring)
	var glow := Line2D.new()
	glow.width = 22
	glow.default_color = Color(MAPS[current_map].accent, 0.2)
	glow.points = ring.points
	glow.z_index = -1
	area.add_child(glow)
	var label := Label.new()
	label.text = arrow + "  W/↑"
	label.position = Vector2(-28,18)
	label.add_theme_font_size_override("font_size",18)
	area.add_child(label)
	var info := {"map":target,"portal":target_id}
	area.body_entered.connect(func(body):
		if body.has_method("register_portal"): body.register_portal(info))
	area.body_exited.connect(func(body):
		if body.has_method("unregister_portal"): body.unregister_portal(info))

func _make_lift_pair(x: float) -> void:
	var stops := [Vector2(x,1320), Vector2(x,1130), Vector2(x,880), Vector2(x,630), Vector2(x,380)]
	for i in range(stops.size()-1):
		_make_local_portal(stops[i], stops[i+1], "▲")
		_make_local_portal(stops[i+1] + Vector2(72,0), stops[i] + Vector2(72,0), "▼")

func _make_local_portal(pos: Vector2, target: Vector2, arrow: String) -> void:
	var area := Area2D.new()
	area.position = pos
	world.add_child(area)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 28
	capsule.height = 82
	shape.shape = capsule
	shape.position.y = -34
	area.add_child(shape)
	var ring := Line2D.new()
	ring.width = 7
	ring.default_color = MAPS[current_map].accent
	for point in range(25):
		var angle := TAU * point / 24.0
		ring.add_point(Vector2(cos(angle)*25, sin(angle)*38-34))
	area.add_child(ring)
	var label := Label.new()
	label.text = arrow + " W/↑"
	label.position = Vector2(-25,10)
	label.add_theme_font_size_override("font_size",14)
	area.add_child(label)
	var info := {"local_target": target}
	area.body_entered.connect(func(body):
		if body.has_method("register_portal"): body.register_portal(info))
	area.body_exited.connect(func(body):
		if body.has_method("unregister_portal"): body.unregister_portal(info))

func _spawn_slimes() -> void:
	slime_spawn_cursor = 0
	slime_spawn_serial = 0
	for spawn_index in range(SLIME_INITIAL_POPULATION):
		_spawn_next_slime()

func _start_slime_spawner() -> void:
	if slime_spawn_timer == null:
		slime_spawn_timer = Timer.new()
		slime_spawn_timer.name = "SlimePopulationTimer"
		slime_spawn_timer.wait_time = SLIME_RESPAWN_INTERVAL
		slime_spawn_timer.one_shot = false
		slime_spawn_timer.timeout.connect(_on_slime_spawn_timer)
		add_child(slime_spawn_timer)
	slime_spawn_timer.start(SLIME_RESPAWN_INTERVAL)

func _on_slime_spawn_timer() -> void:
	if not game_started or not world.visible or not is_instance_valid(player): return
	if get_tree().get_nodes_in_group("slimes").size() >= SLIME_POPULATION_LIMIT: return
	_spawn_next_slime()

func _slime_roaming_platforms() -> Array[Rect2]:
	var layout := _platform_layout(current_map)
	var roaming_platforms: Array[Rect2] = []
	# Todas las plataformas elevadas reciben enemigos.
	for platform_index in range(1, layout.size()):
		roaming_platforms.append(layout[platform_index])
	# El suelo se divide en sectores para que no formen una sola masa.
	for ground_index in range(5):
		roaming_platforms.append(Rect2(360.0 + ground_index * 700.0, 680.0, 500.0, 40.0))
	return roaming_platforms

func _spawn_next_slime() -> void:
	if not is_instance_valid(player): return
	var roaming_platforms := _slime_roaming_platforms()
	if roaming_platforms.is_empty(): return
	var attempts := roaming_platforms.size()
	while attempts > 0:
		var platform: Rect2 = roaming_platforms[slime_spawn_cursor % roaming_platforms.size()]
		slime_spawn_cursor += 1
		attempts -= 1
		var usable_width := maxf(platform.size.x - 104.0, 1.0)
		var offset := fmod(float(slime_spawn_serial * 137 + slime_spawn_cursor * 43), usable_width)
		var spawn_position := Vector2(platform.position.x + 52.0 + offset, platform.position.y - 2.0)
		if spawn_position.distance_to(player.global_position) < 190.0: continue
		var occupied := false
		for existing_slime in get_tree().get_nodes_in_group("slimes"):
			if is_instance_valid(existing_slime) and existing_slime.global_position.distance_to(spawn_position) < 92.0:
				occupied = true
				break
		if occupied: continue
		var slime := CharacterBody2D.new()
		slime.set_script(SlimeScript)
		var slime_level := 1 + current_map + (slime_spawn_serial % 4)
		slime.setup(slime_level, player, platform)
		slime.position = spawn_position
		world.add_child(slime)
		slime.hit_player.connect(_on_slime_hit_player)
		slime.defeated.connect(_on_slime_defeated)
		slime_spawn_serial += 1
		return

func _on_player_attack(damage: int, origin: Vector2, facing_direction: float) -> void:
	for slime in get_tree().get_nodes_in_group("slimes"):
		if not is_instance_valid(slime): continue
		var offset: Vector2 = slime.global_position + Vector2(0, -52.0) - origin
		if absf(offset.y) < 100.0 and offset.x * facing_direction > -15.0 and offset.x * facing_direction < 145.0:
			slime.take_damage(damage, origin.x)
			_show_damage_number(slime.global_position + Vector2(0,-105), damage)

func _on_player_summon(damage: int, origin: Vector2, facing_direction: float) -> void:
	var leviathan := Node2D.new()
	leviathan.set_script(WaterLeviathanScript)
	leviathan.setup(damage, origin, facing_direction)
	leviathan.blast_requested.connect(_on_water_blast)
	leviathan.rain_pulse_requested.connect(_on_water_rain_pulse)
	world.add_child(leviathan)
	mana = maxi(0, mana - 20)
	if mana_orb != null: mana_orb.call("set_value", mana, max_mana)

func _on_water_blast(damage: int, origin: Vector2, facing_direction: float, reach: float, vertical_tolerance: float) -> void:
	for slime in get_tree().get_nodes_in_group("slimes"):
		if not is_instance_valid(slime): continue
		# El rayo apunta al cuerpo visible del slime, no a su punto de apoyo.
		var offset: Vector2 = slime.global_position + Vector2(0, -52.0) - origin
		var forward_distance := offset.x * facing_direction
		if absf(offset.y) <= vertical_tolerance and forward_distance >= -22.0 and forward_distance <= reach:
			slime.take_damage(damage, origin.x)
			_show_damage_number(slime.global_position + Vector2(0, -108), damage)

func _on_water_rain_pulse(damage: int, center: Vector2, radius: float) -> void:
	for slime in get_tree().get_nodes_in_group("slimes"):
		if not is_instance_valid(slime): continue
		var body_center: Vector2 = slime.global_position + Vector2(0, -52.0)
		if absf(body_center.x - center.x) <= radius and absf(body_center.y - center.y) <= 125.0:
			slime.take_damage(damage, center.x)
			_show_damage_number(slime.global_position + Vector2(0, -108), damage)

func _show_damage_number(at: Vector2, damage: int) -> void:
	var label := Label.new()
	label.text = "%d" % damage
	label.position = at - Vector2(60, 18)
	label.size = Vector2(120, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.pivot_offset = label.size * 0.5
	label.z_index = 30
	label.scale = Vector2(0.55, 0.55)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color("ffd84d"))
	label.add_theme_color_override("font_outline_color", Color("9d201d"))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.02, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)
	world.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.08)
	tween.tween_property(label, "position:y", label.position.y - 42.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.48).set_delay(0.18)
	tween.tween_callback(label.queue_free)

func _on_slime_hit_player(raw_damage: int) -> void:
	if not is_instance_valid(player): return
	var health_before: int = player.health
	player.take_damage(raw_damage)
	var damage_received: int = health_before - int(player.health)
	if damage_received > 0:
		_show_damage_number(player.global_position + Vector2(0, -112), damage_received)

func _on_slime_defeated(_slime: CharacterBody2D, reward: int) -> void:
	souls += reward
	coins += reward * 2
	experience += reward * 3
	while experience >= next_level_xp:
		experience -= next_level_xp
		hero_level += 1
		stat_points += 3
		skill_points += 1
		next_level_xp = 100 + (hero_level - 1) * 55
	_update_stats_ui()
	_save_game(current_map, 0)

func _on_player_health_changed(current: int, maximum: int) -> void:
	if health_bar != null:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label != null: health_label.text = "PV  %d / %d" % [current, maximum]
	if life_orb != null: life_orb.call("set_value", current, maximum)

func _update_stats_ui() -> void:
	var values: Dictionary = selected_character.stats
	if stats_label != null: stats_label.text = "%s · %s\nSTR %d   AGI %d   VIT %d   ENE %d" % [selected_character.name, selected_character.race, values.str, values.agi, values.vit, values.ene]
	if souls_label != null: souls_label.text = "✦ Esencia: %d" % souls
	if inventory_currency_label != null:
		inventory_currency_label.text = "◉  %s monedas     ✦  %s esencia" % [_format_amount(coins), _format_amount(souls)]
	max_mana = 55 + int(values.ene) * 9
	mana = mini(mana, max_mana)
	if mana_orb != null: mana_orb.call("set_value", mana, max_mana)
	if xp_bar != null:
		xp_bar.max_value = next_level_xp
		xp_bar.value = experience
		level_label.text = "NIVEL %d  ·  EXP %d / %d  ·  Puntos de skill: %d" % [hero_level, experience, next_level_xp, skill_points]
	if is_instance_valid(player): _on_player_health_changed(player.health, player.max_health)

func _format_amount(amount: int) -> String:
	var raw := str(maxi(amount, 0))
	var formatted := ""
	while raw.length() > 3:
		formatted = "." + raw.right(3) + formatted
		raw = raw.left(raw.length() - 3)
	return raw + formatted

func _on_portal_requested(info: Dictionary) -> void:
	if info.has("local_target"):
		player.position = info.local_target
		player.velocity = Vector2.ZERO
	else:
		_load_map(info.map, info.portal)
