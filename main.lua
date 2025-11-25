-- main.lua
-- Wire modules into LOVE callbacks

require("model")
require("logic")
require("graphics")
require("controls")

function love.keypressed(key)
  local handler = KeyPress[key]
  if handler then
    handler()
  end
end

function love.draw()
  gfx.clear(COLOR_BG)
  draw_board_frame()
  draw_board()
  draw_score()
  draw_game_over()
end

-- start game immediately
game_reset()
