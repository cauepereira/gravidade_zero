extends Node2D

# ─────────────────────────────────────────────
#  CONSTANTES GLOBAIS
# ─────────────────────────────────────────────
const W: int   = 1280
const H: int   = 720
const WALK_SPEED: float = 175.0
const RUN_SPEED:  float = 260.0
const PLAYER_SIZE: Vector2 = Vector2(28, 46)

const STATE_MENU:  int = 0
const STATE_PLAY:  int = 1
const STATE_PAUSE: int = 2
const STATE_WIN:   int = 3
const STATE_LOSE:  int = 4

# ─────────────────────────────────────────────
#  ESTADO DO JOGO
# ─────────────────────────────────────────────
var state: int = STATE_MENU

var player_pos:     Vector2 = Vector2(120, 530)
var player_dir:     Vector2 = Vector2.RIGHT
var player_moving:  bool    = false
var player_running: bool    = false
var player_face:    int     = 1   # 1 = direita, -1 = esquerda

var score:       float = 0.0
var oxygen:      float = 100.0
var suit_energy: float = 100.0
var time_played: float = 0.0

var card_collected:   bool = false
var cell_a_collected: bool = false
var cell_b_collected: bool = false
var cell_c_collected: bool = false
var oxy_a_collected:  bool = false
var oxy_b_collected:  bool = false
var code_collected:   bool = false

var door_a_open:    bool = false
var energy_on:      bool = false
var laser_off:      bool = false
var exit_unlocked:  bool = false

var current_puzzle:    int    = 0
var message:           String = ""
var message_timer:     float  = 0.0
var animation_time:    float  = 0.0
var interaction_flash: float  = 0.0
var action_flash:      float  = 0.0
var screen_flash:      float  = 0.0
var footstep_timer:    float  = 0.0
var o2_warning_shown:  bool   = false
var o2_critical:       bool   = false
var heartbeat_timer:   float  = 0.0

# Menu
var menu_selected:   int   = 0   # 0=jogar 1=créditos
var show_credits:    bool  = false
var transition_alpha: float = 0.0
var transitioning:   bool  = false
var transition_target: int = STATE_PLAY

# Nearest interactive
var nearest_interactive:      String = ""
var nearest_interactive_dist: float  = INF

# Parallax / fundo menu
var nebula_offset: float = 0.0

var stars:     Array = []
var stars_far: Array = []
var feedbacks: Array = []
var key_memory: Dictionary = {}
var particles:  Array = []   # partículas de coleta
var sparks:     Array = []   # faíscas elétricas
var smoke:      Array = []   # fumaça / vapor

# ─────────────────────────────────────────────
#  ÁUDIO (100% sintético, sem arquivos externos)
# ─────────────────────────────────────────────
var _bus_idx: int = 0   # AudioServer.get_bus_index("Master")

# ─────────────────────────────────────────────
#  PALETA DE CORES
# ─────────────────────────────────────────────
var bg:          Color = Color("#03060f")
var floor_col:   Color = Color("#0c1524")
var floor_alt:   Color = Color("#101d30")
var wall_col:    Color = Color("#d9efff")
var cyan:        Color = Color("#28d7ff")
var cyan_dim:    Color = Color("#0e4f62")
var green:       Color = Color("#28e070")
var red:         Color = Color("#ff2857")
var yellow:      Color = Color("#ffd84a")
var orange:      Color = Color("#ff914d")
var purple:      Color = Color("#b563ff")
var sector_cols: Array = [
	Color("#0a1625"),  # sala inicial    — azul muito escuro
	Color("#0d1e14"),  # setor energia   — verde escuro
	Color("#180e1a"),  # setor segurança — roxo escuro
	Color("#1a0e0e"),  # código/saída    — vermelho escuro
]

# ─────────────────────────────────────────────
#  LAYOUT DO MAPA
# ─────────────────────────────────────────────
# Zona caminhável unificada
var walk_zones: Array = [ Rect2(55, 238, 1170, 382) ]

# Zonas de radiação
var radiation_zones: Array = [ Rect2(835, 510, 100, 72) ]

# Posições FIXAS (terminais, gerador, saída — nunca mudam)
const card_pos:       Vector2 = Vector2(155, 530)
const terminal_a_pos: Vector2 = Vector2(310, 530)
const generator_pos:  Vector2 = Vector2(695, 325)
const terminal_b_pos: Vector2 = Vector2(880, 530)
const terminal_c_pos: Vector2 = Vector2(1105, 385)
const exit_pos:       Vector2 = Vector2(1150, 530)

# Posições ALEATÓRIAS por partida (inicializadas em _randomize_item_positions)
var cell_a_pos: Vector2 = Vector2(510, 530)
var cell_b_pos: Vector2 = Vector2(590, 325)
var cell_c_pos: Vector2 = Vector2(715, 530)
var oxy_a_pos:  Vector2 = Vector2(515, 325)
var oxy_b_pos:  Vector2 = Vector2(905, 325)
var code_pos:   Vector2 = Vector2(1045, 530)

const R_TERM: float = 58.0
const R_GEN:  float = 62.0
const R_CODE: float = 36.0
const R_EXIT: float = 58.0
const R_ITEM: float = 32.0

# Slots possíveis por setor (cx, cy) — afastados de paredes e terminais
# Setor energia X: 445–780  Y: 260–600
const CELL_SLOTS: Array = [
	Vector2(480, 540), Vector2(510, 310), Vector2(555, 560),
	Vector2(590, 310), Vector2(640, 555), Vector2(680, 310),
	Vector2(720, 545), Vector2(760, 310),
]
# O2 primeiro: qualquer setor acessível antes da porta A
const OXY_A_SLOTS: Array = [
	Vector2(110, 430), Vector2(110, 550), Vector2(190, 430),
	Vector2(200, 555), Vector2(260, 430), Vector2(350, 430),
	Vector2(370, 555),
]
# O2 segundo: setor energia/segurança, liberado depois da energia
const OXY_B_SLOTS: Array = [
	Vector2(455, 310), Vector2(500, 555), Vector2(620, 310),
	Vector2(760, 555), Vector2(830, 310), Vector2(850, 555),
]
# Código: setor após laser X: 980–1130  Y: 260–600
const CODE_SLOTS: Array = [
	Vector2(1000, 540), Vector2(1020, 310), Vector2(1060, 555),
	Vector2(1090, 310), Vector2(1120, 540),
]

func _randomize_item_positions() -> void:
	# Embaralha e escolhe posições sem repetição para cada grupo
	var cells  := CELL_SLOTS.duplicate();  cells.shuffle()
	var oxya   := OXY_A_SLOTS.duplicate(); oxya.shuffle()
	var oxyb   := OXY_B_SLOTS.duplicate(); oxyb.shuffle()
	var codes  := CODE_SLOTS.duplicate();  codes.shuffle()
	cell_a_pos = cells[0]
	cell_b_pos = cells[1]
	cell_c_pos = cells[2]
	oxy_a_pos  = oxya[0]
	oxy_b_pos  = oxyb[0]
	code_pos   = codes[0]

# ─────────────────────────────────────────────
#  _READY
# ─────────────────────────────────────────────
func _ready() -> void:
	randomize()   # semente aleatória real a cada execução
	for _i in range(180):
		stars.append({
			"pos": Vector2(randf_range(0, W), randf_range(0, H)),
			"r":   randf_range(0.6, 1.8),
			"spd": randf_range(0.005, 0.02),
			"phase": randf_range(0, TAU)
		})
	for _i in range(80):
		stars_far.append({
			"pos": Vector2(randf_range(0, W), randf_range(0, H)),
			"r":   randf_range(0.3, 0.9)
		})
	set_process(true)
	_randomize_item_positions()
	queue_redraw()

# ─────────────────────────────────────────────
#  _PROCESS
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	animation_time += delta
	nebula_offset  += delta * 4.0
	message_timer      = max(0.0, message_timer - delta)
	interaction_flash  = max(0.0, interaction_flash - delta)
	action_flash       = max(0.0, action_flash - delta)
	screen_flash       = max(0.0, screen_flash - delta)

	# Transição de tela
	if transitioning:
		transition_alpha += delta * 2.5
		if transition_alpha >= 1.0:
			transition_alpha = 1.0
			state = transition_target
			transitioning = false
		queue_redraw()
		return

	match state:
		STATE_MENU:
			_process_menu(delta)
		STATE_PLAY:
			_process_play(delta)
		STATE_PAUSE:
			if _just_pressed_key(KEY_P) or _just_pressed_key(KEY_ESCAPE):
				state = STATE_PLAY
			elif _just_pressed_key(KEY_M):
				_go_to_menu()
		STATE_WIN, STATE_LOSE:
			if _just_pressed_key(KEY_R) or _just_pressed_key(KEY_ENTER):
				_begin_transition(STATE_PLAY, true)
			elif _just_pressed_key(KEY_M):
				_go_to_menu()

	_update_feedbacks(delta)
	_update_particles(delta)
	if state == STATE_PLAY:
		_spawn_ambient_effects(delta)
		_update_ambient_effects(delta)
	queue_redraw()

func _process_menu(delta: float) -> void:
	if show_credits:
		if _just_pressed_key(KEY_ESCAPE) or _just_pressed_key(KEY_ENTER) or _just_pressed_key(KEY_SPACE):
			show_credits = false
		return
	if _just_pressed_key(KEY_UP) or _just_pressed_key(KEY_W):
		menu_selected = 0
		_beep(880, 0.05)
	elif _just_pressed_key(KEY_DOWN) or _just_pressed_key(KEY_S):
		menu_selected = 1
		_beep(880, 0.05)
	elif _just_pressed_key(KEY_ENTER) or _just_pressed_key(KEY_SPACE):
		if menu_selected == 0:
			_beep(1200, 0.12)
			_begin_transition(STATE_PLAY, false)
		else:
			_beep(880, 0.08)
			show_credits = true
	elif _just_pressed_key(KEY_ESCAPE):
		get_tree().quit()

func _process_play(delta: float) -> void:
	if _just_pressed_key(KEY_P) or _just_pressed_key(KEY_ESCAPE):
		state = STATE_PAUSE
		return
	_update_game(delta)

# ─────────────────────────────────────────────
#  TRANSIÇÃO DE TELA
# ─────────────────────────────────────────────
func _begin_transition(target: int, do_restart: bool) -> void:
	if do_restart:
		_reset_game_state()
	elif target == STATE_PLAY:
		_reset_game_state()
	transitioning    = true
	transition_alpha = 0.0
	transition_target = target

func _go_to_menu() -> void:
	_reset_game_state()
	state = STATE_MENU
	show_credits  = false
	menu_selected = 0

# ─────────────────────────────────────────────
#  RESET
# ─────────────────────────────────────────────
func _reset_game_state() -> void:
	player_pos    = Vector2(120, 530)
	player_dir    = Vector2.RIGHT
	player_face   = 1
	player_moving = false
	player_running = false
	score         = 0.0
	oxygen        = 100.0
	suit_energy   = 100.0
	time_played   = 0.0
	card_collected   = false
	cell_a_collected = false
	cell_b_collected = false
	cell_c_collected = false
	oxy_a_collected  = false
	oxy_b_collected  = false
	code_collected   = false
	door_a_open   = false
	energy_on     = false
	laser_off     = false
	exit_unlocked = false
	current_puzzle = 0
	o2_warning_shown = false
	o2_critical      = false
	heartbeat_timer  = 0.0
	feedbacks.clear()
	particles.clear()
	sparks.clear()
	smoke.clear()
	_randomize_item_positions()
	message = "Missão iniciada. Colete o cartão azul para começar."
	message_timer = 4.0

