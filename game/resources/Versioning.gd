class_name Versioning extends Node

# Stable, Beta, In-Dev
enum VersionType {IRIS, LUNA, LILYPAD}

const GAME_VERSION:String = "0.01"
const FNF_VERSION:String = "0.2.8"
const VER_TYPE:VersionType = VersionType.LILYPAD

static func grab_schema_name() -> String:
	match VER_TYPE:
		# VersionType.IRIS: return "[Iris]"
		VersionType.LUNA: return "[Luna]"
		VersionType.LILYPAD: return "[Lilypad]"
		_: return ""
