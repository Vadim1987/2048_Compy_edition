-- logic.lua
-- Movement and merging logic

require("model")

-- read and modify board
function get_value(indices, index)
  local row, col = indices(index)
  return Game.cells[row][col]
end

function set_value(indices, index, value)
  local row, col = indices(index)
  Game.cells[row][col] = value
end

function get_line_values(indices, size)
  local line = { }
  for index = 1, size do
    line[index] = get_value(indices, index)
  end
  return line
end

function fill_slide_indices(before, after, size)
  local src = { }
  local dst = { }
  for index = 1, size do
    if before[index] then
      src[#src + 1] = index
    end
    if after[index] then
      dst[#dst + 1] = index
    end
  end
  return src, dst
end

function is_merged_pair(before, after, dest_index, from1, from2)
  if not from2 then
    return false
  end
  local value = before[from1]
  if before[from2] ~= value then
    return false
  end
  return after[dest_index] == value + value
end

function add_anim(kind, idx, a, b, value)
  local args = { }
  args.row_from, args.col_from = idx(a)
  args.row_to, args.col_to = idx(b)
  args.value = value
  game_add_animation(kind, args)
end

function apply_slide_step(before, after, idx, src, dst, si, di)
  local from1 = src[si]
  if not from1 then
    return nil
  end
  local dest, from2, value = dst[di], src[si + 1], before[from1]
  if is_merged_pair(before, after, dest, from1, from2) then
    add_anim("slide", idx, from1, dest, value)
    add_anim("slide", idx, from2, dest, value)
    add_anim("merge", idx, dest, dest, value)
    return si + 2
  end
  add_anim("slide", idx, from1, dest, value)
  return si + 1
end

function add_line_slides(before, after, idx, size)
  local src, dst = fill_slide_indices(before, after, size)
  local si = 1
  for di = 1, #dst do
    si = apply_slide_step(before, after, idx, src, dst, si, di)
    if not si then
      break
    end
  end
end

-- compact line in-place via accessors
function compact_line(indices, size)
  local moved, write = false, 1
  for index = 1, size do
    local value = get_value(indices, index)
    if value then
      moved = moved or (index ~= write)
      set_value(indices, write, value)
      write = write + 1
    end
  end
  for index = write, size do
    set_value(indices, index, nil)
  end
  return moved
end

-- merge equal neighbours in-place, update score/empty_count
function merge_line(indices, size)
  local moved = false
  for index = 1, size - 1 do
    local value = get_value(indices, index)
    if value and get_value(indices, index + 1) == value then
      local merged = value + value
      set_value(indices, index, merged)
      set_value(indices, index + 1, nil)
      Game.score = Game.score + merged
      Game.empty_count = Game.empty_count + 1
      moved = true
    end
  end
  return moved
end

-- full move on abstract line via accessors
function line_move(indices, size)
  local before = get_line_values(indices, size)
  local moved = compact_line(indices, size)
  if merge_line(indices, size) then
    moved = true
  end
  if compact_line(indices, size) then
    moved = true
  end
  local after = get_line_values(indices, size)
  add_line_slides(before, after, indices, size)
  return moved
end

-- apply left move to one row
function line_apply_row_left(row)
  local function indices(index)
    return row, index
  end
  return line_move(indices, Game.cols)
end

-- apply right move to one row
function line_apply_row_right(row)
  local function indices(index)
    return row, (Game.cols - index) + 1
  end
  return line_move(indices, Game.cols)
end

-- apply up move to one column
function line_apply_col_up(col)
  local function indices(index)
    return index, col
  end
  return line_move(indices, Game.rows)
end

-- apply down move to one column
function line_apply_col_down(col)
  local function indices(index)
    return (Game.rows - index) + 1, col
  end
  return line_move(indices, Game.rows)
end

-- move the whole board
function move_board(line_apply, lines)
  local moved = false
  for index = 1, lines do
    if line_apply(index) then
      moved = true
    end
  end
  return moved
end

-- move left on whole board
function move_left()
  return move_board(line_apply_row_left, Game.rows)
end

-- move right on whole board
function move_right()
  return move_board(line_apply_row_right, Game.rows)
end

-- move up on whole board
function move_up()
  return move_board(line_apply_col_up, Game.cols)
end

-- move down on whole board
function move_down()
  return move_board(line_apply_col_down, Game.rows)
end

-- run one move in a given direction
function game_handle_move(move_func)
  if move_func() then
    game_add_random_tile()
    if (0 < Game.empty_count) or game_can_merge() then
      return 
    end
    Game.state = "gameover"
  else
    Game.animations = { }
  end
end
