--[[
Usage: mod require(...)
mod.mirror('socket', bufnr)
mod.stop()
--]]

---@diagnostic disable: unused-function
---@diagnostic disable: unused-local

local M = {}

local function force_replace_buf_lines(buf, lines)
  -- TODO: Make sure that buf is an integer and not zero..
  local ret = {vim.api.nvim_buf_set_lines (buf, 0, -1, false, lines)}
  assert(vim.tbl_isempty(ret), "Call must not return anything")
end


local function construct_remote_buf(socket_path, buf_nr)
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

  --[[
  Closures can be expensive because we make a copy of functions for every object
  Lua has x:method and metatables which can be cheaper. You lose encapsulation tho
  --]]
  return {
    get_ft = get_ft,
    get_buflines = get_buflines,
    get_tick = get_tick,
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

  buf_to_coro = function (coro) return buf_coro[coro] end
end


-- When a coroutine calls chill, it will chill for a bit
-- You could make this into a chilling module, which would require coroutine -> timer state
local chill
do
  chill = function ()
    local coro_refresh_tick = 100 -- 0.1s per refresh
    local thiscoro = assert(coroutine.running())

    local function defer_body()
      assert(coroutine.resume(thiscoro))
    end
    -- TODO inv checks / timers
    vim.defer_fn(defer_body, coro_refresh_tick)
    coroutine.yield()
  end
end

local function mirror_coro(server_path, remote_buf)
  --Create a new visible + scratch buffer 
  --A scratch buffer has buftype=nofile,
  --so it can never be associated with a file..
  local newbuf = vim.api.nvim_create_buf(true, true)

  local thiscoro = assert(coroutine.running())

  bind_coro_buf(thiscoro, newbuf)

  vim.api.nvim_set_current_buf(newbuf) -- TODO Check that it is loaded, etc.

  local remote = construct_remote_buf(server_path, remote_buf)

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

  while true do
    assert(vim.api.nvim_buf_is_valid(newbuf), "Buffer should be valid")
    update_ft()
    update_lines()
    chill() -- TODO: Make this event driven later.
  end
end

function M.mirror(server_path, remote_buf)
  coroutine.wrap(function () mirror_coro(server_path, remote_buf) end)()
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
