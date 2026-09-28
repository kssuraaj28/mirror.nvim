local M = {}

local coro_refresh_tick = 100 -- 0.1s per refresh

local function coro_sleep(t)
  local coro = coroutine.running()
  assert(coro, "Must be called when running in a coroutine")
  vim.defer_fn(function () assert(coroutine.resume(coro)) end, t)
  coroutine.yield()
end; local _ = coro_sleep


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



-- TODO: Can I see the list of coroutines which are running?
-- I can use this for debugging
local function mirror_coro(server_path, remote_buf)
  --[[
  Create a new visible + scratch buffer A scratch buffer has buftype=nofile,
  so it can never be associated with a file..
  --]]
  local newbuf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(newbuf) -- TODO Check that it is loaded, etc.

  local remote = construct_remote_buf(server_path, remote_buf)

  local function update_ft()
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
      vim.bo[newbuf].modifiable = true
      force_replace_buf_lines(newbuf, lines)
      vim.bo[newbuf].modifiable = false
    end
  end

  while true do
    assert(vim.api.nvim_buf_is_valid(newbuf), "Buffer should be valid")
    update_ft()
    update_lines()
    coro_sleep(coro_refresh_tick)
  end
end

function M.mirror(server_path, remote_buf)
  coroutine.wrap(function () mirror_coro(server_path, remote_buf) end)()
end

return M


--[[
Lua + vim notes
* undolevels
* changedtick
* modifiable is for buffers (we need). readonly is for the underlying file
* bo is buffer options. Wrapper around nvim_set_option_value
* b is buffer variables. Also a wrapper
* nvim_buf_is_valid
* bunload wipes the buffer memory. However, the buffer still exists (nvim_buf_is_valid)
* Use bwipeout [b] to make a buffer invalid.
* Use vim.api.nvim_list_chans()  to list leaked channels
* x:method = x.method(x)
* vim.uv.new_thread is for actual multithreading
* Use t:stop(), t:start(), t:close() and t:is_closing() (where t is a timer (look at defer_fn ret) to cancel work) for intimate coroutine control
--]]
