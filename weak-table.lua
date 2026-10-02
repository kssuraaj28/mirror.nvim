local l = {};
---[[ Keys are weak. Weak values don't make sense to me...
setmetatable(l, {__mode = 'k'}) 
--]]
do local k1, k2 = {}, {}; l[k1] = 3; l[k2] = 4 end

vim.print(l)
collectgarbage('collect')
vim.print(l)
