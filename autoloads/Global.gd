extends Node


var log_path = "user://log.txt"

var startup = true


func log_error(err_code: int, message: String = ""):
	var file: File = File.new()
	file.open(log_path, File.WRITE_READ)
	file.store_line("ERROR %d: %s" % [err_code, message])
	file.close()
