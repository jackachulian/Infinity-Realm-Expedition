extends MeshInstance3D

@export var start: float = 0.1
@export var duration: float = 0.25
@export var fade: float = 0.033

var time_elapsed: float
var playing: bool
var in_half_alpha: bool
var fading_out: bool

const HALF_ALPHA := Color(1,1,1,0.5)

func _ready():
	hide()

func play():
	playing = true
	in_half_alpha = false
	fading_out = false
	time_elapsed = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not playing:
		return
		
	time_elapsed += delta
	
	if not in_half_alpha and not fading_out and time_elapsed > start:
		in_half_alpha = true;
		material_override.albedo_color = HALF_ALPHA
		show()
		
	if in_half_alpha and not fading_out and time_elapsed > start + fade:
		material_override.albedo_color = Color.WHITE
		in_half_alpha = false
		fading_out = true
		
	if not in_half_alpha and fading_out and time_elapsed > start + duration - fade:
		material_override.albedo_color = HALF_ALPHA
		in_half_alpha = true
		
	if time_elapsed > start + duration:
		playing = false;
		hide()
		
