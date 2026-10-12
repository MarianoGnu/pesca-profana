class_name Inventory
extends RefCounted


var contents: Dictionary[BodyPart, int]


func has(object: BodyPart) -> bool:
	return contents.get(object) > 0


func add(object: BodyPart, amount: int = 1) -> void:
	if amount < 0:
		push_error("Invalid amount %d" % amount)
		return
	if !object in contents:
		contents[object] = 0
	contents[object] += amount


func remove(object: BodyPart, amount: int = 1) -> void:
	if amount < 0:
		push_error("Invalid amount ", amount)
		return
	if !object in contents:
		contents[object] = 0
	if amount > contents[object]:
		push_error("Atempted to remove too many items at once. (%s,%d)" % [object, amount])
	contents[object] -= amount
