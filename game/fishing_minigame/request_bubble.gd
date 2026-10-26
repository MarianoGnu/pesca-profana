@tool
class_name RequestBubble
extends Control

@export var _label: Label

func update(p_client: Client) -> void:
	if !is_node_ready(): await ready
	if _label == null:
		return
	var missing: PackedStringArray
	if p_client.has_head:
		if !p_client.has_eyes:
			missing.append("👀")
		if !p_client.has_left_leg:
			missing.append("👣")
		if !p_client.has_rigth_leg:
			missing.append("👣")
		if !p_client.has_left_arm:
			missing.append("🦾")
		if !p_client.has_rigth_arm:
			missing.append("🦾")
	else:
		missing.append("?")
	visible = !missing.is_empty()
	_label.text = " ".join(missing)
