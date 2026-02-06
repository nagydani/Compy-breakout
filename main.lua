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

HIT_NORMAL = zero2d()

-- Entities 

paddle = {
  pos = zero2d(),
  size = {
    x = PADDLE.w,
    y = PADDLE.h
  },
  vel = zero2d(),
  color = COLOR_PAD
}

ball = {
  color = COLOR_BALL,
  pos = zero2d(),
  vel = zero2d(),
  radius = BALL.radius,
  snapshot = zero2d(),
  st = 0
}

-- Helpers 

function get_key_dir(key_check, pos, neg)
  if key_check(pos) then
    return 1
  end
  if key_check(neg) then
    return -1
  end
  return 0
end

function copy_vector(dest, src)
  dest.x, dest.y = src.x, src.y
end

function integrate_pos(pos, vel, dt)
  pos.x = pos.x + vel.x * dt
  pos.y = pos.y + vel.y * dt
end

function update_scale()
  local w, h = gfx.getDimensions()
  GS.tf = love.math.newTransform():scale(
    w / GAME.width,
    h / GAME.height
  )
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
  paddle.pos.x = (GAME.width - PADDLE.w) / 2
  paddle.pos.y = PADDLE.y
  paddle.vel.x, paddle.vel.y = 0, 0
end

function reset_round(now)
  init_level()
  reset_ball_pos()
  sync_phys(now)
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
    reset_round(timer.getTime())
    GS.init = true
  end
end

-- Logic 

function process_input(dt)
  if GS.mouse.x == 0 then
    local dx = get_key_dir(
      love.keyboard.isDown,
      "right",
      "left"
    )
    paddle.vel.x = dx * GAME.pad_spd
  else
    paddle.vel.x = (GS.mouse.x * GAME.sensitivity) / dt
    GS.mouse.x = 0
  end
end

function constrain_paddle(dt)
  integrate_pos(paddle.pos, paddle.vel, dt)
  if paddle.pos.x < 0 then
    paddle.pos.x = 0
    paddle.vel.x = 0
  end
  if GAME.width - paddle.size.x < paddle.pos.x then
    paddle.pos.x = GAME.width - paddle.size.x
    paddle.vel.x = 0
  end
end

-- Physics Loop 

function select_hit_obj(dt)
  local bt, bo, bi
  local t, n = detect(ball, paddle, dt)
  if t then
    bt, bo, bi = t, paddle, nil
    copy_vector(HIT_NORMAL, n)
  end
  for i, b in ipairs(bricks) do
    local t_brk, n_brk = detect(ball, b, dt)
    if t_brk and (not bt or t_brk < bt) then
      bt, bo, bi = t_brk, b, i
      copy_vector(HIT_NORMAL, n_brk)
    end
  end
  return bt, bo, bi
end

function process_hit(t, obj, idx, t_sim)
  local t_imp = t_sim + t
  move_ball_time(t_imp)
  bounce(ball, obj, HIT_NORMAL)
  if obj.destruct then
    table.remove(bricks, idx)
    if #bricks <= GRID.lives_cols then
      GS.mode = "win"
      GS.assets.text_info:set("YOU WIN! Press R")
      sfx.win()
      love.mouse.setRelativeMode(false)
    end
  end
  sync_phys(t_imp)
end

-- Boundary Logic 

function check_bounds(b, now)
  local vx, vy = b.vel.x, b.vel.y
  if b.pos.x < b.radius then
    b.pos.x, b.vel.x = b.radius, -vx
  elseif GAME.width - b.radius < b.pos.x then
    b.pos.x, b.vel.x = GAME.width - b.radius, -vx
  end
  if b.pos.y < b.radius then
    b.pos.y, b.vel.y = b.radius, -vy
  end
  if b.vel.x ~= vx or b.vel.y ~= vy then
    sync_phys(now)
    sfx.knock()
  end
end

function check_game_over(b)
  if GAME.height < b.pos.y then
    GS.mode, GS.mouse.x = "over", 0
    GS.assets.text_info:set("GAME OVER")
    love.mouse.setRelativeMode(false)
    sfx.gameover()
  end
end

function update_ball(dt, now)
  sync_phys(now - dt)
  local t, obj, idx = select_hit_obj(dt)
  if t then
    process_hit(t, obj, idx, now - dt)
  end
  move_ball_time(now)
  check_bounds(ball, now)
  check_game_over(ball)
end

-- Controls 

actions = {
  start = { },
  play = { },
  over = { },
  win = { }
}

function actions.start.space()
  local dir_x = (love.math.random(2) == 1) and 1 or -1
  ball.vel.y = -GAME.launch_spd
  ball.vel.x = paddle.vel.x + (GAME.launch_spd * dir_x)
  GS.mode = "play"
  sfx.beep()
end

actions.play.r = function() 
  reset_round(timer.getTime()) 
end

actions.over.r = actions.play.r
actions.over.space = actions.play.r
actions.win.r = actions.play.r
actions.win.space = actions.play.r

-- Drawing 

function draw_background()
  gfx.setColor(COLOR_FIELD)
  gfx.rectangle("fill", 0, 0, GAME.width, GAME.height)
end

function draw_rectangle(obj)
  local p, s = obj.pos, obj.size
  gfx.setColor(obj.color)
  gfx.rectangle("fill", p.x, p.y, s.x, s.y)
end

function draw_bricks_and_paddle()
  for _, brick in ipairs(bricks) do
    draw_rectangle(brick)
  end
  draw_rectangle(paddle)
end

function draw_ball()
  gfx.setColor(ball.color)
  gfx.circle("fill", ball.pos.x, ball.pos.y, ball.radius)
end

function draw_objs()
  draw_background()
  draw_bricks_and_paddle()
  draw_ball()
end

function draw_ui()
  if GS.mode ~= "play" then
    local ti = GS.assets.text_info
    local tx = (GAME.width - ti:getWidth()) / 2
    gfx.draw(ti, tx, GAME.height * 0.4)
  end
end

-- Main Loop 

function love.update(dt)
  ensure_init()
  local now = timer.getTime()
  process_input(dt)
  constrain_paddle(dt)
  if GS.mode == "start" then
    reset_ball_pos()
  elseif GS.mode == "play" then
    update_ball(dt, now)
  end
end

function love.draw()
  if GS.init then
    gfx.push()
    gfx.applyTransform(GS.tf)
    gfx.clear(COLOR_BG)
    draw_objs()
    draw_ui()
    gfx.pop()
  end
end

function love.mousemoved(_, _, dx, _)
  GS.mouse.x = GS.mouse.x + dx
end

function love.mousepressed(_, _, button)
  if button == 1 and actions[GS.mode]
       and actions[GS.mode].space
  then
    actions[GS.mode].space()
  end
end

function love.keypressed(k)
  local action = actions[GS.mode][k]
  if action then
    action()
  end
  if k == "escape" then
    love.event.quit()
  end
end

function love.resize()
  if GS.init then
    update_scale()
  end
end
