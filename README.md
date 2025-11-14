

# 2048 (Compy-friendly)

A minimalist implementation of the classic **2048** game in Lua/LÖVE, polished for teaching purposes and following **Compy formatting rules** (≤64 characters per line, ≤14 lines per function/table, ≤4 arguments, nesting depth ≤4, no complex inline expressions).

The game draws a 4×4 grid; you slide tiles with arrow keys / WASD, merging powers of two.

---

## Multiple source files

The project is split into several short files for readability and pedagogy (like in the example) :

* `board.lua` — board logic (data, moves, merges, game over, drawing)
* `main.lua` — glue for input/drawing and window setup
* `utils.lua` — placeholder for future helpers

---

## Gameplay (in short)

* Each move **shifts** all numbers in the chosen direction, then performs **merges** of equal neighbors.
* After a successful move, a new tile `2` (90%) or `4` (10%) appears.
* When there are no empty cells and no possible merges — **Game Over**.

---

## Controls

* **Arrow keys** or **W/A/S/D** — move
* **R** — restart
* **Esc** — quit

See the handler in `love.keypressed`: a simple key map with unified move logic.

```lua
-- main.lua (fragment)
function love.keypressed(key)
  if key == "escape" then love.event.quit() end
  local map = {
    left="left", right="right", up="up", down="down",
    a="left", d="right", w="up", s="down",
  }
  local dir = map[key]
  if dir then
    if board:move(dir) then board:add_random_tile() end
  elseif key == "r" then
    board:reset()
  end
end
```

---

## Board logic

Everything related to data and rules lives in `board.lua`.

### Data structure

* `self.grid[r][c]` — integer (0 = empty, otherwise power of two).
* Sizes: `self.rows`, `self.cols` (default 4×4).
* Initialization — via `Board.new` → `:reset()` → `:seed()`.

### Shifting and merging

The core idea: transform one **line** (row/column), then place it back into the grid. This keeps code consistent across all directions.

```lua
-- board.lua (fragment)
local function slide_line(line)
  local merged, res, last = {}, {}, nil
  for _, v in ipairs(line) do
    if v ~= 0 then
      local m = last and last == v and not merged[#res]
      if m then
        res[#res] = v * 2; merged[#res] = true; last = nil
      else
        res[#res + 1] = v; merged[#res] = false; last = v
      end
    end
  end
  for i = #res + 1, #line do res[i] = 0 end
  return res
end
```

Why this way?

* Scan left-to-right (or top-to-bottom), **compressing** non-zero tiles.
* Merge only once per position (tracked with `merged[#res]`).
* Fill with zeros at the end to keep the line length.

For reverse directions we use `reverse(slide_line(reverse(...)))` — short and avoids duplication.

### Checking game over

Two cases: there are empty cells, or merges are possible. If neither, it’s over.

```lua
function Board:isGameOver()
  return not self:has_empty() and not self:has_merge()
end
```

---

## Drawing

`board.lua` also contains the “view” — convenient for a small teaching project: easy to read and modify.

* Board background — soft rectangle.
* Cells — rounded rectangles; color depends on value.
* Numbers are centered with `G.printf` and slight vertical shift.

```lua
-- board.lua (fragment)
function Board:_draw_cell(r, c)
  local G, size = love.graphics, self._cell
  local x = self._dx + (c - 1) * size
  local y = self._dy + (r - 1) * size
  local val = self.grid[r][c]
  local color = (val == 0) and {0.9, 0.85, 0.7}
    or {0.9, 0.7 - (val / 2048) * 0.6, 0.3}
  G.setColor(color)
  G.rectangle("fill", x, y, size - 4, size - 4, 6, 6)
  if val ~= 0 then
    G.setColor(0.1, 0.1, 0.1)
    G.printf(tostring(val), x, y + size/2 - 12, size - 4, "center")
  end
end
```

## Changing board size / tile size

* Grid size is set when creating: `Board.new(4, 4)`.
  Example: `Board.new(5, 5)` — everything else adapts.
* Cell size is controlled in `Board:_begin_draw(x, y, cell)` —
  the third parameter `cell` (see `board:draw(40, 80, 80)` in `love.draw`).

---

## Adding utilities

`utils.lua` is currently a placeholder — deliberately empty to avoid clutter in the base teaching example. If needed, put things here like:

* `clamp(v, lo, hi)` — clamp value
* `copy2d(grid)` — copy 2D array
* `any(t, pred)` — “does any element match predicate?”

Keep each function **short** and **self-contained**.


