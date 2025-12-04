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

function love.update(dt)
  game_update_animations(dt)
end

function love.mousepressed(x, y, button, istouch, presses)
  pointer_begin(x, y)
end

function love.mousereleased(x, y, button, istouch, presses)
  pointer_end(x, y)
end

function love.draw()
  gfx.clear(COLOR_BG)
  draw_board_frame()
  draw_board()
  draw_animations()
  draw_score()
  draw_game_over()
end

-- start game immediately
game_reset()
