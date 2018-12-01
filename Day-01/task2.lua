package.path = "?.lua;../?.lua"
local input = require "input"

function solve(input)
	local history = {}
	local freq = 0

	while true do
		for _, v in ipairs(input) do
			freq = freq + tonumber(v)
			if history[freq] then return freq end
			history[freq] = 1
		end
	end
end

local input = input.read_file("input.txt")
print("Solution: " .. solve(input))