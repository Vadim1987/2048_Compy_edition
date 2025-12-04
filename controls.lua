-- controls.lua
require("model")
require("logic")

-- 1. Action Definitions 
ACTIONS = { }

function ACTIONS.left()   
  game_handle_move("left") 
end

function ACTIONS.right()  
  game_handle_move("right") 
end

function ACTIONS.up()     
  game_handle_move("up") 
end

function ACTIONS.down()   
  game_handle_move("down") 
end

function ACTIONS.undo()   
  Logic.undo() 
end

function ACTIONS.redo()   
  Logic.redo() 
end

function ACTIONS.replay() 
  Logic.replay() 
end

function ACTIONS.quit()   
  love.event.quit() 
end

function ACTIONS.reset()  
  game_reset() 
end

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
  escape = "quit"
}

MOUSE_MAP = { 
  "undo", 
  "redo", 
  "replay" 
}

-- 3. Explicit Dispatcher (The only logic handler)
function dispatch_action(name)
  if not name then 
    return 
  end
  if Game.state == "replay" then
    Game.state = "play"
    return 
  end
  local func = ACTIONS[name]
  if func then
    func()
  end
end

-- 4. Public Entry Points 
function controls_key(key)
  local action_name = BINDINGS[key]
  dispatch_action(action_name)
end

function controls_click(x, y)
 if y < BTN_Y or y > BTN_Y + BTN_H then
   pointer_begin(x, y) 
    return
  end
  local offset = x - BOARD_LEFT
  local stride = BTN_W + BTN_GAP
  local index = math.floor(offset / stride) + 1
  local local_x = offset % stride
  if index >= 1 and index <= #MOUSE_MAP 
  and local_x <= BTN_W 
  then
    dispatch_action(MOUSE_MAP[index])
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
  local dir = swipe_direction(x - POINTER_X, y - POINTER_Y)
  dispatch_action(dir)
end