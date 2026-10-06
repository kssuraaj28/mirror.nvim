# Lua + vim notes
* undolevels=-1 will always "already at oldest / newest change".
* Use vim.api.nvim_list_chans()  to list leaked channels
* x:method = x.method(x)
* vim.uv.new_thread is for actual multithreading
* Use t:stop(), t:start(), t:close() and t:is_closing() (where t is a timer (look at defer_fn ret) to cancel work) for intimate coroutine control
* vim.in_fast_event()
* uv.timeout.
* vim.schedule.

## Various options

For servers
--embed
--listen
--headless

For clients
--remote-ui
--server
--remote-expr

:detach
v:servername

## Module system
- lua/mirror.lua and lua/mirror/init.lua are equivalent, and can both be required using mirror
- files in the lua directory do not run automatically. Only when some code calls require do they run. However, files in the plugin directory do run.

## Misc
vim.api.nvim_list_uis
vim.api.nvim_list_chans
vim.api.nvim_get_chan_info # I think that this just indexes onto chans

┌──────────┬────────────────────────────────────────────────────────┐
│  stream  │                        Meaning                         │
├──────────┼────────────────────────────────────────────────────────┤
│          │ this Neovim's own stdin/stdout, i.e. the pipes from    │
│ "stdio"  │ the parent. This is what the built-in terminal UI      │
│          │ should show.                                           │
├──────────┼────────────────────────────────────────────────────────┤
│ "socket" │ a socket connection, such as a --remote-ui client or a │
│          │  script connected to v:servername                      │
├──────────┼────────────────────────────────────────────────────────┤
│ "job"    │ a process this Neovim started (jobstart), for example  │
│          │ your --embed experiments                               │
├──────────┼────────────────────────────────────────────────────────┤
│ "stderr" │ stderr                                                 │
└──────────┴────────────────────────────────────────────────────────┘

The result also includes mode ("rpc" for these connections) and, if the client identified itself, a client table with its name and version.

To see every connection at once, not just UIs:

:lua =vim.api.nvim_list_chans()


Channels vs UIs
- ch = sockconnect
- rpcrequest(ch,"nvim_ui_attach") # Rpc only 
(Use vim.ui_attach for lua things)


--- Exps
+ Test automatically applying rpcrequest.. 
