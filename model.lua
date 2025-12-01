-- model.lua
-- Game model and state

-- board size
GRID_SIZE = 4

-- game state
Game = {
  rows = GRID_SIZE,
  cols = GRID_SIZE,
  cells = { },
  score = 0,
  empty_count = 0,
  state = "play",
  animations = { }
}

-- probabilities and counts
START_TILES = 2
TILE_TWO_PROBABILITY = 0.9
SPAWN_ANIM_DURATION = 0.15
SLIDE_ANIM_DURATION = 0.12
MERGE_ANIM_DURATION = 0.12

-- reset board to empty state
function game_clear()
  Game.empty_count = Game.rows * Game.cols
  Game.animations = { }
  for row = 1, Game.rows do
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

local ANIM_DURATION = {
  spawn = SPAWN_ANIM_DURATION,
  slide = SLIDE_ANIM_DURATION,
  merge = MERGE_ANIM_DURATION
}

function game_add_animation(kind, args)
  local anim = args or { }
  anim.type = kind
  anim.t = 0
  anim.duration = anim.duration or ANIM_DURATION[kind]
  table.insert(Game.animations, anim)
end

function game_add_random_tile()
  local target = love.math.random(Game.empty_count)
  local row, col = find_empty_by_index(target)
  local value = tile_random_value()
  Game.cells[row][col] = value
  Game.empty_count = Game.empty_count - 1
  game_add_animation("spawn", {
    row_to = row,
    col_to = col,
    value = value
  })
end

-- full reset of the game
function game_reset()
  game_clear()
  Game.score = 0
  for i = 1, START_TILES do
    game_add_random_tile()
  end
  Game.state = "play"
end

function game_update_animations(dt)
  local index = 1
  while index <= #Game.animations do
    local anim = Game.animations[index]
    local duration = anim.duration
    anim.t = anim.t + dt / duration
    if anim.t > 1 then
      table.remove(Game.animations, index)
    else
      index = index + 1
    end
  end
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
