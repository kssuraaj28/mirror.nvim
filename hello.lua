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

-- Use :lua print(Greeting) to get the value of this global
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

--[[
vim.api.nvim_create_user_command("Hello", function(args)
  greet(args.args ~= "" and args.args or nil)
end, { nargs = "?" })

vim.keymap.set("n", "<leader>h", greet, { desc = "Say hello" })

Loading it
--]]
