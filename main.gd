extends GridContainer

const cell_size := Vector2i(32, 32)
const blank_color := Color(0)
const MAIN_COLUMNS = 10
const MAIN_ROWS = 20

enum { PLAYING, STOP }

var state = PLAYING
# 当前在下落中的图形
var current_shape := ShapeData.get_new()
# 下一个要下落的图形
var next_shape := ShapeData.get_new()
# current_shape x 轴的偏移量
var offset_x = 0
# current_shape 当前所在行数
var row_idx = 0
# current_shape 中每个图块在主场景中的索引数组
var current_shape_idx_arr: Array[int]
# 场景中所有图块
var cells: Array
# 下落计时器
var ticker: Timer
# 当前场景中已存在的图块(非透明图块)
var main_cells: Array[int] = []


func _ready():
	var blank_rect = ColorRect.new()
	blank_rect.set_custom_minimum_size(cell_size)
	blank_rect.set_color(blank_color)
	# 使用透明图块将场景填充满景
	for i in range(MAIN_COLUMNS * MAIN_ROWS):
		add_child(blank_rect.duplicate())
	cells = get_children()
	init_shape()
	ticker = get_parent().get_node("Ticker")
	ticker.connect("timeout", on_tick)
	ticker.start()


func on_tick():
	""" 计时器每次响应回调 """
	row_idx += 1
	place_shape()
	

func init_shape():
	current_shape_idx_arr = get_shape_idxs()
	set_cells()


func set_cells() -> bool:
	""" 将 current_shape 图块颜色填充 """
	for idx in current_shape_idx_arr:
		if idx in main_cells:
			return false
		cells[idx].set_color(current_shape.color)
	return true


func place_shape():
	""" 变形/下落 等动作的总调度器 """
	if not reset_current_shape():
		# game over
		print("game_over")
		ticker.stop()
		state = STOP


func reset_current_shape() -> bool:
	""" 变形/下落 重设颜色 """
	var idxs = get_shape_idxs()
	if len(idxs) == 0:
		main_cells.append_array(current_shape_idx_arr)
		if row_idx == 0:
			# game over
			return false
		row_idx = 0
		offset_x = 0
		current_shape = next_shape
		next_shape = ShapeData.get_new()
		current_shape_idx_arr.clear()
		calc_main_cells()
		place_shape()
		ticker.stop()
		ticker.start(1)
	else:
		for i in current_shape_idx_arr:
			cells[i].set_color(blank_color)
		current_shape_idx_arr = idxs
		set_cells()
	return true


func calc_main_cells():
	""" 计算当前界面需要减掉的图形, 并重新填色 """
	main_cells.sort()
	var start_row = main_cells[0] / 10
	var sub_rows = []
	for row in range(start_row, MAIN_ROWS):
		var filled = true
		for idx in range(row * 10, (row + 1) * 10):
			if idx not in main_cells:
				filled = false
				break
		if filled:
			sub_rows.append(row)
	print('sub_rows=', sub_rows)
	var subbed_count = 0
	var new_main_cells = []
	# 倒序遍历
	for row in range(MAIN_ROWS - 1, start_row - 1, -1):
		var sub_row = func(row):
			for i in range(row * 10, (row + 1) * 10):
				cells[i].set_color(blank_color)
		if row in sub_rows:
			# 需要减掉的图形, 先设置透明
			sub_row.call(row)
		elif subbed_count != 0:  # and row not in sub_rows
			# 下层已有减掉的图形了, 先将此层颜色涂到下面应到的层数, 然后将此层涂为透明色
			for i in range(row * 10, (row + 1) * 10):
				if i in main_cells:
					var idx = i + subbed_count * 10
					cells[idx].set_color(cells[i].get_color())
					new_main_cells.append(idx)
			sub_row.call(row)
		else:  # 
			for i in range(row * 10, (row + 1) * 10):
				if i in main_cells:
					new_main_cells.append(i)
		if row in sub_rows:
			subbed_count += 1
	main_cells = new_main_cells


func get_shape_idxs() -> Array[int]:
	var idx_0 = row_idx * MAIN_COLUMNS + current_shape.start_pos + offset_x
	var idx_arr: Array[int] = []
	var current_col = 0
	var shape_columns = current_shape.rotate_columns[current_shape.grid_idx]
	var now_idx = idx_0
	var shape_rows = len(current_shape.current_data) / shape_columns
	if row_idx + shape_rows >= MAIN_ROWS:
#		print("到达最底行")
		return []
#	print('shape_columns=', shape_columns)
	for i in range(len(current_shape.current_data)):
#		print('i=', i, '; current_col=', current_col, '; now_idx=', now_idx, '; shape_data=', current_shape.current_data[i])
		if i == 0:
			if current_shape.current_data[i] == 1:
				idx_arr.append(idx_0)
			now_idx += 1
			continue
		if i / shape_columns > current_col:
			now_idx += (MAIN_COLUMNS - shape_columns)
			current_col += 1
		if current_shape.current_data[i] == 1:
			if now_idx in main_cells:
				# 当前图形已与场景中的图块重合
				return []
			idx_arr.append(now_idx)
		now_idx += 1
	return idx_arr


func move_left():
	offset_x -= 1
	if current_shape.start_pos + offset_x < 0:
		offset_x += 1
	place_shape()


func move_right():
	offset_x += 1
	if current_shape.start_pos + current_shape.get_cols() + offset_x > MAIN_COLUMNS:
		offset_x -= 1
	place_shape()


func rotate_left():
	current_shape.grid_idx -= 1
	if current_shape.grid_idx < 0:
		current_shape.grid_idx = current_shape.data_len - 1
	current_shape.set_data()


func rotate_right():
	current_shape.grid_idx += 1
	if current_shape.grid_idx >= current_shape.data_len:
		current_shape.grid_idx = 0
	current_shape.set_data()
	
	
func _input(event):
	if state == PLAYING:
		if event.is_action_pressed("ui_left"):
			move_left()
	#		$LeftTimer.start(WAIT_TIME)
		elif event.is_action_released("ui_left"):
	#		$LeftTimer.stop()
			pass
		elif event.is_action_pressed("ui_right"):
			move_right()
	#		$RightTimer.start(WAIT_TIME)
		elif event.is_action_released("ui_right"):
	#		$RightTimer.stop()
			pass
		elif event.is_action_pressed("ui_up"):
	#		if event.is_action_pressed("shift"):
			rotate_right()
	#		else:
	#			rotate_left()
			place_shape()
		elif event.is_action_pressed("ui_accept"):
			ticker.stop()
			ticker.start(0.01)
			
	else:
		if event.is_action_pressed("ui_accept"):
			state = PLAYING


#func _on_timer_timeout():
#	print('_on_timer_timeout')
#	row_idx += 1
#	place_shape()
