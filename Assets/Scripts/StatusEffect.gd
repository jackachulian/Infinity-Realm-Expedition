class_name StatusEffect

# string used as an id for the status type. ex. "submerged", "burn", etc
var status_type: String

var duration: float = -1

var accel_multiplier: float = 1.0
var speed_multiplier: float = 1.0

func _init(status_type: String = "Status", duration: float = -1.0):
	self.status_type = status_type
	self.duration = duration
