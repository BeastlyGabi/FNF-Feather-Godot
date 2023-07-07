class_name DiscordNode extends DiscordRPC

var app_id:int = 748278415785721997

func _ready() -> void:
	establish_connection(app_id)
	rpc_ready.connect(_on_ready_rpc)
	rpc_closed.connect(_on_close_rpc)
	rpc_error.connect(_on_error_rpc)

func update_status(new_state:String, new_details:String, new_assets:Dictionary = {}) -> void:
	if not is_inside_tree(): return
	
	if new_assets == {}:
		new_assets = {"large_image": "bianca", "large_text": Game.VERSION.name + " (" + Game.VERSION.branch_to_string() + ")"}
	
	update_presence({
		state = new_state,
		details = new_details,
		assets = new_assets
	})

## IGNORE THESE
func _on_ready_rpc(usr:Dictionary) -> void:
	print_debug("Connection initialized!")

func _on_error_rpc(error_code:int) -> void:
	print_debug("Something went wrong, connection terminated with error code %s.", [error_code])

func _on_close_rpc() -> void:
	print_debug("Shutting down...")
