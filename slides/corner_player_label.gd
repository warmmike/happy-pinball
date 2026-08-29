extends Label

@export var player_number: int = 1
@export var score_node_path: NodePath

var _score_node: Label = null

func _ready() -> void:
	if score_node_path:
		_score_node = get_node(score_node_path)
	MPF.server.add_event_handler("player_turn_start", _on_player_turn)
	MPF.game.connect("player_added", _on_player_added)
	call_deferred("_update_visibility", MPF.game.player.get("number", 1))

func _exit_tree() -> void:
	MPF.server.remove_event_handler("player_turn_start", _on_player_turn)
	MPF.game.disconnect("player_added", _on_player_added)

func _on_player_turn(payload: Dictionary) -> void:
	_update_visibility(payload.get("player_num", 0))

func _on_player_added(_total: int) -> void:
	# Re-evaluate after each player is added — on ball 1, num_players starts
	# at 0 (game reset) and increments as players are restored, so we wait
	# until the count reaches our player_number before showing anything.
	_update_visibility(MPF.game.player.get("number", 1))

func _update_visibility(current_player: int) -> void:
	var is_my_turn: bool = (current_player == player_number)
	var enough_players: bool = MPF.game.num_players >= player_number
	self.visible = not is_my_turn and enough_players
	if _score_node != null:
		_score_node.visible = not is_my_turn and enough_players
