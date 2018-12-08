package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse(str)
	return str:match("Step ([A-Z]) must be finished before step ([A-Z]) can begin.")
end

function solve(input)

	local t0 = os.clock()

	local steps = {}
	local constraints = {}
	for _, v in ipairs(input) do
		local a, b = parse(v)
		local t = constraints[b] or {}
		utils.array_append(t, a)
		constraints[b] = t
		steps[a] = 1
		steps[b] = 1
		if not constraints[a] then constraints[a] = {} end -- Creates empty entry for first step
	end

	local ordered_steps = {}
	local steps_count = utils.set_count(steps)
	while #ordered_steps < steps_count do
		-- Find possible next steps
		local next_steps = {}
		for k, t in pairs(constraints) do
			if #t == 0 then utils.array_append(next_steps, k) end
		end

		-- Sort possible next steps if there is more than one
		if #next_steps > 1 then table.sort(next_steps) end

		-- Take first possible next step and append it to the result
		local step = next_steps[1]
		utils.array_append(ordered_steps, step)
		
		-- Remove the step from all constraints
		constraints[step] = nil
		for _, t in pairs(constraints) do utils.array_remove(t, step) end
	end

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	local result = table.concat(ordered_steps, "")

	return result
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))