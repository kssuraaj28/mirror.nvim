--@diagnostic disable: unused-function
--@diagnostic disable: unused-local

-- The point of this function is to visibly panic when there is some error
-- Lua coroutines don't
local function coro_error(msg)
  vim.notify(msg,vim.log.levels.ERROR)
  error() -- TODO: What are other ways to throw in lua?
end

-- Spawns a coroutine with a body
-- The body is a function that takes in an argument which
-- allows it to chill for a little bit
local function spawn (body)
  local function body_wrapped()
    local c = assert(coroutine.running())

    local capability = {}
    local function chill()

      -- Access control
      local cnew = assert(coroutine.running())
      if c ~= cnew then
        coro_error("Something else stole this function")
      end


      local function resume_c ()
        assert(not coroutine.running()) -- This is run in the main loop
        local ret = {coroutine.resume(c, capability)}
        -- nvim uses an old version of lua
        ---@diagnostic disable-next-line: deprecated
        assert(unpack(ret)) -- A coroutine error is bad
        assert(#ret == 2, "We return the capability")
        assert(ret[2] == capability, "Unauthorized yield")
      end

      local chill_interval = 1000
      vim.defer_fn(resume_c, chill_interval)
      -- While an unauthorized resumer might steal the coroutine, 
      -- if it does that, the current coroutine will just die.
      -- So, this should be okay.. Is it?
      if coroutine.yield(capability) == capability then return end
      coro_error("Unauthorized resumption of coroutine, not resuming")
    end

    chill()
    body(chill)
    coro_error("Temination not handled yet")
  end
  coroutine.wrap(body_wrapped)()
end

spawn(
  function (chill)
    local i = 0
    while true do
      print (i)
      i = i + 1
      chill()
    end
  end
)
