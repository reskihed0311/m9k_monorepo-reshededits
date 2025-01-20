M9K = M9K or {}


local expectedTickSpeed = 1 / 67
local tickSpeed = engine.TickInterval()
M9K.TickspeedMult = tickSpeed / expectedTickSpeed
