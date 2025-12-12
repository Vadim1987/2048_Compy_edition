-- logic.lua
-- Movement 

require("model")
sfx = compy.audio

-- read and modify board
function get_value(indices, index)
  local row, col = indices(index)
  return Game.board.cells[row][col]
end

function set_value(indices, index, value)
  local row, col = indices(index)
  Game.board.cells[row][col] = value
end

function get_line_values(indices, size)
  local line = { }
  for index = 1, size do
    line[index] = get_value(indices, index)
  end
  return line
end

function fill_slide_indices(before, after, size)
  local src = { }
  local dst = { }
  for index = 1, size do
    if before[index] then
      src[#src + 1] = index
    end
    if after[index] then
      dst[#dst + 1] = index
    end
  end
  return src, dst
end

function is_merged_pair(before, after, dest_index, from1, from2)
  if not from2 then
    return false
  end
  local value = before[from1]
  if before[from2] ~= value then
    return false
  end
  return after[dest_index] == value + value
end

function add_anim(kind, idx, a, b, value)
  local args = { }
  args.row_from, args.col_from = idx(a)
  args.row_to, args.col_to = idx(b)
  args.value = value
  game_add_animation(kind, args)
end

function apply_slide_step(before, after, idx, src, dst, si, di)
  local from1 = src[si]
  if not from1 then
    return nil
  end
  local dest, from2, value = dst[di], src[si + 1], before[from1]
  if is_merged_pair(before, after, dest, from1, from2) then
    add_anim("slide", idx, from1, dest, value)
    add_anim("slide", idx, from2, dest, value)
    add_anim("merge", idx, dest, dest, value)
    return si + 2
  end
  add_anim("slide", idx, from1, dest, value)
  return si + 1
end

function add_line_slides(before, after, idx, size)
  local src, dst = fill_slide_indices(before, after, size)
  local si = 1
  for di = 1, #dst do
    si = apply_slide_step(before, after, idx, src, dst, si, di)
    if not si then
      break
    end
  end
end

-- compact line in-place via accessors
function compact_line(indices, size)
  local moved, write = false, 1
  for index = 1, size do
    local value = get_value(indices, index)
    if value then
      moved = moved or (index ~= write)
      set_value(indices, write, value)
      write = write + 1
    end
  end
  for index = write, size do
    set_value(indices, index, nil)
  end
  return moved
end

-- Helper: apply merge updates
function apply_merge_step(indices, idx, val)
  local merged = val + val
  if Game.max_merge < merged then
    Game.max_merge = merged
  end
  set_value(indices, idx, merged)
  set_value(indices, idx + 1, nil)
  Game.board.score = Game.board.score + merged
  Game.board.empty_count = Game.board.empty_count + 1
end

-- merge equal neighbours in-place, update score/empty_count
function merge_line(indices, size)
  local moved = false
  for i = 1, size - 1 do
    local v = get_value(indices, i)
    if v and get_value(indices, i + 1) == v then
      apply_merge_step(indices, i, v)
      moved = true
    end
  end
  return moved
end

-- full move on abstract line via accessors
function line_move(indices, size)
  local before = get_line_values(indices, size)
  local moved = compact_line(indices, size)
  if merge_line(indices, size) then
    moved = true
  end
  if compact_line(indices, size) then
    moved = true
  end
  local after = get_line_values(indices, size)
  add_line_slides(before, after, indices, size)
  return moved
end

-- apply left move to one row
function line_apply_row_left(row)
  local function indices(index)
    return row, index
  end
  return line_move(indices, Game.cols)
end

-- apply right move to one row
function line_apply_row_right(row)
  local function indices(index)
    return row, (Game.cols - index) + 1
  end
  return line_move(indices, Game.cols)
end

-- apply up move to one column
function line_apply_col_up(col)
  local function indices(index)
    return index, col
  end
  return line_move(indices, Game.rows)
end

-- apply down move to one column
function line_apply_col_down(col)
  local function indices(index)
    return (Game.rows - index) + 1, col
  end
  return line_move(indices, Game.rows)
end

-- move the whole board
function move_board(line_apply, lines)
  local moved = false
  for index = 1, lines do
    if line_apply(index) then
      moved = true
    end
  end
  return moved
end

-- Move map table
MOVES = { }

-- move left on whole board
function MOVES.left()
  return move_board(line_apply_row_left, Game.rows)
end

-- move right on whole board
function MOVES.right()
  return move_board(line_apply_row_right, Game.rows)
end

-- move up on whole board
function MOVES.up()
  return move_board(line_apply_col_up, Game.cols)
end

-- move down on whole board
function MOVES.down()
  return move_board(line_apply_col_down, Game.cols)
end

-- Helper: record new move to history
function record_history(dir, new_spawn)
  History.future_moves = { }
  setmetatable(History.future_moves, STACK)
  History.past_moves:insert({
    dir = dir,
    spawn = new_spawn
  })
end

function check_merge()
  Game.sound = sfx.knock
  if 0 < Game.max_merge then
    Game.sound = sfx.jump
    if 2048 <= Game.max_merge then
      Game.sound = sfx.wow
    end
  end
end

function check_game_over()
  if (0 < Game.board.empty_count) or game_can_merge() then
    return 
  end
  Game.state = "gameover"
  Game.sound = sfx.gameover
end

function execute_spawn_logic(dir, spawn)
  if not spawn then
    spawn = random_tile()
    record_history(dir, spawn)
  end
  spawn_tile(spawn)
end

function execute_move_logic(dir, spawn)
  Game.max_merge = 0
  if MOVES[dir]() then
    execute_spawn_logic(dir, spawn)
    check_merge()
    check_game_over()
    Game.sound()
    return true
  end
  return false
end

function new_move(dir)
  save_snapshot()
  execute_move_logic(dir, nil)
end

function undo()
  if restore_snapshot() then
    local last_move = History.past_moves:remove()
    History.future_moves:insert(last_move)
    Game.animations = { }
    Game.state = "play"
    sfx.beep()
  end
end

function redo()
  local move = History.future_moves:remove()
  if not move then
    return 
  end
  save_snapshot()
  execute_move_logic(move.dir, move.spawn)
  History.past_moves:insert(move)
end

function game_replay()
  Game.state = "replay"
  board_clear()
  for _, spawn in ipairs(History.initial) do
    spawn_tile(spawn)
  end
  Game.replay_index = 1
  Game.replay_timer = 0
end

-- Helper: execute one step or finish replay
function process_replay_step()
  local move = History.past_moves[Game.replay_index]
  if move then
    execute_move_logic(move.dir, move.spawn)
    Game.replay_index = Game.replay_index + 1
    Game.replay_timer = REPLAY_DELAY
  elseif Game.state ~= "gameover" then
    Game.state = "play"
  end
end

function update_replay(dt)
  Game.replay_timer = Game.replay_timer - dt
  if 0 < Game.replay_timer or 0 < #(Game.animations) then
    return 
  end
  process_replay_step()
end
