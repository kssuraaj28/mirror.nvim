local M = {}
local events = {}

function M.print_events()
  print("Printing monitored events")
  for _, e in ipairs(events) do
    print(vim.inspect(e))
  end
end

function M.start_monitor()
  local cur_buf = vim.api.nvim_get_current_buf()
  print("Current buf is " .. cur_buf)

  -- The false ignored for lua callbacks apparently..
  vim.api.nvim_buf_attach(cur_buf, false, {
    on_lines = -- A syncronous callback for every buffer change
      function(literal_str, ...)
        assert(literal_str == "lines")

        local buf, tick, first, last_old, last_new = ...
        table.insert(events, {
          buf = buf, tick = tick,
          first = first, last_old = last_old, last_new = last_new,})
      end})
-- TODO: Have on_reload (:edit, :checktime)
-- TODO: Have on_detach (:unloaded / wiped)
-- Maybe the first version of mirror should just be a shitty version that redraws on every  notification

  print("Started monitor on buffer " .. cur_buf)
end

return M
