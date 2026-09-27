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

-- TODO: You can make this into a class pattern??
local function rmt_get_ft(rpcch, bufnr)
  return vim.rpcrequest(rpcch, "nvim_get_option_value", "filetype", { buf
  = bufnr })
end

local function rmt_get_buflines(rpcch, bufnr)
  -- TODO: What are these args
  return (vim.rpcrequest(rpcch, "nvim_buf_get_lines", bufnr, 0, -1, false))
end


-- TODO: Can I see the list of coroutines which are running?
-- I can use this for debugging
local function mirror_coro(server_path, remote_buf)
  local cur_buf = vim.api.nvim_get_current_buf() -- TODO Check that it is loaded, etc.
  local rpcch = vim.fn.sockconnect("pipe", server_path, { rpc = true })

  -- Full buffer clone to start..
  local function clone_step()
    local ft = rmt_get_ft(rpcch, remote_buf)
    local lines = rmt_get_buflines(rpcch, remote_buf)

    -- TODO: Readonly..
    vim.bo[cur_buf].modifiable = true
    vim.bo[cur_buf].filetype = ft
    force_replace_buf_lines(cur_buf, lines)
    vim.bo[cur_buf].modifiable = false

    coro_sleep(coro_refresh_tick)
  end

  while true do clone_step() end
end

function M.mirror(server_path, remote_buf)
  coroutine.wrap(function () mirror_coro(server_path, remote_buf) end)()
end

return M
