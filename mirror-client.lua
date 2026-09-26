-- Take two arguments: existing server + buffer number
-- Prints the number of lines in the server or something
--
-- Experimental setup
-- two nvim 
-- nvim --listen "/tmp/nvim.test" #Only one server can listen at a time
-- nvim -c "..." # Source this file w the right args
local server, bufno = ... -- TODO: Assert not none?
local rpcch

-- Methods
local init
local get_remote_ft

init = function ()
  rpcch = vim.fn.sockconnect("pipe", server, { rpc = true })
  -- rpc* functions only work on channels opened with rpc = true. TODO: Te
  print(vim.rpcrequest(rpcch, "nvim_eval", "1+2"))
  print(vim.rpcrequest(rpcch, "nvim_command", [[echom "hi"]]))

  vim.print(vim.rpcrequest(rpcch, "nvim_buf_get_lines", bufno, 0, -1, false)) -- TODO: What are these args

  print(get_remote_ft())

  --[[
  Raw mode, where you handle msgpack yourself (the pull design):
  local ch = vim.fn.sockconnect("pipe", "/tmp/nvim.sock", {
    on_data = function(_, data) ... end,
  })
  vim.fn.chansend(ch, vim.mpack.encode({ 0, 1, "nvim_eval", { "1+2" } }))
  --]]
end

get_remote_ft =  function ()
  local ft = vim.rpcrequest(rpcch, "nvim_get_option_value", "filetype", { buf
  = bufno })
  return ft
end


init()
print(server, bufno)