# ─────────────────────────────────────────────
#  LÓGICA DO JOGO
# ─────────────────────────────────────────────
func _update_game(delta: float) -> void:
	time_played += delta
	_update_nearest_interactive()

	if current_puzzle == 0:
		_handle_movement(delta)
		_try_collect_items()
		if _just_pressed_key(KEY_E):
			_try_interact()
		if not o2_warning_shown and time_played > 6.0:
			o2_warning_shown = true
			message = "⚠ O2 diminuindo! Explore rápido e colete bolinhas verdes."
			message_timer = 4.0
	else:
		if _just_pressed_key(KEY_1): _answer(1)
		elif _just_pressed_key(KEY_2): _answer(2)
		elif _just_pressed_key(KEY_3): _answer(3)
		elif _just_pressed_key(KEY_E) or _just_pressed_key(KEY_ESCAPE):
			current_puzzle = 0
			message = "Terminal fechado."
			message_timer = 1.2

	# O2 só drena fora do puzzle
	if current_puzzle == 0:
		_update_oxygen(delta)

	# Alerta crítico de O2
	if oxygen < 25.0 and not o2_critical:
		o2_critical = true
	if oxygen >= 30.0:
		o2_critical = false

	if oxygen <= 0.0:
		oxygen = 0.0
		state  = STATE_LOSE
		message = "Falha na missão: oxigênio esgotado."
		_beep(220, 0.4)

	# Batida de coração quando O2 crítico
	if o2_critical and current_puzzle == 0:
		heartbeat_timer -= delta
		if heartbeat_timer <= 0.0:
			_beep(60, 0.08)
			heartbeat_timer = 0.7 + (oxygen / 25.0) * 0.6

func _update_nearest_interactive() -> void:
	nearest_interactive      = ""
	nearest_interactive_dist = INF
	var candidates := [
		{"id": "card",       "pos": card_pos,       "r": R_ITEM, "on": not card_collected},
		{"id": "terminal_a", "pos": terminal_a_pos,  "r": R_TERM, "on": true},
		{"id": "generator",  "pos": generator_pos,   "r": R_GEN,  "on": true},
		{"id": "terminal_b", "pos": terminal_b_pos,  "r": R_TERM, "on": true},
		{"id": "terminal_c", "pos": terminal_c_pos,  "r": R_TERM, "on": true},
		{"id": "exit",       "pos": exit_pos,        "r": R_EXIT, "on": true},
	]
	if laser_off and not code_collected:
		candidates.append({"id": "code", "pos": code_pos, "r": R_CODE, "on": true})
	for c in candidates:
		if not c["on"]: continue
		var d: float = player_pos.distance_to(c["pos"])
		if d < c["r"] and d < nearest_interactive_dist:
			nearest_interactive_dist = d
			nearest_interactive      = c["id"]

func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	player_moving  = false
	player_running = false
	if dir.length() > 0.0:
		dir = dir.normalized()
		player_dir   = dir
		player_moving = true
		if dir.x != 0.0:
			player_face = 1 if dir.x > 0 else -1
		var spd := WALK_SPEED
		if Input.is_key_pressed(KEY_SHIFT) and suit_energy > 5.0:
			spd = RUN_SPEED
			player_running = true
			suit_energy = max(0.0, suit_energy - 22.0 * delta)
		else:
			suit_energy = min(100.0, suit_energy + 13.0 * delta)
		player_pos = _move_with_collision(player_pos, player_pos + dir * spd * delta)
	else:
		suit_energy = min(100.0, suit_energy + 18.0 * delta)
	if player_moving:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_beep(randf_range(180, 220), 0.03)
			footstep_timer = 0.30 if not player_running else 0.20

func _move_with_collision(old: Vector2, nw: Vector2) -> Vector2:
	if not _is_blocked(_prect(nw)): return nw
	var tx := Vector2(nw.x, old.y)
	if not _is_blocked(_prect(tx)): return tx
	var ty := Vector2(old.x, nw.y)
	if not _is_blocked(_prect(ty)): return ty
	return old

func _prect(p: Vector2 = Vector2.INF) -> Rect2:
	var pos := player_pos if p == Vector2.INF else p
	return Rect2(pos - PLAYER_SIZE / 2.0, PLAYER_SIZE)

func _is_blocked(r: Rect2) -> bool:
	if not _in_walkable(r): return true
	for b in _active_blockers():
		if r.intersects(b): return true
	return false

func _in_walkable(r: Rect2) -> bool:
	for pt in [r.position + Vector2(3,3), r.position + Vector2(r.size.x-3,3),
			   r.position + Vector2(3,r.size.y-3), r.position + r.size - Vector2(3,3)]:
		var ok := false
		for z in walk_zones:
			if (z as Rect2).has_point(pt): ok = true; break
		if not ok: return false
	return true

func _active_blockers() -> Array:
	var a := []
	if not door_a_open: a.append(Rect2(415, 238, 36, 382))
	if not energy_on:   a.append(Rect2(783, 238, 36, 382))
	if not laser_off:   a.append(Rect2(955, 238, 32, 382))
	return a

func _update_oxygen(delta: float) -> void:
	var loss := 0.55 * delta
	for z in radiation_zones:
		if _prect().intersects(z as Rect2):
			loss += 9.0 * delta
			if message_timer <= 0.0:
				message = "⚠ RADIAÇÃO! Saia da área vermelha agora!"
				message_timer = 1.0
	oxygen = max(0.0, oxygen - loss)

func _try_collect_items() -> void:
	if not card_collected and player_pos.distance_to(card_pos) < R_ITEM:
		card_collected = true; score += 20
		_feedback("Cartão coletado!", card_pos, cyan)
		message = "Cartão coletado. Vá ao Terminal A e pressione E."
		message_timer = 3.5; _beep(1047, 0.15)
		_spawn_collect_particles(card_pos, cyan)

	if door_a_open:
		if not cell_a_collected and player_pos.distance_to(cell_a_pos) < R_ITEM:
			cell_a_collected = true; _collect_cell(cell_a_pos)
		if not cell_b_collected and player_pos.distance_to(cell_b_pos) < R_ITEM:
			cell_b_collected = true; _collect_cell(cell_b_pos)
		if not cell_c_collected and player_pos.distance_to(cell_c_pos) < R_ITEM:
			cell_c_collected = true; _collect_cell(cell_c_pos)

	if not oxy_a_collected and player_pos.distance_to(oxy_a_pos) < R_ITEM:
		oxy_a_collected = true; oxygen = min(100.0, oxygen + 35.0); score += 10
		_feedback("+35 O2", oxy_a_pos, green); _beep(880, 0.12)
		message = "Oxigênio recarregado! Mantenha o O2 acima de zero."
		message_timer = 3.0; _spawn_collect_particles(oxy_a_pos, green)

	if energy_on and not oxy_b_collected and player_pos.distance_to(oxy_b_pos) < R_ITEM:
		oxy_b_collected = true; oxygen = min(100.0, oxygen + 35.0); score += 10
		_feedback("+35 O2", oxy_b_pos, green); _beep(880, 0.12)
		_spawn_collect_particles(oxy_b_pos, green)

	if laser_off and not code_collected and player_pos.distance_to(code_pos) < R_CODE:
		code_collected = true; score += 30
		_feedback("Código coletado!", code_pos, purple); _beep(1175, 0.15)
		message = "Código coletado. Use o Terminal C para liberar a saída."
		message_timer = 3.5; _spawn_collect_particles(code_pos, purple)

func _collect_cell(pos: Vector2) -> void:
	score += 15
	var c := _cells_count()
	_feedback("Célula %d/3" % c, pos, yellow); _beep(1047, 0.12)
	message = "Célula coletada: %d/3.%s" % [c, "  Vá ao Gerador!" if c == 3 else ""]
	message_timer = 2.5; _spawn_collect_particles(pos, yellow)

func _cells_count() -> int:
	return (1 if cell_a_collected else 0) + (1 if cell_b_collected else 0) + (1 if cell_c_collected else 0)

func _try_interact() -> void:
	interaction_flash = 0.35
	_beep(660, 0.06)

	if player_pos.distance_to(terminal_a_pos) < R_TERM:
		if not card_collected:
			message = "Terminal A bloqueado. Colete o cartão azul primeiro."; message_timer = 2.5; _beep(300, 0.1)
		elif not door_a_open:
			current_puzzle = 1; message = "Terminal A: resolva a equação."; message_timer = 1.5
		else:
			message = "Porta A aberta. Colete as 3 células amarelas."; message_timer = 2.0
		return

	if player_pos.distance_to(generator_pos) < R_GEN:
		if energy_on:
			message = "Gerador ligado. Avance para o Setor de Segurança."; message_timer = 2.0
		elif _cells_count() < 3:
			message = "Faltam células: %d/3." % _cells_count(); message_timer = 2.0; _beep(300, 0.1)
		else:
			energy_on = true; score += 60; action_flash = 0.8
			message = "Energia restaurada! Barreira removida."; message_timer = 3.0
			_feedback("ENERGIA ON!", generator_pos, green); _beep(880, 0.25)
			_spawn_collect_particles(generator_pos, yellow)
		return

	if player_pos.distance_to(terminal_b_pos) < R_TERM:
		if not energy_on:
			message = "Terminal B sem energia. Ligue o gerador."; message_timer = 2.5; _beep(300, 0.1)
		elif not laser_off:
			current_puzzle = 2; message = "Terminal B: resolva a equação."; message_timer = 1.5
		else:
			message = "Laser desligado. Pegue o código roxo."; message_timer = 2.0
		return

	if player_pos.distance_to(terminal_c_pos) < R_TERM:
		if not code_collected:
			message = "Terminal C bloqueado. Pegue o código roxo."; message_timer = 2.5; _beep(300, 0.1)
		elif not exit_unlocked:
			current_puzzle = 3; message = "Terminal C: resolva a equação."; message_timer = 1.5
		else:
			message = "Saída liberada! Entre e pressione E."; message_timer = 2.0
		return

	if player_pos.distance_to(exit_pos) < R_EXIT:
		if exit_unlocked:
			state = STATE_WIN; score += 100
			message = "Missão concluída! Você escapou!"; _beep(1320, 0.3)
		else:
			message = "Saída travada. Complete o Terminal C."; message_timer = 2.5; _beep(300, 0.1)
		return

	message = "Nada aqui. Siga o marcador OBJ."; message_timer = 1.5

func _answer(choice: int) -> void:
	action_flash = 0.45; _beep(700, 0.08)
	match current_puzzle:
		1:  # x+2=5 → x=3 → opção 3
			if choice == 3: _puzzle_ok(1, "x + 2 = 5 → x = 3", "PORTA A ABERTA!", terminal_a_pos)
			else: _puzzle_err("Dica: qual número + 2 = 5?")
		2:  # 3x=12 → x=4 → opção 1
			if choice == 1: _puzzle_ok(2, "3x = 12 → x = 4", "LASER DESLIGADO!", terminal_b_pos)
			else: _puzzle_err("Dica: 12 ÷ 3 = ?")
		3:  # 2x+4=10 → x=3 → opção 2
			if choice == 2: _puzzle_ok(3, "2x + 4 = 10 → x = 3", "SAÍDA LIBERADA!", terminal_c_pos)
			else: _puzzle_err("Dica: 10 - 4 = 6; 6 ÷ 2 = ?")

func _puzzle_ok(puzzle_id: int, solve_text: String, tag: String, pos: Vector2) -> void:
	match puzzle_id:
		1: door_a_open   = true; score += 50
		2: laser_off     = true; score += 70
		3: exit_unlocked = true; score += 80
	current_puzzle = 0
	message = "Correto! %s" % solve_text; message_timer = 3.5
	_feedback(tag, pos, green); _beep(1175, 0.2)
	_spawn_collect_particles(pos, green)

func _puzzle_err(hint: String) -> void:
	oxygen = max(0.0, oxygen - 8.0); score = max(0, score - 5)
	screen_flash = 0.3; message = hint; message_timer = 3.0
	_feedback("-8 O2", player_pos + Vector2(0, -40), red); _beep(200, 0.2)

# ─────────────────────────────────────────────
#  PARTÍCULAS
# ─────────────────────────────────────────────
func _spawn_collect_particles(pos: Vector2, col: Color) -> void:
	for _i in range(12):
		particles.append({
			"pos":  pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
			"vel":  Vector2(randf_range(-60, 60), randf_range(-100, -20)),
			"life": randf_range(0.5, 1.1),
			"max":  1.1,
			"r":    randf_range(2.0, 4.5),
			"col":  col
		})

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] -= delta
		p["pos"]   = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
		p["vel"]   = Vector2(p["vel"]) + Vector2(0, 120) * delta
		particles[i] = p
		if p["life"] <= 0.0: particles.remove_at(i)

# ─────────────────────────────────────────────
#  EFEITOS AMBIENTE — faíscas e fumaça
# ─────────────────────────────────────────────

# Pontos fixos de emissão de faíscas (painel danificado, fio exposto, etc.)
const SPARK_EMITTERS: Array = [
	Vector2(178, 238),   # teto sala inicial
	Vector2(540, 620),   # piso setor energia
	Vector2(770, 238),   # teto perto da barreira de energia
	Vector2(1000, 620),  # piso setor código
]

