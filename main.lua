-- main.lua
-- Wire modules into LOVE callbacks

require("model")
require("logic")
require("graphics")
require("controls")

function love.keypressed(key)
  controls_key(key)
end

function love.update(dt)
  game_update_animations(dt)
  update_replay(dt)
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