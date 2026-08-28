extends Label

@export var player_number: int = 1
@export var score_node_path: NodePath

var _score_node: Label = null

func _ready() -> void:
	if score_node_path:
		_score_node = get_node(score_node_path)
	MPF.server.add_event_handler("player_turn_start", _on_player_turn)
	if MPF.game and MPF.game.player:
		_update_visibility(MPF.game.player.get("number", 0))

func _exit_tree() -> void:
	MPF.server.remove_event_handler("player_turn_start", _on_player_turn)

func _on_player_turn(payload: Dictionary) -> void:
	_update_visibility(payload.get("player_num", 0))

func _update_visibility(current_player: int) -> void:
	var is_my_turn: bool = (current_player == player_number)
	self.visible = not is_my_turn
	if _score_node != null:
		_score_node.visible = not is_my_turn and MPF.game.num_players >= player_number
