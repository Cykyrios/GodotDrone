extends Node


var log_path = "user://output.log"

var startup = true


func get_formatted_date_time():
	var date_time := OS.get_datetime()
	var time := "[%04d-%02d-%02d %02d:%02d:%02d]" % [date_time["year"], date_time["month"], \
			date_time["day"], date_time["hour"], date_time["minute"], date_time["second"]]
	return time


func log_error(err_code: int, message: String = ""):
	var file: File = File.new()
	var _discard = file.open(log_path, File.WRITE_READ)
	file.store_line("%s ERROR %d: %s" % [get_formatted_date_time(), err_code, message])
	file.close()
