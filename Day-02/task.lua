package.path = "?.lua;../?.lua"
local input = require "input"

function count_characters(str)
	local counts = {}
	for i = 1, #str do
		local b = str:byte(i)
		counts[b] = (counts[b] or 0) + 1
	end

	return counts
end

function find_count(counted, num)
	for _, v in pairs(counted) do
		if v == num then return true end
	end
end

function solve(input)
	local count2 = 0
	local count3 = 0
	for _, line in ipairs(input) do
		local counted = count_characters(line)
		if find_count(counted, 2) then count2 = count2 + 1 end
		if find_count(counted, 3) then count3 = count3 + 1 end
	end

	return count2 * count3
end

local input = input.read_file("input.txt")
print("Solution: " .. solve(input))