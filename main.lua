-- main.lua

require("constants")
require("physics")
require("level")

sfx = compy.audio
gfx = love.graphics
timer = love.timer

-- Game State

GS = {
  init = false,
  mode = "start",
  tf = nil
}

GS.assets = { text_info = nil }

GS.mouse = zero2d()

-- Entities

paddle = {
  pos = zero2d(),
  size = {
    x = PADDLE.width,
    y = PADDLE.height
  },
  vel = zero2d(),
  color = Color[Color.cyan]
}

ball = {
  color = Color[Color.white + Color.bright],
  pos = zero2d(),
  vel = zero2d(),
  radius = BALL.radius,
  snapshot = zero2d(),
  st = 0
}

-- Helpers

function copy_vector(dest, src)
  dest.x, dest.y = src.x, src.y
end

function integrate_pos(pos, vel, dt)
  pos.x = pos.x + vel.x * dt
  pos.y = pos.y + vel.y * dt
end

function update_scale()
  local w, h = gfx.getDimensions()
  GS.tf = love.math.newTransform()
  GS.tf:scale(w / GAME.width, h / GAME.height)
end

function sync_phys(now)
  copy_vector(ball.snapshot, ball.pos)
  ball.st = now
end

function move_ball_time(t_target)
  local dt = t_target - ball.st
  copy_vector(ball.pos, ball.snapshot)
  integrate_pos(ball.pos, ball.vel, dt)
end

-- Init Functions

function reset_ball_pos()
  ball.pos.x = paddle.pos.x + paddle.size.x / 2
  ball.pos.y = paddle.pos.y - ball.radius
  ball.vel.x, ball.vel.y = 0, 0
end

function init_level()
  bricks = level.generate()
  paddle.pos.x = (GAME.width - PADDLE.width) / 2
  paddle.pos.y = PADDLE.y
  paddle.vel.x, paddle.vel.y = 0, 0
end

function reset_round()
  init_level()
  reset_ball_pos()
  sync_phys(timer.getTime())
  GS.mode = "start"
  GS.assets.text_info:set("Press Space")
  love.mouse.setRelativeMode(true)
end

function init_assets()
  local f = gfx.getFont()
  GS.assets.text_info = gfx.newText(f, "")
end

function ensure_init()
  if not GS.init then
    update_scale()
    init_assets()
    reset_round()
    GS.init = true
  end
end

-- Logic

function process_input(dt)
  if GS.mouse.x ~= 0 then
    paddle.vel.x = (GS.mouse.x * GAME.sensitivity) / dt
    GS.mouse.x = 0
  elseif love.keyboard.isDown("right") then
    paddle.vel.x = GAME.paddle_speed
  elseif love.keyboard.isDown("left") then
    paddle.vel.x = -GAME.paddle_speed
  else
    paddle.vel.x = 0
  end
end

function constrain_paddle()
  local max_x = GAME.width - paddle.size.x
  if paddle.pos.x < 0 then
    paddle.pos.x = 0
  elseif max_x < paddle.pos.x then
    paddle.pos.x = max_x
  end
end

-- Game Loop

function select_hit_obj(dt)
  local best_t, best_obj, best_idx, best_n
  for i, brick in ipairs(bricks) do
    local t, n = detect(ball, brick, dt)
    if t and (not best_t or t < best_t) then
      best_t, best_obj, best_idx, best_n = t, brick, i, n
    end
  end
  local t, n = detect(ball, paddle, dt)
  if t and (not best_t or t < best_t) then
    best_t, best_obj, best_idx, best_n = t, paddle, nil, n
  end
  return best_t, best_obj, best_idx, best_n
end

function destroy_brick(idx)
  local b = bricks[idx]
  if b.is_target then
    bricks.target = bricks.target - 1
    if bricks.target == 0 then
      GS.mode = "done"
      GS.assets.text_info:set("YOU WIN!")
      sfx.win()
    end
  end
  table.remove(bricks, idx)
end

function process_hit(t_hit, obj, idx, normal)
  move_ball_time(t_hit)
  bounce(ball, obj, normal)
  if idx then
    destroy_brick(idx)
  end
  sync_phys(t_hit)
end

function check_gameover()
  if GAME.height < ball.pos.y then
    GS.mode = "done"
    GS.assets.text_info:set("GAME OVER")
    sfx.gameover()
    return true
  end
  return false
end

function check_bounds()
  local r = ball.radius
  local max_x = GAME.width - r
  if ball.pos.x < r then
    ball.pos.x, ball.vel.x = 2 * r - ball.pos.x, -ball.vel.x
  elseif ball.pos.x > max_x then
    ball.pos.x, ball.vel.x = 2 * max_x - ball.pos.x, -ball.vel.x
  elseif ball.pos.y < r then
    ball.pos.y, ball.vel.y = 2 * r - ball.pos.y, -ball.vel.y
  else
    return false
  end
  return true
end

function update_ball(dt, now)
  sync_phys(now - dt)
  local t, obj, idx, n = select_hit_obj(dt)
  if t then
    process_hit((now - dt) + t, obj, idx, n)
  end
  move_ball_time(now)
  if check_bounds() then
    sync_phys(now)
    sfx.knock()
  elseif check_gameover() then
    return 
  end
end

-- Controls

function action_launch()
  local dir = (love.math.random(2) == 1) and 1 or -1
  ball.vel.y = -GAME.launch_speed
  ball.vel.x = paddle.vel.x + (GAME.launch_speed * dir)
  GS.mode = "play"
  GS.assets.text_info:set("")
  sfx.beep()
end

actions = {
  start = { space = action_launch },
  play = { r = reset_round },
  done = { space = reset_round }
}

for k, v in pairs(actions) do
  v.escape = love.event.quit
end

updaters = {
  start = reset_ball_pos,
  play = update_ball
}

-- Drawing

function draw_rect(obj)
  local x, y = obj.pos.x, obj.pos.y
  local w, h = obj.size.x, obj.size.y
  gfx.setColor(obj.color)
  gfx.rectangle("fill", x, y, w, h)
end

function draw_objs()
  for _, b in ipairs(bricks) do
    draw_rect(b)
  end
  draw_rect(paddle)
  gfx.setColor(ball.color)
  gfx.circle("fill", ball.pos.x, ball.pos.y, ball.radius)
end

function draw_info()
  local ti = GS.assets.text_info
  local tx = (GAME.width - ti:getWidth()) / 2
  gfx.draw(ti, tx, GAME.height * 0.4)
end

-- Main Loop

function love.update(dt)
  ensure_init()
  local now = timer.getTime()
  process_input(dt)
  integrate_pos(paddle.pos, paddle.vel, dt)
  constrain_paddle()
  if updaters[GS.mode] then
    updaters[GS.mode](dt, now)
  end
end

function love.draw()
  if GS.init then
    gfx.push()
    gfx.applyTransform(GS.tf)
    gfx.clear(Color[Color.black])
    draw_objs()
    draw_info()
    gfx.pop()
  end
end

function love.mousemoved(_, _, dx, _)
  GS.mouse.x = GS.mouse.x + dx
end

function love.mousepressed(_, _, btn)
  if btn == 1 then
    love.keypressed("space")
  end
end

function love.keypressed(k)
  local act = actions[GS.mode]
  if act and act[k] then
    act[k]()
  end
end

function love.resize()
  if GS.init then
    update_scale()
  end
end
