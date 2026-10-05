---@diagnostic disable: unused-function
--@diagnostic disable: unused-local

-- External functions: spawn, (maybe inspect, etc. later)
-- Coroutine functions (passed as parameters - chill)
-- The coroutine should not be able to call yield, because then it dies forever..

-- The point of this function is to visibly panic when there is some error
local function coro_error(msg)
  vim.notify(msg,vim.log.levels.ERROR)
  error() -- TODO: What are other ways to throw in lua?
end

-- Needs to create a coroutine with body, 
-- and schedules it along with an argument which causes it to chill
local function spawn (body)

  local chill_count = 0 -- I think that a parity probably suffices
  local function chill () -- This should not be exposed in public..
    local chill_interval = 1000
    local capability = {}
    local c = assert(coroutine.running())


    local function resume_c (old_chill)
      assert(not coroutine.running()) -- This is run in the main loop
      local ret = {coroutine.resume(c, capability)}
      -- nvim uses an old version of lua
      ---@diagnostic disable-next-line: deprecated
      assert(unpack(ret)) -- Assert throws existing error if there is.
      assert(#ret == 1, "We don't return anything")
      assert(old_chill + 1 == chill_count, "Unauthorized yield")
    end

    chill_count = chill_count + 1
    vim.defer_fn(function () resume_c(chill_count) end, chill_interval)
    if coroutine.yield() == capability then return end
    coro_error("Unauthorized resumption of coroutine, not resuming")
  end

  local function wrap_body()
      local c = assert(coroutine.running())
      local function chill_ac()
        if c ~= coroutine.running() then
          coro_error("Something other coroutine stole this function")
        end
        chill()
      end

      chill_ac()
      body(chill_ac)
      coro_error("Temination not handled yet")
    end
  coroutine.wrap(wrap_body)()
end

spawn(
  function (chill)
    local i = 0
    while true do
      print (i)
      i = i + 1
      chill()
      -- coroutine.yield() -- This should throw an error
    end
  end
)
