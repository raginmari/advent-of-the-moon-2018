package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function hundred_digit(num)
	local n = 1000
	local floor = math.floor
	while true do
		local q = floor(num / n)
		if q == 0 then break end
		num = num - q * n
		n = n * 10
	end
	return math.floor(num / 100)
end

function grid_xy(index)
	index = index - 1
	local y = math.floor(index / 300)
	local x = index - y * 300
	return x + 1, y + 1
end

function grid_sum(pw, index)
	local x, y = grid_xy(index)
	if x > 298 or y > 298 then return 0 end
	local offsets = { 0, 1, 2, 300, 301, 302, 600, 601, 602 }
	local sum = 0
	for _, i in ipairs(offsets) do
		sum = sum + pw[index + i]
	end
	return sum
end

function solve(input)

	local t0 = os.clock()

	local power_levels = {}
	for y = 1, 300 do
		for x = 1, 300 do
			local rack_id = x + 10
			local pw = rack_id * y
			pw = pw + input
			pw = pw * rack_id
			pw = hundred_digit(pw)
			pw = pw - 5
			power_levels[#power_levels + 1] = pw
		end
	end

	local max = nil
	local max_index = nil
	for i = 1, #power_levels do
		local sum = grid_sum(power_levels, i)
		if not max or sum > max then
			max = sum
			max_index = i
		end
	end

	local x, y = grid_xy(max_index)
	local result = table.concat({x, y}, ",")

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local input = 2694
print("Solution: " .. (solve(input) or "not found"))
