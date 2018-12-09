package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse(str)
	return str:match("Step ([A-Z]) must be finished before step ([A-Z]) can begin.")
end

function possible_steps(constraints)
	local steps = {}
	for k, t in pairs(constraints) do
		if #t == 0 then utils.array_append(steps, k) end
	end
	if #steps > 1 then table.sort(steps) end
	return steps
end

function duration(step)
	return 60 + step:byte(1) - 64
end

function finish_step(step, constraints)
	for _, t in pairs(constraints) do utils.array_remove(t, step) end
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

	-- Create idle workers
	local workers = {}
	for i = 1, 5 do utils.array_append(workers, { done_time = 0 }) end

	local timer = 0
	local steps_done = {}
	local steps_count = utils.set_count(steps)
	local min = math.min
	while #steps_done < steps_count do

		-- Find idle workers
		local idle_workers = utils.array_filter(workers, function(a) return not a.step end)
		-- Find possible next steps
		local next_steps = possible_steps(constraints)
		
		if #next_steps > 0 then
			-- Assign as many new steps to idle workers as possible
			local lim = min(#idle_workers, #next_steps)
			for i = 1, lim do 
				local step = next_steps[i]
				local worker = idle_workers[i]
				worker.step = step
				worker.done_time = timer + duration(step)
				constraints[step] = nil
			end
		end

		-- Find the worker who finishes his current step the earliest
		local busy_workers = utils.array_filter(workers, function(a) return a.step end)
		table.sort(busy_workers, function(a, b) return a.done_time < b.done_time end)
		local worker = busy_workers[1]

		-- Finish the worker's step
		finish_step(worker.step, constraints)
		utils.array_append(steps_done, worker.step)

		-- Update the current time
		timer = worker.done_time

		-- Mark the worker idle
		worker.step = nil
	end

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return timer
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))