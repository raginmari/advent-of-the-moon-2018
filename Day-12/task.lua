package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse_initial_state(str)
	return str:match("([%.#]+)")
end

function parse_rule(str)
	return str:match("([%.#]+) => ([%.#]+)")
end

function solve(input)

	local t0 = os.clock()

	local input = utils.array_filter(input, function(a) return a:len() > 0 end)

	local pots = parse_initial_state(input[1])

	local rules = {}
	for i = 2, #input do
		local pattern, value = parse_rule(input[i])
		print(string.format("rule %s => %s", pattern, value))
		if value == '#' then rules[pattern] = value end
	end

	pots = ".." .. pots .. ".."
	local first_number = -2

	for g = 1, 20 do
		-- Append empty pots to the left and right of the existing pots
		local prev_pots = ".." .. pots .. ".."
		first_number = first_number - 2
		local next_pots = ".."
		for i = 3, #prev_pots - 2 do 
			local pat = prev_pots:sub(i - 2, i + 2) -- Fetches five characteres
			local val = rules[pat] or "."
			next_pots = next_pots .. val
		end
		next_pots = next_pots .. ".."
		pots = next_pots
	end

	local sum = 0
	for i = 1, #pots do
		local byte = pots:byte(i)
		if byte == 35 then -- '#' is ASCII 35
			local number = first_number + i - 1
			sum = sum + number
		end
	end

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return sum
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))
