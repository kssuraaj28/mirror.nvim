--[[
Usage: local mod =  require(...)
mod.mirror('socket', bufnr)
mod.stop_mirroring()
--]]

--@diagnostic disable: unused-function
--@diagnostic disable: unused-local

local M = {}

-- Use set rtp+='...' to test locally
local spawn = require('chill').spawn

local function force_replace_buf_lines(buf, lines)
  -- TODO: Make sure that buf is an integer and not zero..
  local ret = {vim.api.nvim_buf_set_lines (buf, 0, -1, false, lines)}
  assert(vim.tbl_isempty(ret), "Call must not return anything")
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

  local function close()
    vim.fn.chanclose(rpcch)
  end

  --Closures can be expensive because we make a copy of functions for every object
  --Lua has x:method and metatables which can be cheaper. You lose encapsulation tho
  return {
    get_ft = get_ft,
    get_buflines = get_buflines,
    get_tick = get_tick,
    close = close,
  }
end

local function queue()
  local data = {}
  return {
      push = function(elm)
          assert(elm ~= nil, "Cannot push nil")
          table.insert(data,elm)
      end,
      pop = function() return table.remove(data,1) end,
  }
end

-- Message queue
local send_msg
local register_to_queue_db
local unregister_from_queue_db
do
  local db = {}
  register_to_queue_db = function (send_fn)
    local c = assert(coroutine.running())
    assert(not db[c])
    db[c] = send_fn
  end

  unregister_from_queue_db = function ()
    local c = assert(coroutine.running())
    assert(db[c])
    db[c] = nil
  end

  send_msg = function (coro, msg)
     db[coro](msg)
  end
end

local buf_to_coro = {}

local stop_tkn = {}
function M.stop_mirroring()
  local coro = assert(buf_to_coro[vim.api.nvim_get_current_buf()], "No coroutine associated with buffer")
  send_msg(coro, stop_tkn)
end

local function todo_error_call(f)
  local ok, ret = pcall(f)
  if not ok then error("Unhandled") end
  return ret
end

local function mirror_coro(server_path, remote_buf, chill)
  --Create a new visible + scratch buffer 
  --A scratch buffer has buftype=nofile,
  --so it can never be associated with a file..
  local thiscoro = assert(coroutine.running())
  local remote = cnstrct_rmt_bf(server_path, remote_buf)

  local newbuf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(newbuf) -- TODO Check that it is loaded, etc.
  -- Many things run synchronously when this runs (autocommands, etc.)

  -- this : format thing useds string __index + lua's : sugar
  -- Putting local buffer name makes this unique
  vim.api.nvim_buf_set_name(newbuf, ('mirror:%s [%d] -> (%d)'):format(server_path, remote_buf, newbuf))
  vim.bo[newbuf].undolevels = -1

  buf_to_coro[newbuf] = thiscoro
  local msg_queue = queue()
  register_to_queue_db(msg_queue.push)

  local function update_ft()
  -- bo is buffer options. Wrapper around nvim_set_option_value
  -- b is buffer variables. Also a wrapper
    local ftlcl = vim.bo[newbuf].filetype
    local ftrmt = todo_error_call(remote.get_ft)
    if ftlcl ~= ftrmt then vim.bo[newbuf].filetype = ftrmt end
  end

  local tickrmt = 0
  local function update_lines()
    local newtickrmt = todo_error_call(remote.get_tick)

    if tickrmt ~= newtickrmt then
      assert (newtickrmt > tickrmt)
      tickrmt = newtickrmt
      local lines = todo_error_call(remote.get_buflines)

      -- modifiable is for buffers (we need). 
      -- readonly is for the underlying file
      vim.bo[newbuf].modifiable = true
      force_replace_buf_lines(newbuf, lines)
      vim.bo[newbuf].modifiable = false
    end
  end


  local function handle_msgs_for_exit()
    while true do
      local msg = msg_queue.pop()
      if not msg then break end
      if (msg  == stop_tkn) then
        return true
      else
        error("Unhandled message")
      end
    end
  end

  while true do
    if handle_msgs_for_exit() then break end
    assert(vim.api.nvim_buf_is_valid(newbuf), "Buffer should be valid") -- bwipe does not do cleanup.. We really need RAII
    update_ft() -- You can get filetype, tick, etc atomic later for optimization
    update_lines()
    chill() -- TODO: Make this event driven later.
  end

  -- Cleanup. Ideally, we'd have some RAII
  -- I'm assuming that any error from the coroutine is a bug.
  unregister_from_queue_db()
  buf_to_coro[newbuf] = nil
  -- wipeout the buffer (not just unload. The buffer is now invalid)
  vim.api.nvim_buf_delete(newbuf, {}) -- You don't need to have a force = true
  remote.close()
end

function M.mirror(server_path, remote_buf)
  spawn(function(chill) mirror_coro(server_path, remote_buf, chill) end)
end

return M
