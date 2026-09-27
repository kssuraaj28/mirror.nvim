local function callback_loop ()
  print("hello");
  vim.defer_fn(callback_loop, 1000)
end


callback_loop()
