local M = {}

local coro_refresh_tick = 500 -- 0.5s per refresh

local function coro_sleep(t)
  local coro = coroutine.running()
  assert(coro, "Must be called when running in a coroutine")
  vim.defer_fn(function () assert(coroutine.resume(coro)) end, t)
  coroutine.yield()
end; local _ = coro_sleep



--[[
buf: buffer number
lines: array of lines
--]]
local function force_replace_buf_lines(buf, lines)
    -- TODO: Make sure that buf is an integer and not zero..
    local ret = {pcall(vim.api.nvim_buf_set_lines, buf, 0, -1, false, lines)}
    local ok =  ret[1]
    if not ok then
      local err = ret[2]
      error("Buffer replacement error: " .. tostring(err), 0) -- TODO 0?
    end
    ret[1] = nil
    assert(vim.tbl_isempty(ret), "Call must not return anything")
end

local function mirror_coro(server_sock, remote_buf)
  local cur_buf = vim.api.nvim_get_current_buf() -- TODO Check that it is loaded, etc.
  -- local rpcch = vim.fn.sockconnect("pipe", server_sock, { rpc = true })
  local a = 0
  while true do
    local astr = string.format("%d",a)
    force_replace_buf_lines(cur_buf, {astr, 'hello', 'there'})
    a = a + 1
    coro_sleep(coro_refresh_tick)
  end
end

function M.mirror(server_sock, remote_buf)
  coroutine.wrap(function () mirror_coro(server_sock, remote_buf) end)()
end

return M
