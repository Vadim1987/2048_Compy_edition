-- logic.lua
-- Movement 

require("model")

Logic = { }

-- read and modify board
function get_value(indices, index)
  local row, col = indices(index)
  return Game.cells[row][col]
end

function set_value(indices, index, value)
  local row, col = indices(index)
  Game.cells[row][col] = value
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
  Game.score = Game.score + merged
  Game.empty_count = Game.empty_count + 1
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

-- move left on whole board
function move_left()
  return move_board(line_apply_row_left, Game.rows)
end

-- move right on whole board
function move_right()
  return move_board(line_apply_row_right, Game.rows)
end

-- move up on whole board
function move_up()
  return move_board(line_apply_col_up, Game.cols)
end

-- move down on whole board
function move_down()
  return move_board(line_apply_col_down, Game.rows)
end

-- Move map table
MOVES = {
  left = move_left,
  right = move_right,
  up = move_up,
  down = move_down
}

-- Helper: record new move to history
function record_history(dir, new_spawn)
  History.future = { }
  table.insert(History.moves, {
    dir = dir,
    spawn = new_spawn
  })
end

function execute_move_logic(dir, spawn)
  Game.max_merge = 0
  if not MOVES[dir]() then
    return false
  end
  local new_spawn = game_add_random_tile(spawn)
  if not spawn then
    record_history(dir, new_spawn)
  end
  check_game_over()
  resolve_move_sound()
  return true
end

function check_game_over()
  if (0 < Game.empty_count) or game_can_merge() then
    return 
  end
  Game.state = "gameover"
end

SoundHandlers = { }

function SoundHandlers.gameover()
  compy.audio.gameover() 
end

function SoundHandlers.play()
  if Game.max_merge >= 2048 then
    compy.audio.wow()
  elseif Game.max_merge > 0 then
    compy.audio.jump()
  else
    compy.audio.knock()
  end
end

SoundHandlers.replay = SoundHandlers.play

function resolve_move_sound()
  local handler = SoundHandlers[Game.state]
  if handler then
    handler()
  end
end

-- Main entry point for moves
function game_handle_move(dir)
  if Game.state ~= "play" then
    return 
  end
  save_snapshot()
  if execute_move_logic(dir, nil) then
    check_game_over()
  else
    table.remove(History.snapshots)
    Game.animations = { }
  end
end

function Logic.undo()
  if Game.state == "replay" then 
    return 
  end
  if restore_snapshot() then
    local last_move = table.remove(History.moves)
    table.insert(History.future, last_move)
    Game.state = "play"
    Game.animations = { }
    compy.audio.beep() 
  end
end

function Logic.redo()
  if Game.state == "replay" then
    return 
  end
  local move = table.remove(History.future)
  if not move then
    return 
  end
  save_snapshot()
  execute_move_logic(move.dir, move.spawn)
  table.insert(History.moves, move)
  check_game_over()
end

function Logic.replay()
  if Game.state == "replay" or #(History.moves) == 0 then
    return 
  end
  Game.state = "replay"
  game_clear()
  Game.score = 0
  for _, spawn in ipairs(History.initial) do
    game_add_random_tile(spawn)
  end
  Game.replay_index = 1
  Game.replay_timer = 0
end

-- Helper: execute one step or finish replay
function process_replay_step()
  local move = History.moves[Game.replay_index]
  if move then
    execute_move_logic(move.dir, move.spawn)
    Game.replay_index = Game.replay_index + 1
    Game.replay_timer = REPLAY_DELAY
  else
    Game.state = "play"
    check_game_over()
  end
end

function update_replay(dt)
  if Game.state ~= "replay" then
    return 
  end
  Game.replay_timer = Game.replay_timer - dt
  if 0 < Game.replay_timer or 0 < #Game.animations then
    return 
  end
  process_replay_step()
end
