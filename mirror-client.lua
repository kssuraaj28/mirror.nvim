-- Take two arguments: existing server + buffer number
-- Prints the number of lines in the server or something
--
-- Experimental setup
-- two nvim 
-- nvim --listen "/tmp/nvim.test" #Only one server can listen at a time
-- nvim -c "..." # Source this file w the right args
local server, bufno = ... -- TODO: Assert not none?

local function connect()
  local rpcch = vim.fn.sockconnect("pipe", server, { rpc = true })
  print(vim.rpcrequest(rpcch, "nvim_eval", "1+2"))
  print(vim.rpcrequest(rpcch, "nvim_command", [[echom "hi"]]))
  --[[
  Raw mode, where you handle msgpack yourself (the pull design):
  local ch = vim.fn.sockconnect("pipe", "/tmp/nvim.sock", {
    on_data = function(_, data) ... end,
  })
  vim.fn.chansend(ch, vim.mpack.encode({ 0, 1, "nvim_eval", { "1+2" } }))
  --]]
end

connect()
print(server, bufno)
