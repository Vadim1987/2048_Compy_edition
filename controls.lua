-- controls.lua
-- Keyboard handlers + mouse/touch swipe

require("model")
require("logic")

KeyPress = { }

SWIPE_MIN_DISTANCE2 = 40 * 40
SWIPE_DIR_RATIO = 1.5
SWIPE_DIR_RATIO2 = SWIPE_DIR_RATIO * SWIPE_DIR_RATIO
POINTER_ACTIVE = false
POINTER_X = 0
POINTER_Y = 0

function KeyPress.left()
  game_handle_move(move_left)
end

function KeyPress.right()
  game_handle_move(move_right)
end

function KeyPress.up()
  game_handle_move(move_up)
end

function KeyPress.down()
  game_handle_move(move_down)
end

KeyPress.a = KeyPress.left
KeyPress.d = KeyPress.right
KeyPress.w = KeyPress.up
KeyPress.s = KeyPress.down
KeyPress.escape = love.event.quit
KeyPress.r = game_reset

function pointer_begin(x, y)
  POINTER_ACTIVE = true
  POINTER_X = x
  POINTER_Y = y
end

function swipe_direction(dx, dy)
  local dx2 = dx * dx
  local dy2 = dy * dy
  if dx2 + dy2 < SWIPE_MIN_DISTANCE2 then
    return nil
  end
  if dy2 * SWIPE_DIR_RATIO2 <= dx2 then
    return 0 < dx and "right" or "left"
  end
  if dx2 * SWIPE_DIR_RATIO2 <= dy2 then
    return 0 < dy and "down" or "up"
  end
  return nil
end

function pointer_end(x, y)
  if not POINTER_ACTIVE then
    return 
  end
  POINTER_ACTIVE = false
  local dir = swipe_direction(x - POINTER_X, y - POINTER_Y)
  if not dir then
    return 
  end
  love.keypressed(dir)
end
