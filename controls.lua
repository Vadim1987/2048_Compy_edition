-- controls.lua
require("model")
require("logic")

-- 1. Action Definitions 
ACTIONS = { }

-- Wrappers for moves (Pass name to handler)
ACTIONS.left  = game_handle_move
ACTIONS.right = game_handle_move
ACTIONS.up    = game_handle_move
ACTIONS.down  = game_handle_move

-- Direct assignments 
ACTIONS.undo   = Logic.undo
ACTIONS.redo   = Logic.redo
ACTIONS.replay = Logic.replay
ACTIONS.quit   = love.event.quit
ACTIONS.reset  = game_reset

-- 2. Input Mappings (Configuration)
BINDINGS = {
  left = "left",
  right = "right",
  up = "up",
  down = "down",
  a = "left",
  d = "right",
  w = "up",
  s = "down",
  backspace = "undo",
  space = "redo",
  r = "replay",
  n = "reset",
  escape = "quit"
}

MOUSE_MAP = { 
  "undo", 
  "redo", 
  "replay",
  "reset"
}

-- 3. Explicit Dispatcher
function dispatch_action(name)
  if not name then return end
  if Game.state == "replay" then
    Game.state = "play"
    return 
  end
  if ACTIONS[name] then 
    ACTIONS[name](name) 
  end
end

-- 4. Public Entry Points 
function controls_key(key)
  dispatch_action(BINDINGS[key])
end

function controls_click(x, y)
  if y >= BTN_Y and y <= BTN_Y + BTN_H then
    local offset = x - BOARD_LEFT
    local stride = BTN_W + BTN_GAP
    local index = math.floor(offset / stride) + 1
    if (offset % stride <= BTN_W) and MOUSE_MAP[index] then
      dispatch_action(MOUSE_MAP[index])
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

-- Swipe logic integration
function pointer_begin(x, y)
  POINTER_ACTIVE = true
  POINTER_X = x
  POINTER_Y = y
end

function pointer_end(x, y)
  if not POINTER_ACTIVE then 
    return 
  end
  POINTER_ACTIVE = false
  dispatch_action(swipe_direction(x - POINTER_X, y - POINTER_Y))
end
