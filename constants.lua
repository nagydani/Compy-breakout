-- constants.lua

-- Colors (RGB)

COLOR_BG = {
  0,
  0,
  0
}
COLOR_FIELD = {
  0.1,
  0.1,
  0.1
}

-- Brick Palettes (Bright, Dim)

COLOR_R = {
  1,
  0.2,
  0.2
}
COLOR_R_DIM = {
  0.7,
  0.1,
  0.1
}
COLOR_Y = {
  1,
  1,
  0.2
}
COLOR_Y_DIM = {
  0.7,
  0.7,
  0.1
}
COLOR_G = {
  0.2,
  0.8,
  0.2
}
COLOR_G_DIM = {
  0.1,
  0.6,
  0.1
}
COLOR_B = {
  0.3,
  0.3,
  1
}
COLOR_B_DIM = {
  0.2,
  0.2,
  0.7
}
COLOR_M = {
  1,
  0.2,
  1
}
COLOR_M_DIM = {
  0.7,
  0.1,
  0.7
}

COLOR_PAD = {
  0.6,
  0.6,
  0.8
}

COLOR_BALL = {
  1,
  1,
  1
}

-- Game Settings

GAME = {
  width = 640,
  height = 480,
  launch_spd = 350,
  pad_spd = 450,
  sensitivity = 0.5
}

-- Grid Layout

GRID = {
  cols = 16,
  rows = 4,
  lives_cols = 8,
  top_empty = 2,
  pad_empty = 1
}

-- Auto-calculate sizes

GRID.cw = GAME.width / GRID.cols
GRID.ch = GRID.cw / 2
GRID.life_w = GRID.cw * 2

-- Vertical offsets

GRID.start_y = GRID.ch * GRID.top_empty
GRID.bot_y = GAME.height - GRID.ch

-- Paddle Geometry 

PADDLE = {
  w = GRID.cw * 2,
  h = GRID.ch,
  y = GAME.height - (GRID.ch * 3)
}

BALL = { radius = 6 }