# Pontos de fumaça / vapor
const SMOKE_EMITTERS: Array = [
	Vector2(105, 620),   # cano da sala inicial
	Vector2(650, 238),   # teto setor energia
	Vector2(900, 620),   # zona de radiação
	Vector2(1080, 238),  # teto setor saída
]

func _spawn_ambient_effects(delta: float) -> void:
	# Faíscas — emite periodicamente de cada ponto
	for ep in SPARK_EMITTERS:
		if randf() < delta * 6.0:   # ~6 faíscas/seg por emissor
			for _si in range(randi_range(2, 5)):
				sparks.append({
					"pos":  Vector2(ep) + Vector2(randf_range(-6, 6), randf_range(-4, 4)),
					"vel":  Vector2(randf_range(-80, 80), randf_range(-140, -20)),
					"life": randf_range(0.18, 0.55),
					"max":  0.55,
					"col":  Color(1.0, randf_range(0.6, 1.0), randf_range(0.0, 0.3)),
					"r":    randf_range(1.2, 2.8),
				})

	# Fumaça — emite suavemente
	for sp in SMOKE_EMITTERS:
		if randf() < delta * 3.0:
			smoke.append({
				"pos":  Vector2(sp) + Vector2(randf_range(-8, 8), 0.0),
				"vel":  Vector2(randf_range(-12, 12), randf_range(-28, -10)),
				"life": randf_range(1.2, 2.4),
				"max":  2.4,
				"r":    randf_range(4.0, 9.0),
				"col":  Color(randf_range(0.55, 0.75), randf_range(0.55, 0.75), randf_range(0.65, 0.85)),
			})

func _update_ambient_effects(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var s: Dictionary = sparks[i]
		s["life"] -= delta
		s["pos"]   = Vector2(s["pos"]) + Vector2(s["vel"]) * delta
		s["vel"]   = Vector2(s["vel"]) + Vector2(0, 280) * delta   # gravidade rápida
		sparks[i] = s
		if s["life"] <= 0.0: sparks.remove_at(i)

	for i in range(smoke.size() - 1, -1, -1):
		var s: Dictionary = smoke[i]
		s["life"] -= delta
		s["pos"]   = Vector2(s["pos"]) + Vector2(s["vel"]) * delta
		s["r"]     = float(s["r"]) + delta * 5.0   # expande ao subir
		smoke[i] = s
		if s["life"] <= 0.0: smoke.remove_at(i)

# ─────────────────────────────────────────────
#  FEEDBACKS
# ─────────────────────────────────────────────
func _feedback(text: String, pos: Vector2, col: Color) -> void:
	feedbacks.append({"text": text, "pos": pos, "life": 1.6, "max": 1.6, "col": col})

func _update_feedbacks(delta: float) -> void:
	for i in range(feedbacks.size() - 1, -1, -1):
		var f: Dictionary = feedbacks[i]
		f["life"] -= delta
		f["pos"]   = Vector2(f["pos"]) + Vector2(0, -28.0 * delta)
		feedbacks[i] = f
		if f["life"] <= 0.0: feedbacks.remove_at(i)

# ─────────────────────────────────────────────
#  TECLADO
# ─────────────────────────────────────────────
func _just_pressed_key(kc: Key) -> bool:
	var now: bool = Input.is_key_pressed(kc)
	var old: bool = key_memory.get(kc, false)
	key_memory[kc] = now
	return now and not old

# ─────────────────────────────────────────────
#  SOM SINTÉTICO (beep via AudioStreamGenerator)
# ─────────────────────────────────────────────
func _beep(freq: float, duration: float) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate      = 22050.0
	gen.buffer_length = max(duration + 0.1, 0.15)
	var player := AudioStreamPlayer.new()
	player.stream    = gen
	player.volume_db = -14.0
	player.bus       = "Master"
	add_child(player)
	player.play()
	# Aguarda 1 frame para o playback ficar disponível
	await get_tree().process_frame
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return
	var samples := int(22050.0 * duration)
	var frames  := PackedVector2Array()
	frames.resize(samples)
	for i in range(samples):
		var t: float   = float(i) / 22050.0
		var env: float = clamp(1.0 - t / duration, 0.0, 1.0)
		var s: float   = sin(TAU * freq * t) * 0.38 * env
		frames[i] = Vector2(s, s)
	pb.push_buffer(frames)
	var timer := get_tree().create_timer(duration + 0.15)
	timer.timeout.connect(player.queue_free)

# ─────────────────────────────────────────────
#  DRAW PRINCIPAL
# ─────────────────────────────────────────────
func _draw() -> void:
	_draw_space_bg()
	if state != STATE_MENU:
		_draw_station()
		_draw_items()
		_draw_terminals()
		_draw_exit_obj()
		_draw_player_char()
		_draw_objective_marker()
		_draw_interact_prompt()
		_draw_particles()
		_draw_sparks_smoke()
		_draw_feedbacks_gfx()
		_draw_hud()
		if current_puzzle != 0: _draw_puzzle_panel()
		if state == STATE_PAUSE: _draw_pause()
		elif state == STATE_WIN:  _draw_end_screen(true)
		elif state == STATE_LOSE: _draw_end_screen(false)
	else:
		_draw_menu()
	# Flash de dano
	if screen_flash > 0.0:
		draw_rect(Rect2(0,0,W,H), Color(1,0,0, screen_flash * 0.5))
	# Flash de transição
	if transitioning:
		draw_rect(Rect2(0,0,W,H), Color(0,0,0, transition_alpha))

# ─────────────────────────────────────────────
#  FUNDO ESPACIAL
# ─────────────────────────────────────────────
func _draw_space_bg() -> void:
	draw_rect(Rect2(0, 0, W, H), bg)

	# Nebulosa animada (gradiente circular)
	var nb_x: float = W * 0.62 + sin(nebula_offset * 0.03) * 30.0
	var nb_y: float = H * 0.30 + cos(nebula_offset * 0.02) * 20.0
	for ring in range(8, 0, -1):
		var rr := ring * 38.0
		var aa := 0.04 - ring * 0.004
		draw_circle(Vector2(nb_x, nb_y), rr, Color(0.15, 0.05, 0.35, aa))
	for ring in range(6, 0, -1):
		var rr := ring * 28.0
		var aa := 0.03 - ring * 0.004
		draw_circle(Vector2(nb_x + 90, nb_y + 40), rr, Color(0.0, 0.10, 0.40, aa))

	# Estrelas distantes (fixas)
	for sd in stars_far:
		var sp: Dictionary = sd
		draw_circle(sp["pos"], sp["r"], Color(0.6, 0.75, 1.0, 0.35))

	# Estrelas próximas (twinkle)
	for sd in stars:
		var sp: Dictionary = sd
		var a: float = 0.30 + 0.55 * abs(sin(animation_time * sp["spd"] * 80.0 + sp["phase"]))
		draw_circle(sp["pos"], sp["r"], Color(0.75, 0.90, 1.0, a))

	# Planeta decorativo (canto superior direito)
	_draw_planet(Vector2(1140, 88), 72)

func _draw_planet(center: Vector2, radius: float) -> void:
	# Corpo do planeta
	draw_circle(center, radius, Color(0.06, 0.16, 0.42))
	# Atmosfera
	for ring in range(4):
		draw_circle(center, radius + ring * 3.5, Color(0.12, 0.35, 0.80, 0.06 - ring * 0.012))
	# Continentes / manchas
	draw_circle(center + Vector2(-18, -10), 24, Color(0.08, 0.22, 0.55))
	draw_circle(center + Vector2(20, 14),   18, Color(0.07, 0.20, 0.50))
	draw_circle(center + Vector2(-5, 22),   14, Color(0.06, 0.18, 0.48))
	# Brilho polar
	draw_circle(center + Vector2(-22, -30), 14, Color(0.75, 0.90, 1.0, 0.18))
	# Anel
	draw_line(center + Vector2(-radius - 8, 12), center + Vector2(radius + 8, -12),
			  Color(0.55, 0.75, 1.0, 0.25), 4)
	draw_line(center + Vector2(-radius - 5, 8),  center + Vector2(radius + 5, -8),
			  Color(0.55, 0.75, 1.0, 0.15), 2)
	# Limbo (borda escura)
	draw_arc(center, radius, 0, TAU, 64, Color(0.02, 0.05, 0.15, 0.6), 3)

# ─────────────────────────────────────────────
#  ESTAÇÃO ESPACIAL
# ─────────────────────────────────────────────
func _draw_station() -> void:
	var base: Rect2 = walk_zones[0]

	# ── Pisos por setor com cores distintas ──
	var sector_rects: Array = [
		Rect2(base.position.x, base.position.y, 368, base.size.y),          # sala inicial
		Rect2(base.position.x + 368, base.position.y, 368, base.size.y),    # setor energia
		Rect2(base.position.x + 736, base.position.y, 238, base.size.y),    # setor segurança
		Rect2(base.position.x + 974, base.position.y, 196, base.size.y),    # código/saída
	]
	for i in range(sector_rects.size()):
		draw_rect(sector_rects[i], sector_cols[i])

	# ── Borda da estação ──
	draw_rect(base, Color(0, 0, 0, 0), false)
	draw_rect(Rect2(base.position + Vector2(-2,-2), base.size + Vector2(4,4)), cyan, false, 2)

	# ── Grade de piso ──
	_draw_floor_grid(base)

	# ── Paredes externas ──
	var pw: int = 12
	draw_rect(Rect2(base.position.x - pw, base.position.y - pw, base.size.x + pw*2, pw), wall_col)
	draw_rect(Rect2(base.position.x - pw, base.position.y + base.size.y, base.size.x + pw*2, pw), wall_col)
	draw_rect(Rect2(base.position.x - pw, base.position.y, pw, base.size.y), wall_col)
	draw_rect(Rect2(base.position.x + base.size.x, base.position.y, pw, base.size.y), wall_col)

	# ── Detalhes arquitetônicos nas paredes ──
	_draw_wall_details(base)

	# ── Divisores de setor ──
	_draw_sector_divider(423, "PORTA A",   red   if not door_a_open else green)
	_draw_sector_divider(791, "ENERGIA",   yellow if not energy_on  else green)
	_draw_sector_divider(961, "LASER",     red   if not laser_off   else green)

	# ── Bloqueios visíveis ──
	_draw_blockers()

	# ── Zona de radiação ──
	_draw_radiation()

	# ── Iluminação de piso (pools de luz) ──
	_draw_floor_lights()

	# ── Decorações de cenário ──
	_draw_decorations()

	# ── Efeitos de ambiente (faíscas, fumaça, alarmes) ──
	_draw_ambient_fx()

	# ── Labels de setor ──
	_draw_sector_label(Vector2(85,  230), "SALA INICIAL")
	_draw_sector_label(Vector2(476, 230), "SETOR DE ENERGIA")
	_draw_sector_label(Vector2(812, 230), "SETOR DE SEGURANÇA")
	_draw_sector_label(Vector2(1000,230), "CÓDIGO/SAÍDA")

func _draw_floor_grid(r: Rect2) -> void:
	var x: float = r.position.x
	while x <= r.position.x + r.size.x:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y),
				  Color(0.18, 0.40, 0.60, 0.12), 1)
		x += 64.0
	var y: float = r.position.y
	while y <= r.position.y + r.size.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.position.x + r.size.x, y),
				  Color(0.18, 0.40, 0.60, 0.10), 1)
		y += 32.0

func _draw_wall_details(base: Rect2) -> void:
	# Painéis na parede superior
	var panel_y: float = base.position.y - 8.0
	for px in [100.0, 240.0, 480.0, 620.0, 760.0, 900.0, 1060.0, 1160.0]:
		draw_rect(Rect2(px, panel_y, 64, 8), Color(cyan.r, cyan.g, cyan.b, 0.15))
		draw_rect(Rect2(px, panel_y, 64, 8), Color(cyan.r, cyan.g, cyan.b, 0.35), false, 1)
	# Painéis na parede inferior
	var bot_y: float = base.position.y + base.size.y
	for px in [80.0, 200.0, 460.0, 600.0, 740.0, 870.0, 1020.0, 1140.0]:
		draw_rect(Rect2(px, bot_y, 64, 8), Color(cyan.r, cyan.g, cyan.b, 0.12))
		draw_rect(Rect2(px, bot_y, 64, 8), Color(cyan.r, cyan.g, cyan.b, 0.30), false, 1)
	# Luzes de teto
	for lx in [130.0, 330.0, 530.0, 700.0, 870.0, 1020.0, 1150.0]:
		draw_rect(Rect2(lx - 12, base.position.y - 2, 24, 5), Color(1,1,0.8, 0.6))
		draw_circle(Vector2(lx, base.position.y + 1), 3, Color(1,1,0.9, 0.9))

