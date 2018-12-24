package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function digits(number)
	local tens = math.floor(number / 10)
	local rest = number - tens * 10
	return tens, rest
end

function visualize(recipes, elves)
	local components = {}
	for i, r in ipairs(recipes) do
		if i == elves[1] then
			components[#components + 1] = "(" .. r .. ")"
		elseif i == elves[2] then
			components[#components + 1] = "[" .. r .. "]"
		else
			components[#components + 1] = " " .. r .. " "
		end
	end

	local string = table.concat(components, "")
	print(string)
end

function solve(input)

	local t0 = os.clock()

	local recipes = { 3, 7 }
	local elves = { 1, 2 }

	-- visualize(recipes, elves)

	while #recipes < input + 10 do
		local elf1 = elves[1]
		local elf2 = elves[2]
		local score1 = recipes[elf1]
		local score2 = recipes[elf2]
		local digit1, digit2 = digits(score1 + score2)
		if digit1 > 0 then recipes[#recipes + 1] = digit1 end
		recipes[#recipes + 1] = digit2

		elves[1] = 1 + (elf1 + score1) % #recipes
		elves[2] = 1 + (elf2 + score2) % #recipes
		
		-- visualize(recipes, elves)
	end

	local last_ten = utils.subarray(recipes, #recipes - 9, #recipes)
	local result = table.concat(last_ten, "")

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local input = tonumber(arg[1]) or 293801
print("Solution: " .. (solve(input) or "not found"))
