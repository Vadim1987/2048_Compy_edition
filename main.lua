-- main.lua

-- colors
COLOR_BG = Color[Color.black]
COLOR_FG = Color[Color.white + Color.bright]
COLOR_FRAME = Color[Color.cyan]
COLOR_EMPTY = Color[Color.white]
COLOR_TILE_BG = Color[Color.yellow]
COLOR_TILE_FG = Color[Color.black]

-- size from single base unit
BASE_SIZE = 56
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
  cells = {},
  score = 0,
  empty_count = 0
}

KeyPress = { }
gfx = love.graphics

-- reset board to empty state
function game_clear()
  Game.empty_count = Game.rows * Game.cols
  for row = 1, Game.rows do
    Game.cells[row] = { }
  end
end

-- choose random value 2 or 4
function tile_random_value()
  if love.math.random() < 0.9 then
    return 2
  end
  return 4
end

-- find N-th empty cell (by scan order)
function find_empty_by_index(target)
  seen = 0
  for row = 1, Game.rows do
    for col = 1, Game.cols do
      if not Game.cells[row][col] then
        seen = seen + 1
        if seen == target then
          return row, col
        end
      end
    end
  end
end

-- add one random 2 or 4
function game_add_random_tile()
  target = love.math.random(Game.empty_count)
  row, col = find_empty_by_index(target)
  if row then
    Game.cells[row][col] = tile_random_value()
    Game.empty_count = Game.empty_count - 1
  end
end

-- full reset of the game
function game_reset()
  game_clear()
  Game.score = 0
  game_add_random_tile()
  game_add_random_tile()
  Game.state = "play"
end

-- read and modify board
function get_value(indices, index)
  local row, col = indices(index)
  return Game.cells[row][col]
end
function set_value(indices, index, value)
  local row, col = indices(index)
  Game.cells[row][col] = value
end

-- compact line in-place via accessors
function compact_line(indices, size)
  local moved, write = false, 1
  for index = 1, size do
    local value = get_value(indices, index)
    if value then
      moved = moved or index ~= write
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
  local moved = compact_line(indices, size)
  if merge_line(indices, size) then
    moved = true
  end
  if compact_line(indices, size) then
    moved = true
  end
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
    return row, Game.cols - index + 1
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
    return Game.rows - index + 1, col
  end
  return line_move(indices, Game.rows)
end

-- move the whole board
function move_board(line_apply, lines)
  moved = false
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
  return move_board(line_apply_col_down, Game.cols)
end

-- true if at least one merge is possible on a full board
function game_can_merge()
  local cells, rows, cols = Game.cells, Game.rows, Game.cols
  for row = 1, rows do
    for col = 1, cols do
      if (col < cols)
           and (cells[row][col] == cells[row][col + 1])
      then
        return true
      end
      if (row < rows)
           and (cells[row][col] == cells[row + 1][col])
      then
        return true
      end
    end
  end
  return false
end

-- run one move in a given direction
function game_handle_move(move_func)
  if move_func() then
    game_add_random_tile()
    if (0 < Game.empty_count) or game_can_merge() then
      return
    end
    Game.state = "gameover"
  end
end

-- draw board frame with uniform thickness
function draw_board_frame()
  gfx.setColor(COLOR_FRAME)
  gfx.rectangle(
    "fill",
    BOARD_LEFT - FRAME_THICK,
    BOARD_TOP  - FRAME_THICK,
    BOARD_WIDTH  + FRAME_THICK * 2,
    BOARD_HEIGHT + FRAME_THICK * 2
  )
end

-- draw a single tile
function draw_cell(row, col, value)
  local x = BOARD_LEFT + (col - 1) * CELL_SIZE
  local y = BOARD_TOP + (row - 1) * CELL_SIZE
  local size = CELL_SIZE - CELL_GAP
  if value then
    gfx.setColor(COLOR_TILE_BG)
  else
    gfx.setColor(COLOR_EMPTY)
  end
  gfx.rectangle("fill", x, y, size, size)
  if value then
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

-- keyboard handlers
function KeyPress.left()
  game_handle_move(move_left)
end

function KeyPress.right()
  game_handle_move(move_right)
end

function KeyPress.up()
  game_handle_move(move_up)
end

function KeyPress.down()
  game_handle_move(move_down)
end

KeyPress.a = KeyPress.left
KeyPress.d = KeyPress.right
KeyPress.w = KeyPress.up
KeyPress.s = KeyPress.down
KeyPress.escape = love.event.quit
KeyPress.r = game_reset

-- keyboard input
function love.keypressed(key)
  local handler = KeyPress[key]
  if handler then
    handler()
  end
end

-- main draw
function love.draw()
  gfx.clear(COLOR_BG)
  draw_board_frame()
  draw_board()
  draw_score()
  if Game.state == "gameover" then
    gfx.print("GAME OVER", BOARD_LEFT, HUD_Y + 30)
  end
end

-- start game
game_reset()
