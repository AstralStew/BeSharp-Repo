class_name DeckOfFate extends CanvasLayer
#Runs the game

enum CombatResult {p1win,draw,p2win}

@export_category("REFERENCES")
static var instance:DeckOfFate = null
@onready var p1: PlayerManager = $Player1
@onready var p2: PlayerManager = $Player2
@onready var phase_label: RichTextLabel = $PhaseLabel
@onready var p1_score_label: RichTextLabel = $P1ScoreDesc_VB/P1Score_RTL
@onready var p2_score_label: RichTextLabel = $P2ScoreDesc_VB/P2Score_RTL
@onready var helper_label: RichTextLabel = $HelperText_MC/HelperText_VB/HelperText_RTL

@export_category("CONTROL")
@export var number_of_rounds : int = 3

@export_category("READ ONLY")
@export var current_round : int = 0
@export var p1_score : int = 0
@export var p2_score : int = 0
@export var current_phase : phases = phases.TurnStart
@export var combat_result : CombatResult = CombatResult.draw

@export var waiting_for_p1 : bool = false
@export var waiting_for_p2 : bool = false

signal both_players_ready

enum phases {TurnStart, PickLeader, PickSupport, RevealSupport, RevealLeader, Battle, BacklineLeader, BacklineSupport, TurnEnd}


static var first_turn:bool = true

static var last_combat_result:CombatResult:
	get:
		return instance.combat_result


static func set_helper_message(msg:String):
	instance.helper_label.text = msg


static func player_ready(player:PlayerManager):
	
	print("[DeckOfFate] Was informed that '",player,"' is ready!")
	instance._player_ready(player)
	
func _player_ready(player:PlayerManager):
	if player == p1:
		if waiting_for_p1:
			print("[DeckOfFate] Player 1 ready!")
			waiting_for_p1 = false
		else: push_warning("[DeckOfFate] WARNING > Player 1 was already marked as ready! Hmmm...?")
	elif player == p2:
		if waiting_for_p2:
			print("[DeckOfFate] Player 2 ready!")
			waiting_for_p2 = false
		else: push_warning("[DeckOfFate] WARNING > Player 2 was already marked as ready! Hmmm...?")
	else:
		push_error("[DeckOfFate] WARNING > Unrecognised player! Wtf...?")
		return
	
	if !waiting_for_p1 && !waiting_for_p2:
		both_players_ready.emit()


static func add_points(player:PlayerManager,amount:int):
	instance._add_points(player,amount)
	 
func _add_points(player:PlayerManager,amount:int):
	if player == p1:
		print("[DeckOfFate] Adding ",amount," points to Player 1!")
		add_points_p1(amount)
	elif player == p2:
		print("[DeckOfFate] Adding ",amount," points to Player 2!")
		add_points_p2(amount)
	else:
		push_error("[DeckOfFate] WARNING > Unrecognised player! Wtf...?")
		return



func _init() -> void:
	CG.def_front_layout = "Default"

func _ready() -> void:
	instance = self
	p1.deck_manager.setup()
	p2.deck_manager.setup()
	_start_game()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_F):
		Engine.time_scale = 5
	else: 
		Engine.time_scale = 1


func _start_game() -> void:
	
	# Reset the listed scores
	p1_score_label.text = "0"
	p2_score_label.text = "0"
	
	# Start the "next phase" loop
	await get_tree().create_timer(1).timeout 
	_next_phase()


