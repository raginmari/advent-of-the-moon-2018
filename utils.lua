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

function M.array_filter(t, f)
	local filtered = {}
	for _, v in ipairs(t) do 
		if f(v) then M.array_append(filtered, v) end
	end
	return filtered
end

function M.array_reverse(t)
	local i, j = 1, #t
	while i < j do
		t[i], t[j] = t[j], t[i]
		i = i + 1
		j = j - 1
	end
end

function M.array_print(t)
	for _, v in ipairs(t) do print(v) end
end

function M.set_count(t)
	local c = 0
	for _, _ in pairs(t) do c = c + 1 end
	return c
end

return M