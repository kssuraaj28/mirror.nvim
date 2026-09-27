
vim.print(coroutine.running())
-- coroutine.yield() Will fail because you are not in a coroutine..
-- :h lua-coroutine
local x -- Only then you refer to the right x in the body.. Scoping rules
x = coroutine.create(
    function()
      assert(x == coroutine.running())
      print("hi")
      coroutine.yield(39)
      print("how are you")
      return 40
    end)
vim.print('!!'..type(x))
-- x is of type thread (print its type!)
-- x() -- This will fail 
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})
vim.print({coroutine.resume(x)})

-- coroutine.wrap is very similar to create
