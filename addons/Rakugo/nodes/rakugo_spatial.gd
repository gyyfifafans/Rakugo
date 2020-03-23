tool
extends Spatial
class_name RakugoSpatial, "res://addons/Rakugo/icons/rakugo_spatial.svg"

signal on_substate(substate)

var rnode := RakugoNodeCore.new()

export var node_id := "" setget _set_node_id, _get_node_id
export var saveable := true setget _set_saveable, _get_saveable
export (Array, String) var state: Array setget _set_state, _get_state

var _node_id := ""
var _saveable := true
var _state: Array
var node_link: NodeLink
var last_show_args: Dictionary

func _ready() -> void:
	_set_saveable(_saveable)

	if Engine.editor_hint:
		if node_id.empty():
			node_id = name
		return

	Rakugo.connect("show", self, "_on_show")
	Rakugo.connect("hide", self, "_on_hide")
	rnode.connect("on_substate", self, "_on_rnode_substate")

	if node_id.empty():
		node_id = name

	node_link = Rakugo.get_node_link(node_id)

	if not node_link:
		node_link = Rakugo.node_link(node_id, get_path())

	else:
		node_link.node_path = get_path()


func _on_rnode_substate(substate):
	emit_signal("on_substate", substate)

func _set_node_id(value: String):
	_node_id = value


func _get_node_id() -> String:
	if _node_id == "":
		_node_id = name

	return _node_id


func _set_saveable(value: bool):
	_saveable = value

	if _saveable:
		add_to_group("save", true)

	elif is_in_group("save"):
		remove_from_group("save")


func _get_saveable() -> bool:
	return _saveable


func _on_show(node_id: String, state_value: Array, show_args: Dictionary) -> void:
	if self.node_id != node_id:
		return

	var def_pos = Vector2(translation.x , translation.y)
	var pos = rnode.show_at(show_args, def_pos)

	var z = translation.z

	if z in show_args:
		z = show_args.z

	translation = Vector3(pos.x, pos.y, z)

	_set_state(state_value)

	if not self.visible:
		show()


func _set_state(value: Array) -> void:
	_state = value

	if not value:
		return

	if not rnode:
		return

	_state = rnode.setup_state(value)


func _get_state() -> Array:
	return _state


func _on_hide(_node_id: String) -> void:
	if _node_id != node_id:
		return

	hide()


func _exit_tree() -> void:
	if(Engine.editor_hint):
		return

	var id = NodeLink.new("").var_prefix + node_id
	Rakugo.variables.erase(id)


func on_save() -> void:
	if not node_link:
		push_error("error with saving: %s" %node_id)
		return

	node_link.value["visible"] = visible
	node_link.value["state"] = _state
	node_link.value["show_args"] = last_show_args


func on_load(game_version: String) -> void:
	if not node_link:
		push_error("error with loading: %s" %node_id)
		return

	visible = node_link.value["visible"]

	if visible:
		_state = node_link.value["state"]
		last_show_args = node_link.value["show_args"]
		_on_show(node_id, _state, last_show_args)

	else:
		_on_hide(node_id)


func _on_substate(substate):
	pass