func _draw_sector_divider(x: float, label: String, col: Color) -> void:
	draw_line(Vector2(x, 248), Vector2(x, 612), Color(col.r, col.g, col.b, 0.30), 1)
	var tx: float = x - 28.0
	draw_rect(Rect2(tx - 2, 260, label.length() * 7 + 6, 16), Color(0,0,0,0.7))
	draw_string(ThemeDB.fallback_font, Vector2(tx, 274), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(col.r, col.g, col.b, 0.85))

func _draw_blockers() -> void:
	# ── PORTA A ──
	if not door_a_open:
		# Parede sólida opaca — bloqueia completamente a visão
		_draw_solid_wall(Rect2(415, 238, 36, 382), red, "PORTA A")
	else:
		_draw_open_indicator(Vector2(370, 295), "ABERTA", green)

	# ── BARREIRA DE ENERGIA ──
	if not energy_on:
		_draw_solid_wall(Rect2(783, 238, 36, 382), yellow, "ENERGIA")
	else:
		_draw_open_indicator(Vector2(753, 295), "ENERGIA OK", green)

	# ── LASER ──
	if not laser_off:
		_draw_laser_gate(Rect2(955, 238, 32, 382))
	else:
		_draw_open_indicator(Vector2(942, 295), "LASER OFF", green)

# Parede TOTALMENTE opaca — nada do outro lado é visível
func _draw_solid_wall(r: Rect2, col: Color, lbl: String) -> void:
	var pulse: float = 0.55 + 0.45 * abs(sin(animation_time * 3.0))

	# 1) Bloco de concreto/metal — preenchimento sólido, zero transparência
	draw_rect(r, Color(0.04, 0.06, 0.10))           # base escura quase preta
	# Camadas de placa metálica
	var stripe_h: float = 24.0
	var sy: float = r.position.y
	var flip: bool = false
	while sy < r.position.y + r.size.y:
		var ch: float = min(stripe_h, r.position.y + r.size.y - sy)
		var c: Color = Color(0.10, 0.13, 0.18) if flip else Color(0.07, 0.09, 0.14)
		draw_rect(Rect2(r.position.x, sy, r.size.x, ch), c)
		# Parafuso nas placas
		if ch >= stripe_h:
			draw_circle(Vector2(r.position.x + 6, sy + 6), 2.5, Color(0.25, 0.30, 0.38))
			draw_circle(Vector2(r.position.x + r.size.x - 6, sy + 6), 2.5, Color(0.25, 0.30, 0.38))
		sy += stripe_h
		flip = not flip

	# 2) Faixa de aviso diagonal (hazard stripes)
	var stripe_w: float = 14.0
	var sx2: float = r.position.x - r.size.y   # começa fora para cobrir toda a altura
	while sx2 < r.position.x + r.size.x + r.size.y:
		var x1: float = clamp(sx2,              r.position.x, r.position.x + r.size.x)
		var x2: float = clamp(sx2 + stripe_w,  r.position.x, r.position.x + r.size.x)
		if x2 > x1:
			# triângulo / paralelogramo diagonal
			var pts := PackedVector2Array([
				Vector2(x1, r.position.y),
				Vector2(x2, r.position.y),
				Vector2(x2 + r.size.y, r.position.y + r.size.y),
				Vector2(x1 + r.size.y, r.position.y + r.size.y),
			])
			draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.12))
		sx2 += stripe_w * 2.0

	# 3) Luz de status pulsante (LEDs ao longo da borda)
	var led_step: float = 40.0
	var lly: float = r.position.y + 20.0
	while lly < r.position.y + r.size.y - 10:
		var la: float = pulse if fmod((lly - r.position.y) / led_step, 2.0) < 1.0 else 1.0 - pulse
		draw_circle(Vector2(r.position.x + r.size.x * 0.5, lly), 3.5,
					Color(col.r, col.g, col.b, 0.4 + la * 0.6))
		lly += led_step

	# 4) Bordas da parede
	draw_rect(r, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5), false, 2)
	draw_rect(r, Color(col.r, col.g, col.b, 0.6 + pulse * 0.4), false, 1)

	# 5) Label + ícone de cadeado acima
	var lx: float = r.get_center().x - 28.0
	draw_rect(Rect2(lx - 2, r.position.y - 22, 62, 20), Color(0,0,0,0.85))
	draw_string(ThemeDB.fallback_font, Vector2(lx, r.position.y - 6), "🔒 " + lbl,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)

func _draw_laser_gate(r: Rect2) -> void:
	var pulse: float = 0.5 + 0.5 * abs(sin(animation_time * 5.0))

	# Base da parede do laser (opaca)
	draw_rect(r, Color(0.08, 0.03, 0.06))
	var sy: float = r.position.y
	var flip: bool = false
	while sy < r.position.y + r.size.y:
		var ch: float = min(20.0, r.position.y + r.size.y - sy)
		draw_rect(Rect2(r.position.x, sy, r.size.x, ch),
				  Color(0.12, 0.04, 0.08) if flip else Color(0.08, 0.03, 0.05))
		sy += 20.0; flip = not flip

	# Emissores do laser (caixinhas nas bordas)
	for emy in [r.position.y + 12, r.get_center().y, r.position.y + r.size.y - 12]:
		draw_rect(Rect2(r.position.x - 4, emy - 5, r.size.x + 8, 10), Color(0.25, 0.05, 0.10))
		draw_rect(Rect2(r.position.x - 4, emy - 5, r.size.x + 8, 10),
				  Color(red.r, red.g, red.b, 0.8), false, 1)
		draw_circle(Vector2(r.get_center().x, emy), 3.5,
					Color(1.0, 0.3, 0.4, 0.6 + pulse * 0.4))

	# Feixes de laser (linhas vermelhas brilhantes entre emissores)
	var beam_x: float = r.get_center().x
	var y: float = r.position.y
	while y < r.position.y + r.size.y:
		var ba: float = 0.4 + 0.6 * abs(sin(animation_time * 8.0 + y * 0.05))
		draw_line(Vector2(beam_x - r.size.x * 0.3, y),
				  Vector2(beam_x + r.size.x * 0.3, y + 3.0),
				  Color(1.0, 0.1, 0.2, ba * pulse), 2)
		y += 8.0

	# Borda vermelha
	draw_rect(r, Color(red.r, red.g, red.b, 0.4 + pulse * 0.6), false, 2)

	# Label
	var lx: float = r.get_center().x - 26.0
	draw_rect(Rect2(lx - 2, r.position.y - 22, 58, 20), Color(0,0,0,0.85))
	draw_string(ThemeDB.fallback_font, Vector2(lx, r.position.y - 6), "⚡ LASER",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, red)

func _draw_open_indicator(pos: Vector2, text: String, col: Color) -> void:
	draw_rect(Rect2(pos.x - 4, pos.y - 16, text.length() * 8 + 10, 20), Color(0,0,0,0.65))
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _draw_radiation() -> void:
	for z in radiation_zones:
		var r: Rect2 = z
		var a: float = 0.30 + 0.22 * abs(sin(animation_time * 4.5))
		# Preenchimento
		draw_rect(r, Color(red.r, red.g, red.b, a * 0.55))
		# Grade hazard
		var sz: float = 14.0
		var xi: float = r.position.x
		while xi < r.position.x + r.size.x:
			var yi: float = r.position.y
			while yi < r.position.y + r.size.y:
				var c: Color = Color(1, 0.2, 0.3, 0.18) if fmod((xi + yi) / sz, 2.0) < 1.0 else Color(0.1, 0.0, 0.0, 0.1)
				draw_rect(Rect2(xi, yi, sz, sz), c)
				yi += sz
			xi += sz
		draw_rect(r, red, false, 2)
		draw_string(ThemeDB.fallback_font, r.position + Vector2(6, 16), "⚠", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		draw_string(ThemeDB.fallback_font, r.position + Vector2(6, 34), "RAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_ambient_fx() -> void:
	# ── Fumaça (atrás de tudo) ──
	for item in smoke:
		var s: Dictionary = item
		var a: float = clamp(float(s["life"]) / float(s["max"]), 0.0, 1.0) * 0.28
		var col: Color = Color(s["col"]); col.a = a
		draw_circle(Vector2(s["pos"]), float(s["r"]), col)

	# ── Faíscas ──
	for item in sparks:
		var s: Dictionary = item
		var a: float = clamp(float(s["life"]) / float(s["max"]), 0.0, 1.0)
		var col: Color = Color(s["col"]); col.a = a
		draw_circle(Vector2(s["pos"]), float(s["r"]) * a, col)
		# rastro da faísca
		var trail: Vector2 = Vector2(s["pos"]) - Vector2(s["vel"]).normalized() * 6.0
		draw_line(Vector2(s["pos"]), trail,
				  Color(col.r, col.g, col.b, a * 0.5), 1)

	# ── Alarmes de parede piscantes ──
	_draw_wall_alarms()

	# ── Névoa de O2 crítico ──
	if o2_critical and state == STATE_PLAY:
		_draw_o2_critical_vignette()

# Luminárias de alarme nas paredes — piscam vermelho quando uma barreira está ativa
func _draw_wall_alarms() -> void:
	var base: Rect2 = walk_zones[0]
	var alarm_positions: Array = []

	if not door_a_open:
		alarm_positions.append_array([
			Vector2(380, base.position.y + 8),
			Vector2(380, base.position.y + base.size.y - 8),
		])
	if not energy_on:
		alarm_positions.append_array([
			Vector2(748, base.position.y + 8),
			Vector2(748, base.position.y + base.size.y - 8),
		])
	if not laser_off:
		alarm_positions.append_array([
			Vector2(920, base.position.y + 8),
			Vector2(920, base.position.y + base.size.y - 8),
		])

	var blink: float = abs(sin(animation_time * 3.5))
	for ap in alarm_positions:
		var apos: Vector2 = ap
		# Halo projetado na parede
		draw_circle(apos, 18, Color(red.r, red.g, red.b, blink * 0.18))
		# Corpo da luminária
		draw_circle(apos, 7, Color(0.15, 0.05, 0.06))
		draw_circle(apos, 7, Color(red.r, red.g, red.b, 0.3 + blink * 0.7), false, 2)
		# Lente interna acesa
		draw_circle(apos, 4, Color(1.0, 0.2, 0.2, 0.4 + blink * 0.6))
		draw_circle(apos + Vector2(-1.5, -1.5), 1.5, Color(1, 1, 1, 0.5 * blink))

# Vinheta de névoa vermelha nas bordas quando O2 crítico
func _draw_o2_critical_vignette() -> void:
	var blink: float = 0.3 + 0.4 * abs(sin(animation_time * 4.5))
	var base: Rect2 = walk_zones[0]
	# Bordas internas vermelhas pulsantes
	for edge_w in [6, 12, 18]:
		var alpha: float = blink * (0.22 - edge_w * 0.008)
		# Topo
		draw_rect(Rect2(base.position.x, base.position.y, base.size.x, edge_w),
				  Color(red.r, red.g, red.b, alpha))
		# Base
		draw_rect(Rect2(base.position.x, base.position.y + base.size.y - edge_w,
						base.size.x, edge_w),
				  Color(red.r, red.g, red.b, alpha))
		# Esquerda
		draw_rect(Rect2(base.position.x, base.position.y, edge_w, base.size.y),
				  Color(red.r, red.g, red.b, alpha))
		# Direita
		draw_rect(Rect2(base.position.x + base.size.x - edge_w, base.position.y,
						edge_w, base.size.y),
				  Color(red.r, red.g, red.b, alpha))

func _draw_floor_lights() -> void:
	# Pools de luz coloridos por setor no piso
	var lights: Array = [
		{"pos": Vector2(200, 540), "col": Color(0.15, 0.55, 1.0, 0.08), "r": 90.0},
		{"pos": Vector2(600, 400), "col": Color(0.15, 0.80, 0.40, 0.07), "r": 100.0},
		{"pos": Vector2(880, 500), "col": Color(0.60, 0.20, 1.0, 0.07), "r": 85.0},
		{"pos": Vector2(1100, 520), "col": Color(1.0, 0.30, 0.40, 0.07), "r": 80.0},
	]
	for l in lights:
		var ld: Dictionary = l
		var pulse: float = 0.85 + 0.15 * sin(animation_time * 1.8)
		for ring in range(4, 0, -1):
			draw_circle(ld["pos"], ld["r"] * ring * 0.28 * pulse,
						Color(ld["col"].r, ld["col"].g, ld["col"].b, ld["col"].a * (1.0 - ring * 0.2)))

func _draw_decorations() -> void:
	# ── Sala inicial ──
	_draw_console_panel(Vector2(95, 295), 120, 55, "O2 BAY")
	_draw_console_panel(Vector2(250, 300), 105, 50, "MAPA")
	_draw_crate(Vector2(138, 585)); _draw_crate(Vector2(210, 585))
	# Tubulações
	_draw_pipe(Vector2(60, 330), Vector2(60, 530), cyan_dim)
	_draw_pipe(Vector2(60, 430), Vector2(160, 430), cyan_dim)

	# ── Setor de energia ──
	_draw_console_panel(Vector2(620, 382), 130, 54, "GERADOR")
	# Cabo de energia
	draw_line(Vector2(640, 436), Vector2(785, 436), orange, 4)
	draw_line(Vector2(640, 441), Vector2(785, 441), Color("#74340f"), 2)
	_draw_crate(Vector2(565, 585)); _draw_crate(Vector2(738, 585))
	_draw_pipe(Vector2(795, 280), Vector2(795, 380), yellow)

	# ── Setor de segurança ──
	_draw_console_panel(Vector2(836, 305), 100, 46, "COMANDO")
	_draw_crate(Vector2(990, 300))
	_draw_pipe(Vector2(963, 238), Vector2(963, 350), red)

	# ── Código/saída ──
	_draw_console_panel(Vector2(1032, 308), 105, 46, "SAÍDA EMER.")
	_draw_crate(Vector2(1098, 585))

func _draw_console_panel(pos: Vector2, w: float, h: float, label: String) -> void:
	var r: Rect2 = Rect2(pos, Vector2(w, h))
	draw_rect(r, Color("#071d31"))
	draw_rect(r, cyan_dim, false, 1)
	draw_rect(r, cyan, false, 1)
	# Indicador LED
	var led_on: bool = true
	draw_circle(pos + Vector2(w - 10, 10), 4, green if led_on else red)
	# Tela simulada
	draw_rect(Rect2(pos + Vector2(6, 14), Vector2(w - 12, h - 22)), Color("#020c18"))
	var lines: int = int((h - 24) / 10)
	for i in range(lines):
		var lw: float = randf_range(w * 0.3, w * 0.7)
		draw_rect(Rect2(pos + Vector2(8, 16 + i * 10), Vector2(lw, 4)),
				  Color(cyan.r, cyan.g, cyan.b, 0.25))
	draw_string(ThemeDB.fallback_font, pos + Vector2(6, -6), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9de9ff"))

func _draw_pipe(from: Vector2, to: Vector2, col: Color) -> void:
	draw_line(from, to, Color(col.r, col.g, col.b, 0.5), 5)
	draw_line(from, to, Color(col.r, col.g, col.b, 0.9), 2)
	# Flange nas pontas
	var perp: Vector2 = (to - from).normalized().rotated(PI / 2.0) * 5.0
	draw_line(from - perp, from + perp, col, 3)
	draw_line(to   - perp, to   + perp, col, 3)

func _draw_crate(pos: Vector2) -> void:
	var r: Rect2 = Rect2(pos - Vector2(18, 18), Vector2(36, 36))
	draw_rect(r, Color("#1e2e44"))
	draw_rect(r, Color("#8fb3df"), false, 1)
	draw_line(r.position, r.position + r.size, Color(0.56, 0.70, 0.87, 0.5), 1)
	draw_line(r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), Color(0.56, 0.70, 0.87, 0.5), 1)
	# Faixa de perigo
	for i in range(3):
		var hy: float = r.position.y + i * 12.0
		draw_rect(Rect2(r.position.x, hy, 36, 6),
				  Color(1.0, 0.7, 0.0, 0.12) if i % 2 == 0 else Color(0,0,0,0.08))

func _draw_sector_label(pos: Vector2, text: String) -> void:
	draw_rect(Rect2(pos.x - 6, pos.y - 18, text.length() * 8 + 14, 22), Color(0.01, 0.02, 0.06, 0.90))
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.88, 1.0, 0.95))

