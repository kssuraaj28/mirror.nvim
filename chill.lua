---@diagnostic disable: unused-function
--@diagnostic disable: unused-local

-- External functions: spawn, (maybe inspect, etc. later)
-- Coroutine functions (passed as parameters - chill)
-- The coroutine should not be able to call yield, because then it dies forever..

-- The point of this function is to visibly panic when there is some error
-- Lua coroutines don't
local function coro_error(msg)
  vim.notify(msg,vim.log.levels.ERROR)
  error() -- TODO: What are other ways to throw in lua?
end

-- Needs to create a coroutine with body, 
-- and schedules it along with an argument which causes it to chill
local function spawn (body)
  local function body_wrapped()
    local c = assert(coroutine.running())

    local capability = {} -- You can bring this outside the body
    local function chill()

      -- Access control
      local cnew = assert(coroutine.running())
      if c ~= cnew then
        coro_error("Something else stole this function") -- TODO: Test
      end


      local function resume_c ()
        assert(not coroutine.running()) -- This is run in the main loop
        local ret = {coroutine.resume(c, capability)}
        -- nvim uses an old version of lua
        ---@diagnostic disable-next-line: deprecated
        assert(unpack(ret)) -- The coroutine should not throw.. 
        assert(#ret == 2, "We return the capability")
        assert(ret[2] == capability, "Unauthorized yield")
      end

      local chill_interval = 1000
      vim.defer_fn(resume_c, chill_interval)
      -- While an unauthorized resumer might steal the coroutine, 
      -- if it does that, the current coroutine will just die.
      -- So, this should be okay..
      if coroutine.yield(capability) == capability then return end
      coro_error("Unauthorized resumption of coroutine, not resuming")
    end

    chill()
    body(chill)
    coro_error("Temination not handled yet")
  end
  coroutine.wrap(body_wrapped)()
end

local x
spawn(
  function (chill)
    x = chill
    local i = 0
    while true do
      print (i)
      i = i + 1
      chill()
    end
  end
)

function M()
coroutine.wrap(function ()
 x ()
end)() end
