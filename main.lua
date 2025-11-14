-- main.lua

-- colors
COLOR_BG = Color[Color.black]
COLOR_FG = Color[Color.white + Color.bright]
COLOR_FRAME = Color[Color.cyan]
COLOR_EMPTY = Color[Color.white]
-- these will depend on tile value
COLOR_TILE_BG = Color[Color.yellow]
COLOR_TILE_FG = Color[Color.black]

-- size from single base unit
BASE_SIZE = 40
GRID_SIZE = 4
FRAME_THICK = BASE_SIZE
CELL_SIZE = BASE_SIZE * 2
CELL_GAP = math.floor(BASE_SIZE / 5 + 0.5)

BOARD_LEFT = FRAME_THICK
BOARD_TOP = FRAME_THICK
BOARD_WIDTH = GRID_SIZE * CELL_SIZE
BOARD_HEIGHT = GRID_SIZE * CELL_SIZE
HUD_Y = BOARD_TOP + BOARD_HEIGHT + BASE_SIZE

Game = {
  rows = GRID_SIZE,
  cols = GRID_SIZE,
  cells = { },
  state = "start",
  score = 0
}

Line = {
  values = { },
  size = GRID_SIZE
}

EmptyCells = { list = { } }

MoveTable = { }

gfx = love.graphics

-- reset board cells to zero
function game_clear()
  for row = 1, Game.rows do
    Game.cells[row] = { }
    for col = 1, Game.cols do
      Game.cells[row][col] = 0
    end
  end
end

-- collect coordinates of empty cells
function empty_collect()
  EmptyCells.list = { }
  for row = 1, Game.rows do
    for col = 1, Game.cols do
      if Game.cells[row][col] == 0 then
        EmptyCells.list[#(EmptyCells.list) + 1] = {
          row = row,
          col = col
        }
      end
    end
  end
end

