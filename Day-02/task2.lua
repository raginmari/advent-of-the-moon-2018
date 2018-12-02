package.path = "?.lua;../?.lua"
local input = require "input"

function eliminate_char_at(str, index)
	if index == 1 then
		return str:sub(2)
	elseif index == #str then
		return str:sub(1, -2) -- Eliminates last character
	else 
		return str:sub(1, index - 1) .. str:sub(index + 1)
	end
end

function solve(input)
	for i = 1, #input - 1 do
		-- Start j from i + 1 or else lines will be 
		-- a) compared to themselves and 
		-- b) compared to lines they have already been compared to
		for j = i + 1, #input do
			local line1 = input[i]
			local line2 = input[j]
			local index = nil
			for k = 1, #line1 do
				local byte = line1:byte(k)
				if byte ~= line2:byte(k) then
					if not index then 
						index = k
					else 
						index = nil
						break
					end
				end
			end

			if index then return eliminate_char_at(line1, index) end
		end
	end
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))