# ─────────────────────────────────────────────
#  ITENS COLETÁVEIS
# ─────────────────────────────────────────────
func _draw_items() -> void:
	if not card_collected:     _draw_card(card_pos)
	if door_a_open:
		if not cell_a_collected: _draw_battery(cell_a_pos)
		if not cell_b_collected: _draw_battery(cell_b_pos)
		if not cell_c_collected: _draw_battery(cell_c_pos)
	if not oxy_a_collected:    _draw_o2_cylinder(oxy_a_pos)
	if energy_on and not oxy_b_collected: _draw_o2_cylinder(oxy_b_pos)
	if laser_off and not code_collected:  _draw_code_chip(code_pos)

# ── Cartão de acesso (retângulo ciano com chip) ──
func _draw_card(pos: Vector2) -> void:
	var bob: float = sin(animation_time * 3.2) * 3.0
	var p: Vector2 = pos + Vector2(0, bob)
	var pulse: float = 0.6 + 0.4 * abs(sin(animation_time * 4.0))

	# Sombra
	draw_rect(Rect2(p.x - 16, p.y + 18, 32, 6), Color(0,0,0,0.4))
	# Aura
	draw_rect(Rect2(p.x - 20, p.y - 26, 40, 52), Color(cyan.r, cyan.g, cyan.b, 0.08 * pulse))
	# Corpo do cartão
	draw_rect(Rect2(p.x - 16, p.y - 22, 32, 40), Color(0.05, 0.25, 0.45))
	draw_rect(Rect2(p.x - 16, p.y - 22, 32, 40), Color(cyan.r, cyan.g, cyan.b, pulse), false, 2)
	# Chip dourado
	draw_rect(Rect2(p.x - 7, p.y - 14, 14, 10), Color(0.85, 0.70, 0.15))
	draw_rect(Rect2(p.x - 7, p.y - 14, 14, 10), Color(1.0, 0.85, 0.3), false, 1)
	for ci in range(3):
		draw_line(Vector2(p.x - 4 + ci * 4, p.y - 14), Vector2(p.x - 4 + ci * 4, p.y - 4),
				  Color(0.55, 0.45, 0.08), 1)
	# Faixa magnética
	draw_rect(Rect2(p.x - 16, p.y + 6, 32, 5), Color(0.08, 0.08, 0.08))
	# Logo GZ
	draw_string(ThemeDB.fallback_font, Vector2(p.x - 8, p.y + 18),
				"GZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(cyan.r, cyan.g, cyan.b, 0.8))
	# Label flutuante
	_draw_item_label(p + Vector2(0, -34), "CARTÃO", cyan)

# ── Bateria de energia (célula AA espacial) ──
func _draw_battery(pos: Vector2) -> void:
	var bob: float = sin(animation_time * 3.8) * 3.5
	var p: Vector2 = pos + Vector2(0, bob)
	var pulse: float = 0.55 + 0.45 * abs(sin(animation_time * 5.0))
	var charge: float = 0.75 + 0.25 * abs(sin(animation_time * 2.0))  # nível simulado

	# Sombra
	draw_circle(p + Vector2(0, 22), 10, Color(0,0,0,0.4))
	# Aura amarela
	draw_circle(p, 22 * pulse, Color(yellow.r, yellow.g, yellow.b, 0.12))

	# Corpo principal da bateria (retângulo arredondado simulado)
	draw_rect(Rect2(p.x - 10, p.y - 20, 20, 38), Color(0.18, 0.18, 0.20))
	draw_rect(Rect2(p.x - 10, p.y - 20, 20, 38), Color(0.35, 0.35, 0.38), false, 1)

	# Terminal positivo (polo superior)
	draw_rect(Rect2(p.x - 4, p.y - 25, 8, 6), Color(0.60, 0.60, 0.65))
	draw_rect(Rect2(p.x - 4, p.y - 25, 8, 6), Color(0.85, 0.85, 0.90), false, 1)
	# Terminal negativo (polo inferior)
	draw_rect(Rect2(p.x - 8, p.y + 18, 16, 3), Color(0.40, 0.40, 0.44))

	# Etiqueta da bateria (faixa central)
	draw_rect(Rect2(p.x - 10, p.y - 8, 20, 20), Color(0.15, 0.35, 0.08))
	draw_rect(Rect2(p.x - 10, p.y - 8, 20, 20), Color(yellow.r, yellow.g, yellow.b, 0.5), false, 1)

	# Símbolo de raio na etiqueta
	var bolt: PackedVector2Array = PackedVector2Array([
		Vector2(p.x + 2, p.y - 6),
		Vector2(p.x - 3, p.y + 1),
		Vector2(p.x + 1, p.y + 1),
		Vector2(p.x - 2, p.y + 10),
		Vector2(p.x + 4, p.y + 2),
		Vector2(p.x,     p.y + 2),
	])
	draw_colored_polygon(bolt, Color(yellow.r, yellow.g, yellow.b, 0.95))

	# Indicador de carga (barrinhas laterais)
	for bi in range(4):
		var bfill: float = float(bi) / 3.0
		var ba: float = 0.9 if bfill <= charge else 0.18
		draw_rect(Rect2(p.x + 11, p.y + 15 - bi * 8, 4, 5),
				  Color(yellow.r, yellow.g, yellow.b, ba))

	# Brilho no canto superior esquerdo
	draw_line(Vector2(p.x - 9, p.y - 19), Vector2(p.x - 5, p.y - 19),
			  Color(1,1,1,0.25), 1)

	_draw_item_label(p + Vector2(0, -38), "BATERIA", yellow)

# ── Cilindro de O2 (tanque pressurizado) ──
func _draw_o2_cylinder(pos: Vector2) -> void:
	var bob: float = sin(animation_time * 2.8 + pos.x * 0.01) * 3.0
	var p: Vector2 = pos + Vector2(0, bob)
	var pulse: float = 0.5 + 0.5 * abs(sin(animation_time * 3.5))

	# Sombra
	draw_rect(Rect2(p.x - 10, p.y + 22, 20, 5), Color(0,0,0,0.45))
	# Aura verde
	draw_circle(p, 24 * pulse, Color(green.r, green.g, green.b, 0.10))

	# Corpo do cilindro
	draw_rect(Rect2(p.x - 9, p.y - 18, 18, 38), Color(0.08, 0.32, 0.22))
	draw_rect(Rect2(p.x - 9, p.y - 18, 18, 38), Color(0.15, 0.55, 0.38), false, 1)

	# Tampa superior (abóbada)
	draw_circle(Vector2(p.x, p.y - 18), 9, Color(0.10, 0.38, 0.26))
	draw_arc(Vector2(p.x, p.y - 18), 9, PI, TAU, 16,
			 Color(0.25, 0.70, 0.50), 2)

	# Tampa inferior
	draw_circle(Vector2(p.x, p.y + 20), 9, Color(0.06, 0.22, 0.16))

	# Válvula / registro no topo
	draw_rect(Rect2(p.x - 3, p.y - 30, 6, 13), Color(0.50, 0.50, 0.55))
	draw_rect(Rect2(p.x - 5, p.y - 32, 10, 4), Color(0.40, 0.40, 0.45))
	draw_rect(Rect2(p.x - 5, p.y - 32, 10, 4), Color(0.75, 0.75, 0.80), false, 1)

	# Faixas de segurança (brancas horizontais)
	for fi in range(3):
		draw_rect(Rect2(p.x - 9, p.y - 10 + fi * 12, 18, 3),
				  Color(1,1,1, 0.12))

	# Rótulo "O2" na lateral
	draw_rect(Rect2(p.x - 7, p.y - 6, 14, 14), Color(0.05, 0.18, 0.12))
	draw_rect(Rect2(p.x - 7, p.y - 6, 14, 14), Color(green.r, green.g, green.b, 0.6), false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(p.x - 5, p.y + 6),
				"O2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color(green.r, green.g, green.b, 0.9 + pulse * 0.1))

	# Indicador de pressão (ponteiro animado)
	var gauge_ang: float = -PI * 0.75 + fposmod(animation_time * 0.3, PI * 0.5 + 0.01) * 0.4
	draw_arc(Vector2(p.x, p.y + 8), 5, -PI * 0.75, PI * 0.25 + 0.5, 16,
			 Color(0.3, 0.3, 0.35), 1)
	draw_line(Vector2(p.x, p.y + 8),
			  Vector2(p.x + cos(gauge_ang) * 4, p.y + 8 + sin(gauge_ang) * 4),
			  Color(green.r, green.g, green.b, 0.8), 1)

	# Névoa de O2 saindo pela válvula (partícula estática animada)
	for gi in range(3):
		var gx: float = p.x + sin(animation_time * 2.0 + gi * 2.1) * 4.0
		var gy: float = p.y - 34 - gi * 5.0 - fmod(animation_time * 12.0, 12.0)
		draw_circle(Vector2(gx, gy), 2.5 - gi * 0.6,
					Color(green.r, green.g, green.b, (0.35 - gi * 0.1) * pulse))

	_draw_item_label(p + Vector2(0, -46), "OXIGÊNIO", green)

# ── Chip / código de acesso (roxo) ──
func _draw_code_chip(pos: Vector2) -> void:
	var bob: float = sin(animation_time * 4.0) * 4.0
	var p: Vector2 = pos + Vector2(0, bob)
	var pulse: float = 0.5 + 0.5 * abs(sin(animation_time * 6.0))

	# Sombra
	draw_circle(p + Vector2(0, 18), 12, Color(0,0,0,0.4))
	# Aura
	draw_circle(p, 24 * pulse, Color(purple.r, purple.g, purple.b, 0.15))

	# Placa do chip (PCB verde escuro)
	draw_rect(Rect2(p.x - 14, p.y - 14, 28, 28), Color(0.04, 0.14, 0.08))
	draw_rect(Rect2(p.x - 14, p.y - 14, 28, 28), Color(purple.r, purple.g, purple.b, pulse), false, 2)

	# Pinos de conexão (laterais)
	for pi2 in range(4):
		var py2: float = p.y - 9 + pi2 * 6
		draw_rect(Rect2(p.x - 18, py2, 5, 3), Color(0.7, 0.6, 0.1))  # esquerda
		draw_rect(Rect2(p.x + 13, py2, 5, 3), Color(0.7, 0.6, 0.1))  # direita

	# Die central (quadrado cinza)
	draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color(0.20, 0.20, 0.22))
	draw_rect(Rect2(p.x - 7, p.y - 7, 14, 14), Color(purple.r, purple.g, purple.b, 0.7), false, 1)

	# Trilhas no PCB
	for tri in range(3):
		draw_line(Vector2(p.x - 14, p.y - 8 + tri * 8),
				  Vector2(p.x - 7,  p.y - 8 + tri * 8),
				  Color(purple.r, purple.g, purple.b, 0.4), 1)
		draw_line(Vector2(p.x + 7,  p.y - 8 + tri * 8),
				  Vector2(p.x + 14, p.y - 8 + tri * 8),
				  Color(purple.r, purple.g, purple.b, 0.4), 1)

	# Brilho central pulsante
	draw_circle(p, 4 * pulse, Color(1, 1, 1, 0.3 * pulse))

	_draw_item_label(p + Vector2(0, -28), "CÓDIGO", purple)

# Label flutuante padronizado
func _draw_item_label(pos: Vector2, text: String, col: Color) -> void:
	var lw: float = text.length() * 7.2 + 10.0
	draw_rect(Rect2(pos.x - lw * 0.5, pos.y - 14, lw, 16), Color(0,0,0,0.72))
	draw_rect(Rect2(pos.x - lw * 0.5, pos.y - 14, lw, 16),
			  Color(col.r, col.g, col.b, 0.35), false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - lw * 0.5 + 5, pos.y - 2),
				text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

# ─────────────────────────────────────────────
#  TERMINAIS E GERADOR
# ─────────────────────────────────────────────
func _draw_terminals() -> void:
	_draw_terminal_box(terminal_a_pos, "TERMINAL A", "x + 2 = 5",  door_a_open, card_collected)
	_draw_generator_box(generator_pos)
	_draw_terminal_box(terminal_b_pos, "TERMINAL B", "3x = 12",    laser_off,   energy_on)
	_draw_terminal_box(terminal_c_pos, "TERMINAL C", "2x + 4 = 10", exit_unlocked, code_collected)

func _draw_terminal_box(pos: Vector2, title: String, eq: String, solved: bool, active: bool) -> void:
	var near: bool = player_pos.distance_to(pos) < R_TERM + 4.0 and state == STATE_PLAY and current_puzzle == 0
	var border: Color = green if solved else (cyan if active else Color("#3a4f60"))

	# Glow ao se aproximar
	if near and not solved:
		var glow: float = 0.3 + 0.3 * abs(sin(animation_time * 5.0))
		draw_circle(pos, 52, Color(cyan.r, cyan.g, cyan.b, glow * 0.20))

	var body: Rect2 = Rect2(pos - Vector2(36, 38), Vector2(72, 76))
	# Sombra
	draw_rect(Rect2(body.position + Vector2(3,3), body.size), Color(0,0,0,0.5))
	# Corpo
	draw_rect(body, Color("#060f1c"))
	draw_rect(body, border, false, 3)
	# Tela interna
	var screen: Rect2 = Rect2(pos - Vector2(28, 28), Vector2(56, 32))
	draw_rect(screen, Color("#020810"))
	draw_rect(screen, Color(border.r, border.g, border.b, 0.4), false, 1)
	# Equação na tela
	draw_string(ThemeDB.fallback_font, screen.position + Vector2(4, 22), eq,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9de9ff"))
	# LED de status
	draw_circle(pos + Vector2(28, -30), 5, green if solved else (yellow if active else Color("#3a4f60")))
	# Tecla E
	_draw_key_hint(pos + Vector2(-8, 26))
	# Label acima
	draw_string(ThemeDB.fallback_font, pos + Vector2(-52, -52), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_generator_box(pos: Vector2) -> void:
	var near:   bool  = player_pos.distance_to(pos) < R_GEN + 4.0 and state == STATE_PLAY and current_puzzle == 0
	var solved: bool  = energy_on
	var ready:  bool  = _cells_count() >= 3
	var border: Color = green if solved else (yellow if ready else cyan)

	if near and not solved:
		var glow: float = 0.3 + 0.3 * abs(sin(animation_time * 5.0))
		draw_circle(pos, 58, Color(yellow.r, yellow.g, yellow.b, glow * 0.20))

	var body: Rect2 = Rect2(pos - Vector2(44, 40), Vector2(88, 80))
	draw_rect(Rect2(body.position + Vector2(3,3), body.size), Color(0,0,0,0.5))
	draw_rect(body, Color("#060f1c"))
	draw_rect(body, border, false, 3)

	# Rotor central
	var ang: float = animation_time * (3.0 if solved else 0.8)
	for spoke in range(6):
		var a: float = ang + spoke * TAU / 6.0
		draw_line(pos, pos + Vector2(cos(a), sin(a)) * 16.0,
				  Color(border.r, border.g, border.b, 0.7), 2)
	draw_circle(pos, 7, Color("#445160"))
	draw_circle(pos, 4, border)

	draw_circle(pos + Vector2(32, -32), 5, green if solved else (yellow if ready else Color("#3a4f60")))
	_draw_key_hint(pos + Vector2(-8, 28))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-52, -54), "GERADOR",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-44, -40), "CÉLULAS %d/3" % _cells_count(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#dcefff"))

func _draw_key_hint(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(20, 20)), Color("#111f30"))
	draw_rect(Rect2(pos, Vector2(20, 20)), Color("#4a6e8a"), false, 1)
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, 16), "E",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