-- add one random 2 or 4
function game_add_random_tile()
  empty_collect()
  if #(EmptyCells.list) == 0 then
    return 
  end
  index = love.math.random(#(EmptyCells.list))
  spot = EmptyCells.list[index]
  value = 2
  if 0.9 < love.math.random() then
    value = 4
  end
  Game.cells[spot.row][spot.col] = value
end

-- full reset of the game
function game_reset()
  game_clear()
  Game.score = 0
  game_add_random_tile()
  game_add_random_tile()
  Game.state = "play"
end

-- read row left→right into Line.values
function line_read_row(row)
  Line.values = { }
  for col = 1, Game.cols do
    Line.values[col] = Game.cells[row][col]
  end
end

-- write row left→right from Line.values, report change
function line_write_row(row)
  changed = false
  for col = 1, Game.cols do
    value = Line.values[col] or 0
    if Game.cells[row][col] ~= value then
      Game.cells[row][col] = value
      changed = true
    end
  end
  return changed
end

-- read row right→left
function line_read_row_reverse(row)
  Line.values = { }
  index = 1
  for col = Game.cols, 1, -1 do
    Line.values[index] = Game.cells[row][col]
    index = index + 1
  end
end

-- write row right→left from Line.values
function line_write_row_reverse(row)
  index = 1
  changed = false
  for col = Game.cols, 1, -1 do
    value = Line.values[index] or 0
    if Game.cells[row][col] ~= value then
      Game.cells[row][col] = value
      changed = true
    end
    index = index + 1
  end
  return changed
end

-- read column top→bottom
function line_read_col(col)
  Line.values = { }
  for row = 1, Game.rows do
    Line.values[row] = Game.cells[row][col]
  end
end

-- write column top→bottom
function line_write_col(col)
  changed = false
  for row = 1, Game.rows do
    value = Line.values[row] or 0
    if Game.cells[row][col] ~= value then
      Game.cells[row][col] = value
      changed = true
    end
  end
  return changed
end

-- read column bottom→top
function line_read_col_reverse(col)
  Line.values = { }
  index = 1
  for row = Game.rows, 1, -1 do
    Line.values[index] = Game.cells[row][col]
    index = index + 1
  end
end

-- write column bottom→top
function line_write_col_reverse(col)
  index = 1
  changed = false
  for row = Game.rows, 1, -1 do
    value = Line.values[index] or 0
    if Game.cells[row][col] ~= value then
      Game.cells[row][col] = value
      changed = true
    end
    index = index + 1
  end
  return changed
end

-- remove zeros, keep order
function line_pack_left()
  packed = { }
  for index = 1, Line.size do
    value = Line.values[index] or 0
    if value ~= 0 then
      packed[#packed + 1] = value
    end
  end
  Line.values = packed
end

-- merge equal neighbors, update score
function line_merge_left()
  index = 1
  while index < #(Line.values) do
    if Line.values[index] == Line.values[index + 1] then
      merged = Line.values[index] * 2
      Line.values[index] = merged
      Game.score = Game.score + merged
      table.remove(Line.values, index + 1)
    else
      index = index + 1
    end
  end
end

-- fill with zeros to fixed size
function line_fill_zero()
  while #(Line.values) < Line.size do
    Line.values[#(Line.values) + 1] = 0
  end
end

-- full left move on current Line.values
function line_build_left()
  line_pack_left()
  line_merge_left()
  line_fill_zero()
end

-- apply left move to one row
function line_apply_row_left(row)
  line_read_row(row)
  line_build_left()
  return line_write_row(row)
end

-- apply right move to one row
function line_apply_row_right(row)
  line_read_row_reverse(row)
  line_build_left()
  return line_write_row_reverse(row)
end

-- apply up move to one column
function line_apply_col_up(col)
  line_read_col(col)
  line_build_left()
  return line_write_col(col)
end

-- apply down move to one column
function line_apply_col_down(col)
  line_read_col_reverse(col)
  line_build_left()
  return line_write_col_reverse(col)
end

-- move the whole board
function move_board(line_apply, lines)
  moved = false
  for i = 1, lines do
    if line_apply(i) then
      moved = true
    end
  end
  return moved
end

-- move left on whole board
function MoveTable.left()
  return move_board(line_apply_row_left, Game.rows)
end

-- move right on whole board
function MoveTable.right()
  return move_board(line_apply_row_right, Game.rows)
end

-- move up on whole board
function MoveTable.up()
  return move_board(line_apply_col_up, Game.cols)
end

-- move down on whole board
function MoveTable.down()
  return move_board(line_apply_col_down, Game.cols)
end

-- check for empty cell
function game_has_empty()
  for row = 1, Game.rows do
    for col = 1, Game.cols do
      if Game.cells[row][col] == 0 then
        return true
      end
    end
  end
  return false
end

-- check merges in rows (left/right neighbours)
function game_can_merge_row()
  for row = 1, Game.rows do
    for col = 1, Game.cols - 1 do
      if Game.cells[row][col] ~= 0
           and Game.cells[row][col + 1] == Game.cells[row][col]
      then
        return true
      end
    end
  end
  return false
end

-- check merges in columns (up/down neighbours)
function game_can_merge_col()
  for row = 1, Game.rows - 1 do
    for col = 1, Game.cols do
      if Game.cells[row][col] ~= 0
           and Game.cells[row + 1][col] == Game.cells[row][col]
      then
        return true
      end
    end
  end
  return false
end

-- true if at least one merge is possible
function game_can_merge()
  return game_can_merge_row() or game_can_merge_col()
end

-- true when no moves left
function game_is_over()
  return not (game_has_empty() or game_can_merge())
end

-- run one move in a given direction
function game_handle_move(dir)
  move_func = MoveTable[dir]
  if not move_func then
    return 
  end
  if move_func() then
    game_add_random_tile()
    if game_is_over() then
      Game.state = "gameover"
    end
  end
end

-- draw board frame with uniform thickness
function draw_board_frame()
  gfx.setColor(COLOR_FRAME)
  gfx.rectangle(
    "fill",
    BOARD_LEFT - FRAME_THICK,
    BOARD_TOP - FRAME_THICK,
    BOARD_WIDTH + FRAME_THICK * 2,
    BOARD_HEIGHT + FRAME_THICK * 2
  )
end

-- draw a single tile
function draw_cell(row, col, value)
  x = BOARD_LEFT + (col - 1) * CELL_SIZE
  y = BOARD_TOP + (row - 1) * CELL_SIZE
  size = CELL_SIZE - CELL_GAP
  if value > 0 then
    gfx.setColor(COLOR_TILE_BG)
  else
    gfx.setColor(COLOR_EMPTY)
  end
  gfx.rectangle("fill", x, y, size, size)
  if value > 0 then
    gfx.setColor(COLOR_TILE_FG)
    gfx.print(value, x + 10, y + 10)
  end
end

-- draw whole board
function draw_board()
  for row = 1, Game.rows do
    for col = 1, Game.cols do
      draw_cell(row, col, Game.cells[row][col])
    end
  end
end

-- draw score text
function draw_score()
  gfx.setColor(COLOR_FG[1], COLOR_FG[2], COLOR_FG[3])
  gfx.print("Score: " .. Game.score, BOARD_LEFT, HUD_Y)
end

KeyToDir = {
  left = "left",
  right = "right",
  up = "up",
  down = "down",
  a = "left",
  d = "right",
  w = "up",
  s = "down"
}

-- keyboard input
function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
    return 
  end
  if key == "r" then
    game_reset()
    return 
  end
  dir = KeyToDir[key]
  if dir then
    game_handle_move(dir)
  end
end

-- main draw
function love.draw()
  gfx.clear(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3])
  draw_board_frame()
  draw_board()
  draw_score()
  if Game.state == "gameover" then
    gfx.print("GAME OVER", BOARD_LEFT, HUD_Y + 30)
  end
end

-- start game
game_reset()
