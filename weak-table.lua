local l = {}
--[[ 
Keys are weak. Weak values don't make sense to me...
Seem a little bit like destructors. 
'k' does two things:
* instructs gc to ignore keys
* when gc does garbage collect, (k+v removed / sets the value to null)
--]]
setmetatable(l, {__mode = 'k'})

do local k1, k2 = {}, {}; l[k1] = 3; l[k2] = 4 end

assert(vim.tbl_count(l) == 2)
--[[
collectgarbage('collect')
assert(vim.tbl_count(l) == 0)
--]]

do
  local i = 0; while i < 6670 do
  local x = {i}
  l[x] = 67
  i = i + 1
  end
end

print(vim.tbl_count(l))
