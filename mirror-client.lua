--[[
Usage: mod require(...)
mod.mirror('socket', bufnr)
mod.stop()
--]]

---@diagnostic disable: unused-function
--@diagnostic disable: unused-local

local M = {}

local function force_replace_buf_lines(buf, lines)
  -- TODO: Make sure that buf is an integer and not zero..
  local ret = {vim.api.nvim_buf_set_lines (buf, 0, -1, false, lines)}
  assert(vim.tbl_isempty(ret), "Call must not return anything")
end

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

        -- The coroutine can die peacefully
        if coroutine.status(c) == 'dead' then return end

        assert(#ret == 2, "We return the capability")
        assert(ret[2] == capability, "Unauthorized yield")
      end

      local chill_interval = 100
      vim.defer_fn(resume_c, chill_interval)
      -- While an unauthorized resumer might steal the coroutine, 
      -- if it does that, the current coroutine will just die.
      -- So, this should be okay.. Is it?
      if coroutine.yield(capability) == capability then return end
      coro_error("Unauthorized resumption of coroutine, not resuming")
    end

    chill() -- This makes the coroutine run after a while. Maybe that is okay..
    body(chill)
  end
  coroutine.wrap(body_wrapped)()
end

local function cnstrct_rmt_bf(socket_path, buf_nr)
  local rpcch = vim.fn.sockconnect("pipe", socket_path, { rpc = true })

  local function get_ft()
    return vim.rpcrequest(rpcch, "nvim_get_option_value", "filetype", { buf = buf_nr })
  end

  local function get_buflines()
    return (vim.rpcrequest(rpcch, "nvim_buf_get_lines", buf_nr, 0, -1, false))
  end

  local function get_tick()
   return vim.rpcrequest(rpcch, "nvim_buf_get_changedtick", buf_nr)
  end

  --Closures can be expensive because we make a copy of functions for every object
  --Lua has x:method and metatables which can be cheaper. You lose encapsulation tho
  return {
    get_ft = get_ft,
    get_buflines = get_buflines,
    get_tick = get_tick,
  }
end


local function queue()
  local data = {}
  return {
      push = function(e)
          -- TODO: Have one error function for coro and main..
          assert(x ~= nil, "Cannot push nil")
          table.insert(data,e)
      end,
      pop = function() return table.remove(data,1) end,
  }
end


-- Maybe what you need are channels
-- What you need to have is a way to communicate with a coroutine
-- push_message (coro)
-- pop_message () -- It would have been cool to make this private to a coroutine when you spawn.. 

local function cnstrct_kv_store()
  local l = {}
  setmetatable(l, {__mode = 'k'})
  return {
    put = function(k,v) l[k] = v end,
    get = function(k) return l[k] end,
  }
end


local bind_coro_buf
local buf_to_coro
do
  -- Invariant: This is a bijection
  local coro_buf = {}
  local buf_coro = {}

  bind_coro_buf = function (coro, buf)
    assert(not coro_buf[coro], "Needs to be a fresh coro")
    assert(not buf_coro[buf], "Needs to be a fresh buffer")
    coro_buf[coro] = buf
    buf_coro[buf] = coro
  end

  buf_to_coro = function (buf) return buf_coro[buf] end
end

-- Message queue
local send_msg
local register_to_queue_db
do
  local db = {}
  register_to_queue_db = function (send_fn)
    local c = assert(coroutine.running())
    assert(not db[c])
    db[c] = send_fn
  end

  send_msg = function (coro, msg) db[coro](msg)  end
end


function Send () end

local function mirror_coro(server_path, remote_buf, chill)
  --Create a new visible + scratch buffer 
  --A scratch buffer has buftype=nofile,
  --so it can never be associated with a file..
  local thiscoro = assert(coroutine.running())

  local newbuf = vim.api.nvim_create_buf(true, true)
  bind_coro_buf(thiscoro, newbuf)

  vim.api.nvim_set_current_buf(newbuf) -- TODO Check that it is loaded, etc.

  local remote = cnstrct_rmt_bf(server_path, remote_buf)

  local msg_queue = queue()
  register_to_queue_db(msg_queue.push)

  local function update_ft()
  -- bo is buffer options. Wrapper around nvim_set_option_value
  -- b is buffer variables. Also a wrapper
    local ftlcl = vim.bo[newbuf].filetype
    local ftrmt = remote.get_ft()
    if ftlcl ~= ftrmt then vim.bo[newbuf].filetype = ftrmt end
  end

  local tickrmt = 0
  local function update_lines()
    local newtickrmt = remote.get_tick()
    if tickrmt ~= newtickrmt then
      assert (newtickrmt > tickrmt)
      tickrmt = newtickrmt
      local lines = remote.get_buflines()

      -- modifiable is for buffers (we need). 
      -- readonly is for the underlying file
      vim.bo[newbuf].modifiable = true
      force_replace_buf_lines(newbuf, lines)
      vim.bo[newbuf].modifiable = false
    end
  end

  local function handle_msgs()
    while true do
      local msg = msg_queue.pop()
      if not msg then break end
      print(msg)
    end
  end

  while true do
    assert(vim.api.nvim_buf_is_valid(newbuf), "Buffer should be valid")
    update_ft()
    update_lines()
    handle_msgs()
    chill() -- TODO: Make this event driven later.
  end
end

function M.mirror(server_path, remote_buf)
  spawn(function(chill) mirror_coro(server_path, remote_buf, chill) end)
end

return M
--[[
Lua + vim notes
* undolevels=-1 will always "already at oldest / newest change".
* nvim_buf_is_valid
* bunload wipes the buffer memory. However, the buffer still exists (nvim_buf_is_valid)
* Use bwipeout [b] to make a buffer invalid.
* Use vim.api.nvim_list_chans()  to list leaked channels
* x:method = x.method(x)
* vim.uv.new_thread is for actual multithreading
* Use t:stop(), t:start(), t:close() and t:is_closing() (where t is a timer (look at defer_fn ret) to cancel work) for intimate coroutine control

  assert(coroutine.status(co) == "dead", "coroutine still
  running")
--]]
