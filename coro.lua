
-- coroutine.yield() Will fail because you are not in a coroutine..
-- :h lua-coroutine
local x = coroutine.create(
    function()
      print("hi")
      coroutine.yield(39)
      print("how are you")
      return 40
    end)
-- x is of type thread (print its type!)
-- x() -- This will fail 
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})
