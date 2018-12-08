local M = {}

function M.array_append(t, val)
	t[#t + 1] = val
end

function M.array_remove(t, val)
	for i, v in ipairs(t) do 
		if v == val then 
			if i ~= #t then
				t[i] = t[#t] -- Copy last to current index
			end
			t[#t] = nil	
		end
	end
end

function M.set_count(t)
	local c = 0
	for _, _ in pairs(t) do c = c + 1 end
	return c
end

return M