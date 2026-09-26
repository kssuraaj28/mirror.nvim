--[[
Lua has multivalue expressions
--]]
x = 3, 4
print(x)

local function f ()
    return 5,0
end

local x, y = f()
print(x)
print(y)


-- The ...
local function g(...)
  local t = ...
  local _, u = ...
  print (t)
  print (u)
  local table = { ... }
  vim.print(table)
end

g ()
g (5)
g (5, 0)
g ({5, 0})
