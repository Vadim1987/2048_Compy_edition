-- controls.lua

require("model")
require("logic")

-- 2. Input Mappings (Configuration)
BINDINGS = {
  play = { },
  replay = { },
  gameover = { }
}

local play = BINDINGS.play
local replay = BINDINGS.replay
local gameover = BINDINGS.gameover

for _, dir in pairs({
  "left", "right", "up", "down"
}) do
  play[dir] = function()
    new_move(dir)
  end
end

play.a = play.left
play.d = play.right
play.w = play.up
play.s = play.down
play.backspace = undo
play.space = redo
play.r = game_replay
play.n = game_reset
play.escape = love.event.quit

replay.r = play.r
replay.n = play.n
replay.escape = play.escape

gameover.backspace = play.backspace
gameover.r = play.r
gameover.n = play.n
gameover.escape = play.escape

MOUSE_MAP = {
  "backspace",
  "space",
  "r",
  "n"
}

-- 4. Public Entry Points 
function controls_key(key)
  local action = BINDINGS[Game.state][key]
  if action then
    action()
  end
end

function controls_click(x, y)
  if BTN_Y <= y and y <= BTN_Y + BTN_H then
    local offset = x - BOARD_LEFT
    local stride = BTN_W + BTN_GAP
    local index = math.floor(offset / stride) + 1
    if (offset % stride <= BTN_W) and MOUSE_MAP[index] then
      controls_key(MOUSE_MAP[index])
      return 
    end
  end
  pointer_begin(x, y)
end

function swipe_direction(dx, dy)
  local ax, ay = math.abs(dx), math.abs(dy)
  if math.max(ax, ay) < 20 then
    return nil
  end
  if ay < ax then
    return 0 < dx and "right" or "left"
  else
    return 0 < dy and "down" or "up"
  end
end

-- Swipe logic
function pointer_end_inactive(x, y)
  
end

function pointer_end_active(x, y)
  pointer_end = pointer_end_inactive
  controls_key(swipe_direction(x - pointer_x, y - pointer_y))
end

pointer_end = pointer_end_inactive

function pointer_begin(x, y)
  pointer_end = pointer_end_active
  pointer_x = x
  pointer_y = y
end
