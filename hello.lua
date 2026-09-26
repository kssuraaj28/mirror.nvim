--[[
How  to setup testing, use either
- nvim -c "source hello.lua"
- nvim -S "hello.lua"

You could also :luafile, which runs any file as a lua file
source records things in :scriptnames
--]]

--[[
local greeting = "hello"
print (greeting)
Greeting = "hello"
print(Greeting) -- writes to messages

-- Use :lua print(Greeting) to get the value of this global. Each :lua invocation has its own scope
-- Local vars have to start with lowercase
--]]


--[[
local function greet()
  local greeting = "hello"
  print(greeting)
end

greet()
--]]

local greet = function ()
  local greeting = "hello"
  print(greeting)
end

greet()

-- Use :h lua-guide in neovim for the lua guide
-- vim.cmd and vim.fn seem to be the 'vim api'
-- vim.api seems to be the 'nvim api'
-- vim.* are the other functions (there's a vim.print, which is different from print. E.g. print(package)

-- Use vim.cmd to run arbitrary vim commands from lua
vim.cmd('echom "Hello"') -- Another way to say hello!
vim.cmd([[echom "Hello"]]) -- Yet another way to say hello using string literals!

--[[
vim.api.nvim_create_user_command("Hello", function(args)
  greet(args.args ~= "" and args.args or nil)
end, { nargs = "?" })

vim.keymap.set("n", "<leader>h", greet, { desc = "Say hello" })

Loading it
--]]
