-- Level.lua

level = { }

function make_brick(x, y, color, is_t)
  return {
    pos = {
      x = x,
      y = y
    },
    size = {
      x = (is_t and GRID.cw or GRID.life_w),
      y = GRID.ch
    },
    vel = zero2d(),
    color = color,
    destruct = true,
    is_target = is_t
  }
end

function add_row(list, r, color)
  local y = GRID.start_y + (r - 1) * GRID.ch
  for c = 1, GRID.cols do
    local colors = Color[color + Color.bright * ((c + r) % 2)]
    local x = (c - 1) * GRID.cw
    table.insert(list, make_brick(x, y, colors, true))
  end
end

function gen_grid(list)
  add_row(list, 1, Color.red)
  add_row(list, 2, Color.yellow)
  add_row(list, 3, Color.green)
  add_row(list, 4, Color.blue)
end

function gen_lives(list)
  local y = GRID.bot_y
  for c = 1, GRID.lives_cols do
    local color = Color[Color.magenta + Color.bright * (c % 2)]
    local x = (c - 1) * GRID.life_w
    table.insert(list, make_brick(x, y, color, false))
  end
end

function level.generate()
  local list = { }
  gen_grid(list)
  gen_lives(list)
  return list
end
