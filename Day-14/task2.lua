package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

local floor = math.floor

function digits(number) -- Does not work with numbers > 99!
	local tens = floor(number / 10)
	local rest = number - tens * 10
	return tens, rest
end

function digits_of_string(str)
	local chars = {}
	for i = 1, #str do 
		chars[#chars + 1] = str:byte(i) - 48 
	end
	return chars
end

function check(recipes, pattern)
	if #recipes < #pattern then return end
	for i = 1, #pattern do
		if recipes[#recipes - #pattern + i] ~= pattern[i] then return end
	end
	return true
end

function solve(input)

	local t0 = os.clock()

	local recipes = { 3, 7 }
	local elf1 = 1
	local elf2 = 2

	local input_digits = digits_of_string(input)
	utils.array_print(input_digits)

	while true do
		local score1 = recipes[elf1]
		local score2 = recipes[elf2]
		local digit1, digit2 = digits(score1 + score2)
		if digit1 > 0 then
			recipes[#recipes + 1] = digit1
			if check(recipes, input_digits) then break end
		end

		recipes[#recipes + 1] = digit2
		if check(recipes, input_digits) then break end

		elf1 = 1 + (elf1 + score1) % #recipes
		elf2 = 1 + (elf2 + score2) % #recipes
	end

	local result = #recipes - #input_digits

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local input = arg[1] or "293801"
print("Solution: " .. (solve(input) or "not found"))
