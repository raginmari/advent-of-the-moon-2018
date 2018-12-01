package.path = "?.lua;../?.lua"
local input = require "input"

function solve(input)
	local freq = 0
	for _, v in ipairs(input) do
		freq = freq + tonumber(v)
	end

	return freq
end

local input = input.read_file("input.txt")
print("Solution: " .. solve(input))