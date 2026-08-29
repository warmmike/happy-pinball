extends Label

@export var player_number: int = 1

var _score_node: Label = null

func _ready() -> void:
	# Derive score node name from label name: "P1Label" -> "P1Score"
	var score_name = self.name.replace("Label", "Score")
	if get_parent().has_node(score_name):
		_score_node = get_parent().get_node(score_name)
	MPF.server.add_event_handler("player_turn_start", _on_player_turn)
	MPF.game.connect("player_added", _on_player_added)
	# Deferred so mpf_variable._ready() and _on_player_added(show) run first
	call_deferred("_update_visibility", MPF.game.player.get("number", 1))

func _exit_tree() -> void:
	MPF.server.remove_event_handler("player_turn_start", _on_player_turn)
	MPF.game.disconnect("player_added", _on_player_added)

func _on_player_turn(payload: Dictionary) -> void:
	_update_visibility(payload.get("player_num", 0))

func _on_player_added(_total: int) -> void:
	# Deferred so mpf_variable's synchronous show() call runs before we hide
	call_deferred("_update_visibility", MPF.game.player.get("number", 1))

func _update_visibility(current_player: int) -> void:
	var is_my_turn: bool = (current_player == player_number)
	var enough_players: bool = MPF.game.num_players >= player_number
	self.visible = not is_my_turn and enough_players
	if _score_node != null:
		_score_node.visible = not is_my_turn and enough_players
