extends RefCounted

class_name ShapeData

const shape_names := ["l", "j", "z", "s", "t", "i", "o"]
const shape_fills = {
	# 旋转预演 - 顺时针旋转
	l = {
		data = [[0,0,1,1,1,1], [1,0,1,0,1,1], [1,1,1,1,0,0], [1,1,0,1,0,1]],
		columns = [3,2,3,2],
		color = "ff24ff",
	},
	# 列数; 与上面的预演一一对应
	j = {
		data = [[1,0,0,1,1,1], [1,1,1,0,1,0], [1,1,1,0,0,1], [0,1,0,1,1,1]],
		columns = [3,2,3,2],
		color = "4fb2be"
	},
	z = {
		data = [[1,1,0,0,1,1], [0,1,1,1,1,0]],
		columns = [3,2],
		color = "3ebf3a",
	},
	s = {
		data = [[0,1,1,1,1,0], [1,0,1,1,0,1]],
		columns = [3,2],
		color = "a68afc",
	},
	t = {
		data = [[0,1,0,1,1,1], [1,0,1,1,1,0], [1,1,1,0,1,0], [0,1,1,1,0,1]],
		columns = [3,2,3,2],
		color = "e28820",
	},
	i = {
		data = [[1,1,1,1], [1,1,1,1]],
		columns = [4,1],
		color = "ffffff",
	},
	o = {
		data = [[1,1,1,1]],
		columns = [2],
		color = "1c3eed",
	},
}
const cel_vector2i := Vector2i(32, 32)
const blank_color := Color("ffffff", 0)

var grid_idx := 0
var rotate_data: Array[Array]
var current_data: Array[int]
var rotate_columns: Array[int]
var data_len := 0
var color: Color
var start_pos: int
var container: GridContainer
var rect_array: Array[ColorRect] = []
var rect_blank_array: Array[ColorRect] = []


static func get_new() -> ShapeData:
	var shape_name = shape_names[randi() % len(shape_names)]
	var obj = new()
	var origin_data = shape_fills[shape_name]
	obj.grid_idx = 0
	obj.rotate_data = origin_data.data
	obj.data_len = len(obj.rotate_data) 
	obj.rotate_columns = origin_data.columns
	obj.color = Color(origin_data.color, 1)
	obj.set_data()
	return obj


func set_data():
	start_pos = (10 - rotate_columns[grid_idx]) / 2
	current_data = rotate_data[grid_idx]


func get_cols() -> int:
	return rotate_columns[grid_idx]
