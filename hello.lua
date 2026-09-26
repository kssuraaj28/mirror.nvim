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
vim.cmd.echom([["hello"]]) -- Yet another way. TODO: Are these hardcoded? or is there a programatic way for this sugar? I think that there's lua's metatable (and __index, etc. things which are useful for this.. vim.g, etc. are all defined like this..

local x = vim.cmd.call("bufnr(0)") -- You don't get anything
print(x)
local y = vim.fn.bufnr(0) -- Now you do
print(y)

vim.cmd([[
 function! Hello() abort
   echo "Hello there!"
 endfunction
      ]]) -- Let's you do :call Hello()

vim.fn.Hello() -- Now you can call the thing that you just defined!
-- I think that a.x in lua is just a['x']. TODO: Check
-- Also check whether you can define the value to be some kind of computation

-- Use vim.g, vim.b, vim.t, etc. for vim variables too

-- Seems like a better rule of thumb is to use vim.api. These are things that are written in C
-- There are (mostly) three ways to call api functions  
-- 1. lua
-- 2. :call in vim
-- 3. some external program nonsense
--
-- So technically, vim.api.x and vim.fn.x will do the same thing but the fn version is slower
-- because it goes through vimscript. There are functions like nvim_ui_attach, etc. 
-- whch are RPC only, which are lua only etc. Looking at :h api and "Attributes" tells you more

-- Creating vimscript functions using nvim_create_user_command
--
vim.api.nvim_create_user_command("HelloAgain", function()
  print("Yet another way to say hello")
end, { nargs = 0 }) -- Call using :HelloAgain

vim.cmd.HelloAgain() -- Yet another way wow

-- Use vim.keymap.set("n", "<leader>h", greet, { desc = "Say hello" }) to set keybindings

--[[
It is good practice to never set global variables in your lua scripts

local M = {} -- Creating a new local module
return M -- Something you return when you :luafile 

function M.name(args)
    
end
is shorthand for M.name = function ...
local M.name is a syntax error
--]]
