-- constants.lua

GAME = {
  width = 640,
  height = 480,
  launch_speed = 350,
  paddle_speed = 450,
  sensitivity = 0.5
}

cols = 16
brick_w = GAME.width / cols
brick_h = brick_w / 2

GRID = {
  cols = cols,
  rows = 4,
  lives_cols = 8,
  top_empty_rows = 2,
  brick_width = brick_w,
  brick_height = brick_h,
  life_width = brick_w * 2,
  start_y = brick_h * 2,
  bottom_y = GAME.height - brick_h
}

PADDLE = {
  width = brick_w * 2,
  height = brick_h,
  y = GAME.height - (brick_h * 3)
}

BALL = { radius = 6 }
