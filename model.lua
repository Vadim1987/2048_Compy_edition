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
  state = "play"
}

-- probabilities and counts
START_TILES = 2
TILE_TWO_PROBABILITY = 0.9

-- reset board to empty state
function game_clear()
  Game.empty_count = Game.rows * Game.cols
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

-- add one random 2 or 4
function game_add_random_tile()
  local target = love.math.random(Game.empty_count)
  local row, col = find_empty_by_index(target)
  Game.cells[row][col] = tile_random_value()
  Game.empty_count = Game.empty_count - 1
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
