-- Testing whether it is possible to control the usage of 'yield'..

local c_good_yield = false
local good_yield = function ()
  c_good_yield = true
  coroutine.yield()
end

local c = coroutine.create(
    function()
      print("Running 1")
      if true then
        coroutine.yield()
      else
        good_yield()
      end
      print("Running 2")
    end)

coroutine.resume(c)
assert(c_good_yield)
