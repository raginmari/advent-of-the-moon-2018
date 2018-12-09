package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse(str)
	local t = {}
	for i in string.gmatch(str, "%S+") do utils.array_append(t, i) end
	return t
end

function read_next(t)
	local val = tonumber(t[#t])
	t[#t] = nil -- Consume the entry
	return val
end

function parse_tree(t)
	-- Read header
	local num_children = read_next(t)
	local num_metadata = read_next(t)
	local num = 0

	if num_children == 0 then
		-- Sum metadata entries of this node
		for _ = 1, num_metadata do
			num = num + read_next(t)
		end
	else
		local child_values = {}
		-- Compute values of all child nodes (recurses for each child)
		for _ = 1, num_children do
			utils.array_append(child_values, parse_tree(t))
		end

		-- Sum values of referenced child nodes
		for _ = 1, num_metadata do
			local index = read_next(t)
			if index ~= 0 and index <= #child_values then
				num = num + child_values[index]
			end
		end
	end

	return num
end

function solve(input)

	local t0 = os.clock()

	local numbers = parse(input[1])
	-- The algorithm consumes numbers back to front
	utils.array_reverse(numbers)
	
	local sum_metadata = parse_tree(numbers)

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return math.floor(sum_metadata)
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))