func _draw_exit_obj() -> void:
	var near: bool = player_pos.distance_to(exit_pos) < R_EXIT + 4.0 and state == STATE_PLAY
	var col:  Color = green if exit_unlocked else red

	if near and exit_unlocked:
		var glow: float = 0.4 + 0.4 * abs(sin(animation_time * 5.0))
		draw_circle(exit_pos, 52, Color(green.r, green.g, green.b, glow * 0.3))

	# Portal / escotilha
	draw_circle(exit_pos, 30, Color(col.r, col.g, col.b, 0.12))
	draw_arc(exit_pos, 30, 0, TAU, 64, col, 3)
	draw_arc(exit_pos, 22, 0, TAU, 48, Color(col.r, col.g, col.b, 0.5), 1)
	# Símbolo interior
	draw_string(ThemeDB.fallback_font, exit_pos + Vector2(-8, 6), "E",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	# Label
	var tag: String = "SAÍDA" if not exit_unlocked else "ESCAPE!"
	draw_string(ThemeDB.fallback_font, exit_pos + Vector2(-22, -40), tag,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	if not exit_unlocked:
		draw_string(ThemeDB.fallback_font, exit_pos + Vector2(-16, 44), "LOCK",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, red)

# ─────────────────────────────────────────────
#  PERSONAGEM — ASTRONAUTA DETALHADO
# ─────────────────────────────────────────────
func _draw_player_char() -> void:
	var p: Vector2 = player_pos
	var t: float   = animation_time
	var bob: float = 0.0
	var leg: float = 0.0
	var arm: float = 0.0

	if player_moving:
		var spd: float = 10.0 if player_running else 7.0
		bob = sin(t * spd) * 3.2
		leg = sin(t * spd) * 10.0
		arm = sin(t * spd + PI) * 8.0
	else:
		bob = sin(t * 1.8) * 1.8   # idle flutuante suave

	var fx: float = float(player_face)   # 1 = direita, -1 = esquerda

	# Auras de interação
	if interaction_flash > 0.0:
		draw_circle(p, 38, Color(cyan.r, cyan.g, cyan.b, interaction_flash * 0.35))
	if action_flash > 0.0:
		draw_circle(p, 52, Color(yellow.r, yellow.g, yellow.b, action_flash * 0.22))

	# Sombra no piso
	draw_circle(p + Vector2(0, 22), 18, Color(0, 0, 0, 0.5))

	var by: float = p.y + bob  # base Y com bob

	# ── MOCHILA / TANQUE DE O2 (atrás do corpo) ──
	var tk_x: float = p.x - fx * 10.0
	draw_rect(Rect2(tk_x - 7, by - 12, 14, 26), Color("#2a3f55"))
	draw_rect(Rect2(tk_x - 7, by - 12, 14, 26), Color("#4a7090"), false, 1)
	# Detalhes do tanque
	draw_rect(Rect2(tk_x - 5, by - 8, 10, 4), Color(cyan.r, cyan.g, cyan.b, 0.5))
	draw_rect(Rect2(tk_x - 5, by + 4, 10, 4), Color(cyan.r, cyan.g, cyan.b, 0.5))
	# Indicador de O2 no tanque
	var o2_h: float = 16.0 * (oxygen / 100.0)
	draw_rect(Rect2(tk_x - 3, by + 10 - o2_h, 6, o2_h), Color(green.r, green.g, green.b, 0.8))
	# Tubo conectando ao traje
	draw_line(Vector2(tk_x + fx * 7, by - 2), Vector2(p.x - fx * 11, by + 4),
			  Color("#4a7090"), 2)

	# ── PERNAS ──
	var leg_col: Color = Color("#c8ddf0")
	# Perna esquerda
	var ll_hip: Vector2 = Vector2(p.x - 9, by + 22)
	var ll_knee: Vector2 = ll_hip + Vector2(-2, 12 + leg * 0.3)
	var ll_foot: Vector2 = ll_knee + Vector2(-1, 10 - leg * 0.15)
	draw_line(ll_hip,  ll_knee, leg_col, 6)
	draw_line(ll_knee, ll_foot, leg_col, 5)
	# Perna direita
	var rl_hip: Vector2 = Vector2(p.x + 9, by + 22)
	var rl_knee: Vector2 = rl_hip + Vector2(2, 12 - leg * 0.3)
	var rl_foot: Vector2 = rl_knee + Vector2(1, 10 + leg * 0.15)
	draw_line(rl_hip,  rl_knee, leg_col, 6)
	draw_line(rl_knee, rl_foot, leg_col, 5)
	# Botas
	draw_circle(ll_foot, 5, Color("#3a5570"))
	draw_circle(rl_foot, 5, Color("#3a5570"))

	# ── CORPO / TRAJE ──
	# Torso principal
	draw_rect(Rect2(p.x - 13, by - 4, 26, 28), Color("#ddeeff"))
	# Detalhes do traje
	draw_rect(Rect2(p.x - 13, by - 4, 26, 28), Color("#5a8aaa"), false, 1)
	# Cinto / cintura
	draw_rect(Rect2(p.x - 14, by + 14, 28, 8), Color("#2255aa"))
	draw_rect(Rect2(p.x - 14, by + 14, 28, 8), Color(cyan.r, cyan.g, cyan.b, 0.6), false, 1)
	# Placa de identificação
	draw_rect(Rect2(p.x - 6, by + 2, 12, 8), Color("#1a3350"))
	draw_rect(Rect2(p.x - 6, by + 2, 12, 8), Color("#4a8ab0"), false, 1)
	# Logo / patch no peito
	draw_circle(Vector2(p.x + fx * 5, by + 10), 4, Color(cyan.r, cyan.g, cyan.b, 0.8))
	draw_circle(Vector2(p.x + fx * 5, by + 10), 2, Color.WHITE)

	# ── BRAÇOS ──
	var arm_col: Color = Color("#c8ddf0")
	# Braço esquerdo
	var la_sh: Vector2 = Vector2(p.x - 13, by + 2)
	var la_el: Vector2 = la_sh + Vector2(-10, 8 + arm * 0.3)
	var la_hd: Vector2 = la_el + Vector2(-4, 8 - arm * 0.2)
	draw_line(la_sh, la_el, arm_col, 6)
	draw_line(la_el, la_hd, arm_col, 5)
	draw_circle(la_hd, 4, Color("#3a5570"))
	# Braço direito
	var ra_sh: Vector2 = Vector2(p.x + 13, by + 2)
	var ra_el: Vector2 = ra_sh + Vector2(10, 8 - arm * 0.3)
	var ra_hd: Vector2 = ra_el + Vector2(4, 8 + arm * 0.2)
	draw_line(ra_sh, ra_el, arm_col, 6)
	draw_line(ra_el, ra_hd, arm_col, 5)
	draw_circle(ra_hd, 4, Color("#3a5570"))

	# ── CAPACETE ──
	# Pescoço
	draw_rect(Rect2(p.x - 6, by - 14, 12, 12), Color("#c8ddf0"))
	# Anel do capacete (base)
	draw_circle(Vector2(p.x, by - 18), 21, Color("#4a7090"))
	# Casco externo
	draw_circle(Vector2(p.x, by - 20), 19, Color("#ddeeff"))
	# Visor (olho)
	draw_circle(Vector2(p.x + fx * 4, by - 22), 10, Color("#0a1e35"))
	draw_circle(Vector2(p.x + fx * 4, by - 22), 8,  Color("#0d2d55"))
	# Reflexo no visor
	draw_circle(Vector2(p.x + fx * 6, by - 26), 3, Color(cyan.r, cyan.g, cyan.b, 0.7))
	draw_circle(Vector2(p.x + fx * 2, by - 24), 1.5, Color(1, 1, 1, 0.5))
	# Antena
	draw_line(Vector2(p.x - fx * 14, by - 34), Vector2(p.x - fx * 14, by - 44),
			  Color("#8fb3df"), 2)
	draw_circle(Vector2(p.x - fx * 14, by - 45), 3,
				Color(red.r, red.g, red.b, 0.7 + 0.3 * abs(sin(t * 4.0))))
	# Borda do capacete
	draw_arc(Vector2(p.x, by - 20), 19, 0, TAU, 48, Color("#5a8aaa"), 2)

	# ── INDICADOR DE O2 CRÍTICO ──
	if o2_critical:
		var blink: float = abs(sin(t * 6.0))
		draw_arc(Vector2(p.x, by - 20), 24, 0, TAU, 32,
				 Color(red.r, red.g, red.b, blink * 0.7), 2)

# ─────────────────────────────────────────────
#  MARCADOR DE OBJETIVO
# ─────────────────────────────────────────────
func _draw_objective_marker() -> void:
	if state != STATE_PLAY or current_puzzle != 0: return
	var target: Vector2 = _objective_position()
	var yoff: float = -46.0 + sin(animation_time * 4.5) * 6.0
	# Seta animada
	var arr: Vector2 = target + Vector2(0, yoff + 20)
	draw_line(arr + Vector2(-8, -10), arr, yellow, 2)
	draw_line(arr + Vector2(8, -10),  arr, yellow, 2)
	# Label OBJ
	draw_rect(Rect2(target.x - 20, target.y + yoff - 20, 40, 18), Color(0,0,0,0.7))
	draw_string(ThemeDB.fallback_font, Vector2(target.x - 14, target.y + yoff - 6),
				"OBJ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, yellow)

func _objective_position() -> Vector2:
	if not card_collected:    return card_pos
	if not door_a_open:       return terminal_a_pos
	if _cells_count() < 3:
		if not cell_a_collected: return cell_a_pos
		if not cell_b_collected: return cell_b_pos
		return cell_c_pos
	if not energy_on:         return generator_pos
	if not laser_off:         return terminal_b_pos
	if not code_collected:    return code_pos
	if not exit_unlocked:     return terminal_c_pos
	return exit_pos

func _mission_text() -> String:
	if not card_collected:    return "1/8  Colete o cartão azul"
	if not door_a_open:       return "2/8  Pressione E no Terminal A"
	if _cells_count() < 3:   return "3/8  Colete as 3 células  (%d/3)" % _cells_count()
	if not energy_on:         return "4/8  Pressione E no Gerador"
	if not laser_off:         return "5/8  Pressione E no Terminal B"
	if not code_collected:    return "6/8  Colete o código roxo"
	if not exit_unlocked:     return "7/8  Pressione E no Terminal C"
	return                           "8/8  Entre na saída e pressione E"

# ─────────────────────────────────────────────
#  PROMPT DE INTERAÇÃO
# ─────────────────────────────────────────────
func _draw_interact_prompt() -> void:
	if state != STATE_PLAY or current_puzzle != 0 or nearest_interactive == "": return
	var ppos: Vector2 = Vector2.ZERO
	match nearest_interactive:
		"terminal_a": ppos = terminal_a_pos + Vector2(-46, -78)
		"generator":  ppos = generator_pos  + Vector2(-46, -80)
		"terminal_b": ppos = terminal_b_pos + Vector2(-46, -78)
		"terminal_c": ppos = terminal_c_pos + Vector2(-46, -78)
		"exit":       ppos = exit_pos       + Vector2(-46, -66)
		"code":       ppos = code_pos       + Vector2(-46, -60)
		_: return
	var pulse: float = 0.70 + 0.30 * abs(sin(animation_time * 4.0))
	draw_rect(Rect2(ppos - Vector2(4, 16), Vector2(118, 24)), Color(0.02,0.04,0.10,0.90))
	draw_rect(Rect2(ppos - Vector2(4, 16), Vector2(118, 24)),
			  Color(1,1,1, pulse * 0.50), false, 1)
	draw_string(ThemeDB.fallback_font, ppos, "[ E ]  Interagir",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1,1,1, pulse))

# ─────────────────────────────────────────────
#  PARTÍCULAS (render)
# ─────────────────────────────────────────────
func _draw_particles() -> void:
	for item in particles:
		var p: Dictionary = item
		var a: float = clamp(float(p["life"]) / float(p["max"]), 0.0, 1.0)
		var col: Color = Color(p["col"])
		col.a = a
		draw_circle(Vector2(p["pos"]), float(p["r"]), col)

# Render extra de faíscas/fumaça acima dos objetos de cenário
func _draw_sparks_smoke() -> void:
	# Fumaça sobreposta (camada superior, mais visível)
	for item in smoke:
		var s: Dictionary = item
		var a: float = clamp(float(s["life"]) / float(s["max"]), 0.0, 1.0) * 0.18
		if a < 0.02: continue
		var col: Color = Color(s["col"]); col.a = a
		draw_circle(Vector2(s["pos"]), float(s["r"]) * 1.3, col)
	# Faíscas em cima de tudo
	for item in sparks:
		var s: Dictionary = item
		var a: float = clamp(float(s["life"]) / float(s["max"]), 0.0, 1.0)
		if a < 0.05: continue
		var col: Color = Color(s["col"]); col.a = a
		draw_circle(Vector2(s["pos"]), float(s["r"]) * a + 0.5, col)
		# Brilho central branco
		draw_circle(Vector2(s["pos"]), 1.0, Color(1, 1, 1, a * 0.8))

# ─────────────────────────────────────────────
#  FEEDBACKS (render)
# ─────────────────────────────────────────────
func _draw_feedbacks_gfx() -> void:
	for item in feedbacks:
		var f: Dictionary = item
		var a: float = clamp(float(f["life"]) / float(f["max"]), 0.0, 1.0)
		var col: Color = Color(f["col"]); col.a = a
		# Sombra
		draw_string(ThemeDB.fallback_font, Vector2(f["pos"]) + Vector2(1,1),
					String(f["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0,0,0, a*0.5))
		draw_string(ThemeDB.fallback_font, Vector2(f["pos"]),
					String(f["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)

# ─────────────────────────────────────────────
#  HUD
# ─────────────────────────────────────────────
func _draw_hud() -> void:
	# Painel esquerdo
	draw_rect(Rect2(20, 14, 780, 96), Color(0.02, 0.03, 0.08, 0.92))
	draw_line(Vector2(20, 14), Vector2(800, 14), cyan, 2)
	draw_string(ThemeDB.fallback_font, Vector2(44, 46), "GRAVIDADE ZERO",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(44, 72), _mission_text(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#dbe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(44, 96), "WASD mover  |  Shift correr  |  E interagir  |  1/2/3 responder  |  P pausar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#9de9ff"))

	# Painel direito
	draw_rect(Rect2(836, 14, 424, 132), Color(0.02, 0.03, 0.08, 0.92))
	draw_line(Vector2(836, 14), Vector2(1260, 14), cyan, 2)
	draw_string(ThemeDB.fallback_font, Vector2(858, 46), "Pontuação: %d" % int(score),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(858, 70), "Tempo: %02d:%02d" % [int(time_played)/60, int(time_played)%60],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbe8ff"))
	# Barras
	_draw_bar(Vector2(858, 84),  165, 17, oxygen / 100.0, green,  "O2")
	_draw_bar(Vector2(858, 110), 165, 17, suit_energy / 100.0, yellow, "TRAJE")
	# Status
	draw_string(ThemeDB.fallback_font, Vector2(1040, 88),  "Cartão: %s" % ("✓" if card_collected else "—"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(1040, 108), "Células: %d / 3" % _cells_count(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(1040, 128), "Energia: %s" % ("ON" if energy_on else "OFF"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, green if energy_on else red)

	# Alerta de O2 crítico
	if o2_critical:
		var blink: float = abs(sin(animation_time * 5.0))
		draw_rect(Rect2(836, 84, 424, 17), Color(red.r, red.g, red.b, blink * 0.25))
		draw_string(ThemeDB.fallback_font, Vector2(1034, 100), "⚠ O2 CRÍTICO",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(red.r, red.g, red.b, 0.7 + blink * 0.3))

	# Mensagem contextual
	if message_timer > 0.0:
		var a: float = clamp(message_timer, 0.0, 1.0)
		draw_rect(Rect2(186, 644, 908, 50), Color(0.02, 0.03, 0.08, 0.94 * a))
		draw_rect(Rect2(186, 644, 908, 50), Color(cyan.r, cyan.g, cyan.b, a * 0.7), false, 1)
		draw_string(ThemeDB.fallback_font, Vector2(204, 677), message,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1,1,1, a))

func _draw_bar(pos: Vector2, w: int, h: int, pct: float, col: Color, lbl: String) -> void:
	draw_string(ThemeDB.fallback_font, pos + Vector2(-54, h - 1), lbl,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#dbe8ff"))
	draw_rect(Rect2(pos, Vector2(w, h)), Color("#1a2535"))
	# Barra com gradiente simulado (duas faixas)
	var fw: float = w * clamp(pct, 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(fw, h / 2.0)), Color(col.r, col.g, col.b, 1.0))
	draw_rect(Rect2(pos + Vector2(0, h/2.0), Vector2(fw, h / 2.0)),
			  Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 1.0))
	draw_rect(Rect2(pos, Vector2(w, h)), Color.WHITE, false, 1)
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, h - 2),
				"%d%%" % int(pct * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0,0,0, 0.9))

# ─────────────────────────────────────────────
#  PAINEL DE PUZZLE
# ─────────────────────────────────────────────
func _draw_puzzle_panel() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.60))
	draw_rect(Rect2(265, 148, 750, 358), Color(0.02, 0.03, 0.08, 0.98))
	draw_rect(Rect2(265, 148, 750, 358), cyan, false, 3)
	draw_line(Vector2(265, 148), Vector2(1015, 148), cyan, 2)

	var title: String = "TERMINAL A — PORTA DE ACESSO"
	var eq:    String = "Resolva:  x + 2 = 5"
	var opt1:  String = "[1]  x = 2"
	var opt2:  String = "[2]  x = 1"
	var opt3:  String = "[3]  x = 3"
	var hint:  String = "Qual número somado a 2 é igual a 5?"
	match current_puzzle:
		2:
			title = "TERMINAL B — SISTEMA DO LASER"
			eq    = "Resolva:  3x = 12"
			opt1  = "[1]  x = 4"
			opt2  = "[2]  x = 3"
			opt3  = "[3]  x = 5"
			hint  = "Qual número multiplicado por 3 resulta em 12?"
		3:
			title = "TERMINAL C — SAÍDA DE EMERGÊNCIA"
			eq    = "Resolva:  2x + 4 = 10"
			opt1  = "[1]  x = 2"
			opt2  = "[2]  x = 3"
			opt3  = "[3]  x = 1"
			hint  = "Subtraia 4 de ambos os lados e depois divida por 2."

	draw_string(ThemeDB.fallback_font, Vector2(305, 206), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_line(Vector2(275, 216), Vector2(1005, 216), Color(cyan.r, cyan.g, cyan.b, 0.4), 1)
	draw_string(ThemeDB.fallback_font, Vector2(305, 266), eq,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#9de9ff"))

	# Opções com caixas
	for i in range(3):
		var ox: float = 305.0 + i * 230.0
		var opt_text: String = opt1 if i == 0 else (opt2 if i == 1 else opt3)
		draw_rect(Rect2(ox - 4, 328, 200, 36), Color(0.06, 0.12, 0.22))
		draw_rect(Rect2(ox - 4, 328, 200, 36), Color(yellow.r, yellow.g, yellow.b, 0.4), false, 1)
		draw_string(ThemeDB.fallback_font, Vector2(ox + 6, 353), opt_text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 22, yellow)

	draw_line(Vector2(275, 376), Vector2(1005, 376), Color(cyan.r, cyan.g, cyan.b, 0.25), 1)
	draw_string(ThemeDB.fallback_font, Vector2(305, 400), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(305, 426),
				"Pressione 1, 2 ou 3 para responder   |   E ou ESC para fechar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8db8d8"))
	draw_string(ThemeDB.fallback_font, Vector2(305, 480),
				"[ O2 pausado enquanto o terminal está aberto ]",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(green.r, green.g, green.b, 0.65))

# ─────────────────────────────────────────────
#  MENU PRINCIPAL
# ─────────────────────────────────────────────
func _draw_menu() -> void:
	if show_credits:
		_draw_credits()
		return

	# ── Fundo: estrelas já desenhadas por _draw_space_bg ──

	# Planeta maior no menu (centro-esquerda)
	_draw_planet(Vector2(260, 400), 130)

	# Partículas flutuantes decorativas
	for i in range(8):
		var px: float = 350.0 + sin(animation_time * 0.4 + i * 0.9) * 320.0
		var py: float = 200.0 + cos(animation_time * 0.3 + i * 1.1) * 160.0
		draw_circle(Vector2(px, py), 1.5, Color(cyan.r, cyan.g, cyan.b, 0.25))

	# Painel central
	var px: float = 420.0; var pw: float = 500.0
	var py: float = 110.0; var ph: float = 498.0
	draw_rect(Rect2(px, py, pw, ph), Color(0.02, 0.03, 0.08, 0.94))
	draw_rect(Rect2(px, py, pw, ph), Color(cyan.r, cyan.g, cyan.b, 0.55), false, 2)
	# Barra superior decorativa
	draw_rect(Rect2(px, py, pw, 4), cyan)
	# Barra inferior decorativa
	draw_rect(Rect2(px, py + ph - 4, pw, 4), Color(cyan.r, cyan.g, cyan.b, 0.4))

	# Linhas de scan animadas no painel
	var scan_y: float = fmod(animation_time * 40.0, ph)
	draw_rect(Rect2(px, py + scan_y, pw, 2), Color(cyan.r, cyan.g, cyan.b, 0.07))

	# Título com sombra
	var tx: float = px + 50.0
	draw_string(ThemeDB.fallback_font, Vector2(tx + 2, 192), "GRAVIDADE",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0,0,0,0.5))
	draw_string(ThemeDB.fallback_font, Vector2(tx, 190), "GRAVIDADE",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(tx + 2, 244), "ZERO",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0,0,0,0.5))
	# "ZERO" com cor pulsante
	var pulse_col: Color = Color(
		cyan.r + (yellow.r - cyan.r) * abs(sin(animation_time * 0.8)) * 0.5,
		cyan.g + (yellow.g - cyan.g) * abs(sin(animation_time * 0.8)) * 0.5,
		cyan.b, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(tx, 242), "ZERO",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 54, pulse_col)

	# Linha divisória
	draw_line(Vector2(px + 20, 264), Vector2(px + pw - 20, 264),
			  Color(cyan.r, cyan.g, cyan.b, 0.35), 1)

	# Tagline
	draw_string(ThemeDB.fallback_font, Vector2(tx, 292),
				"Jogo de plataforma  ·  Desafios matemáticos",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9de9ff"))

	# Subtítulo narrativo
	draw_string(ThemeDB.fallback_font, Vector2(tx, 324),
				"Você é um astronauta preso numa",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8ddf0"))
	draw_string(ThemeDB.fallback_font, Vector2(tx, 346),
				"estação espacial avariada. Restaure",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8ddf0"))
	draw_string(ThemeDB.fallback_font, Vector2(tx, 368),
				"a energia, desligue o laser e escape.",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8ddf0"))

	draw_line(Vector2(px + 20, 388), Vector2(px + pw - 20, 388),
			  Color(cyan.r, cyan.g, cyan.b, 0.20), 1)

	# ── Botões de menu ──
	var btn_data := [
		{"label": "▶  JOGAR",    "idx": 0},
		{"label": "✦  CRÉDITOS", "idx": 1},
	]
	for b in btn_data:
		var bd: Dictionary = b
		var by2: float = 420.0 + bd["idx"] * 58.0
		var sel: bool  = menu_selected == bd["idx"]
		var bw: float  = pw - 80.0
		var bx: float  = px + 40.0
		# Fundo do botão
		var btn_col: Color = Color(cyan.r, cyan.g, cyan.b, 0.18) if sel else Color(0.04, 0.07, 0.12, 0.8)
		draw_rect(Rect2(bx, by2, bw, 42), btn_col)
		# Borda
		var border_a: float = (0.6 + 0.4 * abs(sin(animation_time * 4.0))) if sel else 0.25
		draw_rect(Rect2(bx, by2, bw, 42), Color(cyan.r, cyan.g, cyan.b, border_a), false, 2)
		# Barra lateral se selecionado
		if sel:
			draw_rect(Rect2(bx, by2, 4, 42), cyan)
		# Texto
		var lbl_col: Color = Color.WHITE if sel else Color(0.7, 0.8, 0.9, 0.8)
		var font_size: int  = 22 if sel else 20
		draw_string(ThemeDB.fallback_font, Vector2(bx + 28, by2 + 28),
					bd["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, lbl_col)

	# Tecla ESC
	draw_string(ThemeDB.fallback_font, Vector2(px + 40, py + ph - 22),
				"ESC — sair",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.6, 0.7, 0.6))
	# Navegar
	draw_string(ThemeDB.fallback_font, Vector2(px + 260, py + ph - 22),
				"W/S ou ↑↓ para navegar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.6, 0.7, 0.6))

func _draw_credits() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.80))
	draw_rect(Rect2(300, 120, 680, 460), Color(0.02, 0.03, 0.08, 0.97))
	draw_rect(Rect2(300, 120, 680, 460), cyan, false, 2)
	draw_rect(Rect2(300, 120, 680, 4), cyan)

	draw_string(ThemeDB.fallback_font, Vector2(430, 178), "CRÉDITOS",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	draw_line(Vector2(315, 192), Vector2(968, 192), Color(cyan.r, cyan.g, cyan.b, 0.4), 1)

	var lines := [
		["Desenvolvimento", ""],
		["", "Cauê Pereira"],
		["", "Maicon Mendes"],
		["", "Matheus Correia de Oliveira"],
		["", ""],
		["Engine", "Godot Engine 4"],
		["", ""],
		["Gênero", "Plataforma 2D com desafios matemáticos"],
		["", ""],
		["Versão", "1.0 — 2025"],
		["", ""],
		["Agradecimentos", "Professores e colegas da turma de PAC"],
	]
	var ly: float = 224.0
	for ln in lines:
		var l: Array = ln
		if l[0] != "":
			draw_string(ThemeDB.fallback_font, Vector2(330, ly), l[0] + ":",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9de9ff"))
		if l[1] != "":
			draw_string(ThemeDB.fallback_font, Vector2(520, ly), l[1],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbe8ff"))
		ly += 22.0 if l[0] == "" or l[1] == "" else 24.0

	var blink: float = 0.55 + 0.45 * abs(sin(animation_time * 2.5))
	draw_string(ThemeDB.fallback_font, Vector2(386, 548),
				"ENTER ou ESC para voltar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(yellow.r, yellow.g, yellow.b, blink))

# ─────────────────────────────────────────────
#  PAUSA
# ─────────────────────────────────────────────
func _draw_pause() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.62))
	draw_rect(Rect2(380, 222, 520, 240), Color(0.02, 0.03, 0.08, 0.97))
	draw_rect(Rect2(380, 222, 520, 240), cyan, false, 2)
	draw_rect(Rect2(380, 222, 520, 4), cyan)
	draw_string(ThemeDB.fallback_font, Vector2(468, 282), "JOGO PAUSADO",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
	draw_line(Vector2(390, 296), Vector2(890, 296), Color(cyan.r, cyan.g, cyan.b, 0.4), 1)
	draw_string(ThemeDB.fallback_font, Vector2(430, 336), "P ou ESC — continuar",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 19, yellow)
	draw_string(ThemeDB.fallback_font, Vector2(430, 368), "M — voltar ao menu",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#dbe8ff"))

# ─────────────────────────────────────────────
#  TELAS DE FIM
# ─────────────────────────────────────────────
func _draw_end_screen(win: bool) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.70))
	var col:   Color  = green if win else red
	var title: String = "MISSÃO CONCLUÍDA!" if win else "MISSÃO FALHOU"
	var desc:  String = "Você restaurou a energia, desligou o laser e escapou." if win \
					  else "O oxigênio acabou antes da fuga."

	draw_rect(Rect2(272, 152, 736, 388), Color(0.02, 0.03, 0.08, 0.98))
	draw_rect(Rect2(272, 152, 736, 388), col, false, 3)
	draw_rect(Rect2(272, 152, 736, 4), col)

	draw_string(ThemeDB.fallback_font, Vector2(340, 218), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)
	draw_line(Vector2(282, 232), Vector2(998, 232), Color(col.r, col.g, col.b, 0.4), 1)
	draw_string(ThemeDB.fallback_font, Vector2(340, 276), desc,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#dbe8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(340, 318), "Pontuação: %d" % int(score),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 28, yellow)
	draw_string(ThemeDB.fallback_font, Vector2(340, 358), "Tempo: %02d:%02d" % [int(time_played)/60, int(time_played)%60],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	draw_line(Vector2(282, 378), Vector2(998, 378), Color(col.r, col.g, col.b, 0.3), 1)
	draw_string(ThemeDB.fallback_font, Vector2(340, 418), "R ou ENTER — jogar novamente",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, yellow)
	draw_string(ThemeDB.fallback_font, Vector2(340, 452), "M — voltar ao menu",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#dbe8ff"))

	# Estrelas de vitória
	if win:
		for i in range(12):
			var sx: float = 290.0 + i * 60.0
			var sy: float = 478.0 + sin(animation_time * 2.0 + i) * 6.0
			draw_string(ThemeDB.fallback_font, Vector2(sx, sy), "★",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(yellow.r, yellow.g, yellow.b, 0.6))
