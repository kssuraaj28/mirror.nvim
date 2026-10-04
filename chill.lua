---@diagnostic disable: unused-function
--@diagnostic disable: unused-local

-- External functions: spawn, (maybe inspect, etc. later)
-- Coroutine functions (passed as parameters - chill)
-- The coroutine should not be able to call yield, because then it dies forever..

-- Needs to create a coroutine with body, 
-- and schedules it along with an argument which causes it to chill
local function spawn (body)

  local function chill () -- This should not be exposed in public..
    local chill_interval = 1000
    local c = assert(coroutine.running())

    local function defer_fn ()
      assert(not coroutine.running())
      coroutine.resume(c)
    end

    vim.defer_fn(defer_fn, chill_interval)
    coroutine.yield()
  end

  local function wrap_body()
      chill() -- You are immediately in the chill event loop
      body (chill) -- You need to wrap w/ access control
                   -- TODO: Access control
      -- assert(false, "Coroutine termination Unhandled")
    end
  coroutine.wrap(wrap_body)()
end


spawn(
  function (chill)
    print("Hello")
    chill()
    print("There")
  end
)
