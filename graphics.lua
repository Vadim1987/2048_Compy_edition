-- graphics.lua
-- Basic drawing: board, tiles, score, game over

require("model")

gfx = love.graphics

-- size from single base unit
BASE_SIZE = 15
FRAME_THICK = BASE_SIZE
CELL_SIZE = BASE_SIZE * 9
CELL_GAP = BASE_SIZE
CELL_OFFSET = math.floor(CELL_GAP / 2 + 0.5)
BOARD_LEFT = FRAME_THICK
BOARD_TOP = FRAME_THICK
BOARD_WIDTH = GRID_SIZE * CELL_SIZE
BOARD_HEIGHT = GRID_SIZE * CELL_SIZE
HUD_Y = BOARD_TOP + BOARD_HEIGHT + BASE_SIZE
TILE_SIZE = CELL_SIZE - CELL_GAP
TILE_RADIUS = CELL_GAP
FRAME_RADIUS = TILE_RADIUS + FRAME_THICK

-- layout constants
GAME_OVER_OFFSET_X = 20

-- colors
COLOR_BG = {
  0.98,
  0.973,
  0.941
}
COLOR_BOARD = {
  0.612,
  0.545,
  0.486
}
COLOR_EMPTY = {
  0.741,
  0.675,
  0.592
}

-- text colors
COLOR_TILE_FG_DARK = {
  0.467,
  0.431,
  0.396
}
COLOR_TILE_FG_LIGHT = {
  0.976,
  0.965,
  0.949
}
COLOR_FG = COLOR_TILE_FG_DARK

-- tile background colors
TILE_BG = { }
function add_tile_bg(value, r, g, b)
  TILE_BG[value] = {
    r,
    g,
    b
  }
end
add_tile_bg(2, 0.933, 0.894, 0.855)
add_tile_bg(4, 0.929, 0.878, 0.784)
add_tile_bg(8, 0.949, 0.694, 0.475)
add_tile_bg(16, 0.961, 0.584, 0.388)
add_tile_bg(32, 0.965, 0.486, 0.373)
add_tile_bg(64, 0.965, 0.369, 0.231)
add_tile_bg(128, 0.929, 0.812, 0.447)
add_tile_bg(256, 0.929, 0.8, 0.38)
add_tile_bg(512, 0.929, 0.784, 0.314)
add_tile_bg(1024, 0.929, 0.773, 0.247)
add_tile_bg(2048, 0.929, 0.761, 0.18)

-- super tiles > 2048:
COLOR_TILE_BG_SUPER = {
  0.235,
  0.227,
  0.196
}

setmetatable(TILE_BG, {
  __index = function()
    return COLOR_TILE_BG_SUPER
  end
})

-- fonts
TILE_FONT_PATH = "assets/fonts/SarasaGothicJ-Bold.ttf"
TILE_FONT_SIZE = 36
HUD_FONT_SIZE  = 24
tileFont = gfx.newFont(TILE_FONT_PATH, TILE_FONT_SIZE)
hudFont  = gfx.newFont(TILE_FONT_PATH, HUD_FONT_SIZE)

-- rounded-corner squares
D09 = math.pi / 2
D18 = math.pi
D27 = D09 * 3
D36 = D18 * 2

function draw_round_rect(x, y, w, h, radius)
  local x2 = x + w
  local y2 = y + h
  local d = radius * 2
  gfx.rectangle("fill", x + radius, y, w - d, h)
  gfx.rectangle("fill", x, y + radius, w, h - d)
  gfx.arc("fill", x + radius, y + radius, radius, D18, D27)
  gfx.arc("fill", x2 - radius, y + radius, radius, D27, D36)
  gfx.arc("fill", x2 - radius, y2 - radius, radius, 0, D09)
  gfx.arc("fill", x + radius, y2 - radius, radius, D09, D18)
end

-- draw board frame with uniform thickness
function draw_board_frame()
  gfx.setColor(COLOR_BOARD)
  draw_round_rect(
    BOARD_LEFT - CELL_OFFSET,
    BOARD_TOP - CELL_OFFSET,
    BOARD_WIDTH + 2 * CELL_OFFSET,
    BOARD_HEIGHT + 2 * CELL_OFFSET,
    FRAME_RADIUS
  )
end

-- helpers for tile colors
function tile_fg(value)
  if value < 8 then
    return COLOR_TILE_FG_DARK
  end
  return COLOR_TILE_FG_LIGHT
end

function draw_tile_text(value, x, y)
  gfx.setFont(tileFont)
  local tw = tileFont:getWidth(value)
  local th = tileFont:getHeight()
  local tx = x + (TILE_SIZE - tw) / 2
  local ty = y + (TILE_SIZE - th) / 2
  gfx.print(value, tx, ty)
end

-- draw a single tile
function draw_cell(row, col, value)
  local x = BOARD_LEFT + (col - 1) * CELL_SIZE + CELL_OFFSET
  local y = BOARD_TOP + (row - 1) * CELL_SIZE + CELL_OFFSET
  local bg = COLOR_EMPTY
  if value then
    bg = TILE_BG[value]
  end
  gfx.setColor(bg)
  draw_round_rect(x, y, TILE_SIZE, TILE_SIZE, TILE_RADIUS)
  if not value then
    return 
  end
  gfx.setColor(tile_fg(value))
  draw_tile_text(value, x, y)
end

-- draw whole board
function draw_board()
  for row = 1, Game.rows do
    for col = 1, Game.cols do
      draw_cell(row, col, Game.cells[row][col])
    end
  end
end

-- draw text
function draw_score()
  gfx.setColor(COLOR_FG)
  gfx.setFont(hudFont)
  score_str = "Score: " .. Game.score
  gfx.print(score_str, BOARD_LEFT, HUD_Y)
end

function draw_game_over()
  if Game.state == "gameover" then
    gfx.setColor(COLOR_FG)
    gfx.setFont(hudFont)
    gfx.print(
      "GAME OVER",
      BOARD_LEFT + hudFont:getWidth(score_str) + GAME_OVER_OFFSET_X,
      HUD_Y
    )
  end
end
