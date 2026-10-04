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

  local function chill () -- This should not be exposed in public..
    local chill_interval = 1000
    local capability = {}
    local c = assert(coroutine.running())

    local function defer_fn ()
      assert(not coroutine.running())
      coroutine.resume(c, capability)
    end

    vim.defer_fn(defer_fn, chill_interval)

    if coroutine.yield() ~= capability then
        coro_error("Unauthorized resumption of coroutine, not resuming")
    end
  end

  local function wrap_body()
      chill() -- You are immediately in the chill event loop
      body (chill) -- You need to wrap w/ access control
                   -- TODO: Access control
      coro_error("Temination not handled yet")
    end
  coroutine.wrap(wrap_body)()
end


spawn(
  function (chill)
    local c = assert(coroutine.running())
    vim.defer_fn(function ()
      coroutine.resume(c)
    end,2000)

    local i = 0
    while true do
      print (i)
      i = i + 1
      chill()
    end
  end
)
