-- model.lua
-- Game model and state

-- board size
GRID_SIZE = 4

-- history state
History = { }

-- game state
Game = {
  rows = GRID_SIZE,
  cols = GRID_SIZE,
  max_merge = 0,
  state = "play",
  replay_index = 0,
  replay_timer = 0,
  animations = { }
}

Game.board = { cells = { } }

-- probabilities and counts
START_TILES = 2
TILE_TWO_PROBABILITY = 0.9
ANIM_DURATION = {
  spawn = 0.15,
  slide = 0.12,
  merge = 0.12
}
REPLAY_DELAY = 0.2

-- helper to clone board state

function deep_copy(obj)
  if type(obj) ~= "table" then
    return obj
  end
  local r = { }
  for k, v in pairs(obj) do
    r[k] = deep_copy(v)
  end
  return r
end

-- helper metatable for stacks
STACK = {
  __index = function(_, k)
    return table[k]
  end
}

function save_snapshot()
  History.snapshots:insert(deep_copy(Game.board))
end

function restore_snapshot()
  local board = History.snapshots:remove()
  if not board then
    return false
  end
  Game.board = board
  return true
end

-- reset board to empty state
function game_clear()
  Game.board.empty_count = Game.rows * Game.cols
  for row = 1, Game.rows do
    Game.board.cells[row] = { }
  end
  Game.board.score = 0
  Game.animations = { }
  History.past_moves = { }
  History.future_moves = { }
  History.snapshots = { }
  History.initial = { }
  for _, t in pairs(History) do
    setmetatable(t, STACK)
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
      if not Game.board.cells[row][col] then
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

function spawn_random_tile()
  local spawn = { }
  spawn.row_to, spawn.col_to = find_empty_by_index(
    love.math.random(Game.board.empty_count)
  )
  spawn.value = tile_random_value()
  spawn_tile(spawn)
  return spawn
end

function spawn_tile(spawn)
  Game.board.cells[spawn.row_to][spawn.col_to] = spawn.value
  Game.board.empty_count = Game.board.empty_count - 1
  game_add_animation("spawn", spawn)
end

-- full reset of the game
function game_reset()
  game_clear()
  for i = 1, START_TILES do
    History.initial:insert(spawn_random_tile())
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
  local cells, rows, cols = Game.board.cells, Game.rows, Game.
      cols
  for r = 1, rows do
    for c = 1, cols do
      local val = cells[r][c]
      if c < cols and val == cells[r][c + 1] then
        return true
      end
      if r < rows and val == cells[r + 1][c] then
        return true
      end
    end
  end
  return false
end