func _next_phase() -> void:
	
	# Increment phase enum (except for the first draw)
	if !first_turn:
		current_phase = ((current_phase + 1) % phases.size()) as phases
	
	
	# Tell the players which phase we are in
	phase_label.text = phases.keys()[current_phase]
	tween_visibility(phase_label,Color(1,1,1,1),0.5,Tween.EaseType.EASE_OUT,Tween.TransitionType.TRANS_LINEAR)
	await get_tree().create_timer(1).timeout 
	tween_visibility(phase_label,Color(1,1,1,0),0.5,Tween.EaseType.EASE_IN,Tween.TransitionType.TRANS_LINEAR)
	await get_tree().create_timer(0.51).timeout 
	
	# Check the phase enum 
	match current_phase:
		
		
		phases.TurnStart:
			set_helper_message("Dealing cards...")
			combat_result = CombatResult.draw
			current_round += 1
			print("[DeckOfFate] TurnStart - Current round set to ", current_round)
			# Deal 2 cards (or 4 on the first turn)
			p1.deal(first_turn)
			p2.deal(first_turn)
		
		
		phases.PickLeader:
			set_helper_message("Pick a Leader from your hand")
			# Wait till both players select a card			
			p1.pick_leader()
			waiting_for_p1 = true
			p2.pick_leader()
			waiting_for_p2 = true
			await both_players_ready
		
		
		phases.PickSupport:
			set_helper_message("Pick a Support from your hand")
			# Wait till both players select a card
			p1.pick_support()
			waiting_for_p1 = true
			p2.pick_support()
			waiting_for_p2 = true
			await both_players_ready
		
		
		phases.RevealSupport:
			set_helper_message("Revealing Support cards...")
			await get_tree().create_timer(1).timeout
			var p1_support_str = p1.get_support_data().strength
			var p2_support_str = p2.get_support_data().strength
			
			# CASE 1 - Player 1 goes first if they're str is lower (or 50/50 chance if equal)
			if (p1_support_str < p2_support_str) || (p1_support_str == p2_support_str && randi() % 2 == 0):
				set_helper_message("Player 1 str lower, revealing their support first...")
				waiting_for_p1 = true
				await get_tree().create_timer(1).timeout
				p1.reveal_support()
				await both_players_ready
				set_helper_message("Revealing Player 2 support second...")
				waiting_for_p2 = true
				await get_tree().create_timer(1).timeout
				p2.reveal_support()
				await both_players_ready
			
			# CASE 2 - Player 2 goes first if they're str is lower (or 50/50 chance if equal, logic above)
			else:
				set_helper_message("Player 2 str lower, revealing their support first...")
				waiting_for_p2 = true
				await get_tree().create_timer(1).timeout
				p2.reveal_support()
				await both_players_ready
				set_helper_message("Revealing Player 1 support second...")
				waiting_for_p1 = true
				await get_tree().create_timer(1).timeout
				p1.reveal_support()
				await both_players_ready
		
		
		phases.RevealLeader:
			set_helper_message("Revealing Leader cards...")
			await get_tree().create_timer(1).timeout
			var p1_leader_str = p1.get_leader_data().strength
			var p2_leader_str = p2.get_leader_data().strength
			
			# CASE 1 - Player 1 goes first if they're str is lower (or 50/50 chance if equal)
			if (p1_leader_str < p2_leader_str) || (p1_leader_str == p2_leader_str && randi() % 2 == 0):
				set_helper_message("Player 1 str lower, revealing leader first...")
				waiting_for_p1 = true
				await get_tree().create_timer(1).timeout
				p1.reveal_leader()
				await both_players_ready
				set_helper_message("Revealing Player 2 leader second...")
				waiting_for_p2 = true
				await get_tree().create_timer(1).timeout
				p2.reveal_leader()
				await both_players_ready
			
			# CASE 2 - Player 2 goes first if they're str is lower (or 50/50 chance if equal, logic above)
			else:
				set_helper_message("Player 2 str lower, revealing leader first...")
				waiting_for_p2 = true				
				await get_tree().create_timer(1).timeout
				p2.reveal_leader()
				await both_players_ready
				set_helper_message("Revealing Player 1 leader second...")
				waiting_for_p1 = true
				await get_tree().create_timer(1).timeout
				p1.reveal_leader()
				await both_players_ready
		
		
		phases.Battle:
			# Grab the stats for the leader card (just ignoring 2nd player for now)
			var p1_leader_str= p1.get_leader_data().strength
			var p1_tokens = p1.combat_tokens
			var p2_leader_str= p2.get_leader_data().strength
			var p2_tokens = p2.combat_tokens
			
			set_helper_message("Combat:")
			await get_tree().create_timer(1).timeout
			set_helper_message("Combat:" + \
				"P1 Strength = " + str(p1_leader_str) + "(+" + str(p1_tokens) + ")")
			await get_tree().create_timer(1).timeout
			set_helper_message("Combat:" + \
				"P1 Strength = " + str(p1_leader_str) + "(+" + str(p1_tokens) + ")" + \
				"P2 Strength = " + str(p2_leader_str) + "(+" + str(p2_tokens) + ")")
			await get_tree().create_timer(1.5).timeout
			
			# Compare the strength of the leaders and score points accordingly
			var helpermsg = ""
			print("[DeckOfFate] BATTLE: My strength = ",p1_leader_str+p1_tokens,", opponent strength = ", p2_leader_str+p2_tokens)
			if p1_leader_str + p1_tokens > p2_leader_str + p2_tokens:
				helpermsg = "PLAYER 1 WINS THE BATTLE!!"
				print("[DeckOfFate] PLAYER 1 WINS THE BATTLE!!")
				add_points_p1(1)
				combat_result = CombatResult.p1win
				
			elif p1_leader_str + p1_tokens == p2_leader_str + p2_tokens:
				print("[DeckOfFate] BATTLE DRAW :O")
				helpermsg = "DRAW! :O"
				add_points_p1(1)
				add_points_p2(1)
				combat_result = CombatResult.draw
			else:
				helpermsg = "PLAYER 2 WINS THE BATTLE!!"
				print("[DeckOfFate] PLAYER 2 WINS THE BATTLE!!")
				add_points_p2(1)
				combat_result = CombatResult.p2win
			
			set_helper_message("Combat:" + \
			"P1 Strength = " + str(p1_leader_str) + "(+" + str(p1_tokens) + ")" + \
			"P2 Strength = " + str(p2_leader_str) + "(+" + str(p2_tokens) + ")" + \
			"... " + helpermsg)
			
			await get_tree().create_timer(1.5).timeout
			
			# Reset combat tokens
			p1_tokens = 0
			p2_tokens = 0
			
			
			## Perform support post-combat effects
			set_helper_message("Post-combat effects on Support cards...")
			var p1_support_data = p1.get_support_data()
			var p2_support_data = p2.get_support_data()
			await get_tree().create_timer(1).timeout
			
			# CASE 1 - Both players are missing their supports
			if p1_support_data == null && p2_support_data == null:
				set_helper_message("Both players supports have vanished! Skipping post-combat effects...")
				await get_tree().create_timer(1).timeout
			# CASE 2 - Player 1 is missing their support, just wait for player 2
			elif p1_support_data == null:
				set_helper_message("Player 1 support has vanished! Skipping to Player 2...")
				await get_tree().create_timer(1).timeout
				waiting_for_p2 = true
				p2.post_combat_support()
				await both_players_ready
			# CASE 3 - Player 2 is missing their support, just wait for player 1
			elif p2_support_data == null:
				set_helper_message("Player 2 support has vanished! Skipping to Player 1...")
				await get_tree().create_timer(1).timeout
				waiting_for_p1 = true
				p1.post_combat_support()
				await both_players_ready
			# CASE 4 - Compare strengths of supports
			else:
				var p1_support_str = p1_support_data.strength
				var p2_support_str = p2_support_data.strength
				# CASE 4a - Player 1 goes first if they're str is lower (or 50/50 chance if equal)
				if (p1_support_str < p2_support_str) || (p1_support_str == p2_support_str && randi() % 2 == 0):
					set_helper_message("Player 1 str lower, doing post-combat effects on their support first...")
					waiting_for_p1 = true
					p1.post_combat_support()
					await both_players_ready
					set_helper_message("Player 2 support post-combat second...")
					waiting_for_p2 = true
					p2.post_combat_support()
					await both_players_ready
				# CASE 4b - Player 2 goes first if they're str is lower (or 50/50 chance if equal, logic above)
				else:
					set_helper_message("Player 2 str lower, doing post-combat effects on their support first...")
					waiting_for_p2 = true
					p2.post_combat_support()
					await both_players_ready
					set_helper_message("Player 2 support post-combat second...")
					waiting_for_p1 = true
					p1.post_combat_support()
					await both_players_ready
				
			## Perform leader post-combat effects
			set_helper_message("Post-combat effects on Leader cards...")
			var p1_leader_data = p1.get_leader_data()
			var p2_leader_data = p2.get_leader_data()
			await get_tree().create_timer(1).timeout
			
			# CASE 1 - Both players are missing their leaders
			if p1_leader_data == null && p2_leader_data == null:
				set_helper_message("Both players leaders have vanished! Skipping post-combat effects...")
				await get_tree().create_timer(1).timeout
			# CASE 2 - Player 1 is missing their leader, just wait for player 2
			elif p1_leader_data == null:
				set_helper_message("Player 1 leader has vanished! Skipping to Player 2...")
				await get_tree().create_timer(1).timeout
				waiting_for_p2 = true
				p2.post_combat_leader()
				await both_players_ready
			# CASE 3 - Player 2 is missing their leader, just wait for player 1
			elif p2_leader_data == null:
				set_helper_message("Player 2 leader has vanished! Skipping to Player 1...")
				await get_tree().create_timer(1).timeout
				waiting_for_p1 = true
				p1.post_combat_leader()
				await both_players_ready
			# CASE 4 - Compare strengths of leaders
			else:
				# (We already got strengths at the start of this phase)
				# CASE 4a - Player 1 goes first if they're str is lower (or 50/50 chance if equal)
				if (p1_leader_str < p2_leader_str) || (p1_leader_str == p2_leader_str && randi() % 2 == 0):
					set_helper_message("Player 1 str lower, doing post-combat effects on their leader first...")
					waiting_for_p1 = true
					p1.post_combat_leader()
					await both_players_ready
					set_helper_message("Player 2 leader post-combat second...")
					waiting_for_p2 = true
					p2.post_combat_leader()
					await both_players_ready
				# CASE 4b - Player 2 goes first if they're str is lower (or 50/50 chance if equal, logic above)
				else:
					set_helper_message("Player 2 str lower, doing post-combat effects on their leader first...")
					waiting_for_p2 = true
					p2.post_combat_leader()
					await both_players_ready
					set_helper_message("Player 2 leader post-combat second...")
					waiting_for_p1 = true
					p1.post_combat_leader()
					await both_players_ready
						
		
		phases.BacklineLeader:
			set_helper_message("Select a backline slot for your Leader")
			# Wait till both players backline their Leader
			p1.backline_leader()
			waiting_for_p1 = true
			p2.backline_leader()
			waiting_for_p2 = true
			await both_players_ready
		
		phases.BacklineSupport:
			set_helper_message("Select a backline slot for your Support")
			# Wait till both players backline their Leader
			p1.backline_support()
			waiting_for_p1 = true
			p2.backline_support()
			waiting_for_p2 = true
			await both_players_ready
			
		phases.TurnEnd:
			if current_round == number_of_rounds:
				print("[DeckOfFate] TurnEnd - Reached end of game!")
				end_game()
				return
			print("[DeckOfFate] TurnEnd - Current round = ", current_round)
			set_helper_message("Rounds remaining: " + str(3 - current_round))
	
	# Arrange cards
	arrange_decks()
	
	# Mark the first turn as complete
	if first_turn: first_turn = false
	
	# Wait a second then repeat this whole function
	await get_tree().create_timer(1).timeout 
	_next_phase()
	



