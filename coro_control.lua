-- Testing whether it is possible to control the usage of 'yield'..

local good_yield
local good_resume
do
  local capability = {} -- We are using the language's ability to create fresh pointers as capabilities. Damn.. 
  good_yield = function ()
    coroutine.yield(capability)
  end

  good_resume = function (c)
    local ok, cap = coroutine.resume(c)
    local _ = ok
    assert(cap == capability)
  end
end

local c = coroutine.create(
    function()
      print("Running 1")
      good_yield()
      print("Running 2")
    end)

good_resume(c)

-- Actually, I don't think that this solves anything, because a determined client can always spawn a new coroutine that is not constrained by our rules.
-- Maybe I can do something with setfenv, but I'm not going to..
