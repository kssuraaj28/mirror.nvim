local function callback_loop (msg)
  print(msg);
  vim.defer_fn(function () callback_loop(msg) end, 1000)
end

callback_loop("hello")
callback_loop("another one")

-- Different from vim.wait because vim.wait is blocking
local function coro_sleep(t)
  local coro = coroutine.running()
  assert(coro, "Must be called when running in a coroutine")
  vim.defer_fn(function () assert(coroutine.resume(coro)) end, t)
  coroutine.yield()
end; local _ = coro_sleep


local coro = coroutine.wrap(function()
    local n = 0
    while true do
      n = n + 1
      print(n)
      coro_sleep(1000)
    end
  end)

coro()
-- TODO: What happens when you have many coro() calls?
-- You are basically queueing up more number of resumes
vim.keymap.set("n", "ZZ", coro)
