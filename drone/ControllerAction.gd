extends Reference
class_name ControllerAction


enum Type {NULL, BUTTON, AXIS}


var action_name := ""
var action_label := ""
var bound := false
var type: int = Type.NULL
var button := -1
var axis := -1
var axis_min := 0.0
var axis_max := 1.0


func init(a_name: String, a_label: String):
	action_name = a_name
	action_label = a_label


func unbind():
	bound = false
	type = Type.NULL
	button = -1
	axis = -1
	axis_min = 0.0
	axis_max = 1.0
