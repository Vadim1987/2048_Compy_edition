-- main.lua
-- Wire modules into LOVE callbacks

require("model")
require("logic")
require("graphics")
require("controls")

love.keypressed = controls_key

function love.update(dt)
  game_update_animations(dt)
  if Game.state == "replay" then
    update_replay(dt)
  end
end

function love.mousepressed(x, y, button, istouch, presses)
  controls_click(x, y)
end

function love.mousereleased(x, y, button, istouch, presses)
  pointer_end(x, y)
end

function love.draw()
  gfx.clear(COLOR_BG)
  draw_board_frame()
  draw_board()
  draw_animations()
  draw_ui()
end

-- start game immediately
game_reset()