class_name PartyStorage
extends RefCounted

## Shared party convoy storage. Max 40 items.

const MAX_ITEMS: int = 40

var items: Array = []  # Array[ItemData]


func add_item(item: ItemData) -> bool:
	## Add item to convoy. Returns false if full.
	if items.size() >= MAX_ITEMS:
		return false
	items.append(item)
	return true


func remove_item(item: ItemData) -> bool:
	## Remove item from convoy. Returns false if not found.
	var idx: int = items.find(item)
	if idx < 0:
		return false
	items.remove_at(idx)
	return true


func remove_item_by_id(item_id: String) -> bool:
	## Remove first item matching id. Returns false if not found.
	for i in items.size():
		if items[i].id == item_id:
			items.remove_at(i)
			return true
	return false


func count() -> int:
	return items.size()


func is_full() -> bool:
	return items.size() >= MAX_ITEMS


func get_items_by_type(type_name: String) -> Array:
	## Return all items of a given type.
	var result: Array = []
	for item in items:
		if item.type == type_name:
			result.append(item)
	return result


func to_save_data() -> Array:
	var data: Array = []
	for item in items:
		data.append(item.to_dict())
	return data


static func from_save_data(data: Array) -> PartyStorage:
	var storage := PartyStorage.new()
	for d in data:
		if d is Dictionary:
			storage.items.append(ItemData.from_dict(d))
	return storage
