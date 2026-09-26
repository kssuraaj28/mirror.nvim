print ("Plugin loaded")

local M = {}


function M.greet()
  vim.print("Hello there!")
end

function M.quit()
  vim.cmd["q"]()
end


return M
--[[
:lua M = require("first-plug") (Or local)
-- Multiple requires will not load because the module is cached
-- You can package.loaded["first-plug"] to uncache the module

:lua M = dofile("first-plug.lua") 
-- This just sources.
-- There's also loadfile which doesn't run, but gives you a function you can then run.. 
-- dofile (??) === local x = assert(loadfile (??)); x ()
--]]

