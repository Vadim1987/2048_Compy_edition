-- model.lua
-- Game model and state

-- board size
GRID_SIZE = 4

-- history state
History = {
  moves = { },    
  future = { },   
  snapshots = { },
  initial = { }  
}
BUTTON_WIDTH = 80
BUTTON_HEIGHT = 40
BUTTON_GAP = 15

-- game state
Game = {
  rows = GRID_SIZE,
  cols = GRID_SIZE,
  cells = { },
  score = 0,
  empty_count = 0,
  max_merge = 0,
  state = "play",
  replay_index = 0,
  replay_timer = 0,
  animations = { }
}

-- probabilities and counts
START_TILES = 2
TILE_TWO_PROBABILITY = 0.9
MAX_DT = 0.05
ANIM_DURATION = {
  spawn = 0.15,
  slide = 0.12,
  merge = 0.12
}
REPLAY_DELAY = 0.2

-- helper to clone board state
function deep_copy_cells(cells)
  local new_cells = { }
  for r = 1, #cells do
    new_cells[r] = { }
    for c = 1, #cells[r] do
      new_cells[r][c] = cells[r][c]
    end
  end
  return new_cells
end

function save_snapshot()
  local snap = {
    cells = deep_copy_cells(Game.cells),
    score = Game.score,
    empty_count = Game.empty_count
  }
  table.insert(History.snapshots, snap)
end

function restore_snapshot()
  local snap = table.remove(History.snapshots)
  if not snap then return false end
  Game.cells = snap.cells
  Game.score = snap.score
  Game.empty_count = snap.empty_count
  return true
end

-- reset board to empty state
function game_clear()
  Game.empty_count = Game.rows * Game.cols
  Game.animations = { }
  for row = 1, Game.rows + 1 do
    Game.cells[row] = { }
  end
end

-- choose random value 2 or 4
function tile_random_value()
  if love.math.random() < TILE_TWO_PROBABILITY then
    return 2
  end
  return 4
end

-- find N-th empty cell (by scan order)
function find_empty_by_index(target)
  local seen = 0
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

function game_add_animation(kind, args)
  local anim = args or { }
  anim.type = kind
  anim.t = 0
  anim.duration = anim.duration or ANIM_DURATION[kind]
  table.insert(Game.animations, anim)
end

function game_add_random_tile(forced)
  local row, col, value
  if forced then
    row, col, value = forced.row, forced.col, forced.value
  else
    local t = love.math.random(Game.empty_count)
    row, col = find_empty_by_index(t)
    value = tile_random_value()
  end
  Game.cells[row][col] = value
  Game.empty_count = Game.empty_count - 1
  game_add_animation("spawn", { row_to = row, col_to = col, value = value })
  return { row = row, col = col, value = value }
end

-- full reset of the game
function game_reset()
  game_clear()
  Game.score = 0
  History.moves = { }
  History.future = { }
  History.snapshots = { }
  History.initial = { }
  for i = 1, START_TILES do
    local spawn = game_add_random_tile(nil)
    table.insert(History.initial, spawn)
  end
  Game.state = "play"
end

function game_update_animations(dt)
  local pending = false
  for _, a in pairs(Game.animations) do
    a.t = a.t + dt / a.duration
    if 1 < a.t then
      a.t = 1
    end
    pending = pending or (a.t < 1)
  end
  if not pending then
    Game.animations = { }
  end
end

-- true if at least one merge is possible on a full board
function game_can_merge()
  local cells, rows, cols = Game.cells, Game.rows, Game.cols
  for row = 1, rows do
    for col = 1, cols do
      if (cells[row][col] == cells[row][col + 1])
         or (cells[row][col] == cells[row + 1][col])
      then
        return true
      end
    end
  end
  return false
end
