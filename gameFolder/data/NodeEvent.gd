class_name NodeEvent extends Resource

var data:Dictionary = {"cancelled" = false}

func get_event(event:String) -> Variant:
	var ret = -1
	if data.has(event):
		ret = data[event]
	return ret

func set_event(event:String, new_value:Variant) -> void:
	if data.has(event): data[event] = new_value
