extends Camera2D

@export var speed = 10;
@export var zoomSpeed = 5;
@export var maxZoom = 7.5;
@export var minZoom = 2.5;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	processCameraMovement(delta)
	
func processCameraMovement(delta):
	var normalizedSpeed = speed * delta;
	
	if Input.is_action_pressed("ui_right") :
		position.x += normalizedSpeed;
	if Input.is_action_pressed("ui_left") :
		position.x -= normalizedSpeed;
	if Input.is_action_pressed("ui_down") :
		position.y += normalizedSpeed;
	if Input.is_action_pressed("ui_up") :
		position.y -= normalizedSpeed;
	
	if Input.is_action_pressed("zoom_in") && zoom.x <= maxZoom:
		zoom = lerp(zoom, zoom + Vector2.ONE, delta * zoomSpeed)
	if Input.is_action_pressed("zoom_out") && zoom.x >= minZoom:
		zoom = lerp(zoom, zoom - Vector2.ONE, delta * zoomSpeed)
