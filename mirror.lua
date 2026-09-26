local M = {}
local events = {}

function M.print_events()
  print("Printing monitored events")
  for _, e in ipairs(events) do
    print(vim.inspect(e))
  end
end

local function on_lines_callback (...)
  local buf, tick, first, last_old, last_new = ...
  table.insert(events, {
    buf = buf, tick = tick,
    first = first, last_old = last_old, last_new = last_new,})
end

local function panic_callback (...)
  error("Unhandled event: " .. vim.inspect({ ... })) -- We don't know  which function was called.
end; local _ = panic_callback

local function noop_callback (...)
end; local _ = noop_callback

local callback_data = {
    on_lines = {"lines", on_lines_callback},
    on_bytes = {"bytes", noop_callback}, -- on_lines and on_bytes are called together..
    on_changedtick = {"changedtick", panic_callback}, -- undo, redo
    on_reload = {"reload", panic_callback}, -- When? TODO: Test
    on_detach = {"detach", panic_callback}, -- :edit?, :bunload, wiped
}

local function attach_callbacks_to_buf(bufno)
  -- Building callbacks
  local callbacks = {}
  for name, data in pairs(callback_data) do
    local literal, func = data[1], data[2]
    callbacks[name] = function(literal_str, ...)
      assert(literal_str == literal, name .. ": unexpected event " .. tostring(literal_str))
      local results = { pcall(func, ...) }
      local ok = results[1]
      if not ok then
        local err = results[2]
        -- Re-raise, naming the callback (func itself can't know which one it is)
        error(name .. ": " .. tostring(err), 0)
      end
      results[1] = nil
      assert(vim.tbl_isempty(results), name .. ": callback must not return a value")
      -- In the future, callbacks can return something and we can detach by returning true here.
    end
  end
  -- The false ignored for lua callbacks apparently..
  vim.api.nvim_buf_attach(bufno, false, callbacks)
end

function M.start_monitor()
  local cur_buf = vim.api.nvim_get_current_buf()
  print("Current buf is " .. cur_buf)
  attach_callbacks_to_buf(cur_buf)


-- Maybe the first version of mirror should just be a shitty version that redraws on every  notification
-- vim.b solution seems noncanonical. Maybe the right thing to do is to have a global instance

  print("Started monitor on buffer " .. cur_buf)
end

return M
