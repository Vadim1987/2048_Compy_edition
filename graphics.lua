-- graphics.lua
-- Basic drawing: board, tiles, score, game over

require("model")

gfx = love.graphics

-- size from single base unit
BASE_SIZE = 56
FRAME_THICK = BASE_SIZE
CELL_SIZE = BASE_SIZE * 2
CELL_GAP = math.floor(BASE_SIZE / 5 + 0.5)
CELL_OFFSET = math.floor(CELL_GAP / 2 + 0.5)
BOARD_LEFT = FRAME_THICK
BOARD_TOP = FRAME_THICK
BOARD_WIDTH = GRID_SIZE * CELL_SIZE
BOARD_HEIGHT = GRID_SIZE * CELL_SIZE
HUD_Y = BOARD_TOP + BOARD_HEIGHT + BASE_SIZE
TILE_SIZE = CELL_SIZE - CELL_GAP
TILE_CORNER_RATIO = 0.22
TILE_RADIUS = math.floor(TILE_SIZE * TILE_CORNER_RATIO + 0.5)
FRAME_CORNER_OUT_RATIO = 0.4
FRAME_CORNER_IN_RATIO = 0.3

-- layout constants
GAME_OVER_OFFSET_Y = 30

-- colors
COLOR_BG = {0, 0, 0}
COLOR_BOARD = {0.733, 0.678, 0.627}
COLOR_FRAME = COLOR_BOARD
COLOR_EMPTY = {0.804, 0.757, 0.706}

-- text colors
COLOR_TILE_FG_DARK  = {0.467, 0.431, 0.396}
COLOR_TILE_FG_LIGHT = {0.976, 0.965, 0.949}
COLOR_FG = COLOR_TILE_FG_DARK

-- tile background colors
TILE_BG = {
  [2] = {0.933, 0.894, 0.855}, 
  [4] = {0.929, 0.878, 0.784}, 
  [8] = {0.949, 0.694, 0.475}, 
  [16] = {0.961, 0.584, 0.388}, 
  [32] = {0.965, 0.486, 0.373}, 
  [64] = {0.965, 0.369, 0.231}, 
  [128] = {0.929, 0.812, 0.447}, 
  [256] = {0.929, 0.800, 0.380}, 
  [512] = {0.929, 0.784, 0.314}, 
  [1024] = {0.929, 0.773, 0.247}, 
  [2048] = {0.929, 0.761, 0.180}  
}

-- super tiles > 2048:
COLOR_TILE_BG_SUPER = {0.235, 0.227, 0.196}

-- fonts
TILE_FONT_PATH = "assets/fonts/SarasaGothicJ-Bold.ttf"
TILE_FONT_SIZE = 36
HUD_FONT_SIZE  = 24
tileFont = gfx.newFont(TILE_FONT_PATH, TILE_FONT_SIZE)
hudFont  = gfx.newFont(TILE_FONT_PATH, HUD_FONT_SIZE)

-- rounded-corner squares
function draw_round_rect(x, y, w, h, radius)
  local two_pi = 2 * math.pi
  local x2 = x + w
  local y2 = y + h
  local d = radius * 2
  gfx.rectangle("fill", x + radius, y, w - d, h)
  gfx.rectangle("fill", x, y + radius, w, h - d)
  gfx.arc("fill", x + radius, y + radius, radius, 0, two_pi)
  gfx.arc("fill", x2 - radius, y + radius, radius, 0, two_pi)
  gfx.arc("fill", x2 - radius, y2 - radius, radius, 0, two_pi)
  gfx.arc("fill", x + radius, y2 - radius, radius, 0, two_pi)
end

-- draw board frame with uniform thickness
function draw_board_frame()
  gfx.setColor(COLOR_FRAME)
  draw_round_rect(BOARD_LEFT - FRAME_THICK,
    BOARD_TOP  - FRAME_THICK,
    BOARD_WIDTH  + FRAME_THICK * 2,
    BOARD_HEIGHT + FRAME_THICK * 2,
    FRAME_THICK * FRAME_CORNER_OUT_RATIO
  )
  gfx.setColor(COLOR_BOARD)
  draw_round_rect( BOARD_LEFT, BOARD_TOP,
    BOARD_WIDTH,
    BOARD_HEIGHT,
    FRAME_THICK * FRAME_CORNER_IN_RATIO
  )
end

-- helpers for tile colors
function tile_bg(value)
  return TILE_BG[value] or COLOR_TILE_BG_SUPER
end

function tile_fg(value)
  if value == 2 or value == 4 then
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
  local y = BOARD_TOP  + (row - 1) * CELL_SIZE + CELL_OFFSET
  local bg = COLOR_EMPTY
  if value then
    bg = tile_bg(value)
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
  gfx.print("Score: " .. Game.score, BOARD_LEFT, HUD_Y)
end

function draw_game_over()
  if Game.state == "gameover" then
    gfx.setColor(COLOR_FG)
    gfx.setFont(hudFont)
    gfx.print("GAME OVER", BOARD_LEFT, HUD_Y + GAME_OVER_OFFSET_Y)
  end
end