func arrange_decks() -> void:
	p1.arrange_decks()
	p2.arrange_decks()


func end_game() -> void:
	
	print("[DeckOfFate] Ending game!")	
	set_helper_message("GAME OVER")
	
	p1.end_game()
	p2.end_game()
	
	pass





#region Points functions

static func add_points_p1(amount:int):
	print("[DeckOfFate] Add points to p1 score:", amount)
	instance.p1_score += amount
	# Update the label to match the current scores
	instance.p1_score_label.text = str(instance.p1_score)

static func add_points_p2(amount:int):
	print("[DeckOfFate] Add points to p2 score:", amount)
	instance.p2_score += amount
	# Update the label to match the current scores
	instance.p2_score_label.text = str(instance.p2_score)

static func reset_points():
	print("[DeckOfFate] Resetting point scores.")
	instance.p1_score = 0
	instance.p2_score = 0
	# Update the label to match the current scores
	instance.p1_score_label.text = str(instance.p1_score)
	instance.p2_score_label.text = str(instance.p2_score)

#endregion


#region Tweens + Animations

##Tween the phase label
var _visibility_tween
func tween_visibility(canvas_item:CanvasItem, desired_visibility: Color = Color.WHITE, duration: float = 0.5, ease_type:Tween.EaseType=Tween.EASE_OUT,trans_type:Tween.TransitionType=Tween.TRANS_LINEAR) -> void:
	# If we're already tweening, kill it and start again
	if _visibility_tween:
		_visibility_tween.kill()
	# Tween the transparency of whatever we're targetting 
	_visibility_tween = create_tween().set_ease(ease_type).set_trans(trans_type)
	_visibility_tween.tween_property(canvas_item, "modulate", desired_visibility, duration)

#endregion
